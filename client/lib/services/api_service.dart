import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/answer.dart' as answer_model;
import '../utils/constants.dart';
import '../web/proxy.dart';
import 'package:http/http.dart' as http;

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
      final requestBody = {
        'flashcardId': answer.flashcardId,
        'question': answer.question,
        'userAnswer': answer.userAnswer,
      };
      
      debugPrint('Sending API request: ${jsonEncode(requestBody)}');
      
      // Increased timeout from 8 to 12 seconds to allow for LLM processing
      http.Response response;
      try {
        response = await client
            .post(
              '/api/grade',
              body: requestBody,
            )
            .timeout(
              const Duration(seconds: 12),
              onTimeout: () {
                debugPrint('API request timed out after 12 seconds');
                // Create a dummy response instead of throwing an exception
                return http.Response(
                  jsonEncode({
                    'grade': 'N/A',
                    'feedback': 'The grading service took too long to respond.',
                    'suggestions': [
                      'The server might be experiencing high load',
                      'Please try again in a few moments',
                      'Check if the server is running properly'
                    ]
                  }),
                  408, // Request Timeout status code
                  headers: {'content-type': 'application/json'},
                );
              },
            );
      } catch (e) {
        debugPrint('Error during API call: $e');
        return _createNotConnectedAnswer(answer);
      }

      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response headers: ${response.headers}');

      // Handle timeout response specifically
      if (response.statusCode == 408) {
        debugPrint('Handling timeout response');
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return answer_model.Answer(
            flashcardId: answer.flashcardId,
            question: answer.question,
            userAnswer: answer.userAnswer,
            grade: responseData['grade'] ?? 'N/A',
            feedback: responseData['feedback'] ?? 'The server took too long to respond.',
            suggestions: (responseData['suggestions'] as List?)
                    ?.map((item) => item?.toString() ?? '')
                    .toList() ??
                ['Please try again later'],
          );
        } catch (e) {
          debugPrint('Error parsing timeout response: $e');
          return _createNotConnectedAnswer(answer);
        }
      }

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          debugPrint('API response data: $responseData');

          // Accept 'N/A' grade for cases where the server returns a valid but non-graded response
          if (_validateResponseData(responseData, allowNA: true)) {
            // Ensure suggestions is a list of strings
            List<String> suggestions;
            if (responseData['suggestions'] is List) {
              suggestions = (responseData['suggestions'] as List)
                  .map((item) => item?.toString() ?? 'No suggestion provided')
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

  bool _validateResponseData(Map<String, dynamic> data, {bool allowNA = false}) {
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
    
    // Allow 'N/A' if specified
    if (allowNA && grade == 'N/A') {
      return true;
    }
    
    if (grade.isEmpty || !validGradeStarts.any((valid) => grade.startsWith(valid))) {
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
  
  // Test LLM connection to diagnose issues
  Future<Map<String, dynamic>> testLLMConnection() async {
    debugPrint('Testing LLM connection');

    try {
      final response = await client
          .get('/api/test-llm')
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('LLM test request timed out after 15 seconds');
              return http.Response(
                jsonEncode({
                  'status': 'timeout',
                  'message': 'The LLM test request timed out after 15 seconds',
                }),
                408,
                headers: {'content-type': 'application/json'},
              );
            },
          );

      debugPrint('LLM test response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          debugPrint('LLM test response: $responseData');
          return responseData;
        } catch (e) {
          debugPrint('Error parsing LLM test response: $e');
          return {
            'status': 'error',
            'message': 'Error parsing LLM test response',
            'error': e.toString(),
          };
        }
      } else {
        debugPrint('LLM test failed with status: ${response.statusCode}');
        return {
          'status': 'error',
          'message': 'LLM test failed with status: ${response.statusCode}',
          'response': response.body,
        };
      }
    } catch (e) {
      debugPrint('Error during LLM test: $e');
      return {
        'status': 'error',
        'message': 'Error during LLM test',
        'error': e.toString(),
      };
    }
  }
}
