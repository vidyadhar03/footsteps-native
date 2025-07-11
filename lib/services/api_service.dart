import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ApiService {
  static const String baseUrl = 'https://footstepsapi.vercel.app';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add request interceptor to automatically add JWT token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session?.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${session!.accessToken}';
        }
        options.headers['Content-Type'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // Check if user profile exists and get profile data
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/profile/user/profile');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw ApiException('Failed to get user profile');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // User profile not found - this is expected for new users
        return {
          'success': false,
          'message': 'User profile not found',
          'isNewUser': true,
        };
      }
      throw ApiException('Failed to get user profile: ${e.message}');
    }
  }

  // Create or update user profile - Single endpoint for upsert logic
  Future<Map<String, dynamic>> upsertUserProfile(UserProfile profile) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/api/profile/', data: profile.toJson());
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw ApiException('Failed to save profile');
      }
    } on DioException catch (e) {
      throw ApiException('Failed to save profile: ${e.message}');
    }
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get<dynamic>('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
} 