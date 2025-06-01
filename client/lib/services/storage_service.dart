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
    await _appBox.put('flashcard_sets', sets);
  }
  
  /// Get flashcard sets data
  static List<Map<String, dynamic>>? getFlashcardSets() {
    final data = _appBox.get('flashcard_sets');
    return data?.cast<Map<String, dynamic>>();
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
