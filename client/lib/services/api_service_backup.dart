import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/answer.dart' as answer_model;
import '../utils/constants.dart';
import '../web/proxy.dart';

class ApiService {
  final ProxyClient client;
  final bool _useForceOfflineMode = true; // TEMPORARY FOR TESTING - Force offline mode

  // Default fallback response for when API fails
  final Map<String, dynamic> _defaultFallback = {
    'grade': 'B',
    'feedback': 'Your answer shows good understanding, but could be more detailed.',
    'suggestions': [
      'Try to be more specific in your answer',
      'Include key facts or dates if relevant',
      'Consider explaining the underlying concepts',
    ],
  };

  // Constructor
  ApiService() : client = ProxyClient(Constants.apiBaseUrl) {
    debugPrint(
      '⚠️ API Service initialized with FORCED OFFLINE MODE for testing',
    );
  }

  Future<answer_model.Answer> gradeAnswer(answer_model.Answer answer) async {
    debugPrint('Grading answer: ${answer.question} => ${answer.userAnswer}');
    debugPrint('Correct answer: ${answer.correctAnswer}');

    // TEMPORARY FOR TESTING - Skip API call and use smart fallback
    if (_useForceOfflineMode) {
      debugPrint('⚠️ Using forced offline mode - skipping API call');
      return _createSmartFallbackAnswer(answer);
    }

    try {
      final response = await client
          .post(
            '/api/grade',
            body: {
              'flashcardId': answer.flashcardId,
              'question': answer.question,
              'userAnswer': answer.userAnswer,
              'correctAnswer': answer.correctAnswer,
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('API request timed out');
              throw TimeoutException('Server took too long to respond');
            },
          );

      debugPrint('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('API response data: $responseData');

        // Validate response data
        if (_validateResponseData(responseData)) {
          return answer_model.Answer(
            flashcardId: answer.flashcardId,
            question: answer.question,
            userAnswer: answer.userAnswer,
            correctAnswer: answer.correctAnswer,
            grade: responseData['grade'],
            feedback: responseData['feedback'],
            suggestions: List<String>.from(responseData['suggestions']),
          );
        } else {
          debugPrint('Invalid response data format, using smart fallback');
          return _createSmartFallbackAnswer(answer);
        }
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return _createSmartFallbackAnswer(answer);
      }
    } catch (e) {
      debugPrint('Error during API call: $e');
      return _createSmartFallbackAnswer(answer);
    }
  }

  bool _validateResponseData(Map<String, dynamic> data) {
    // Check that all required fields exist and have correct types
    if (!data.containsKey('grade') ||
        !data.containsKey('feedback') ||
        !data.containsKey('suggestions')) {
      return false;
    }

    // Validate grade is a valid letter grade
    final validGrades = ['A', 'B', 'C', 'D', 'F', 'X'];
    if (!validGrades.contains(data['grade'])) {
      return false;
    }

    // Validate feedback is a non-empty string
    if (data['feedback'] == null || (data['feedback'] as String).isEmpty) {
      return false;
    }

    // Validate suggestions is a list
    if (data['suggestions'] == null || data['suggestions'] is! List) {
      return false;
    }

    return true;
  }

  answer_model.Answer _createSmartFallbackAnswer(answer_model.Answer answer) {
    // Extract and normalize answers for comparison
    final String userAnswer = answer.userAnswer.toLowerCase().trim();
    final String correctAnswer = answer.correctAnswer.toLowerCase().trim();

    debugPrint('Smart fallback grading using direct answer comparison');
    debugPrint('User answer: "$userAnswer"');
    debugPrint('Correct answer: "$correctAnswer"');

    // Different levels of matching for more nuanced grading
    final bool isExactMatch = userAnswer == correctAnswer;
    final bool isStrongMatch = _calculateSimilarity(userAnswer, correctAnswer) > 0.8;
    final bool isPartialMatch = _calculateSimilarity(userAnswer, correctAnswer) > 0.5;
    final bool hasKeyElements = _containsKeyElements(userAnswer, correctAnswer);

    debugPrint('Match levels: exact=$isExactMatch, strong=$isStrongMatch, partial=$isPartialMatch, keyElements=$hasKeyElements');
    
    // Grade determination based on answer similarity
    String grade;
    String feedback;
    List<String> suggestions;

    if (isExactMatch) {
      // Perfect match
      grade = 'A';
      feedback = 'Excellent! Your answer is exactly correct.';
      suggestions = [
        'Continue practicing to maintain your understanding',
        'Try applying this knowledge to more complex problems',
        'Consider exploring related topics to deepen your understanding'
      ];
    } else if (isStrongMatch) {
      // Very close match
      grade = 'B';
      feedback = 'Good job! Your answer is very close to the correct one: "${answer.correctAnswer}".';
      suggestions = [
        'Pay attention to the precise wording of your answers',
        'Review the specific terminology for this topic',
        'Practice with similar questions to improve accuracy'
      ];
    } else if (isPartialMatch || hasKeyElements) {
      // Partial match with some correct elements
      grade = 'C';
      feedback = 'Your answer contains some correct elements, but needs improvement. The correct answer is: "${answer.correctAnswer}".';
      suggestions = [
        'Review the core concepts of this topic',
        'Try to be more specific and complete in your answer',
        'Focus on understanding the key terminology'
      ];
    } else {
      // Incorrect answer
      grade = 'F';
      feedback = 'Your answer doesn\'t match the expected response. The correct answer is: "${answer.correctAnswer}".';
      suggestions = [
        'Review the material related to this topic',
        'Consider creating additional flashcards on this subject',
        'Try to understand the reasoning behind the correct answer'
      ];
    }

    debugPrint('Assigning grade: $grade');
    
    return answer_model.Answer(
      flashcardId: answer.flashcardId,
      question: answer.question,
      userAnswer: answer.userAnswer,
      correctAnswer: answer.correctAnswer,
      grade: grade,
      feedback: feedback,
      suggestions: suggestions,
    );
  }
  
  // A similarity calculation based on character matching and word overlap
  double _calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    // If one string contains the other, they are more similar
    if (str1.contains(str2) || str2.contains(str1)) {
      return 0.7; // Base similarity for containment
    }
    
    // Split into words and check word overlap
    final List<String> words1 = str1.split(' ').where((word) => word.isNotEmpty).toList();
    final List<String> words2 = str2.split(' ').where((word) => word.isNotEmpty).toList();
    
    // Count matching words
    int matchingWords = 0;
    for (final word1 in words1) {
      if (words2.contains(word1)) matchingWords++;
    }
    
    // Calculate word similarity
    double wordSimilarity = 0.0;
    if (words1.isNotEmpty && words2.isNotEmpty) {
      wordSimilarity = (matchingWords / ((words1.length + words2.length) / 2));
    }
    
    // Character-level similarity
    int matchingChars = 0;
    int minLength = str1.length < str2.length ? str1.length : str2.length;
    for (int i = 0; i < minLength; i++) {
      if (str1[i] == str2[i]) matchingChars++;
    }
    
    double charSimilarity = matchingChars / ((str1.length + str2.length) / 2);
    
    // Combined similarity (weighted more toward word matching)
    return (wordSimilarity * 0.7) + (charSimilarity * 0.3);
  }
  
  // Check if the user's answer contains the key elements from the correct answer
  bool _containsKeyElements(String userAnswer, String correctAnswer) {
    // Extract key elements (words longer than 3 chars, which are likely meaningful)
    final List<String> correctKeywords = correctAnswer
        .split(' ')
        .where((word) => word.length > 3)
        .toList();
    
    // If there are no key elements, this check isn't meaningful
    if (correctKeywords.isEmpty) return false;
    
    // Count how many key elements are in the user's answer
    int matchCount = 0;
    for (final keyword in correctKeywords) {
      if (userAnswer.contains(keyword)) matchCount++;
    }
    
    // Return true if at least 30% of key elements are present
    return matchCount / correctKeywords.length >= 0.3;
  }
}
