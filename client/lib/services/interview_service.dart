import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/interview_question.dart';
import '../models/interview_answer.dart';
import '../models/question_set.dart';
import '../utils/category_mapper.dart';
import 'default_data_service.dart';
import 'storage_service.dart';

class InterviewService extends ChangeNotifier {
  List<InterviewQuestion> _questions = [];
  List<QuestionSet> _questionSets = [];
  final DefaultDataService _defaultDataService = DefaultDataService();
  
  // Map to store user answers (questionId -> answer text)
  final Map<String, String> _userAnswers = {};
  
  // Getter for questions
  List<InterviewQuestion> get questions => _questions.where((q) => !q.isDraft).toList();
  
  // Getter for drafts
  List<InterviewQuestion> get drafts => _questions.where((q) => q.isDraft).toList();
  
  // Getter for question sets
  List<QuestionSet> get questionSets => _questionSets;
  
  /// Load default questions from server
  Future<void> _loadDefaultQuestions() async {
    try {
      debugPrint('Loading default interview questions from server...');
      final defaultQuestions = await _defaultDataService.loadDefaultInterviewQuestions();
      
      if (defaultQuestions.isNotEmpty) {
        _questions = defaultQuestions;
        debugPrint('Loaded ${defaultQuestions.length} default interview questions from server');
        
        // Save to local storage for offline access
        await _saveQuestionsToStorage();
      } else {
        debugPrint('No default questions loaded from server');
        // Create minimal fallback questions
        _questions = _createFallbackQuestions();
      }
    } catch (e) {
      debugPrint('Error loading default questions from server: $e');
      _questions = _createFallbackQuestions();
    }
  }

  /// Create minimal fallback questions if server fails
  List<InterviewQuestion> _createFallbackQuestions() {
    return [
      InterviewQuestion(
        id: 'fallback-1',
        text: 'Explain the difference between bias and variance in machine learning.',
        category: 'technical',
        subtopic: 'Machine Learning Algorithms',
        difficulty: 'mid',
        answer: 'Bias is error from oversimplification, variance is error from sensitivity to data.',
      ),
      InterviewQuestion(
        id: 'fallback-2',
        text: 'How would you handle missing data in a dataset?',
        category: 'applied',
        subtopic: 'Data Cleaning & Preprocessing',
        difficulty: 'entry',
        answer: 'Identify patterns, evaluate extent, choose imputation strategy, validate approach.',
      ),
    ];
  }

  /// Synchronize with server-generated categories for enhanced integration
  Future<void> synchronizeWithServerCategories() async {
    try {
      debugPrint('Synchronizing interview questions with server categories...');
      
      // Load fresh data from server to get latest categories
      final serverCategories = await _defaultDataService.loadDefaultCategories();
      final serverCategoryCounts = await _defaultDataService.loadCategoryCounts();
      
      if (serverCategories.isNotEmpty) {
        debugPrint('Server provides ${serverCategories.length} categories');
        
        // Validate our questions against server categories
        _validateQuestionCategoryMapping(serverCategories, serverCategoryCounts);
        
        // Update question metadata based on server categories if needed
        await _updateQuestionMetadata(serverCategories);
      }
    } catch (e) {
      debugPrint('Error synchronizing with server categories: $e');
    }
  }

  /// Validate question-category mapping consistency
  void _validateQuestionCategoryMapping(List<dynamic> serverCategories, Map<String, int>? serverCounts) {
    debugPrint('Validating question-category mapping consistency...');
    
    final localCategoryCounts = <String, int>{};
    
    // Count questions by UI category locally
    for (final question in questions) {
      for (final serverCategory in serverCategories) {
        final categoryName = serverCategory['name'] ?? '';
        if (_isQuestionInCategory(question, categoryName)) {
          localCategoryCounts[categoryName] = (localCategoryCounts[categoryName] ?? 0) + 1;
        }
      }
    }
    
    // Compare with server counts
    if (serverCounts != null) {
      for (final entry in serverCounts.entries) {
        final serverCount = entry.value;
        final localCount = localCategoryCounts[entry.key] ?? 0;
        
        if (serverCount != localCount) {
          debugPrint('Category count mismatch for ${entry.key}: server=$serverCount, local=$localCount');
        }
      }
    }
    
    debugPrint('Question-category validation completed');
  }

  /// Check if a question belongs to a specific category
  bool _isQuestionInCategory(InterviewQuestion question, String categoryName) {
    // Use the same simplified logic as getQuestionsByCategory for consistency
    
    // Primary: Check if question has categoryId field (server-generated)
    if (question.categoryId != null) {
      final serverUICategory = CategoryMapper.mapInternalToUICategory(question.categoryId!);
      if (serverUICategory == categoryName) {
        return true;
      }
    }
    
    // Fallback: Use legacy category mapping for backward compatibility
    final mappedCategory = CategoryMapper.getDefaultCategory(question.category);
    if (mappedCategory == categoryName) {
      return true;
    }
    
    // Special: Handle specific subtopic patterns (temporarily disabled)
    // return _isSpecialSubtopicMatch(categoryName, question);
    return false;
  }

  /// Update question metadata based on server categories
  Future<void> _updateQuestionMetadata(List<dynamic> serverCategories) async {
    bool hasUpdates = false;
    
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      
      // Check if question needs category metadata updates
      final updatedQuestion = _enhanceQuestionWithServerData(question, serverCategories);
      
      if (updatedQuestion != null) {
        _questions[i] = updatedQuestion;
        hasUpdates = true;
        debugPrint('Updated metadata for question: ${question.id}');
      }
    }
    
    if (hasUpdates) {
      await _saveQuestionsToStorage();
      notifyListeners();
      debugPrint('Question metadata updated based on server categories');
    }
  }

  /// Enhance question with server-provided category data
  InterviewQuestion? _enhanceQuestionWithServerData(InterviewQuestion question, List<dynamic> serverCategories) {
    // For now, we maintain existing question structure
    // In future versions, this could add server-provided tags, difficulty adjustments, etc.
    
    // Example enhancement: validate difficulty levels against server standards
    final validDifficulties = ['entry', 'mid', 'senior'];
    if (!validDifficulties.contains(question.difficulty)) {
      debugPrint('Question ${question.id} has invalid difficulty: ${question.difficulty}');
      return question.copyWith(difficulty: 'entry'); // Default to entry level
    }
    
    return null; // No changes needed for now
  }
  
  // Method to get all unique subtopics from questions
  List<String> getAllUniqueSubtopics() {
    Set<String> uniqueSubtopics = {};
    
    for (var question in _questions) {
      if (!question.isDraft && question.subtopic.isNotEmpty) {
        uniqueSubtopics.add(question.subtopic);
      }
    }
    
    debugPrint('Found ${uniqueSubtopics.length} unique subtopics');
    return uniqueSubtopics.toList();
  }
  
  // Method to count questions for a specific subtopic
  int getQuestionCountForSubtopic(String subtopic) {
    if (subtopic.isEmpty) return 0;
    
    final count = _questions.where(
      (q) => !q.isDraft && q.subtopic.toLowerCase() == subtopic.toLowerCase()
    ).length;
    
    debugPrint('Found $count questions for subtopic: $subtopic');
    return count;
  }
  
  // Method to get all subtopics for a specific category
  List<String> getSubtopicsForCategory(String category) {
    if (category.isEmpty) return [];
    
    final subtopics = _questions
        .where((q) => !q.isDraft && q.category == category)
        .map((q) => q.subtopic)
        .toSet()
        .toList();
    
    debugPrint('Found ${subtopics.length} subtopics for category $category: ${subtopics.join(", ")}');
    return subtopics;
  }
  
  // Constructor
  InterviewService() {
    _loadQuestions();
    _loadQuestionSetsFromStorage();
  }
  
  // Load questions from storage first, then fallback to mock data if needed
  void _loadQuestions() {
    _loadQuestionsFromStorage();
  }
  
  // Load questions from shared preferences
  Future<void> _loadQuestionsFromStorage() async {
    try {
      final questionsData = StorageService.getInterviewQuestions();
      
      if (questionsData != null && questionsData.isNotEmpty) {
        debugPrint('Found saved questions in storage using StorageService');
        
        List<InterviewQuestion> loadedQuestions = questionsData.map<InterviewQuestion>((item) {
          // Default isDraft to false if it's missing in the stored data
          final bool isDraft = item['isDraft'] ?? false;
          
          // Debug log for loading
          debugPrint('Loading question ${item['id']}: ${item['text']} with isDraft=$isDraft');
          
          // Convert JSON to InterviewQuestion objects
          return InterviewQuestion(
            id: item['id'],
            text: item['text'],
            category: item['category'],
            subtopic: item['subtopic'],
            difficulty: item['difficulty'],
            answer: item['answer'],
            categoryId: item['categoryId'], // ✅ ADDED: Load categoryId from storage
            isStarred: item['isStarred'] ?? false,
            isCompleted: item['isCompleted'] ?? false,
            isDraft: isDraft,
          );
        }).toList();
        
        // Only update if we actually loaded questions
        if (loadedQuestions.isNotEmpty) {
          _questions = loadedQuestions;
          debugPrint('Loaded ${_questions.length} questions from storage using StorageService');
          
          // Count published vs draft questions
          final publishedCount = _questions.where((q) => !q.isDraft).length;
          final draftCount = _questions.where((q) => q.isDraft).length;
          debugPrint('Published questions: $publishedCount, Drafts: $draftCount');
        } else {
          // Fallback to server data if no questions were loaded
          await _loadDefaultQuestions();
          debugPrint('No questions found in storage, loading from server');
        }
      } else {
        // If no saved questions, initialize with server data
        await _loadDefaultQuestions();
        debugPrint('No questions found in storage, loading from server');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading questions from storage: $e');
      // Fallback to server data if there's an error
      await _loadDefaultQuestions();
      notifyListeners();
    }
  }
  
  // Save questions to shared preferences
  Future<void> _saveQuestionsToStorage() async {
    try {
      final List<Map<String, dynamic>> serialized = _questions.map((q) {
        // Convert InterviewQuestion objects to JSON
        final Map<String, dynamic> json = {
          'id': q.id,
          'text': q.text,
          'category': q.category,
          'subtopic': q.subtopic,
          'difficulty': q.difficulty,
          'answer': q.answer,
          'categoryId': q.categoryId, // ✅ ADDED: Include categoryId in storage
          'isStarred': q.isStarred,
          'isCompleted': q.isCompleted,
          'isDraft': q.isDraft,
        };
        
        // Debug log for isDraft value
        debugPrint('Serializing question ${q.id}: ${q.text} with isDraft=${q.isDraft}');
        
        return json;
      }).toList();
      
      // Save using simple StorageService
      await StorageService.saveInterviewQuestions(serialized);
      
      // Verify the data was saved correctly
      debugPrint('Successfully saved ${serialized.length} questions to storage using StorageService');
    } catch (e) {
      debugPrint('Error saving questions: $e');
      // Re-throw for proper error handling
      throw Exception('Failed to save interview questions: $e');
    }
  }
  
  // ✅ UPDATED: Get questions by category - now handles both categories and subtopics
  List<InterviewQuestion> getQuestionsByCategory(String uiCategory, {bool isSubtopic = false}) {
    if (uiCategory == 'all') {
      return questions;
    }
    
    debugPrint('=== FILTERING DEBUG: Getting questions ===');
    debugPrint('Category: $uiCategory');
    debugPrint('isSubtopic: $isSubtopic');
    debugPrint('Total published questions: ${questions.length}');
    
    final filteredQuestions = questions.where((question) {
      // SPECIAL DEBUG: Track API Development questions specifically
      if (uiCategory == 'API Development' || question.subtopic.toLowerCase().contains('api') || question.text.toLowerCase().contains('api')) {
        debugPrint('🔍 POTENTIAL API DEV FILTERING CHECK:');
        debugPrint('  Text: "${question.text}"');
        debugPrint('  Raw subtopic: "${question.subtopic}"');
        debugPrint('  Normalized subtopic: "${question.subtopic.trim()}"');
        debugPrint('  Category: "${question.category}"');
        debugPrint('  CategoryId: "${question.categoryId}"');
        debugPrint('  isDraft: ${question.isDraft}');
        debugPrint('  Target category: "$uiCategory"');
        debugPrint('  isSubtopic: $isSubtopic');
      }
      
      // If this is a subtopic search, match by subtopic directly
      if (isSubtopic) {
        // FIXED: Use same normalization as counting (trim only, case-sensitive)
        final questionSubtopic = question.subtopic.trim();
        final targetSubtopic = uiCategory.trim();
        final matches = questionSubtopic == targetSubtopic;
        
        if (uiCategory == 'API Development') {
          debugPrint('  🔍 API DEV SUBTOPIC CHECK:');
          debugPrint('    Question subtopic (normalized): "$questionSubtopic"');
          debugPrint('    Target subtopic (normalized): "$targetSubtopic"');
          debugPrint('    Matches: $matches');
        }
        
        if (matches) {
          debugPrint('  ✅ MATCH FOUND: ${question.text}');
        }
        return matches;
      }
      
      // Otherwise, use the original category matching logic
      // ✅ PRIMARY: Check if question has categoryId field (server-generated or user-created)
      if (question.categoryId != null) {
        final serverUICategory = CategoryMapper.mapInternalToUICategory(question.categoryId!);
        if (serverUICategory == uiCategory) {
          debugPrint('CategoryId match: ${question.text} (categoryId: ${question.categoryId})');
          return true;
        }
      }
      
      // ✅ FALLBACK: Use legacy category mapping for backward compatibility
      final mappedCategory = CategoryMapper.getDefaultCategory(question.category);
      if (mappedCategory == uiCategory) {
        debugPrint('Legacy category match: ${question.text} (category: ${question.category} -> $mappedCategory)');
        return true;
      }
      
      // ✅ SPECIAL: Handle specific subtopic patterns (temporarily disabled)
      // if (_isSpecialSubtopicMatch(uiCategory, question)) {
      //   debugPrint('Subtopic pattern match: ${question.text} (subtopic: ${question.subtopic})');
      //   return true;
      // }
      
      return false;
    }).toList();
    
    debugPrint('=== FILTERING RESULT ===');
    debugPrint('Found ${filteredQuestions.length} questions for ${isSubtopic ? 'subtopic' : 'category'} $uiCategory');
    for (final q in filteredQuestions) {
      debugPrint('  - "${q.text}" (subtopic: "${q.subtopic}")');
    }
    
    // SPECIAL DEBUG: API Development specific summary
    if (uiCategory == 'API Development') {
      debugPrint('🎯 API DEVELOPMENT FILTERING SUMMARY:');
      debugPrint('  Questions found by filtering: ${filteredQuestions.length}');
      debugPrint('  This is what will be displayed on the questions screen');
      debugPrint('  If this doesn\'t match the card count, there\'s a mismatch!');
    }
    
    debugPrint('=== END FILTERING DEBUG ===');
    
    return filteredQuestions;
  }

  // ✅ SIMPLIFIED: Handle special subtopic patterns (temporarily disabled)
  // bool _isSpecialSubtopicMatch(String uiCategory, InterviewQuestion question) {
  //   final subtopicLower = question.subtopic.toLowerCase();
  //   
  //   switch (uiCategory) {
  //     case 'SQL':
  //       return subtopicLower.contains('sql') || subtopicLower.contains('database');
  //     case 'Python':
  //       return subtopicLower.contains('python');
  //     case 'Data Analysis':
  //       return subtopicLower.contains('data') || subtopicLower.contains('analysis');
  //     case 'Machine Learning':
  //       return subtopicLower.contains('ml') || subtopicLower.contains('machine learning');
  //     case 'Web Development':
  //       return subtopicLower.contains('web') || subtopicLower.contains('api');
  //     case 'Statistics':
  //       return subtopicLower.contains('statistical') || subtopicLower.contains('statistics');
  //     default:
  //       return false;
  //   }
  // }
  
  // Get questions by subtopic
  List<InterviewQuestion> getQuestionsBySubtopic(String subtopic) {
    if (subtopic.isEmpty) {
      return questions;
    }
    
    // Get all non-draft questions
    final allQuestions = questions;
    debugPrint('Getting questions for subtopic: $subtopic');
    debugPrint('Total published questions: ${allQuestions.length}');
    
    // Filter questions based on the subtopic (case-insensitive match)
    final filteredQuestions = allQuestions.where((q) {
      final matches = q.subtopic.toLowerCase() == subtopic.toLowerCase();
      if (matches) debugPrint('Subtopic match found: ${q.text}');
      return matches;
    }).toList();
    
    debugPrint('Found ${filteredQuestions.length} questions for subtopic $subtopic');
    return filteredQuestions;
  }
  
  // Get questions by difficulty
  List<InterviewQuestion> getQuestionsByDifficulty(String difficulty) {
    if (difficulty == 'all') {
      return questions;
    }
    return questions.where((q) => q.difficulty == difficulty).toList();
  }
  
  // ✅ UPDATED: Get filtered questions using same logic as getQuestionsByCategory (now supports subtopics)
  List<InterviewQuestion> getFilteredQuestions({
    String category = 'all',
    String difficulty = 'all',
    String searchQuery = '',
    bool includeDrafts = false,
    bool isSubtopic = false, // New parameter to indicate if category is actually a subtopic
  }) {
    // Start with either all questions or just published ones
    final baseList = includeDrafts ? _questions : questions;
    
    return baseList.where((q) {
      // Filter by category using SAME logic as getQuestionsByCategory
      if (category != 'all') {
        // If this is a subtopic search, match by subtopic directly
        if (isSubtopic) {
          // FIXED: Use same normalization as counting and getQuestionsByCategory
          final questionSubtopic = q.subtopic.trim();
          final targetSubtopic = category.trim();
          if (questionSubtopic != targetSubtopic) {
            return false;
          }
        } else {
          // ✅ FIX: Map legacy categories to UI categories for proper filtering
          String targetUICategory = category;
          
          // Handle legacy category mapping for filters
          if (['technical', 'applied', 'behavioral', 'case', 'job'].contains(category)) {
            targetUICategory = CategoryMapper.mapInternalToUICategory(category);
            debugPrint('🔧 Mapped legacy filter "$category" to UI category "$targetUICategory"');
          }
          
          // Use the original category matching logic with mapped target
          bool matches = false;
          
          // PRIMARY: Check categoryId field
          if (q.categoryId != null) {
            final serverUICategory = CategoryMapper.mapInternalToUICategory(q.categoryId!);
            if (serverUICategory == targetUICategory) {
              matches = true;
            }
          }
          
          // FALLBACK: Use legacy category mapping
          if (!matches) {
            final mappedCategory = CategoryMapper.getDefaultCategory(q.category);
            if (mappedCategory == targetUICategory) {
              matches = true;
            }
          }
          
          // SPECIAL: Handle subtopic patterns (temporarily disabled)
          // if (!matches && _isSpecialSubtopicMatch(targetUICategory, q)) {
          //   matches = true;
          // }
          
          if (!matches) {
            return false;
          }
        }
      }
      
      // Filter by difficulty
      if (difficulty != 'all' && q.difficulty != difficulty) {
        return false;
      }
      
      // Filter by search text
      if (searchQuery.isNotEmpty) {
        return q.text.toLowerCase().contains(searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }
  
  // Toggle star for a question
  void toggleStar(String id) {
    final index = _questions.indexWhere((q) => q.id == id);
    if (index != -1) {
      _questions[index] = _questions[index].copyWith(
        isStarred: !_questions[index].isStarred,
      );
      notifyListeners();
      _saveQuestionsToStorage();
    }
  }
  
  // Toggle completion for a question
  void toggleCompletion(String id) {
    final index = _questions.indexWhere((q) => q.id == id);
    if (index != -1) {
      _questions[index] = _questions[index].copyWith(
        isCompleted: !_questions[index].isCompleted,
      );
      notifyListeners();
      _saveQuestionsToStorage();
    }
  }
  
  // Add a new question
  // Add a question and update the category counts
  Future<void> addQuestion(InterviewQuestion question) async {
    // Debug log to track the question being added
    debugPrint('Adding new question: ${question.text} with isDraft=${question.isDraft}');
    debugPrint('Question details - Category: ${question.category}, CategoryId: ${question.categoryId}, UI Category: ${CategoryMapper.getDefaultCategory(question.category)}, Subtopic: ${question.subtopic}');
    
    // Add to the in-memory list
    _questions.add(question);
    
    // Notify listeners to update UI
    notifyListeners();
    
    // Save to persistent storage
    await _saveQuestionsToStorage();
    
    // Debug log to confirm question count
    debugPrint('Questions count after adding: ${_questions.length}');
    debugPrint('Published questions: ${questions.length}, Drafts: ${drafts.length}');
    
    // ✅ ADDED: Debug verification for category mapping
    _debugQuestionCategoryMapping(question);
  }
  
  // ✅ FIXED: Debug method to verify question category mapping (simplified)
  void _debugQuestionCategoryMapping(InterviewQuestion question) {
    debugPrint('=== CATEGORY MAPPING DEBUG FOR QUESTION ${question.id} ===');
    debugPrint('Question text: ${question.text}');
    debugPrint('Internal category: ${question.category}');
    debugPrint('CategoryId field: ${question.categoryId}');
    debugPrint('Subtopic: ${question.subtopic}');
    
    // Show the final UI category this question will appear in
    if (question.categoryId != null) {
      final uiCategory = CategoryMapper.mapInternalToUICategory(question.categoryId!);
      debugPrint('✅ WILL APPEAR in "$uiCategory" category (using categoryId)');
    } else {
      final uiCategory = CategoryMapper.getDefaultCategory(question.category);
      debugPrint('✅ WILL APPEAR in "$uiCategory" category (using legacy mapping)');
    }
    
    debugPrint('=== END CATEGORY MAPPING DEBUG ===');
  }
  
  // Update a question
  Future<void> updateQuestion(InterviewQuestion question) async {
    // Debug log to track the question being updated
    debugPrint('Updating question: ${question.id} - ${question.text} with isDraft=${question.isDraft}');
    
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      _questions[index] = question;
      
      // Notify listeners to update UI
      notifyListeners();
      
      // Save to persistent storage
      await _saveQuestionsToStorage();
      
      // Debug log to confirm question count
      debugPrint('Questions updated. Published questions: ${questions.length}, Drafts: ${drafts.length}');
    } else {
      debugPrint('Warning: Could not find question to update with ID ${question.id}');
    }
  }
  
  // Delete a question
  void deleteQuestion(String id) {
    _questions.removeWhere((q) => q.id == id);
    notifyListeners();
    _saveQuestionsToStorage();
  }
  
  // Calculate progress statistics
  Map<String, dynamic> getProgressStats() {
    final int completed = questions.where((q) => q.isCompleted).length;
    final int total = questions.length;
    final double percentage = total > 0 ? (completed / total * 100) : 0;
    
    return {
      'completed': completed,
      'total': total,
      'percentage': percentage,
    };
  }
  
  // Save as draft
  Future<void> saveDraft(InterviewQuestion question) async {
    // Ensure the question is marked as a draft
    final draftQuestion = question.copyWith(isDraft: true);
    
    // Check if this draft already exists (update) or is new (add)
    final index = _questions.indexWhere((q) => q.id == draftQuestion.id);
    if (index != -1) {
      _questions[index] = draftQuestion;
    } else {
      _questions.add(draftQuestion);
    }
    
    notifyListeners();
    await _saveQuestionsToStorage();
  }
  
  // Get all drafts
  List<InterviewQuestion> getDrafts() {
    return _questions.where((q) => q.isDraft).toList();
  }
  
  // Publish a draft
  Future<void> publishDraft(String id) async {
    final index = _questions.indexWhere((q) => q.id == id);
    if (index != -1 && _questions[index].isDraft) {
      _questions[index] = _questions[index].copyWith(isDraft: false);
      notifyListeners();
      await _saveQuestionsToStorage();
    }
  }
  
  // Get question by ID
  InterviewQuestion? getQuestionById(String id) {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get a question's answer
  String? getQuestionAnswer(String id) {
    final question = getQuestionById(id);
    return question?.answer;
  }
  
  // Save user answer for a question
  void saveUserAnswer(String questionId, String answer) {
    _userAnswers[questionId] = answer;
    notifyListeners();
  }
  
  // Get user answer for a question
  String? getUserAnswer(String questionId) {
    return _userAnswers[questionId];
  }
  
  // Get answers for a list of question IDs
  List<InterviewAnswer> getAnswersForQuestionIds(List<String> questionIds) {
    List<InterviewAnswer> answers = [];
    
    for (final id in questionIds) {
      final question = getQuestionById(id);
      final userAnswer = getUserAnswer(id);
      
      if (question != null && userAnswer != null && userAnswer.trim().isNotEmpty) {
        answers.add(
          InterviewAnswer(
            questionId: id,
            questionText: question.text,
            userAnswer: userAnswer,
            category: question.category,
            difficulty: question.difficulty,
          )
        );
      }
    }
    
    return answers;
  }
  
  // Track question view (for analytics)
  void trackQuestionView(String id) {
    // In a real implementation, this would log the view for analytics
    debugPrint('Question viewed: $id');
  }
  
  // Track which subtopics have questions
  Map<String, int> getSubtopicCounts() {
    Map<String, int> counts = {};
    for (var question in _questions.where((q) => !q.isDraft)) {
      if (!counts.containsKey(question.subtopic)) {
        counts[question.subtopic] = 0;
      }
      counts[question.subtopic] = (counts[question.subtopic] ?? 0) + 1;
    }
    
    debugPrint('Subtopic counts: ${counts.toString()}');
    return counts;
  }
  
  // Save question set
  Future<void> saveQuestionSet(QuestionSet set) async {
    final existingIndex = _questionSets.indexWhere((s) => s.id == set.id);
    
    if (existingIndex != -1) {
      _questionSets[existingIndex] = set;
    } else {
      _questionSets.add(set);
    }
    
    notifyListeners();
    await _saveQuestionSetsToStorage();
  }
  
  // Save question sets to storage
  Future<void> _saveQuestionSetsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = _questionSets.map((set) => set.toJson()).toList();
      await prefs.setString('question_sets', jsonEncode(serialized));
    } catch (e) {
      debugPrint('Error saving question sets: $e');
    }
  }
  
  // Load question sets from storage
  Future<void> _loadQuestionSetsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final setsJson = prefs.getString('question_sets');
      
      if (setsJson != null) {
        final List<dynamic> decoded = jsonDecode(setsJson);
        _questionSets = decoded.map((item) => QuestionSet.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading question sets: $e');
    }
  }
  
  // Get question set by ID
  QuestionSet? getQuestionSetById(String id) {
    try {
      return _questionSets.firstWhere((set) => set.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Delete question set
  Future<void> deleteQuestionSet(String id) async {
    _questionSets.removeWhere((set) => set.id == id);
    notifyListeners();
    await _saveQuestionSetsToStorage();
  }
  
  // Get all questions for a set
  List<InterviewQuestion> getQuestionsForSet(String setId) {
    final set = getQuestionSetById(setId);
    if (set == null) return [];
    
    return set.questionIds
        .map((id) => getQuestionById(id))
        .whereType<InterviewQuestion>()
        .toList();
  }
  
  /// Debug method to verify subtopic counts and identify mismatches
  void debugSubtopicCounts([String? specificSubtopic]) {
    debugPrint('=== SUBTOPIC COUNT DEBUG ===');
    
    final subtopicCounts = <String, int>{};
    final allPublishedQuestions = questions; // This gets non-draft questions
    
    debugPrint('Total published questions: ${allPublishedQuestions.length}');
    
    for (final question in allPublishedQuestions) {
      final normalizedSubtopic = question.subtopic.trim();
      if (normalizedSubtopic.isNotEmpty) {
        subtopicCounts[normalizedSubtopic] = (subtopicCounts[normalizedSubtopic] ?? 0) + 1;
        
        if (specificSubtopic != null && normalizedSubtopic == specificSubtopic) {
          debugPrint('FOUND for $specificSubtopic: "${question.text}"');
          debugPrint('  - Raw subtopic: "${question.subtopic}"');
          debugPrint('  - Normalized: "$normalizedSubtopic"');
          debugPrint('  - isDraft: ${question.isDraft}');
        }
      }
    }
    
    debugPrint('All subtopic counts:');
    final sortedSubtopics = subtopicCounts.keys.toList()..sort();
    for (final subtopic in sortedSubtopics) {
      debugPrint('  $subtopic: ${subtopicCounts[subtopic]}');
    }
    
    if (specificSubtopic != null) {
      debugPrint('');
      debugPrint('SPECIFIC DEBUG for: $specificSubtopic');
      debugPrint('Count: ${subtopicCounts[specificSubtopic] ?? 0}');
      
      // Test filtering with same subtopic
      final filtered = getQuestionsByCategory(specificSubtopic, isSubtopic: true);
      debugPrint('Filtered count: ${filtered.length}');
      
      if ((subtopicCounts[specificSubtopic] ?? 0) != filtered.length) {
        debugPrint('⚠️  COUNT MISMATCH DETECTED!');
        debugPrint('   Counting found: ${subtopicCounts[specificSubtopic] ?? 0}');
        debugPrint('   Filtering found: ${filtered.length}');
      } else {
        debugPrint('✅ Counts match correctly');
      }
    }
    
    debugPrint('=========================');
  }
  
  /// Debug method to print all questions and their category mappings
  void debugPrintAllQuestions() {
    debugPrint('=== ALL QUESTIONS DEBUG ===');
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      debugPrint('[$i] ID: ${q.id}');
      debugPrint('    Text: ${q.text}'); 
      debugPrint('    Category: ${q.category}');
      debugPrint('    CategoryId: ${q.categoryId}');
      debugPrint('    Subtopic: ${q.subtopic}');
      debugPrint('    isDraft: ${q.isDraft}');
      debugPrint('    UI Category: ${CategoryMapper.getDefaultCategory(q.category)}');
    }
    debugPrint('Total: ${_questions.length}, Published: ${questions.length}');
    debugPrint('=========================');
  }
  
  /// Debug method to verify category counts
  void debugCategoryCounts() {
    final counts = <String, int>{};
    
    for (final question in questions) {
      String uiCategory;
      if (question.categoryId != null) {
        uiCategory = CategoryMapper.mapInternalToUICategory(question.categoryId!);
      } else {
        uiCategory = CategoryMapper.getDefaultCategory(question.category);
      }
      counts[uiCategory] = (counts[uiCategory] ?? 0) + 1;
    }
    
    debugPrint('=== LOCAL CATEGORY COUNTS ===');
    for (final entry in counts.entries) {
      debugPrint('${entry.key}: ${entry.value} questions');
    }
    debugPrint('=============================');
  }

  // Search for interview questions containing the query
  Future<List<InterviewQuestion>> searchQuestions(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    
    // Return an empty list if the query is too short
    if (normalizedQuery.length < 3) {
      return [];
    }
    
    return _questions.where((question) {
      // Properly handle nullable and non-nullable fields
      final textMatch = question.text.toLowerCase().contains(normalizedQuery);
      final categoryMatch = question.category.toLowerCase().contains(normalizedQuery);
      final subtopicMatch = question.subtopic.toLowerCase().contains(normalizedQuery);
      final answerMatch = question.answer?.toLowerCase().contains(normalizedQuery) ?? false;
      
      return textMatch || categoryMatch || subtopicMatch || answerMatch;
    }).toList();
  }
}