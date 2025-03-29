import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'local_auth_service.dart';

class LocalApiService {
  static final LocalApiService _instance = LocalApiService._internal();
  
  factory LocalApiService() {
    return _instance;
  }
  
  LocalApiService._internal();
  
  final LocalAuthService _authService = LocalAuthService();
  
  // Helper method to get headers with authentication token
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authService.token != null) {
      headers['Authorization'] = 'Bearer ${_authService.token}';
    }
    
    return headers;
  }
  
  // Flashcard sets
  Future<List<Map<String, dynamic>>> getFlashcardSets() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/api/flashcard-sets'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load flashcard sets: ${response.body}');
      }
      
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['sets']);
    } catch (e) {
      debugPrint('Error getting flashcard sets: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> createFlashcardSet(Map<String, dynamic> setData) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/flashcard-sets'),
        headers: _getHeaders(),
        body: json.encode(setData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to create flashcard set: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error creating flashcard set: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateFlashcardSet(String id, Map<String, dynamic> setData) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.apiBaseUrl}/api/flashcard-sets/$id'),
        headers: _getHeaders(),
        body: json.encode(setData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update flashcard set: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error updating flashcard set: $e');
      rethrow;
    }
  }
  
  Future<void> deleteFlashcardSet(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${Constants.apiBaseUrl}/api/flashcard-sets/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete flashcard set: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting flashcard set: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rateFlashcardSet(String id, double rating) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/flashcard-sets/$id/rate'),
        headers: _getHeaders(),
        body: json.encode({'rating': rating}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to rate flashcard set: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error rating flashcard set: $e');
      rethrow;
    }
  }
  
  // User profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/api/profile'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load profile: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.apiBaseUrl}/api/profile'),
        headers: _getHeaders(),
        body: json.encode(profileData),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProgress(int xp) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/profile/progress'),
        headers: _getHeaders(),
        body: json.encode({'xp': xp}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update progress: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error updating user progress: $e');
      rethrow;
    }
  }
  
  // Spaced repetition
  Future<List<Map<String, dynamic>>> getDueCards(int limit) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/api/spaced/due-cards?limit=$limit'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load due cards: ${response.body}');
      }
      
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['dueCards']);
    } catch (e) {
      debugPrint('Error getting due cards: $e');
      return [];
    }
  }
  
  Future<void> updateCardProgress(String cardId, int confidenceLevel) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/spaced/update-progress'),
        headers: _getHeaders(),
        body: json.encode({
          'cardId': cardId,
          'confidenceLevel': confidenceLevel,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update card progress: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating card progress: $e');
      rethrow;
    }
  }
  
  // Learning stats
  Future<Map<String, dynamic>> getLearningStats() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/api/spaced/stats'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load learning stats: ${response.body}');
      }
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Error getting learning stats: $e');
      return {
        'cardsLearned': 0,
        'averageConfidence': 0.0,
        'streakDays': 0
      };
    }
  }
}
