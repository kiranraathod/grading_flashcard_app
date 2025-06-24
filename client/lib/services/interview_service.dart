import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interview_question.dart';
import '../models/question_set.dart';
import 'default_data_service.dart';
import 'storage_service.dart';
import 'reliable_operation_service.dart';
import '../utils/enhanced_safe_map_converter.dart';

class InterviewService extends ChangeNotifier {
  List<InterviewQuestion> _questions = [];
  final List<QuestionSet> _questionSets = [];
  final DefaultDataService _defaultDataService = DefaultDataService();
  final ReliableOperationService _reliableOps = ReliableOperationService();
  bool _isInitialized = false;

  // Map to store user answers (questionId -> answer text)
  final Map<String, String> _userAnswers = {};
  String? _currentUserId;

  // Constructor - automatically initialize
  InterviewService() {
    _initializeAsync();
  }

  /// Reload data for a specific user (called after authentication)
  Future<void> reloadForUser(String? userId) async {
    debugPrint('🔄 InterviewService: Reloading data for user: $userId');
    debugPrint('🔄 InterviewService: Current questions count before reload: ${_questions.length}');
    _currentUserId = userId;
    await loadQuestionsFromStorage();
    debugPrint('🔄 InterviewService: Current questions count after reload: ${_questions.length}');
  }

  // Async initialization
  Future<void> _initializeAsync() async {
    if (!_isInitialized) {
      debugPrint('🔧 InterviewService: Auto-initializing...');
      await loadQuestionsFromStorage();
      _isInitialized = true;
      debugPrint(
        '✅ InterviewService: Initialization complete with ${_questions.length} questions',
      );
    }
  }

  // Getters with automatic initialization check
  List<InterviewQuestion> get questions {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ InterviewService: Questions accessed before initialization',
      );
      return [];
    }
    return _questions.where((q) => !q.isDraft).toList();
  }

  List<InterviewQuestion> get drafts =>
      _questions.where((q) => q.isDraft).toList();
  List<QuestionSet> get questionSets => _questionSets;

  // Public initialization method
  Future<void> initialize() async {
    await _initializeAsync();
  }

  // Check if service is ready
  bool get isInitialized => _isInitialized;

  /// Load default questions from server with reliable fallback
  Future<void> _loadDefaultQuestions() async {
    await _reliableOps.withFallback(
      primary: () async {
        debugPrint('Loading default interview questions from server...');
        final defaultQuestions =
            await _defaultDataService.loadDefaultInterviewQuestions();

        if (defaultQuestions.isNotEmpty) {
          _questions = defaultQuestions;
          debugPrint(
            'Loaded ${defaultQuestions.length} default interview questions from server',
          );
          await _saveQuestionsToStorage();
        } else {
          _questions = _createFallbackQuestions();
        }
      },
      fallback: () async => _questions = _createFallbackQuestions(),
      operationName: 'load_default_interview_questions',
    );
  }

  /// Create minimal fallback questions if server fails
  List<InterviewQuestion> _createFallbackQuestions() {
    return [
      InterviewQuestion(
        id: 'fallback-1',
        text:
            'Explain the difference between bias and variance in machine learning.',
        category: 'technical',
        subtopic: 'Machine Learning Algorithms',
        difficulty: 'mid',
        answer:
            'Bias is error from oversimplification, variance is error from sensitivity to data.',
      ),
      InterviewQuestion(
        id: 'fallback-2',
        text: 'How would you handle missing data in a dataset?',
        category: 'applied',
        subtopic: 'Data Cleaning & Preprocessing',
        difficulty: 'entry',
        answer:
            'Identify patterns, evaluate extent, choose imputation strategy, validate approach.',
      ),
    ];
  }

  /// Synchronize with server-generated categories safely
  Future<void> synchronizeWithServerCategories() async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint(
          'Synchronizing interview questions with server categories...',
        );

        final serverCategories =
            await _defaultDataService.loadDefaultCategories();
        final serverCategoryCounts =
            await _defaultDataService.loadCategoryCounts();

        if (serverCategories.isNotEmpty) {
          debugPrint('Server provides ${serverCategories.length} categories');
          _validateQuestionCategoryMapping(
            serverCategories,
            serverCategoryCounts,
          );
          await _updateQuestionMetadata(serverCategories);
        }
      },
      operationName: 'synchronize_with_server_categories',
    );
  }

  /// Validate question-category mapping consistency safely
  void _validateQuestionCategoryMapping(
    List<dynamic> serverCategories,
    Map<String, int>? serverCounts,
  ) {
    _reliableOps.safelySync(
      operation: () {
        debugPrint('Validating question-category mapping consistency...');

        final localCategoryCounts = <String, int>{};

        for (final question in questions) {
          for (final serverCategory in serverCategories) {
            final categoryName = serverCategory['name'] ?? '';
            if (_isQuestionInCategory(question, categoryName)) {
              localCategoryCounts[categoryName] =
                  (localCategoryCounts[categoryName] ?? 0) + 1;
            }
          }
        }

        if (serverCounts != null) {
          for (final entry in serverCounts.entries) {
            final serverCount = entry.value;
            final localCount = localCategoryCounts[entry.key] ?? 0;

            if (serverCount != localCount) {
              debugPrint(
                'Category count mismatch for ${entry.key}: server=$serverCount, local=$localCount',
              );
            }
          }
        }

        debugPrint('Question-category validation completed');
      },
      operationName: 'validate_question_category_mapping',
    );
  }

  /// Check if a question belongs to a specific category
  bool _isQuestionInCategory(InterviewQuestion question, String categoryName) {
    return _reliableOps.safelySync(
          operation: () {
            // Handle 'all' category - should match everything
            if (categoryName.toLowerCase() == 'all') {
              debugPrint('🔍 CATEGORY MATCH: "all" category - returning true');
              return true;
            }

            final categoryLower = categoryName.toLowerCase();
            final subtopicLower = question.subtopic.toLowerCase();
            final textLower = question.text.toLowerCase();

            // DEBUG: Log the comparison
            debugPrint('🔍 CATEGORY MATCH DEBUG:');
            debugPrint('  Question: "${question.text}"');
            debugPrint('  Question subtopic: "${question.subtopic}"');
            debugPrint('  Looking for category: "$categoryName"');
            debugPrint('  Subtopic lower: "$subtopicLower"');
            debugPrint('  Category lower: "$categoryLower"');

            // Direct subtopic match (most common case)
            if (subtopicLower == categoryLower) {
              debugPrint('  ✅ DIRECT MATCH: subtopic == category');
              return true;
            }

            // Specific category mappings
            bool result = false;
            switch (categoryLower) {
              case 'data analysis':
                result =
                    subtopicLower.contains('data') ||
                    subtopicLower.contains('analysis') ||
                    textLower.contains('data');
                break;
              case 'machine learning':
                result =
                    subtopicLower.contains('machine') ||
                    subtopicLower.contains('learning') ||
                    subtopicLower.contains('ml');
                break;
              case 'sql database':
              case 'sql':
                result =
                    subtopicLower.contains('sql') || textLower.contains('sql');
                break;
              case 'python programming':
              case 'python':
                result =
                    subtopicLower.contains('python') ||
                    textLower.contains('python');
                break;
              case 'api development':
                result =
                    subtopicLower.contains('api') ||
                    textLower.contains('api') ||
                    subtopicLower == 'api development';
                break;
              case 'web development':
                result =
                    subtopicLower.contains('web') ||
                    subtopicLower.contains('api') ||
                    textLower.contains('web');
                break;
              case 'statistics':
                result =
                    subtopicLower.contains('statistics') ||
                    subtopicLower.contains('stat') ||
                    textLower.contains('statistic');
                break;
              default:
                // Flexible matching for any other categories
                result =
                    subtopicLower.contains(categoryLower) ||
                    textLower.contains(categoryLower);
            }

            debugPrint('  Match result: $result');
            if (result) {
              debugPrint('  ✅ MATCHED!');
            } else {
              // 🔇 REDUCED: Only log NO MATCH occasionally to prevent spam
              if (DateTime.now().millisecond % 100 == 0) {
                debugPrint('  ❌ NO MATCH (logging reduced to prevent spam)');
              }
            }

            return result;
          },
          defaultValue: false,
          operationName: 'is_question_in_category',
        ) ??
        false;
  }

  /// Update question metadata based on server categories safely
  Future<void> _updateQuestionMetadata(List<dynamic> serverCategories) async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('Updating question metadata based on server categories...');

        bool hasUpdates = false;

        for (int i = 0; i < _questions.length; i++) {
          final question = _questions[i];
          for (final serverCategory in serverCategories) {
            final categoryName = serverCategory['name'] ?? '';
            if (_isQuestionInCategory(question, categoryName)) {
              if (question.categoryId != serverCategory['id']) {
                // Create updated question with new categoryId
                _questions[i] = question.copyWith(
                  categoryId: serverCategory['id'],
                );
                hasUpdates = true;
              }
            }
          }
        }

        if (hasUpdates) {
          await _saveQuestionsToStorage();
          debugPrint('Question metadata updated and saved');
          notifyListeners();
        }
      },
      operationName: 'update_question_metadata',
    );
  }

  /// Save questions to storage safely
  Future<void> _saveQuestionsToStorage() async {
    await _reliableOps.safely(
      operation: () async {
        final questionsJson = _questions.map((q) => q.toJson()).toList();
        await StorageService.saveInterviewQuestions(questionsJson);
        debugPrint(
          'Successfully saved ${_questions.length} questions to storage using StorageService',
        );
      },
      operationName: 'save_questions_to_storage',
    );
  }

  /// Load questions from storage with fallback
  Future<void> loadQuestionsFromStorage() async {
    await _reliableOps.withFallback(
      primary: () async {
        // Check for user-specific migrated data first
        if (_currentUserId != null) {
          final migratedData = await StorageService.getUserMigratedData(_currentUserId!);
          if (migratedData != null && migratedData['interviews'] != null) {
            debugPrint('🔄 Loading migrated interview data for user: $_currentUserId');
            await _loadMigratedData(migratedData['interviews']);
            return;
          }
        }
        
        debugPrint('Loading questions from storage...');
        final questionsData = StorageService.getInterviewQuestions();

        if (questionsData != null && questionsData.isNotEmpty) {
          _questions =
              questionsData
                  .map((data) => InterviewQuestion.fromJson(data))
                  .toList();
          debugPrint('Loaded ${_questions.length} questions from storage');
        } else {
          debugPrint('No questions found in storage, loading from server');
          await _loadDefaultQuestions();
        }

        notifyListeners();
      },
      fallback: () async {
        debugPrint('Storage loading failed, loading from server');
        await _loadDefaultQuestions();
      },
      operationName: 'load_questions_from_storage',
    );
  }

  /// Load migrated data from guest session
  Future<void> _loadMigratedData(List<dynamic> migratedInterviews) async {
    try {
      debugPrint('🔄 InterviewService: Loading migrated data...');
      
      _questions = migratedInterviews
          .map((data) => _safeConvertAndCreateQuestion(data))
          .where((question) => question != null)
          .cast<InterviewQuestion>()
          .toList();
      
      debugPrint('✅ Loaded ${_questions.length} migrated interview questions');
      
      // Save to current storage for persistence
      await _saveQuestionsToStorage();
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Failed to load migrated interview data: $e');
      // Fall back to loading from storage or defaults
      await _loadDefaultQuestions();
    }
  }

  /// FIXED: Safely convert data and create InterviewQuestion using Enhanced SafeMapConverter
  InterviewQuestion? _safeConvertAndCreateQuestion(dynamic data) {
    try {
      if (data == null) return null;
      
      // Use Enhanced SafeMapConverter to handle LinkedMap conversion
      final convertedData = EnhancedSafeMapConverter.safeConvert(data);
      
      if (convertedData == null) {
        debugPrint('❌ Failed to convert interview question data');
        return null;
      }
      
      return InterviewQuestion.fromJson(convertedData);
    } catch (e) {
      debugPrint('❌ Error converting interview question data: $e');
      return null;
    }
  }

  // REMOVED: Custom conversion methods replaced with Enhanced SafeMapConverter
  // All LinkedMap conversion is now handled by EnhancedSafeMapConverter.safeConvert()

  /// Add a new question with reliable storage
  Future<void> addQuestion(InterviewQuestion question) async {
    await _reliableOps.safely(
      operation: () async {
        _questions.add(question);
        await _saveQuestionsToStorage();
        notifyListeners();
        debugPrint('Added question: ${question.text}');
      },
      operationName: 'add_question',
    );
  }

  /// Update an existing question with reliable storage
  Future<void> updateQuestion(InterviewQuestion updatedQuestion) async {
    await _reliableOps.safely(
      operation: () async {
        final index = _questions.indexWhere((q) => q.id == updatedQuestion.id);
        if (index >= 0) {
          _questions[index] = updatedQuestion;
          await _saveQuestionsToStorage();
          notifyListeners();
          debugPrint('Updated question: ${updatedQuestion.id}');
        }
      },
      operationName: 'update_question',
    );
  }

  /// Delete a question with reliable storage
  Future<void> deleteQuestion(String questionId) async {
    await _reliableOps.safely(
      operation: () async {
        _questions.removeWhere((q) => q.id == questionId);
        await _saveQuestionsToStorage();
        notifyListeners();
        debugPrint('Deleted question: $questionId');
      },
      operationName: 'delete_question',
    );
  }

  /// Get questions by category with safe operation
  List<InterviewQuestion> getQuestionsByCategory(
    String category, {
    bool isSubtopic = false,
  }) {
    return _reliableOps.safelySync(
          operation: () {
            debugPrint('Getting questions for category: $category');

            final filteredQuestions =
                questions.where((question) {
                  return _isQuestionInCategory(question, category);
                }).toList();

            debugPrint(
              'Found ${filteredQuestions.length} questions for category: $category',
            );
            return filteredQuestions;
          },
          defaultValue: <InterviewQuestion>[],
          operationName: 'get_questions_by_category',
        ) ??
        <InterviewQuestion>[];
  }

  /// Search questions with default empty result
  List<InterviewQuestion> searchQuestions(String query) {
    return _reliableOps.safelySync(
          operation: () {
            if (query.isEmpty) return questions;

            final lowercaseQuery = query.toLowerCase();
            return questions
                .where(
                  (question) =>
                      question.text.toLowerCase().contains(lowercaseQuery) ||
                      question.subtopic.toLowerCase().contains(
                        lowercaseQuery,
                      ) ||
                      question.category.toLowerCase().contains(
                        lowercaseQuery,
                      ) ||
                      (question.answer?.toLowerCase().contains(
                            lowercaseQuery,
                          ) ??
                          false),
                )
                .toList();
          },
          defaultValue: <InterviewQuestion>[],
          operationName: 'search_questions',
        ) ??
        <InterviewQuestion>[];
  }

  /// Get user answer safely
  String getUserAnswer(String questionId) {
    return _reliableOps.safelySync(
          operation: () => _userAnswers[questionId] ?? '',
          defaultValue: '',
          operationName: 'get_user_answer',
        ) ??
        '';
  }

  /// Save user answer safely
  Future<void> saveUserAnswer(String questionId, String answer) async {
    await _reliableOps.safely(
      operation: () async {
        _userAnswers[questionId] = answer;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_answer_$questionId', answer);
        debugPrint('Saved user answer for question: $questionId');
      },
      operationName: 'save_user_answer',
    );
  }

  /// Toggle completion status safely
  Future<void> toggleCompletion(String questionId) async {
    await _reliableOps.safely(
      operation: () async {
        final question = _questions.firstWhere((q) => q.id == questionId);
        question.isCompleted = !question.isCompleted;
        await _saveQuestionsToStorage();
        notifyListeners();
        debugPrint(
          'Toggled completion for question: $questionId to ${question.isCompleted}',
        );
      },
      operationName: 'toggle_completion',
    );
  }

  /// Mark question as completed (always sets to true, doesn't toggle)
  Future<void> markAsCompleted(String questionId) async {
    await _reliableOps.safely(
      operation: () async {
        final question = _questions.firstWhere((q) => q.id == questionId);
        if (!question.isCompleted) {
          question.isCompleted = true;
          await _saveQuestionsToStorage();
          notifyListeners();
          debugPrint('✅ Marked question as completed: $questionId');
        } else {
          debugPrint('📝 Question already completed: $questionId');
        }
      },
      operationName: 'mark_as_completed',
    );
  }

  /// Toggle star status safely
  Future<void> toggleStar(String questionId) async {
    await _reliableOps.safely(
      operation: () async {
        final question = _questions.firstWhere((q) => q.id == questionId);
        question.isStarred = !question.isStarred;
        await _saveQuestionsToStorage();
        notifyListeners();
        debugPrint(
          'Toggled star for question: $questionId to ${question.isStarred}',
        );
      },
      operationName: 'toggle_star',
    );
  }

  /// Load user answers safely
  Future<void> loadUserAnswers() async {
    await _reliableOps.safely(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        for (final question in _questions) {
          final answer = prefs.getString('user_answer_${question.id}');
          if (answer != null) {
            _userAnswers[question.id] = answer;
          }
        }
        debugPrint('Loaded user answers for ${_userAnswers.length} questions');
      },
      operationName: 'load_user_answers',
    );
  }

  /// Get statistics safely
  Map<String, int> getStatistics() {
    return _reliableOps.safelySync(
          operation: () {
            final totalQuestions = questions.length;
            final completedQuestions =
                questions.where((q) => q.isCompleted).length;
            final starredQuestions = questions.where((q) => q.isStarred).length;
            final answeredQuestions =
                _userAnswers.keys
                    .where((key) => _userAnswers[key]?.isNotEmpty == true)
                    .length;

            return {
              'total': totalQuestions,
              'completed': completedQuestions,
              'starred': starredQuestions,
              'answered': answeredQuestions,
            };
          },
          defaultValue: {
            'total': 0,
            'completed': 0,
            'starred': 0,
            'answered': 0,
          },
          operationName: 'get_statistics',
        ) ??
        {'total': 0, 'completed': 0, 'starred': 0, 'answered': 0};
  }

  /// Clear all user answers safely
  Future<void> clearAllUserAnswers() async {
    await _reliableOps.safely(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        for (final questionId in _userAnswers.keys) {
          await prefs.remove('user_answer_$questionId');
        }
        _userAnswers.clear();
        debugPrint('Cleared all user answers');
      },
      operationName: 'clear_all_user_answers',
    );
  }

  // ==============================================
  // MISSING METHODS & COMPATIBILITY ALIASES
  // ==============================================

  /// Get filtered questions (compatibility method)
  List<InterviewQuestion> getFilteredQuestions({
    String? category,
    String? difficulty,
    String? searchQuery,
  }) {
    return _reliableOps.safelySync(
          operation: () {
            debugPrint(
              '🔧 FILTER START: category="$category", difficulty="$difficulty", searchQuery="$searchQuery"',
            );
            var filtered = questions;
            debugPrint('🔧 Initial questions count: ${filtered.length}');

            if (category != null && category.isNotEmpty && category != 'all') {
              debugPrint('🔧 Filtering by category: $category');
              final beforeCount = filtered.length;
              filtered =
                  filtered
                      .where((q) => _isQuestionInCategory(q, category))
                      .toList();
              debugPrint(
                '🔧 After category filter: ${filtered.length} (was $beforeCount)',
              );
            }

            if (difficulty != null &&
                difficulty.isNotEmpty &&
                difficulty != 'all') {
              debugPrint('🔧 Filtering by difficulty: $difficulty');
              final beforeCount = filtered.length;
              filtered =
                  filtered.where((q) => q.difficulty == difficulty).toList();
              debugPrint(
                '🔧 After difficulty filter: ${filtered.length} (was $beforeCount)',
              );
            }

            if (searchQuery != null && searchQuery.isNotEmpty) {
              debugPrint('🔧 Filtering by search query: $searchQuery');
              final beforeCount = filtered.length;
              filtered =
                  filtered
                      .where(
                        (q) =>
                            q.text.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            q.subtopic.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();
              debugPrint(
                '🔧 After search filter: ${filtered.length} (was $beforeCount)',
              );
            }

            debugPrint('🔧 FILTER END: Returning ${filtered.length} questions');
            return filtered;
          },
          defaultValue: <InterviewQuestion>[],
          operationName: 'get_filtered_questions',
        ) ??
        <InterviewQuestion>[];
  }

  /// Get progress stats (compatibility method)
  Map<String, dynamic> getProgressStats() {
    return _reliableOps.safelySync(
          operation: () {
            final stats = getStatistics();
            final total = stats['total'] ?? 0;
            final completed = stats['completed'] ?? 0;
            final starred = stats['starred'] ?? 0;
            final answered = stats['answered'] ?? 0;

            return {
              // 🎯 FIX: Return keys that match what the UI expects
              'total': total,
              'completed': completed,
              'starred': starred,
              'answered': answered,
              // Also provide detailed keys for backward compatibility
              'totalQuestions': total,
              'completedQuestions': completed,
              'starredQuestions': starred,
              'answeredQuestions': answered,
              'completionRate': total > 0 ? (completed / total) : 0.0,
            };
          },
          defaultValue: {
            'total': 0,
            'completed': 0,
            'starred': 0,
            'answered': 0,
            'totalQuestions': 0,
            'completedQuestions': 0,
            'starredQuestions': 0,
            'answeredQuestions': 0,
            'completionRate': 0.0,
          },
          operationName: 'get_progress_stats',
        ) ??
        {
          'total': 0,
          'completed': 0,
          'starred': 0,
          'answered': 0,
          'totalQuestions': 0,
          'completedQuestions': 0,
          'starredQuestions': 0,
          'answeredQuestions': 0,
          'completionRate': 0.0,
        };
  }

  // ==============================================
  // COMPATIBILITY METHODS FOR EXISTING UI
  // ==============================================

  /// Get question by ID (compatibility method)
  InterviewQuestion? getQuestionById(String id) {
    return _reliableOps.safelySync(
      operation: () {
        return _questions.firstWhere((q) => q.id == id);
      },
      defaultValue: null,
      operationName: 'get_question_by_id',
    );
  }

  /// Save question set (compatibility method)
  Future<void> saveQuestionSet(QuestionSet questionSet) async {
    await _reliableOps.safely(
      operation: () async {
        _questionSets.add(questionSet);
        debugPrint('Saved question set: ${questionSet.title}');
        notifyListeners();
      },
      operationName: 'save_question_set',
    );
  }

  /// Get question set by ID (compatibility method)
  QuestionSet? getQuestionSetById(String id) {
    return _reliableOps.safelySync(
      operation: () {
        return _questionSets.firstWhere((set) => set.id == id);
      },
      defaultValue: null,
      operationName: 'get_question_set_by_id',
    );
  }

  /// Get questions for set (compatibility method)
  List<InterviewQuestion> getQuestionsForSet(String setId) {
    return _reliableOps.safelySync(
          operation: () {
            final questionSet = getQuestionSetById(setId);
            if (questionSet != null) {
              return _questions
                  .where((q) => questionSet.questionIds.contains(q.id))
                  .toList();
            }
            return <InterviewQuestion>[];
          },
          defaultValue: <InterviewQuestion>[],
          operationName: 'get_questions_for_set',
        ) ??
        <InterviewQuestion>[];
  }

  /// Delete question set (compatibility method)
  Future<void> deleteQuestionSet(String setId) async {
    await _reliableOps.safely(
      operation: () async {
        _questionSets.removeWhere((set) => set.id == setId);
        debugPrint('Deleted question set: $setId');
        notifyListeners();
      },
      operationName: 'delete_question_set',
    );
  }
}
