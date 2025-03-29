import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/answer.dart' as answer_model;
import '../utils/constants.dart';
import '../web/proxy.dart';
import '../services/local_auth_service.dart';
import '../screens/auth/auth_wrapper.dart';

class ApiService {
  final ProxyClient client;
  final LocalAuthService _authService = LocalAuthService();

  // Constructor
  ApiService() : client = ProxyClient(Constants.apiBaseUrl) {
    debugPrint(
      'API Service initialized with server connection: ${Constants.apiBaseUrl}',
    );
  }

  // We'll remove the unused method

  // Simple grading based on exact match
  answer_model.Answer _performLocalGrading(answer_model.Answer answer) {
    final userAnswer = answer.userAnswer.trim().toLowerCase();
    final correctAnswer = answer.question.toLowerCase();
    String grade, feedback;
    List<String> suggestions;

    if (userAnswer == correctAnswer) {
      grade = "A";
      feedback = "Perfect! Your answer is correct.";
      suggestions = ["Well done!"];
    } else if (correctAnswer.contains(userAnswer) ||
        userAnswer.contains(correctAnswer)) {
      grade = "B";
      feedback = "Close! Your answer is partially correct.";
      suggestions = ["Try to be more specific"];
    } else {
      grade = "C";
      feedback = "Your answer needs improvement.";
      suggestions = ["Review the material and try again"];
    }

    return answer_model.Answer(
      flashcardId: answer.flashcardId,
      question: answer.question,
      userAnswer: answer.userAnswer,
      grade: grade,
      feedback: feedback,
      suggestions: suggestions,
    );
  }

  Future<answer_model.Answer> gradeAnswer(
    answer_model.Answer answer, {
    BuildContext? context,
  }) async {
    debugPrint('Grading answer: ${answer.question} => ${answer.userAnswer}');

    // Always try to use the LLM grading for all users - no auth check
    debugPrint('Attempting to use LLM grading for all users');

    try {
      debugPrint('Making API request to ${Constants.apiBaseUrl}/api/grade');
      final requestBody = {
        'flashcardId': answer.flashcardId,
        'question': answer.question,
        'userAnswer': answer.userAnswer,
      };

      debugPrint('Sending API request: ${jsonEncode(requestBody)}');

      final response = await client
          .post('/api/grade', body: requestBody)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('API request timed out');
              throw TimeoutException('Server took too long to respond');
            },
          );

      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response headers: ${response.headers}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Authentication error: ${response.body}');

        // Authentication token might be expired - show login dialog if context provided
        if (context != null) {
          // Show a snackbar first
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please log in again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );

          // Then show login dialog
          showLoginScreen(context);
        }

        // Fall back to local grading
        return _performLocalGrading(answer);
      } else if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          debugPrint('API response data: $responseData');

          // Validate response data
          if (_validateResponseData(responseData)) {
            // Ensure suggestions is a list of strings
            List<String> suggestions;
            if (responseData['suggestions'] is List) {
              suggestions =
                  (responseData['suggestions'] as List)
                      .map(
                        (item) => item?.toString() ?? 'No suggestion provided',
                      )
                      .toList();
            } else {
              suggestions = ['No suggestions available'];
            }

            return answer_model.Answer(
              flashcardId: answer.flashcardId,
              question: answer.question,
              userAnswer: answer.userAnswer,
              grade: responseData['grade'],
              feedback: responseData['feedback'],
              suggestions: suggestions,
            );
          } else {
            debugPrint('Invalid response data format');
            return _createNotConnectedAnswer(answer);
          }
        } catch (e) {
          debugPrint('Error parsing API response: $e');
          debugPrint('Raw response body: ${response.body}');
          return _createNotConnectedAnswer(answer);
        }
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return _createNotConnectedAnswer(answer);
      }
    } catch (e) {
      debugPrint('Error during API call: $e');
      return _createNotConnectedAnswer(answer);
    }
  }

  bool _validateResponseData(Map<String, dynamic> data) {
    // Check that all required fields exist and have correct types
    if (!data.containsKey('grade') ||
        !data.containsKey('feedback') ||
        !data.containsKey('suggestions')) {
      debugPrint('Missing required fields in response data');
      return false;
    }

    // Validate grade is a non-empty string that starts with a valid letter grade
    final validGradeStarts = ['A', 'B', 'C', 'D', 'F'];
    final grade = data['grade'] as String;
    if (grade.isEmpty ||
        !validGradeStarts.any((valid) => grade.startsWith(valid))) {
      debugPrint('Invalid grade format: ${data['grade']}');
      return false;
    }

    // Validate feedback is a non-empty string
    if (data['feedback'] == null || (data['feedback'] as String).isEmpty) {
      debugPrint('Missing or empty feedback');
      return false;
    }

    // Validate suggestions is a list
    if (data['suggestions'] == null || data['suggestions'] is! List) {
      debugPrint('Missing or invalid suggestions format');
      return false;
    }

    // If we got here, all validations passed
    return true;
  }

  answer_model.Answer _createNotConnectedAnswer(answer_model.Answer answer) {
    // Check if it's an authentication issue
    if (!_authService.isAuthenticated) {
      return answer_model.Answer(
        flashcardId: answer.flashcardId,
        question: answer.question,
        userAnswer: answer.userAnswer,
        grade: 'N/A',
        feedback: 'Authentication required to grade flashcards',
        suggestions: [
          'Please log in to use the grading feature',
          'Your answer will be saved after login',
        ],
      );
    } else {
      // General connection issue
      return answer_model.Answer(
        flashcardId: answer.flashcardId,
        question: answer.question,
        userAnswer: answer.userAnswer,
        grade: 'N/A',
        feedback: 'Grading system is not connected',
        suggestions: [
          'Please check your internet connection',
          'Ensure the grading server is running',
          'Try again later',
        ],
      );
    }
  }
}
