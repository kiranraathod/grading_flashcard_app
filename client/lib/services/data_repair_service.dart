import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_validation_service.dart';
import 'migration_backup_service.dart';
import 'simple_error_handler.dart';

/// Task 1.2: Data Cleanup and Repair Implementation
/// 
/// This service automatically repairs data corruption issues identified by the validation system,
/// ensuring all SharedPreferences data is migration-ready for Supabase.
class DataRepairService {
  static const String _logTag = '[DATA_REPAIR]';
  final DataValidationService _validator = DataValidationService();
  
  /// Main repair method - fixes all identified issues
  Future<DataRepairResult> repairAllData() async {
    debugPrint('$_logTag Starting comprehensive data repair...');
    final result = DataRepairResult();
    
    return await SimpleErrorHandler.safe(
      () async {
        // Create backup before any repairs (Task 1.3 integration)
        debugPrint('$_logTag Creating backup before repairs...');
        final backupService = MigrationBackupService();
        final backupResult = await backupService.createFullBackup(label: 'pre_repair_backup');
        
        if (backupResult.isSuccess) {
          result.addInfo('Created repair backup: ${backupResult.metadata!.id}');
          debugPrint('$_logTag Backup created successfully: ${backupResult.metadata!.id}');
        } else {
          result.addError('Failed to create backup: ${backupResult.error}');
          debugPrint('$_logTag Warning: Backup creation failed, continuing with repairs...');
        }
        
        // Repair in priority order (critical first)
        await _repairInterviewQuestions(result);
        await _repairFlashcardSets(result);
        await _repairUserProgress(result);
        await _repairRecentViewData(result);
        await _cleanupCorruptedCache(result);
        
        // Validate repairs
        await _validateRepairs(result);
        
        debugPrint('$_logTag Data repair completed');
        debugPrint('$_logTag Repairs Applied: ${result.repairs.length}');
        debugPrint('$_logTag Errors: ${result.errors.length}');
        debugPrint('$_logTag Success: ${result.wasSuccessful}');
        
        return result;
      },
      fallbackOperation: () async {
        result.addError('Fatal error during repair operation');
        return result;
      },
      operationName: 'repair_all_data',
    );
  }  
  /// Repair interview questions - CRITICAL for Supabase migration
  Future<void> _repairInterviewQuestions(DataRepairResult result) async {
    debugPrint('$_logTag Repairing interview questions...');
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getString('interview_questions');
    
    if (questionsJson == null || questionsJson.isEmpty) {
      result.addInfo('No interview questions to repair');
      return;
    }
    
    await SimpleErrorHandler.safely(
      () async {
        final List<dynamic> questions = jsonDecode(questionsJson);
        final List<Map<String, dynamic>> repairedQuestions = [];
        int repairCount = 0;
        
        debugPrint('$_logTag Found ${questions.length} interview questions to repair');
        
        for (int i = 0; i < questions.length; i++) {
          if (questions[i] is! Map<String, dynamic>) {
            result.addError('interview_questions[$i]: Invalid question structure - skipping');
            continue;
          }
          
          final question = Map<String, dynamic>.from(questions[i]);
          bool wasModified = false;
          
          // CRITICAL: Repair missing categoryId field
          if (!question.containsKey('categoryId') || question['categoryId'] == null || question['categoryId'].toString().isEmpty) {
            final category = question['category'] as String?;
            if (category != null && category.isNotEmpty) {
              question['categoryId'] = _mapLegacyCategoryToCategoryId(category);
              result.addRepair('interview_questions[$i]', 'Added missing categoryId: ${question['categoryId']} (mapped from category: $category)');
              wasModified = true;
            } else {
              question['categoryId'] = 'data_analysis'; // Safe default
              result.addRepair('interview_questions[$i]', 'Added default categoryId: data_analysis (no category available)');
              wasModified = true;
            }
          }
          
          // Repair boolean fields stored as strings
          final boolFields = ['isDraft', 'isStarred', 'isCompleted'];
          for (final field in boolFields) {
            if (question.containsKey(field)) {
              final value = question[field];
              if (value is String) {
                question[field] = value.toLowerCase() == 'true';
                result.addRepair('interview_questions[$i]', 'Fixed boolean field $field: "$value" -> ${question[field]}');
                wasModified = true;
              } else if (value is! bool && value != null) {
                question[field] = false; // Safe default
                result.addRepair('interview_questions[$i]', 'Fixed invalid boolean field $field: $value -> false');
                wasModified = true;
              }
            } else {
              question[field] = false; // Add missing boolean fields
              result.addRepair('interview_questions[$i]', 'Added missing boolean field $field: false');
              wasModified = true;
            }
          }
          
          // Additional repair logic continues...
          // Repair invalid difficulty values
          if (question.containsKey('difficulty')) {
            final difficulty = question['difficulty'] as String?;
            final validDifficulties = ['entry', 'mid', 'senior'];
            if (difficulty == null || !validDifficulties.contains(difficulty)) {
              final oldDifficulty = difficulty ?? 'null';
              question['difficulty'] = 'entry'; // Safe default
              result.addRepair('interview_questions[$i]', 'Fixed invalid difficulty: "$oldDifficulty" -> "entry"');
              wasModified = true;
            }
          } else {
            question['difficulty'] = 'entry';
            result.addRepair('interview_questions[$i]', 'Added missing difficulty field: entry');
            wasModified = true;
          }
          
          // Ensure required string fields are present and non-empty
          final requiredStringFields = ['id', 'text', 'category', 'subtopic'];
          for (final field in requiredStringFields) {
            if (!question.containsKey(field) || question[field] == null || question[field].toString().trim().isEmpty) {
              String defaultValue;
              if (field == 'id') {
                defaultValue = 'repair_${DateTime.now().millisecondsSinceEpoch}_$i';
              } else if (field == 'text') {
                defaultValue = 'Question text needs to be added';
              } else if (field == 'category') {
                // Derive from categoryId if available
                final categoryId = question['categoryId'] as String?;
                defaultValue = _mapCategoryIdToLegacyCategory(categoryId) ?? 'technical';
              } else if (field == 'subtopic') {
                defaultValue = 'General Knowledge';
              } else {
                defaultValue = 'Unknown';
              }
              
              question[field] = defaultValue;
              result.addRepair('interview_questions[$i]', 'Fixed missing/empty field $field: "$defaultValue"');
              wasModified = true;
            }
          }
          
          // Validate category mapping consistency
          if (question.containsKey('category') && question.containsKey('categoryId')) {
            final category = question['category'] as String;
            final categoryId = question['categoryId'] as String;
            final expectedCategoryId = _mapLegacyCategoryToCategoryId(category);
            
            if (categoryId != expectedCategoryId) {
              question['categoryId'] = expectedCategoryId;
              result.addRepair('interview_questions[$i]', 'Fixed category mapping inconsistency: category "$category" categoryId "$categoryId" -> "$expectedCategoryId"');
              wasModified = true;
            }
          }
          
          if (wasModified) {
            repairCount++;
          }
          
          repairedQuestions.add(question);
        }
        
        // Save repaired data
        final repairedJson = jsonEncode(repairedQuestions);
        await prefs.setString('interview_questions', repairedJson);
        result.addInfo('Successfully repaired $repairCount/${repairedQuestions.length} interview questions');
      },
      operationName: 'repair_interview_questions',
    );
  }  
  /// Map legacy category names to new categoryId values
  String _mapLegacyCategoryToCategoryId(String category) {
    final mapping = {
      'technical': 'data_analysis',
      'applied': 'machine_learning', 
      'behavioral': 'python',
      'case': 'statistics',
      'job': 'web_development',
      // Direct mappings for server-aligned categories
      'data_analysis': 'data_analysis',
      'machine_learning': 'machine_learning',
      'sql': 'sql',
      'python': 'python',
      'web_development': 'web_development',
      'statistics': 'statistics',
    };
    return mapping[category.toLowerCase()] ?? 'data_analysis';
  }
  
  /// Map categoryId back to legacy category (for consistency)
  String? _mapCategoryIdToLegacyCategory(String? categoryId) {
    if (categoryId == null) return null;
    
    final reverseMapping = {
      'data_analysis': 'technical',
      'machine_learning': 'applied',
      'python': 'behavioral',
      'statistics': 'case',
      'web_development': 'job',
      'sql': 'technical',
    };
    return reverseMapping[categoryId] ?? 'technical';
  }
  
  /// Repair flashcard sets structure and data types
  Future<void> _repairFlashcardSets(DataRepairResult result) async {
    debugPrint('$_logTag Repairing flashcard sets...');
    final prefs = await SharedPreferences.getInstance();
    final setsJson = prefs.getStringList('flashcard_sets');
    
    if (setsJson == null || setsJson.isEmpty) {
      result.addInfo('No flashcard sets to repair');
      return;
    }
    
    final List<String> repairedSets = [];
    int repairCount = 0;
    
    for (int i = 0; i < setsJson.length; i++) {
      await SimpleErrorHandler.safely(
        () async {
          final setData = Map<String, dynamic>.from(jsonDecode(setsJson[i]));
          bool wasModified = false;
          
          // Ensure required fields exist
          if (!setData.containsKey('id') || setData['id'] == null || setData['id'].toString().trim().isEmpty) {
            setData['id'] = 'repair_set_${DateTime.now().millisecondsSinceEpoch}_$i';
            result.addRepair('flashcard_sets[$i]', 'Added missing id: ${setData['id']}');
            wasModified = true;
          }
          
          if (!setData.containsKey('title') || setData['title'] == null || setData['title'].toString().trim().isEmpty) {
            setData['title'] = 'Untitled Flashcard Set ${i + 1}';
            result.addRepair('flashcard_sets[$i]', 'Added missing title: ${setData['title']}');
            wasModified = true;
          }
          
          if (wasModified) {
            repairCount++;
          }
          
          repairedSets.add(jsonEncode(setData));
        },
        operationName: 'repair_flashcard_set_$i',
      );
    }
    
    await prefs.setStringList('flashcard_sets', repairedSets);
    result.addInfo('Successfully repaired $repairCount/${repairedSets.length} flashcard sets');
  }  
  /// Repair user progress data
  Future<void> _repairUserProgress(DataRepairResult result) async {
    debugPrint('$_logTag Repairing user progress data...');
    final prefs = await SharedPreferences.getInstance();
    
    final progressKeys = ['user_answers', 'question_progress', 'completion_status'];
    int repairedKeys = 0;
    
    for (final key in progressKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        final isValid = await SimpleErrorHandler.safe(
          () async {
            jsonDecode(value);
            return true;
          },
          fallback: false,
          operationName: 'validate_progress_$key',
        );
        
        if (!isValid) {
          await prefs.remove(key);
          result.addRepair('user_progress', 'Removed corrupted progress key: $key');
          repairedKeys++;
        }
      }
    }
    
    result.addInfo(repairedKeys == 0 ? 'No user progress repairs needed' : 'Repaired $repairedKeys progress entries');
  }
  
  /// Repair recent view data structure
  Future<void> _repairRecentViewData(DataRepairResult result) async {
    debugPrint('$_logTag Repairing recent view data...');
    final prefs = await SharedPreferences.getInstance();
    final recentViewsJson = prefs.getString('recently_viewed_items');
    
    if (recentViewsJson == null || recentViewsJson.isEmpty) {
      result.addInfo('No recent view data to repair');
      return;
    }
    
    await SimpleErrorHandler.safely(
      () async {
        final List<dynamic> recentViews = jsonDecode(recentViewsJson);
        final List<Map<String, dynamic>> repairedViews = [];
        
        for (int i = 0; i < recentViews.length; i++) {
          if (recentViews[i] is Map<String, dynamic>) {
            final item = Map<String, dynamic>.from(recentViews[i]);
            
            // Ensure required fields
            if (!item.containsKey('type')) item['type'] = 'interviewQuestion';
            if (!item.containsKey('viewedAt')) item['viewedAt'] = DateTime.now().toIso8601String();
            
            repairedViews.add(item);
          }
        }
        
        await prefs.setString('recently_viewed_items', jsonEncode(repairedViews));
        result.addInfo('Successfully repaired ${repairedViews.length} recent view items');
      },
      operationName: 'repair_recent_view_data',
    );
  }
  
  /// Clean up corrupted cache entries
  Future<void> _cleanupCorruptedCache(DataRepairResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeys = prefs.getKeys().where((key) => key.startsWith('cache_')).toList();
    int removedKeys = 0;
    
    for (final key in cacheKeys) {
      final value = prefs.getString(key);
      if (value != null) {
        final isValid = await SimpleErrorHandler.safe(
          () async {
            jsonDecode(value);
            return true;
          },
          fallback: false,
          operationName: 'validate_cache_$key',
        );
        
        if (!isValid) {
          await prefs.remove(key);
          removedKeys++;
        }
      }
    }
    
    result.addInfo(removedKeys == 0 ? 'No corrupted cache entries' : 'Removed $removedKeys corrupted cache entries');
  }  
  /// Validate repairs by running the validation system again
  Future<void> _validateRepairs(DataRepairResult result) async {
    await SimpleErrorHandler.safely(
      () async {
        final validationReport = await _validator.validateAllStoredData();
        result.postRepairValidation = validationReport;
        
        if (validationReport.hasBlockingIssues) {
          result.addError('Repairs did not resolve all blocking issues');
          result.addError('Remaining critical errors: ${validationReport.criticalErrors.length}');
        } else {
          result.addInfo('✅ All repairs successful - data is now migration-ready');
          result.addInfo('Migration status: ${validationReport.migrationStatus}');
        }
      },
      operationName: 'validate_repairs',
    );
  }
  
  /// Quick repair check - returns true if repairs are needed
  Future<bool> repairNeeded() async {
    return await SimpleErrorHandler.safe(
      () async {
        final validationReport = await _validator.validateAllStoredData();
        return validationReport.hasBlockingIssues;
      },
      fallback: false,
      operationName: 'repair_needed',
    );
  }
}
/// Result of data repair operations
class DataRepairResult {
  final List<String> repairs = [];
  final List<String> errors = [];
  final List<String> info = [];
  DataValidationReport? postRepairValidation;
  
  void addRepair(String location, String description) {
    repairs.add('$location: $description');
    debugPrint('[REPAIR] $location: $description');
  }
  
  void addError(String message) {
    errors.add(message);
    debugPrint('[REPAIR_ERROR] $message');
  }
  
  void addInfo(String message) {
    info.add(message);
    debugPrint('[REPAIR_INFO] $message');
  }
  
  bool get wasSuccessful => errors.isEmpty && (postRepairValidation?.hasBlockingIssues != true);
  
  int get totalChanges => repairs.length;
  
  String get summary {
    return 'Repairs: ${repairs.length}, Errors: ${errors.length}, Success: ${wasSuccessful ? 'YES' : 'NO'}';
  }
  
  void printSummary() {
    debugPrint('=== DATA REPAIR SUMMARY ===');
    debugPrint('Repairs Applied: ${repairs.length}');
    debugPrint('Errors: ${errors.length}');
    debugPrint('Success: ${wasSuccessful ? 'YES' : 'NO'}');
    
    if (repairs.isNotEmpty) {
      debugPrint('🔧 REPAIRS APPLIED:');
      for (final repair in repairs.take(10)) {
        debugPrint('  ✅ $repair');
      }
      if (repairs.length > 10) {
        debugPrint('  ... and ${repairs.length - 10} more');
      }
    }
    
    if (errors.isNotEmpty) {
      debugPrint('❌ ERRORS:');
      for (final error in errors) {
        debugPrint('  ❌ $error');
      }
    }
    
    if (postRepairValidation != null) {
      debugPrint('📊 POST-REPAIR VALIDATION:');
      debugPrint('  Migration Status: ${postRepairValidation!.migrationStatus}');
      debugPrint('  Critical Errors: ${postRepairValidation!.criticalErrors.length}');
      debugPrint('  Errors: ${postRepairValidation!.errors.length}');
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'repairs_applied': repairs.length,
      'errors_encountered': errors.length,
      'was_successful': wasSuccessful,
      'total_changes': totalChanges,
      'repairs': repairs,
      'errors': errors,
      'info': info,
      'post_repair_validation': postRepairValidation?.toJson(),
    };
  }
}