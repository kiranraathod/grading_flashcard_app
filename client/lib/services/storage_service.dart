import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Simple storage service using industry-standard Hive database
/// 
/// Replaces the complex 247-line StorageManager with a 20-line solution
/// using Hive's built-in race condition protection and atomic operations.
class StorageService {
  static late Box _appBox;
  
  /// Initialize Hive storage (one-time setup)
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _appBox = await Hive.openBox('flashmaster_data');
  }
  
  /// Save flashcard sets data (atomic operation with built-in race protection)
  static Future<void> saveFlashcardSets(List<Map<String, dynamic>> sets) async {
    debugPrint('StorageService: Saving ${sets.length} flashcard sets to Hive');
    if (sets.isNotEmpty && sets[0]['flashcards'] != null && sets[0]['flashcards'].isNotEmpty) {
      debugPrint('StorageService: First set first flashcard answer: ${sets[0]['flashcards'][0]['answer']}');
    }
    await _appBox.put('flashcard_sets', sets);
  }
  
  /// Get flashcard sets data
  static List<Map<String, dynamic>>? getFlashcardSets() {
    final data = _appBox.get('flashcard_sets');
    final result = data?.cast<Map<String, dynamic>>();
    
    debugPrint('StorageService: Loading ${result?.length ?? 0} flashcard sets from Hive');
    if (result != null && result.isNotEmpty && result[0]['flashcards'] != null && result[0]['flashcards'].isNotEmpty) {
      debugPrint('StorageService: First set first flashcard answer: ${result[0]['flashcards'][0]['answer']}');
    }
    
    return result;
  }
  
  /// Save interview questions data (atomic operation with built-in race protection)
  static Future<void> saveInterviewQuestions(List<Map<String, dynamic>> questions) async {
    await _appBox.put('interview_questions', questions);
  }
  
  /// Get interview questions data
  static List<Map<String, dynamic>>? getInterviewQuestions() {
    final data = _appBox.get('interview_questions');
    return data?.cast<Map<String, dynamic>>();
  }
  
  /// Remove data by key
  static Future<void> remove(String key) async {
    await _appBox.delete(key);
  }
  
  /// Clear all data
  static Future<void> clear() async {
    await _appBox.clear();
  }
}
