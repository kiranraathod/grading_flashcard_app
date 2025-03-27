import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/answer.dart' as answer_model;
import '../utils/constants.dart';
import '../web/proxy.dart';

class ApiService {
  final ProxyClient client;

  // Constructor
  ApiService() : client = ProxyClient(Constants.apiBaseUrl) {
    debugPrint(
      'API Service initialized with server connection: ${Constants.apiBaseUrl}',
    );
  }

  Future<answer_model.Answer> gradeAnswer(answer_model.Answer answer) async {
    debugPrint('Grading answer: ${answer.question} => ${answer.userAnswer}');

    try {
      debugPrint('Making API request to ${Constants.apiBaseUrl}/api/grade');
      final response = await client
          .post(
            '/api/grade',
            body: {
              'flashcardId': answer.flashcardId,
              'question': answer.question,
              'userAnswer': answer.userAnswer,
            },
          )
          .timeout(
            const Duration(seconds: 15),
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
            grade: responseData['grade'],
            feedback: responseData['feedback'],
            suggestions: List<String>.from(responseData['suggestions']),
          );
        } else {
          debugPrint('Invalid response data format');
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
      return false;
    }

    // Validate grade is a valid letter grade
    final validGrades = ['A', 'B', 'C', 'D', 'F'];
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

  answer_model.Answer _createNotConnectedAnswer(answer_model.Answer answer) {
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
