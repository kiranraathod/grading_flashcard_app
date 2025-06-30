import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/enhanced_safe_map_converter.dart';

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
    debugPrint('');
    debugPrint('💾 ========== HIVE DATA SAVE OPERATION ==========');
    debugPrint('🗃️ Storage: Hive database');
    debugPrint('📁 Box: flashmaster_data');
    debugPrint('🔑 Key: flashcard_sets');
    debugPrint('📊 Data: ${sets.length} flashcard sets');
    debugPrint('');
    
    debugPrint('📋 Save Operation Details:');
    for (int i = 0; i < sets.length; i++) {
      final set = sets[i];
      final title = set['title'] ?? 'Untitled';
      final cardCount = (set['flashcards'] as List?)?.length ?? 0;
      debugPrint('  Set ${i + 1}: "$title" ($cardCount cards)');
    }
    
    if (sets.isNotEmpty && sets[0]['flashcards'] != null && sets[0]['flashcards'].isNotEmpty) {
      final firstCard = sets[0]['flashcards'][0];
      debugPrint('');
      debugPrint('🔍 Sample Data Verification:');
      debugPrint('  • First set: ${sets[0]['title']}');
      debugPrint('  • First card question: ${firstCard['question']}');
      debugPrint('  • First card answer: ${firstCard['answer']}');
      debugPrint('  • First card completed: ${firstCard['isCompleted']}');
    }
    
    debugPrint('');
    debugPrint('💾 Writing to Hive database...');
    await _appBox.put('flashcard_sets', sets);
    debugPrint('✅ Data saved successfully to Hive');
    
    debugPrint('');
    debugPrint('🔄 SAVE OPERATION SUMMARY:');
    debugPrint('=========================');
    debugPrint('✅ Operation: Atomic write with race condition protection');
    debugPrint('✅ Persistence: Data will survive app restarts');
    debugPrint('✅ Availability: Immediately available for reads');
    debugPrint('ℹ️ Cloud Sync: Upload enabled, full bidirectional sync planned');
    debugPrint('========================================================');
  }
  
  /// Get flashcard sets data with user context support
  static List<Map<String, dynamic>>? getFlashcardSets({String? userId}) {
    debugPrint('');
    debugPrint('📖 ========== HIVE DATA RETRIEVAL ==========');
    debugPrint('🗃️ Storage: Hive database');
    debugPrint('📁 Box: flashmaster_data');
    debugPrint('🔑 Key: flashcard_sets');
    debugPrint('👤 Context: ${userId ?? "Global/Guest"}');
    debugPrint('');
    
    // For now, just return the global data
    // The user-specific migrated data will be handled by getUserMigratedData() async method
    final data = _appBox.get('flashcard_sets');
    
    debugPrint('🔍 Raw Data Analysis:');
    debugPrint('  • Data exists: ${data != null}');
    debugPrint('  • Data type: ${data?.runtimeType ?? 'null'}');
    
    if (data != null) {
      if (data is List) {
        debugPrint('  • List length: ${data.length}');
        debugPrint('  • Item types: ${data.isNotEmpty ? data.map((e) => e.runtimeType).toSet() : 'N/A'}');
      }
    }
    
    // 🔧 FIX: Use safe conversion instead of dangerous cast
    List<Map<String, dynamic>>? result;
    if (data != null) {
      if (data is List<Map<String, dynamic>>) {
        debugPrint('  • ✅ Data is already in correct format');
        result = data;
      } else if (data is List) {
        debugPrint('  • 🔧 Converting LinkedMap data using Enhanced SafeMapConverter');
        // Convert potentially problematic LinkedMap objects safely using Enhanced SafeMapConverter
        result = EnhancedSafeMapConverter.safeConvertList(data);
        debugPrint('  • ✅ Conversion completed: ${result.length} items');
      }
    }
    
    debugPrint('');
    debugPrint('📊 Final Result:');
    debugPrint('  • Sets returned: ${result?.length ?? 0}');
    
    if (result != null && result.isNotEmpty) {
      debugPrint('  • Set details:');
      for (int i = 0; i < result.length; i++) {
        final set = result[i];
        final title = set['title'] ?? 'Untitled';
        final cardCount = (set['flashcards'] as List?)?.length ?? 0;
        final completedCount = (set['flashcards'] as List?)
            ?.where((card) => card['isCompleted'] == true)
            .length ?? 0;
        
        debugPrint('    ${i + 1}. "$title": $completedCount/$cardCount completed');
      }
    }
    
    debugPrint('');
    debugPrint('💾 STORAGE ARCHITECTURE NOTES:');
    debugPrint('==============================');
    debugPrint('🎯 CURRENT: Hive local storage (no Supabase sync yet)');
    debugPrint('  • Read/Write: Direct to device storage');
    debugPrint('  • Persistence: Survives app restarts');
    debugPrint('  • Scope: Device-specific, not cloud synced');
    debugPrint('');
    debugPrint('🌐 PLANNED: Supabase database integration');
    debugPrint('  • When: After migration system is stable');
    debugPrint('  • What: Two-way sync between Hive and PostgreSQL');
    debugPrint('  • Benefits: Cross-device sync, backup, collaboration');
    debugPrint('========================================');

    return result;
  }

  /// Check if user has migrated data (synchronous check)
  static Future<bool> hasUserMigratedData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('user_has_migrated_data_$userId') ?? false;
    } catch (e) {
      debugPrint('❌ Failed to check migration status: $e');
      return false;
    }
  }

  /// Get user-specific migrated data (async version)
  static Future<Map<String, dynamic>?> getUserMigratedData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'user_migrated_data_$userId';
      final dataString = prefs.getString(backupKey);
      if (dataString != null) {
        // 🔧 FIXED: Use Enhanced SafeMapConverter for safe JSON decoding
        final data = EnhancedSafeMapConverter.jsonCycleConvert(dataString);
        if (data != null) {
          debugPrint('📚 Retrieved migrated data for user $userId: ${data['flashcards']?.length ?? 0} flashcard sets');
          return data;
        } else {
          debugPrint('❌ Failed to safely decode migrated data for user $userId');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to get migrated data for user $userId: $e');
    }
    return null;
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

  /// UUID Mapping storage for Flashcards
  static const String _uuidMappingsKey = 'uuid_mappings';
  static const String _interviewUuidMappingsKey = 'interview_uuid_mappings';

  /// Save UUID mappings for flashcard sets and cards
  static Future<void> saveUuidMappings(Map<String, String> mappings) async {
    try {
      await _appBox.put(_uuidMappingsKey, mappings);
    } catch (e) {
      debugPrint('Error saving UUID mappings: $e');
    }
  }

  /// Get UUID mappings for flashcard sets and cards
  static Future<Map<String, String>?> getUuidMappings() async {
    try {
      final data = _appBox.get(_uuidMappingsKey);
      if (data != null) {
        return Map<String, String>.from(data);
      }
    } catch (e) {
      debugPrint('Error loading UUID mappings: $e');
    }
    return null;
  }

  /// Save UUID mappings for interview questions
  static Future<void> saveInterviewUuidMappings(Map<String, String> mappings) async {
    try {
      await _appBox.put(_interviewUuidMappingsKey, mappings);
    } catch (e) {
      debugPrint('Error saving interview UUID mappings: $e');
    }
  }

  /// Get UUID mappings for interview questions
  static Future<Map<String, String>?> getInterviewUuidMappings() async {
    try {
      final data = _appBox.get(_interviewUuidMappingsKey);
      if (data != null) {
        return Map<String, String>.from(data);
      }
    } catch (e) {
      debugPrint('Error loading interview UUID mappings: $e');
    }
    return null;
  }
}
