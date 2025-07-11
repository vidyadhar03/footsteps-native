import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'dart:io';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;
  final ProfileRepository _profileRepository = ProfileRepository();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCompletedOnboarding = false;
  bool _needsProfileSetup = false;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get needsProfileSetup => _needsProfileSetup;
  bool get isSupabaseConfigured => SupabaseConfig.isConfigured;

  AuthService() {
    // Initialize Google Sign-In with platform-specific client IDs
    // For basic sign-in, we only need the platform-specific client IDs
    if (kIsWeb) {
      // Web platform uses default initialization; Supabase handles OAuth flow.
      _googleSignIn = GoogleSignIn();
    } else {
      try {
        if (Platform.isAndroid) {
          // Android uses default initialization - the google-services.json handles configuration
          _googleSignIn = GoogleSignIn();
        } else if (Platform.isIOS) {
          // iOS requires explicit clientId configuration
          _googleSignIn = GoogleSignIn(
            clientId: SupabaseConfig.googleClientIdIos,
          );
        } else {
          // Fallback for other platforms
          _googleSignIn = GoogleSignIn();
        }
      } catch (e) {
        // Platform lookup may fail in unit tests or unsupported platforms
        _googleSignIn = GoogleSignIn();
        if (kDebugMode) {
          print('GoogleSignIn initialization fallback: $e');
        }
      }
    }

    // Initialize app state
    _initializeAppState();
  }

  // Initialize app state and check existing session
  Future<void> _initializeAppState() async {
    // First, load onboarding state
    await _loadOnboardingState();

    // Only set up auth listener if Supabase is configured
    if (isSupabaseConfigured) {
      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });

      // Check for existing session
      await _checkExistingSession();
    }
  }

  // Load onboarding state from SharedPreferences
  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasCompletedOnboarding =
          prefs.getBool('has_completed_onboarding') ?? false;

      if (kDebugMode) {
        print('Loaded onboarding state: $_hasCompletedOnboarding');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading onboarding state: $e');
      }
    }
  }

  // Mark onboarding as completed (called after successful login)
  Future<void> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
      _hasCompletedOnboarding = true;

      if (kDebugMode) {
        print('Onboarding marked as completed');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error marking onboarding completed: $e');
      }
    }
  }

  Future<void> _checkExistingSession() async {
    if (!isSupabaseConfigured) return;

    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking existing session: $e');
      }
    }
  }

  // Note: Profile loading for existing sessions removed - 
  // Profile will be created/updated when needed via the unified upsert endpoint

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Google Sign-In Flow - Optimized for all platforms
  Future<bool> signInWithGoogle() async {
    if (!isSupabaseConfigured) {
      _setError(
        'Please configure your Supabase credentials in the .env.local file to enable authentication.',
      );
      return false;
    }

    if (SupabaseConfig.googleClientIdForPlatform == null) {
      _setError(
        'Please configure your Google Client ID for this platform in the .env.local file to enable Google Sign-In.',
      );
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      if (kIsWeb) {
        // WEB PLATFORM: Use Supabase's OAuth provider flow
        return await _signInWithGoogleWeb();
      } else {
        // MOBILE PLATFORMS: Use Google Sign-In plugin + Supabase idToken flow
        return await _signInWithGoogleMobile();
      }
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Google sign-in error: $e');
      }
      
      // Handle expected vs unexpected errors
      if (e is AuthException || e.toString().contains('sign_in_canceled') || e.toString().contains('network_error')) {
        _setError('Google sign-in failed: ${e.toString()}');
        return false;
      } else {
        // Unexpected error - rethrow for better debugging
        _setError('An unexpected error occurred during Google sign-in');
        rethrow;
      }
    }
  }

  // WEB: Use Supabase's built-in Google OAuth provider
  Future<bool> _signInWithGoogleWeb() async {
    try {
      if (kDebugMode) {
        print('Starting web Google OAuth flow via Supabase');
      }

      // Use Supabase's Google OAuth provider - this will redirect to Google
      // and automatically create the user in Supabase
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'http://localhost:3000', // Your app URL
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      // The browser will redirect to Google OAuth
      // User will be redirected back automatically
      // Supabase will handle user creation
      // We don't wait for the result here as it's a redirect
      // Note: markOnboardingCompleted() will be called from the UI when auth state changes

      if (kDebugMode) {
        print('OAuth redirect initiated - user will be redirected to Google');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Web Google OAuth error: $e');
      }
      rethrow;
    }
  }

  // MOBILE: Use Google Sign-In plugin + Supabase integration
  Future<bool> _signInWithGoogleMobile() async {
    try {
      if (kDebugMode) {
        print('Starting mobile Google Sign-In flow');
      }

      // Step 1: Google Sign-In via plugin
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        _setLoading(false);
        return false;
      }

      // Step 2: Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (kDebugMode) {
        print(
          'Google Auth - Access Token: ${accessToken != null ? 'Present' : 'Missing'}',
        );
        print(
          'Google Auth - ID Token: ${idToken != null ? 'Present' : 'Missing'}',
        );
      }

      // Step 3: Validate tokens
      if (accessToken == null) {
        throw Exception('Failed to get Google access token');
      }

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Step 4: Sign in to Supabase with Google credentials
      // This will automatically create the user in Supabase
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        _user = response.user;
        await _saveUserPreferences();

        // Check user profile after successful authentication
        await _checkUserProfile();

        // Mark onboarding as completed for mobile platforms
        await markOnboardingCompleted();

        _setLoading(false);

        if (kDebugMode) {
          print('Mobile Google Sign-In successful - User created in Supabase');
        }

        return true;
      } else {
        throw Exception('Supabase authentication failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Mobile Google Sign-In error: $e');
      }
      rethrow;
    }
  }

  // Phone Sign-In Flow (OTP)
  Future<bool> signInWithPhone(String phoneNumber) async {
    if (!isSupabaseConfigured) {
      _setError(
        'Please configure your Supabase credentials in the .env.local file to enable authentication.',
      );
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
        shouldCreateUser: true,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Phone sign-in error: $e');
      }
      
      // Handle expected vs unexpected errors
      if (e is AuthException) {
        _setError('Phone sign-in failed: ${e.message}');
        return false;
      } else {
        // Unexpected error - rethrow for better debugging
        _setError('An unexpected error occurred during phone sign-in');
        rethrow;
      }
    }
  }

  // Verify OTP for phone sign-in
  Future<bool> verifyOTP(String phoneNumber, String otpCode) async {
    if (!isSupabaseConfigured) {
      _setError(
        'Please configure your Supabase credentials in the .env.local file to enable authentication.',
      );
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final AuthResponse response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: OtpType.sms,
      );

      if (response.user != null) {
        _user = response.user;
        await _saveUserPreferences();

        // Check user profile after successful authentication
        await _checkUserProfile();

        // Mark onboarding as completed after successful OTP verification
        await markOnboardingCompleted();

        _setLoading(false);
        return true;
      } else {
        throw const AuthException('OTP verification failed - no user returned');
      }
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('OTP verification error: $e');
      }
      
      // Handle expected vs unexpected errors
      if (e is AuthException) {
        _setError('OTP verification failed: ${e.message}');
        return false;
      } else {
        // Unexpected error - rethrow for better debugging
        _setError('An unexpected error occurred during OTP verification');
        rethrow;
      }
    }
  }

  // Demo sign-in for when Supabase isn't configured
  Future<bool> signInDemo() async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate sign-in delay
      await Future<void>.delayed(const Duration(seconds: 1));

              // Create a mock user for demo purposes
        _user = const User(
          id: 'demo-user-123',
          appMetadata: {},
          userMetadata: {'full_name': 'Demo User', 'avatar_url': ''},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00.000Z',
        );

      await _saveUserPreferences();

      // Mark onboarding as completed for demo login too
      await markOnboardingCompleted();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Demo sign-in failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Supabase (only if configured)
      if (isSupabaseConfigured) {
        await _supabase.auth.signOut();
      }

      // Clear user preferences
      await _clearUserPreferences();

      _user = null;
      _userProfile = null;
      _setLoading(false);
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
      _setLoading(false);
      if (kDebugMode) {
        print('Sign out error: $e');
      }
    }
  }

  // Save user preferences using secure storage for sensitive data
  Future<void> _saveUserPreferences() async {
    try {
      if (_user != null) {
        // Store sensitive user data in secure storage
        await _secureStorage.write(key: 'user_id', value: _user!.id);
        await _secureStorage.write(key: 'user_email', value: _user!.email ?? '');
        
        // Store non-sensitive authentication state in shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user preferences: $e');
      }
    }
  }

  // Clear user preferences (but preserve onboarding state)
  Future<void> _clearUserPreferences() async {
    try {
      // Clear sensitive data from secure storage
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_email');
      
      // Clear authentication state from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);

      // IMPORTANT: Don't clear 'has_completed_onboarding'
      // Onboarding state should persist even after logout
      // Only gets reset on app reinstall/uninstall

      if (kDebugMode) {
        print('Cleared user auth data, preserved onboarding state');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user preferences: $e');
      }
    }
  }

  // Get user profile information
  String get userDisplayName {
    if (_user == null) return '';
    return (_user!.userMetadata?['full_name'] as String?) ??
        (_user!.userMetadata?['name'] as String?) ??
        _user!.email?.split('@')[0] ??
        'User';
  }

  String get userEmail => _user?.email ?? '';

  String get userAvatarUrl => (_user?.userMetadata?['avatar_url'] as String?) ?? '';

  // Check if user profile exists after authentication
  Future<void> _checkUserProfile() async {
    if (_user == null) return;

    try {
      if (kDebugMode) {
        print('Checking user profile for: ${_user!.id}');
      }

      // Check if profile exists
      final response = await _profileRepository.getUserProfile();
      
      if (response['success'] == true && response['data'] != null) {
        // Profile exists - load it
        _userProfile = UserProfile.fromJson(response['data'] as Map<String, dynamic>);
        _needsProfileSetup = false;
        
        if (kDebugMode) {
          print('User profile loaded successfully');
        }
      } else {
        // Profile doesn't exist - user needs to set it up
        _userProfile = null;
        _needsProfileSetup = true;
        
        if (kDebugMode) {
          print('User profile not found - needs setup');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user profile: $e');
      }
      // On error, assume profile setup is needed
      _needsProfileSetup = true;
      notifyListeners();
    }
  }

  // Create or update user profile (called from UpdateProfileScreen)
  Future<bool> createOrUpdateProfile(UserProfile profile) async {
    if (_user == null) return false;

    try {
      if (kDebugMode) {
        print('Creating/updating user profile for: ${_user!.id}');
      }

      // Call the upsert endpoint
      final response = await _profileRepository.upsertUserProfile(profile);
      
      // Handle response and extract profile data
      if (response['success'] == true && response['data'] != null) {
        _userProfile = UserProfile.fromJson(response['data'] as Map<String, dynamic>);
        _needsProfileSetup = false;
        
        final isNewProfile = response['isNewProfile'] as bool? ?? false;
        
        if (kDebugMode) {
          if (isNewProfile) {
            print('New user profile created successfully');
          } else {
            print('User profile updated successfully');
          }
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid API response: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating/updating user profile: $e');
      }
      _setError('Failed to save profile: ${e.toString()}');
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _setError(null);
  }
}
