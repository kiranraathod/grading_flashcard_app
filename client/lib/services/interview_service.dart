import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/interview_question.dart';
import '../models/interview_answer.dart'; // Added this import
import '../models/question_set.dart';

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
  
  // Constructor
  InterviewService() {
    _loadQuestions();
    _loadQuestionSetsFromStorage();
  }
  
  // Load questions (using mock data for now)
  void _loadQuestions() {
    _questions = InterviewQuestion.getMockQuestions();
    notifyListeners();
    // In a real implementation, this would load from persistent storage
    // For future implementation: _loadQuestionsFromStorage();
  }
  
  // Commented out for future implementation
  /*
  // Load questions from shared preferences
  Future<void> _loadQuestionsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = prefs.getString('interview_questions');
      
      if (questionsJson != null) {
        final List<dynamic> decoded = jsonDecode(questionsJson);
        _questions = decoded.map((item) {
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
            isDraft: item['isDraft'] ?? false,
          );
        }).toList();
      } else {
        // If no saved questions, initialize with mock data
        _questions = InterviewQuestion.getMockQuestions();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading questions: $e');
      // Fallback to mock data if there's an error
      _questions = InterviewQuestion.getMockQuestions();
      notifyListeners();
    }
  }
  */
  
  // Save questions to shared preferences
  Future<void> _saveQuestionsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serialized = _questions.map((q) {
        // Convert InterviewQuestion objects to JSON
        return {
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
      }).toList();
      
      await prefs.setString('interview_questions', jsonEncode(serialized));
    } catch (e) {
      debugPrint('Error saving questions: $e');
    }
  }
  
  // Get questions by category
  List<InterviewQuestion> getQuestionsByCategory(String category) {
    if (category == 'all') {
      return questions;
    }
    return questions.where((q) => q.category == category).toList();
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
      if (category != 'all' && q.category != category) {
        return false;
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
void addQuestion(InterviewQuestion question) {
    _questions.add(question);
    notifyListeners();
    _saveQuestionsToStorage();
  }
  
  // Update a question
  void updateQuestion(InterviewQuestion question) {
    final index = _questions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      _questions[index] = question;
      notifyListeners();
      _saveQuestionsToStorage();
    }
  }
  
  // Delete a question
  void deleteQuestion(String id) {
    _questions.removeWhere((q) => q.id == id);
    notifyListeners();
    _saveQuestionsToStorage();
  }
  
  // Get all unique subtopics for a category
  List<String> getSubtopicsForCategory(String category) {
    final subtopics = _questions
        .where((q) => q.category == category)
        .map((q) => q.subtopic)
        .toSet()
        .toList();
    return subtopics;
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