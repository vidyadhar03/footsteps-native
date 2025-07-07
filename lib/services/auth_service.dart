import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'dart:io';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCompletedOnboarding = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isSupabaseConfigured => SupabaseConfig.isConfigured;

  AuthService() {
    // Initialize Google Sign-In with correct client IDs per platform
    // On Android, the GoogleSignIn plugin expects the *server* (web) client ID
    // via the `serverClientId` parameter, **not** the Android client ID.
    // Passing the Android client ID triggers a DEVELOPER_ERROR (code 10).
    if (kIsWeb) {
      // Web platform uses default initialization; Supabase handles OAuth flow.
      _googleSignIn = GoogleSignIn();
    } else {
      try {
        if (Platform.isAndroid) {
          // Use the WEB client ID as serverClientId on Android
          _googleSignIn = GoogleSignIn(
            serverClientId: SupabaseConfig.googleClientIdWeb,
          );
        } else if (Platform.isIOS) {
          // iOS still requires its own clientId, but serverClientId should be the web client ID
          _googleSignIn = GoogleSignIn(
            clientId: SupabaseConfig.googleClientIdIos,
            serverClientId: SupabaseConfig.googleClientIdWeb,
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
      _setError('Google sign-in failed: ${e.toString()}');
      _setLoading(false);
      if (kDebugMode) {
        print('Google sign-in error: $e');
      }
      return false;
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
      _setError('Phone sign-in failed: ${e.toString()}');
      _setLoading(false);
      if (kDebugMode) {
        print('Phone sign-in error: $e');
      }
      return false;
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

        // Mark onboarding as completed after successful OTP verification
        await markOnboardingCompleted();

        _setLoading(false);
        return true;
      } else {
        throw Exception('OTP verification failed');
      }
    } catch (e) {
      _setError('OTP verification failed: ${e.toString()}');
      _setLoading(false);
      if (kDebugMode) {
        print('OTP verification error: $e');
      }
      return false;
    }
  }

  // Demo sign-in for when Supabase isn't configured
  Future<bool> signInDemo() async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate sign-in delay
      await Future.delayed(const Duration(seconds: 1));

      // Create a mock user for demo purposes
      _user = User(
        id: 'demo-user-123',
        appMetadata: {},
        userMetadata: {'full_name': 'Demo User', 'avatar_url': ''},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
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
      _setLoading(false);
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
      _setLoading(false);
      if (kDebugMode) {
        print('Sign out error: $e');
      }
    }
  }

  // Save user preferences
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_email', _user!.email ?? '');
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
      final prefs = await SharedPreferences.getInstance();
      // Clear authentication data
      await prefs.remove('user_id');
      await prefs.remove('user_email');
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
    return _user!.userMetadata?['full_name'] ??
        _user!.userMetadata?['name'] ??
        _user!.email?.split('@')[0] ??
        'User';
  }

  String get userEmail => _user?.email ?? '';

  String get userAvatarUrl => _user?.userMetadata?['avatar_url'] ?? '';

  // Clear error message
  void clearError() {
    _setError(null);
  }
}
