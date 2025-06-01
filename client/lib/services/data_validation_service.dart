import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataValidationService {
  static const String _logTag = '[DATA_VALIDATION]';
  
  /// Comprehensive validation of all SharedPreferences data
  Future<DataValidationReport> validateAllStoredData() async {
    debugPrint('$_logTag Starting comprehensive data validation...');
    final report = DataValidationReport();
    
    try {
      // Validate flashcard sets
      await _validateFlashcardSets(report);
      
      // Validate interview questions  
      await _validateInterviewQuestions(report);
      
      // Validate user progress data
      await _validateUserProgress(report);
      
      // Validate recent view data
      await _validateRecentViewData(report);
      
      // Validate cache data
      await _validateCacheData(report);
      
      debugPrint('$_logTag Data validation completed');
      debugPrint('$_logTag Critical Errors: ${report.criticalErrors.length}');
      debugPrint('$_logTag Errors: ${report.errors.length}');
      debugPrint('$_logTag Warnings: ${report.warnings.length}');
      debugPrint('$_logTag Migration Blocked: ${report.hasBlockingIssues}');
      
      return report;
    } catch (e, stackTrace) {
      debugPrint('$_logTag FATAL ERROR during validation: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
      report.addCriticalError('validation_system', 'Fatal error during validation: $e');
      return report;
    }
  }
  
  Future<void> _validateFlashcardSets(DataValidationReport report) async {
    debugPrint('$_logTag Validating flashcard sets...');
    final prefs = await SharedPreferences.getInstance();
    final setsJson = prefs.getStringList('flashcard_sets');
    
    if (setsJson == null) {
      report.addWarning('flashcard_sets', 'No flashcard sets found in storage');
      return;
    }
    
    debugPrint('$_logTag Found ${setsJson.length} flashcard sets to validate');
    
    for (int i = 0; i < setsJson.length; i++) {
      try {
        final setData = jsonDecode(setsJson[i]) as Map<String, dynamic>;
        _validateFlashcardSetStructure(setData, i, report);
      } catch (e) {
        report.addError('flashcard_sets', 'Invalid JSON in set $i: $e');
      }
    }
  }
  
  void _validateFlashcardSetStructure(Map<String, dynamic> setData, int index, DataValidationReport report) {
    final setPrefix = 'flashcard_sets[$index]';
    
    // Required fields validation
    if (!setData.containsKey('id') || setData['id'] == null || setData['id'].toString().isEmpty) {
      report.addError(setPrefix, 'Missing or empty id field');
    }
    
    if (!setData.containsKey('title') || setData['title'] == null || setData['title'].toString().isEmpty) {
      report.addError(setPrefix, 'Missing or empty title field');
    }
    
    if (!setData.containsKey('flashcards') || setData['flashcards'] is! List) {
      report.addError(setPrefix, 'Missing or invalid flashcards array');
    } else {
      final flashcards = setData['flashcards'] as List;
      debugPrint('$_logTag Set $index has ${flashcards.length} flashcards');
      for (int j = 0; j < flashcards.length; j++) {
        _validateFlashcardStructure(flashcards[j], '$setPrefix.flashcards[$j]', report);
      }
    }
    
    // Optional fields with type validation
    if (setData.containsKey('rating') && setData['rating'] is! num) {
      report.addWarning(setPrefix, 'Invalid rating type - should be number, found: ${setData['rating'].runtimeType}');
    }
    
    if (setData.containsKey('lastUpdated') && setData['lastUpdated'] != null) {
      try {
        DateTime.parse(setData['lastUpdated']);
      } catch (e) {
        report.addError(setPrefix, 'Invalid lastUpdated format: $e');
      }
    }
    
    // Boolean field validation
    final boolFields = ['isDraft'];
    for (final field in boolFields) {
      if (setData.containsKey(field) && setData[field] != null && setData[field] is! bool) {
        report.addWarning(setPrefix, 'Field $field should be boolean, found: ${setData[field].runtimeType} (${setData[field]})');
      }
    }
  }
  
  void _validateFlashcardStructure(dynamic flashcard, String flashcardPrefix, DataValidationReport report) {
    if (flashcard is! Map<String, dynamic>) {
      report.addError(flashcardPrefix, 'Invalid flashcard structure - should be object');
      return;
    }
    
    final cardData = flashcard;
    
    // Required fields
    final requiredFields = ['id', 'question', 'answer'];
    for (final field in requiredFields) {
      if (!cardData.containsKey(field) || cardData[field] == null || cardData[field].toString().isEmpty) {
        report.addError(flashcardPrefix, 'Missing or empty required field: $field');
      }
    }
    
    // Boolean fields
    if (cardData.containsKey('isCompleted') && cardData['isCompleted'] != null && cardData['isCompleted'] is! bool) {
      report.addWarning(flashcardPrefix, 'Field isCompleted should be boolean, found: ${cardData['isCompleted'].runtimeType} (${cardData['isCompleted']})');
    }
  }
  
  Future<void> _validateInterviewQuestions(DataValidationReport report) async {
    debugPrint('$_logTag Validating interview questions...');
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getString('interview_questions');
    
    if (questionsJson == null || questionsJson.isEmpty) {
      report.addWarning('interview_questions', 'No interview questions found in storage');
      return;
    }
    
    try {
      final List<dynamic> questions = jsonDecode(questionsJson);
      debugPrint('$_logTag Found ${questions.length} interview questions to validate');
      
      for (int i = 0; i < questions.length; i++) {
        if (questions[i] is! Map<String, dynamic>) {
          report.addError('interview_questions[$i]', 'Invalid question structure - should be object');
          continue;
        }
        final question = questions[i] as Map<String, dynamic>;
        _validateInterviewQuestionStructure(question, i, report);
      }
    } catch (e) {
      report.addError('interview_questions', 'Invalid JSON structure: $e');
    }
  }
  
  void _validateInterviewQuestionStructure(Map<String, dynamic> question, int index, DataValidationReport report) {
    final questionPrefix = 'interview_questions[$index]';
    
    // Required fields
    final requiredFields = ['id', 'text', 'category', 'subtopic', 'difficulty'];
    for (final field in requiredFields) {
      if (!question.containsKey(field) || question[field] == null || question[field].toString().isEmpty) {
        report.addError(questionPrefix, 'Missing or empty required field: $field');
      }
    }
    
    // Critical field: categoryId (often missing and causes filtering issues)
    if (!question.containsKey('categoryId') || question['categoryId'] == null) {
      report.addCriticalError(questionPrefix, 'Missing categoryId field - will break Supabase filtering');
      
      // Suggest fix based on category field
      if (question.containsKey('category') && question['category'] != null) {
        final category = question['category'];
        final suggestedCategoryId = _mapCategoryToCategoryId(category);
        report.addSuggestion(questionPrefix, 'Suggested categoryId based on category "$category": $suggestedCategoryId');
      }
    } else {
      // Validate categoryId value
      final categoryId = question['categoryId'];
      if (categoryId.toString().isEmpty) {
        report.addCriticalError(questionPrefix, 'Empty categoryId field - will break Supabase filtering');
      }
    }
    
    // Validate enum values
    if (question.containsKey('difficulty') && question['difficulty'] != null) {
      final validDifficulties = ['entry', 'mid', 'senior'];
      if (!validDifficulties.contains(question['difficulty'])) {
        report.addError(questionPrefix, 'Invalid difficulty value: ${question['difficulty']}. Must be one of: ${validDifficulties.join(', ')}');
      }
    }
    
    // Boolean fields validation
    final boolFields = ['isDraft', 'isStarred', 'isCompleted'];
    for (final field in boolFields) {
      if (question.containsKey(field) && question[field] != null && question[field] is! bool) {
        report.addWarning(questionPrefix, 'Field $field should be boolean, found: ${question[field].runtimeType} (${question[field]})');
      }
    }
    
    // Validate category mapping consistency
    if (question.containsKey('category') && question.containsKey('categoryId')) {
      final category = question['category'];
      final categoryId = question['categoryId'];
      final expectedCategoryId = _mapCategoryToCategoryId(category);
      
      if (categoryId != expectedCategoryId) {
        report.addWarning(questionPrefix, 'Category mapping inconsistency: category "$category" has categoryId "$categoryId", expected "$expectedCategoryId"');
      }
    }
  }
  
  String _mapCategoryToCategoryId(String category) {
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
    return mapping[category] ?? 'data_analysis';
  }
  
  Future<void> _validateUserProgress(DataValidationReport report) async {
    debugPrint('$_logTag Validating user progress data...');
    final prefs = await SharedPreferences.getInstance();
    
    // Check for various progress-related keys
    final progressKeys = [
      'user_answers',
      'question_progress',
      'completion_status',
      'activity_data',
      'study_streak',
    ];
    
    int progressEntries = 0;
    for (final key in progressKeys) {
      final value = prefs.getString(key);
      if (value != null) {
        progressEntries++;
        try {
          jsonDecode(value);
        } catch (e) {
          report.addError('user_progress', 'Invalid JSON in progress key "$key": $e');
        }
      }
    }
    
    if (progressEntries == 0) {
      report.addWarning('user_progress', 'No user progress data found');
    } else {
      debugPrint('$_logTag Found $progressEntries user progress entries');
    }
  }
  
  Future<void> _validateRecentViewData(DataValidationReport report) async {
    debugPrint('$_logTag Validating recent view data...');
    final prefs = await SharedPreferences.getInstance();
    final recentViewsJson = prefs.getString('recently_viewed_items');
    
    if (recentViewsJson == null) {
      report.addWarning('recent_views', 'No recent view data found');
      return;
    }
    
    try {
      final List<dynamic> recentViews = jsonDecode(recentViewsJson);
      debugPrint('$_logTag Found ${recentViews.length} recent view items');
      
      for (int i = 0; i < recentViews.length; i++) {
        if (recentViews[i] is! Map<String, dynamic>) {
          report.addError('recent_views[$i]', 'Invalid recent view structure - should be object');
          continue;
        }
        
        final item = recentViews[i] as Map<String, dynamic>;
        _validateRecentViewItem(item, i, report);
      }
    } catch (e) {
      report.addError('recent_views', 'Invalid JSON structure: $e');
    }
  }
  
  void _validateRecentViewItem(Map<String, dynamic> item, int index, DataValidationReport report) {
    final itemPrefix = 'recent_views[$index]';
    
    // Required fields
    final requiredFields = ['type', 'question', 'viewedAt'];
    for (final field in requiredFields) {
      if (!item.containsKey(field) || item[field] == null) {
        report.addError(itemPrefix, 'Missing required field: $field');
      }
    }
    
    // Validate viewedAt format
    if (item.containsKey('viewedAt') && item['viewedAt'] != null) {
      try {
        DateTime.parse(item['viewedAt']);
      } catch (e) {
        report.addError(itemPrefix, 'Invalid viewedAt format: $e');
      }
    }
    
    // Validate type enum
    if (item.containsKey('type') && item['type'] != null) {
      final validTypes = ['flashcard', 'interviewQuestion'];
      if (!validTypes.contains(item['type'])) {
        report.addError(itemPrefix, 'Invalid type value: ${item['type']}. Must be one of: ${validTypes.join(', ')}');
      }
    }
    
    // Boolean fields
    if (item.containsKey('isCompleted') && item['isCompleted'] != null && item['isCompleted'] is! bool) {
      report.addWarning(itemPrefix, 'Field isCompleted should be boolean, found: ${item['isCompleted'].runtimeType}');
    }
  }
  
  Future<void> _validateCacheData(DataValidationReport report) async {
    debugPrint('$_logTag Validating cache data...');
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();
    debugPrint('$_logTag Found ${cacheKeys.length} cache keys');
    
    int corruptedCacheEntries = 0;
    for (final key in cacheKeys) {
      final value = prefs.getString(key);
      if (value != null) {
        try {
          jsonDecode(value);
        } catch (e) {
          corruptedCacheEntries++;
          report.addWarning('cache_data', 'Corrupted cache entry "$key": $e');
        }
      }
    }
    
    if (corruptedCacheEntries > 0) {
      report.addWarning('cache_data', 'Found $corruptedCacheEntries corrupted cache entries that should be cleared');
    }
  }
}

class DataValidationReport {
  final List<ValidationIssue> errors = [];
  final List<ValidationIssue> warnings = [];
  final List<ValidationIssue> criticalErrors = [];
  final List<ValidationIssue> suggestions = [];
  
  void addError(String location, String message) {
    errors.add(ValidationIssue(location, message, ValidationSeverity.error));
    debugPrint('[VALIDATION_ERROR] $location: $message');
  }
  
  void addWarning(String location, String message) {
    warnings.add(ValidationIssue(location, message, ValidationSeverity.warning));
    debugPrint('[VALIDATION_WARNING] $location: $message');
  }
  
  void addCriticalError(String location, String message) {
    criticalErrors.add(ValidationIssue(location, message, ValidationSeverity.critical));
    debugPrint('[VALIDATION_CRITICAL] $location: $message');
  }
  
  void addSuggestion(String location, String message) {
    suggestions.add(ValidationIssue(location, message, ValidationSeverity.suggestion));
    debugPrint('[VALIDATION_SUGGESTION] $location: $message');
  }
  
  bool get hasBlockingIssues => criticalErrors.isNotEmpty || errors.isNotEmpty;
  bool get hasCriticalIssues => criticalErrors.isNotEmpty;
  
  int get totalIssues => criticalErrors.length + errors.length + warnings.length;
  
  String get migrationStatus {
    if (hasCriticalIssues) return 'BLOCKED - Critical errors must be fixed';
    if (hasBlockingIssues) return 'BLOCKED - Errors must be fixed';
    if (warnings.isNotEmpty) return 'READY with warnings';
    return 'READY';
  }
  
  int estimateFixTime() {
    // Estimate fix time based on issue count and severity
    int days = 0;
    days += criticalErrors.length * 2; // 2 days per critical error
    days += errors.length * 1; // 1 day per error
    days += (warnings.length / 5).ceil(); // 1 day per 5 warnings
    return days.clamp(1, 14); // Between 1 and 14 days
  }
  
  void printReport() {
    debugPrint('=== DATA VALIDATION REPORT ===');
    debugPrint('Generated: ${DateTime.now().toIso8601String()}');
    debugPrint('');
    
    if (criticalErrors.isNotEmpty) {
      debugPrint('🚨 CRITICAL ERRORS (${criticalErrors.length}):');
      for (final issue in criticalErrors) {
        debugPrint('  ❌ ${issue.location}: ${issue.message}');
      }
      debugPrint('');
    }
    
    if (errors.isNotEmpty) {
      debugPrint('❌ ERRORS (${errors.length}):');
      for (final issue in errors) {
        debugPrint('  ❌ ${issue.location}: ${issue.message}');
      }
      debugPrint('');
    }
    
    if (warnings.isNotEmpty) {
      debugPrint('⚠️ WARNINGS (${warnings.length}):');
      for (final issue in warnings) {
        debugPrint('  ⚠️ ${issue.location}: ${issue.message}');
      }
      debugPrint('');
    }
    
    if (suggestions.isNotEmpty) {
      debugPrint('💡 SUGGESTIONS (${suggestions.length}):');
      for (final issue in suggestions) {
        debugPrint('  💡 ${issue.location}: ${issue.message}');
      }
      debugPrint('');
    }
    
    debugPrint('=== SUMMARY ===');
    debugPrint('Critical Errors: ${criticalErrors.length}');
    debugPrint('Errors: ${errors.length}');
    debugPrint('Warnings: ${warnings.length}');
    debugPrint('Suggestions: ${suggestions.length}');
    debugPrint('Total Issues: $totalIssues');
    debugPrint('Migration Status: $migrationStatus');
    debugPrint('');
    
    if (hasBlockingIssues) {
      debugPrint('🚨 MIGRATION BLOCKED - Fix critical errors and errors before proceeding');
      debugPrint('   Estimated fix time: ${estimateFixTime()} days');
    } else {
      debugPrint('✅ Data validation passed - Ready for migration');
    }
  }
  
  int _estimateFixTime() {
    // Estimate fix time based on issue count and severity
    int days = 0;
    days += criticalErrors.length * 2; // 2 days per critical error
    days += errors.length * 1; // 1 day per error
    days += (warnings.length / 5).ceil(); // 1 day per 5 warnings
    return days.clamp(1, 14); // Between 1 and 14 days
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'migration_status': migrationStatus,
      'has_blocking_issues': hasBlockingIssues,
      'has_critical_issues': hasCriticalIssues,
      'total_issues': totalIssues,
      'estimated_fix_days': _estimateFixTime(),
      'critical_errors': criticalErrors.map((e) => e.toJson()).toList(),
      'errors': errors.map((e) => e.toJson()).toList(),
      'warnings': warnings.map((e) => e.toJson()).toList(),
      'suggestions': suggestions.map((e) => e.toJson()).toList(),
    };
  }
}

class ValidationIssue {
  final String location;
  final String message;
  final ValidationSeverity severity;
  final DateTime timestamp;
  
  ValidationIssue(this.location, this.message, this.severity) : timestamp = DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'message': message,
      'severity': severity.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum ValidationSeverity { 
  critical, 
  error, 
  warning, 
  suggestion 
}
