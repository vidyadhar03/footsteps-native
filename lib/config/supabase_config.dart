import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const String _googleClientIdAndroidKey = 'GOOGLE_CLIENT_ID_ANDROID';
  static const String _googleClientIdIosKey = 'GOOGLE_CLIENT_ID_IOS';
  static const String _googleClientIdWebKey = 'GOOGLE_CLIENT_ID_WEB';

  static String get supabaseUrl {
    final url = dotenv.env[_supabaseUrlKey];
    if (url == null || url.isEmpty || url.contains('your_supabase_url_here')) {
      if (kDebugMode) {
        // Return a dummy URL for development/testing
        return 'https://dummy.supabase.co';
      }
      throw Exception('SUPABASE_URL not configured in .env.local file');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env[_supabaseAnonKeyKey];
    if (key == null ||
        key.isEmpty ||
        key.contains('your_supabase_anon_key_here')) {
      if (kDebugMode) {
        // Return a dummy key for development/testing
        return 'dummy_anon_key_for_development';
      }
      throw Exception('SUPABASE_ANON_KEY not configured in .env.local file');
    }
    return key;
  }

  static String? get googleClientId {
    final clientId = dotenv.env[_googleClientIdAndroidKey];
    if (clientId == null ||
        clientId.isEmpty ||
        clientId.contains('your_google_client_id_here')) {
      if (kDebugMode) {
        print(
          'Google Client ID (Android) not configured - Google Sign-In will not work on Android',
        );
      }
      return null;
    }
    return clientId;
  }

  static String? get googleClientIdIos {
    final clientId = dotenv.env[_googleClientIdIosKey];
    if (clientId == null ||
        clientId.isEmpty ||
        clientId.contains('your_google_client_id_ios_here')) {
      if (kDebugMode) {
        print(
          'Google Client ID (iOS) not configured - Google Sign-In will not work on iOS',
        );
      }
      return null;
    }
    return clientId;
  }

  static String? get googleClientIdWeb {
    final clientId = dotenv.env[_googleClientIdWebKey];
    if (clientId == null ||
        clientId.isEmpty ||
        clientId.contains('your_google_client_id_web_here')) {
      if (kDebugMode) {
        print(
          'Google Client ID (Web) not configured - Google Sign-In will not work on Web',
        );
      }
      return null;
    }
    return clientId;
  }

  static String? get googleClientIdForPlatform {
    // Handle web platform first
    if (kIsWeb) {
      // For web, we use the web client ID
      return googleClientIdWeb;
    }

    // For mobile platforms, use platform-specific detection
    try {
      if (Platform.isAndroid) {
        return googleClientId;
      } else if (Platform.isIOS) {
        return googleClientIdIos;
      }
    } catch (e) {
      // If platform detection fails (e.g., on web), default to web client ID
      if (kDebugMode) {
        print('Platform detection failed, defaulting to web client ID: $e');
      }
      return googleClientIdWeb;
    }
    return null;
  }

  static bool get isConfigured {
    try {
      final url = dotenv.env[_supabaseUrlKey];
      final key = dotenv.env[_supabaseAnonKeyKey];
      return url != null &&
          key != null &&
          !url.contains('your_supabase_url_here') &&
          !key.contains('your_supabase_anon_key_here') &&
          url.isNotEmpty &&
          key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> initialize() async {
    try {
      // Try to load environment variables
      await dotenv.load(fileName: '.env.local').catchError((error) {
        if (kDebugMode) {
          print('Warning: Could not load .env.local file: $error');
        }
        return;
      });

      // Only initialize Supabase if we have valid configuration
      if (isConfigured) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          debug: kDebugMode,
        );

        if (kDebugMode) {
          print('Supabase initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('Supabase not configured - running in demo mode');
        }
        // Initialize with dummy values for development
        await Supabase.initialize(
          url: 'https://dummy.supabase.co',
          anonKey: 'dummy_anon_key_for_development',
          debug: kDebugMode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Supabase: $e');
      }
      // Don't rethrow in debug mode to allow app to run
      if (!kDebugMode) {
        rethrow;
      }
    }
  }
}
