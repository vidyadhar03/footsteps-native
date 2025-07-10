import '../models/user_profile.dart';
import '../services/api_service.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  // Create or update user profile using the single API endpoint
  Future<Map<String, dynamic>> upsertUserProfile(UserProfile profile) async {
    try {
      return await _apiService.upsertUserProfile(profile);
    } catch (e) {
      print('Error upserting profile: $e');
      rethrow;
    }
  }

  Future<bool> isApiHealthy() async {
    return await _apiService.checkHealth();
  }
} 