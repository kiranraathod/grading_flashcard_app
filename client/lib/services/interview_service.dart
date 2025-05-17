import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/interview_question.dart';
import '../models/interview_answer.dart';
import '../models/question_set.dart';
import '../utils/category_mapper.dart';

class InterviewService extends ChangeNotifier {
  List<InterviewQuestion> _questions = [];
  List<QuestionSet> _questionSets = [];
  
  // Map to store user answers (questionId -> answer text)
  final Map<String, String> _userAnswers = {};
  
  // Getter for questions
  List<InterviewQuestion> get questions => _questions.where((q) => !q.isDraft).toList();
  
  // Getter for drafts
  List<InterviewQuestion> get drafts => _questions.where((q) => q.isDraft).toList();
  
  // Getter for question sets
  List<QuestionSet> get questionSets => _questionSets;
  
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
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = prefs.getString('interview_questions');
      
      if (questionsJson != null && questionsJson.isNotEmpty) {
        debugPrint('Found saved questions in SharedPreferences');
        final List<dynamic> decoded = jsonDecode(questionsJson);
        
        List<InterviewQuestion> loadedQuestions = decoded.map<InterviewQuestion>((item) {
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
            isStarred: item['isStarred'] ?? false,
            isCompleted: item['isCompleted'] ?? false,
            isDraft: isDraft,
          );
        }).toList();
        
        // Only update if we actually loaded questions
        if (loadedQuestions.isNotEmpty) {
          _questions = loadedQuestions;
          debugPrint('Loaded ${_questions.length} questions from storage');
          
          // Count published vs draft questions
          final publishedCount = _questions.where((q) => !q.isDraft).length;
          final draftCount = _questions.where((q) => q.isDraft).length;
          debugPrint('Published questions: $publishedCount, Drafts: $draftCount');
        } else {
          // Fallback to mock data if no questions were loaded
          _questions = InterviewQuestion.getMockQuestions();
          debugPrint('No questions found in storage, using mock data');
        }
      } else {
        // If no saved questions, initialize with mock data
        _questions = InterviewQuestion.getMockQuestions();
        debugPrint('No questions found in storage, using mock data');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading questions from storage: $e');
      // Fallback to mock data if there's an error
      _questions = InterviewQuestion.getMockQuestions();
      notifyListeners();
    }
  }
  
  // Save questions to shared preferences
  Future<void> _saveQuestionsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serialized = _questions.map((q) {
        // Convert InterviewQuestion objects to JSON
        final Map<String, dynamic> json = {
          'id': q.id,
          'text': q.text,
          'category': q.category,
          'subtopic': q.subtopic,
          'difficulty': q.difficulty,
          'answer': q.answer,
          'isStarred': q.isStarred,
          'isCompleted': q.isCompleted,
          'isDraft': q.isDraft,
        };
        
        // Debug log for isDraft value
        debugPrint('Serializing question ${q.id}: ${q.text} with isDraft=${q.isDraft}');
        
        return json;
      }).toList();
      
      final jsonStr = jsonEncode(serialized);
      await prefs.setString('interview_questions', jsonStr);
      
      // Verify the data was saved correctly
      debugPrint('Successfully saved ${serialized.length} questions to storage');
    } catch (e) {
      debugPrint('Error saving questions: $e');
    }
  }
  
  // Get questions by category
  List<InterviewQuestion> getQuestionsByCategory(String uiCategory) {
    if (uiCategory == 'all') {
      return questions;
    }
    
    // Get all non-draft questions
    final allQuestions = questions;
    debugPrint('Getting questions for UI category: $uiCategory');
    debugPrint('Total published questions: ${allQuestions.length}');
    
    // Filter questions based on the UI category
    final filteredQuestions = allQuestions.where((q) {
      // For SQL category, check if subtopic contains SQL
      if (uiCategory == 'SQL') {
        final matches = q.subtopic.toLowerCase().contains('sql');
        if (matches) debugPrint('SQL match found: ${q.text}');
        return matches;
      }
      
      // For Data Visualization, check if subtopic contains visualization
      if (uiCategory == 'Data Visualization') {
        final matches = q.subtopic.toLowerCase().contains('visualization');
        if (matches) debugPrint('Visualization match found: ${q.text}');
        return matches;
      }
      
      // Get the internal category corresponding to the UI category
      final String internalCategory = CategoryMapper.mapUIToInternalCategory(uiCategory);
      
      // BUGFIX: Check if either:
      // 1. The question's internal category matches our expected internal category OR
      // 2. The question's UI category (based on its internal category) matches our target UI category
      final bool directMatch = q.category == internalCategory;
      final bool reverseMappedMatch = CategoryMapper.getDefaultCategory(q.category) == uiCategory;
      
      final matches = directMatch || reverseMappedMatch;
      
      if (matches) {
        debugPrint('Category match found: ${q.text} (${q.category} mapped to ${CategoryMapper.getDefaultCategory(q.category)})');
      }
      
      return matches;
    }).toList();
    
    debugPrint('Found ${filteredQuestions.length} questions for category $uiCategory');
    return filteredQuestions;
  }
  
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
  
  // Get filtered questions
  List<InterviewQuestion> getFilteredQuestions({
    String category = 'all',
    String difficulty = 'all',
    String searchQuery = '',
    bool includeDrafts = false,
  }) {
    // Start with either all questions or just published ones
    final baseList = includeDrafts ? _questions : questions;
    
    return baseList.where((q) {
      // Filter by category
      if (category != 'all') {
        bool matchesCategory = false;
        
        // Special case for SQL and Data Visualization
        if (category == 'SQL' && q.subtopic.toLowerCase().contains('sql')) {
          matchesCategory = true;
        } else if (category == 'Data Visualization' && q.subtopic.toLowerCase().contains('visualization')) {
          matchesCategory = true;
        } else {
          // For other categories, map UI category to internal category
          final String internalCategory = CategoryMapper.mapUIToInternalCategory(category);
          
          // BUGFIX: Check both direct match and reverse-mapped match
          bool directMatch = (q.category == internalCategory);
          bool reverseMappedMatch = (CategoryMapper.getDefaultCategory(q.category) == category);
          matchesCategory = directMatch || reverseMappedMatch;
        }
        
        if (!matchesCategory) return false;
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
    debugPrint('Question details - Category: ${question.category}, UI Category: ${CategoryMapper.getDefaultCategory(question.category)}, Subtopic: ${question.subtopic}');
    
    // Add to the in-memory list
    _questions.add(question);
    
    // Notify listeners to update UI
    notifyListeners();
    
    // Save to persistent storage
    await _saveQuestionsToStorage();
    
    // Debug log to confirm question count
    debugPrint('Questions count after adding: ${_questions.length}');
    debugPrint('Published questions: ${questions.length}, Drafts: ${drafts.length}');
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