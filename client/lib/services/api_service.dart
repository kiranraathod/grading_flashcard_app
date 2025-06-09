import 'dart:async';
import 'dart:convert';
import '../models/answer.dart' as answer_model;
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../utils/config.dart';
import '../web/proxy.dart';
import 'simple_error_handler.dart';

class ApiService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();
  final bool _useLocalGrading = false; // Ensure this is set to false to use the API

  // Constructor
  ApiService() : client = ProxyClient(AppConfig.apiBaseUrl) {
    AppConfig.logNetwork(
      'API Service initialized with server connection: ${AppConfig.apiBaseUrl}',
      level: NetworkLogLevel.basic
    );
  }

  Future<answer_model.Answer> gradeAnswer(answer_model.Answer answer) async {
    AppConfig.logNetwork(
      'Grading answer: ${answer.question} => ${answer.userAnswer}',
      level: NetworkLogLevel.verbose
    );
    
    // Use local grading if requested (for offline mode or debugging)
    if (_useLocalGrading) {
      AppConfig.logNetwork(
        'Using local grading - skipping API call',
        level: NetworkLogLevel.basic
      );
      return _createSmartFallbackAnswer(answer);
    }

    return await SimpleErrorHandler.safe<answer_model.Answer>(
      () async {
        final gradeEndpoint = AppConfig.endpoints['grade'] ?? '/api/grade';
        
        AppConfig.logNetwork(
          'Making API request to $gradeEndpoint',
          level: NetworkLogLevel.basic
        );
        
        final response = await client.post(
          gradeEndpoint,
          body: {
            'flashcardId': answer.flashcardId,
            'question': answer.question,
            'userAnswer': answer.userAnswer,
            'correctAnswer': answer.correctAnswer,
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          
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
            final error = AppError.api(
              'Invalid response format from server',
              code: 'invalid_response',
              severity: ErrorSeverity.warning,
              context: {
                'endpoint': gradeEndpoint,
                'responseData': responseData,
              },
            );
            _errorService.reportError(error);
            return _createSmartFallbackAnswer(answer);
          }
        } else {
          final error = AppError.api(
            'Server returned an error',
            code: 'server_error',
            severity: ErrorSeverity.warning,
            details: 'Status code: ${response.statusCode}',
            context: {
              'endpoint': gradeEndpoint,
              'statusCode': response.statusCode,
              'responseBody': response.body,
            },
          );
          _errorService.reportError(error);
          return _createSmartFallbackAnswer(answer);
        }
      },
      fallback: _createSmartFallbackAnswer(answer),
      operationName: 'grade_answer_api',
    );
  }

  bool _validateResponseData(Map<String, dynamic> data) {
    // Check that all required fields exist and have correct types
    if (!data.containsKey('grade') ||
        !data.containsKey('feedback') ||
        !data.containsKey('suggestions')) {
      AppConfig.logNetwork(
        'Missing required fields in response data',
        level: NetworkLogLevel.errors
      );
      return false;
    }

    // Validate grade is a valid letter grade
    final validGrades = ['A', 'B', 'C', 'D', 'F', 'X'];  // Added 'X' for system errors
    if (!validGrades.contains(data['grade'])) {
      AppConfig.logNetwork(
        'Invalid grade in response: ${data["grade"]}',
        level: NetworkLogLevel.errors
      );
      return false;
    }

    // Validate feedback is a non-empty string
    if (data['feedback'] == null || (data['feedback'] as String).isEmpty) {
      AppConfig.logNetwork(
        'Missing or empty feedback in response',
        level: NetworkLogLevel.errors
      );
      return false;
    }

    // Validate suggestions is a list
    if (data['suggestions'] == null || data['suggestions'] is! List) {
      AppConfig.logNetwork(
        'Missing or invalid suggestions in response',
        level: NetworkLogLevel.errors
      );
      return false;
    }

    // Make sure suggestions list is not empty
    if ((data['suggestions'] as List).isEmpty) {
      AppConfig.logNetwork(
        'Empty suggestions list in response',
        level: NetworkLogLevel.errors
      );
      return false;
    }

    AppConfig.logNetwork(
      'Response data validation passed',
      level: NetworkLogLevel.verbose
    );
    return true;
  }

  answer_model.Answer _createSmartFallbackAnswer(answer_model.Answer answer) {
    // Extract and normalize answers for comparison
    final String userAnswer = answer.userAnswer.toLowerCase().trim();
    final String correctAnswer = answer.correctAnswer.toLowerCase().trim();

    AppConfig.logNetwork(
      'Smart fallback grading: comparing user answer with correct answer',
      level: NetworkLogLevel.basic
    );

    // Different levels of matching for more nuanced grading
    final bool isExactMatch = userAnswer == correctAnswer;
    final bool isStrongMatch = _calculateSimilarity(userAnswer, correctAnswer) > AppConfig.strongMatchThreshold;
    final bool isPartialMatch = _calculateSimilarity(userAnswer, correctAnswer) > AppConfig.partialMatchThreshold;
    final bool hasKeyElements = _containsKeyElements(userAnswer, correctAnswer);

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
  
  // A similarity calculation based on character matching and Levenshtein distance
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
    
    // Return true if at least the threshold percentage of key elements are present
    return matchCount / correctKeywords.length >= AppConfig.keyElementsMatchThreshold;
  }
}