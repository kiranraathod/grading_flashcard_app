import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/interview_answer.dart';
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../utils/constants.dart';
import '../utils/config.dart';
import '../web/proxy.dart';

class InterviewApiService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();

  // Constructor
  InterviewApiService() : client = ProxyClient(Constants.apiBaseUrl) {
    debugPrint(
      'Interview API Service initialized with server connection: ${Constants.apiBaseUrl}',
    );
  }

  // Method for grading a single interview answer
  Future<InterviewAnswer> gradeInterviewAnswer(InterviewAnswer answer) async {
    debugPrint('Grading interview answer: ${answer.questionText} => ${answer.userAnswer}');
    debugPrint('Category: ${answer.category}, Difficulty: ${answer.difficulty}');

    try {
      debugPrint('Making API request to ${Constants.apiBaseUrl}/api/interview-grade');
      final response = await client
          .post(
            '/api/interview-grade',
            body: {
              'questionId': answer.questionId,
              'questionText': answer.questionText,
              'userAnswer': answer.userAnswer,
              'category': answer.category,
              'difficulty': answer.difficulty,
            },
          )
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              debugPrint('API request timed out');
              final error = AppError.api(
                'The server took too long to respond',
                code: 'api_timeout',
                severity: ErrorSeverity.warning,
                context: {
                  'endpoint': '/api/interview-grade',
                  'timeout': AppConfig.apiTimeout.inSeconds,
                },
              );
              _errorService.reportError(error);
              throw error;
            },
          );

      debugPrint('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('API response data: $responseData');

        // Validate response data
        if (validateResponseData(responseData)) {
          return InterviewAnswer(
            questionId: answer.questionId,
            questionText: answer.questionText,
            userAnswer: answer.userAnswer,
            category: answer.category,
            difficulty: answer.difficulty,
            score: responseData['score'],
            feedback: responseData['feedback'],
            suggestions: List<String>.from(responseData['suggestions']),
          );
        } else {
          debugPrint('Invalid response data format, using fallback');
          final error = AppError.api(
            'Invalid response format from server',
            code: 'invalid_response',
            severity: ErrorSeverity.warning,
            context: {
              'endpoint': '/api/interview-grade',
              'responseData': responseData,
            },
          );
          _errorService.reportError(error);
          return createFallbackAnswer(answer);
        }
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        final error = AppError.api(
          'Server returned an error',
          code: 'server_error',
          severity: ErrorSeverity.warning,
          details: 'Status code: ${response.statusCode}',
          context: {
            'endpoint': '/api/interview-grade',
            'statusCode': response.statusCode,
            'responseBody': response.body,
          },
        );
        _errorService.reportError(error);
        return createFallbackAnswer(answer);
      }
    } catch (e, stackTrace) {
      debugPrint('Error during API call: $e');
      
      // If we already have a structured error, just propagate it
      if (e is AppError) {
        return createFallbackAnswer(answer);
      }
      
      // Otherwise, create a new error
      final error = AppError.unknown(
        e,
        stackTrace: stackTrace,
        context: {
          'endpoint': '/api/interview-grade',
          'questionId': answer.questionId,
          'questionText': answer.questionText,
        },
      );
      _errorService.reportError(error);
      return createFallbackAnswer(answer);
    }
  }

  // Method to grade multiple interview answers in a batch
  Future<List<InterviewAnswer>> gradeBatchAnswers(List<InterviewAnswer> answers) async {
    debugPrint('Grading batch of ${answers.length} interview answers');
    
    // Filter out empty answers
    final nonEmptyAnswers = answers.where((a) => a.userAnswer.trim().isNotEmpty).toList();
    
    if (nonEmptyAnswers.isEmpty) {
      debugPrint('No non-empty answers to grade');
      return answers; // Return original answers without grading
    }

    try {
      debugPrint('Making batch API request to ${Constants.apiBaseUrl}/api/interview-grade-batch');
      
      // Prepare batch request body
      final List<Map<String, dynamic>> requestItems = nonEmptyAnswers.map((answer) => {
        'questionId': answer.questionId,
        'questionText': answer.questionText,
        'userAnswer': answer.userAnswer,
        'category': answer.category,
        'difficulty': answer.difficulty,
      }).toList();
      
      final response = await client
          .post(
            '/api/interview-grade-batch',
            body: {'answers': requestItems},
          )
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              debugPrint('API batch request timed out');
              final error = AppError.api(
                'The server took too long to respond',
                code: 'api_timeout',
                severity: ErrorSeverity.warning,
                context: {
                  'endpoint': '/api/interview-grade-batch',
                  'timeout': AppConfig.apiTimeout.inSeconds,
                },
              );
              _errorService.reportError(error);
              throw error;
            },
          );

      debugPrint('Batch API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        debugPrint('Received responses for ${responseData.length} answers');

        // Create a map of the original answers by questionId for easy lookup
        final Map<String, InterviewAnswer> answerMap = {
          for (var answer in answers) answer.questionId: answer
        };
        
        // Process the graded answers and update the original list
        for (int i = 0; i < responseData.length; i++) {
          final Map<String, dynamic> gradeData = responseData[i];
          final String questionId = gradeData['questionId'];
          
          if (answerMap.containsKey(questionId) && validateResponseData(gradeData)) {
            // Update the answer with grading results
            answerMap[questionId] = InterviewAnswer(
              questionId: questionId,
              questionText: answerMap[questionId]!.questionText,
              userAnswer: answerMap[questionId]!.userAnswer,
              category: answerMap[questionId]!.category,
              difficulty: answerMap[questionId]!.difficulty,
              score: gradeData['score'],
              feedback: gradeData['feedback'],
              suggestions: List<String>.from(gradeData['suggestions']),
            );
          }
        }
        
        // Return the updated list of answers (preserving the original order)
        return answers.map((original) {
          return answerMap[original.questionId] ?? original;
        }).toList();
      } else {
        debugPrint('API batch error: ${response.statusCode} - ${response.body}');
        throw AppError.api(
          'Server returned an error for batch grading',
          code: 'server_error',
          severity: ErrorSeverity.warning,
          details: 'Status code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error during batch API call: $e');
      throw AppError.unknown(
        e,
        stackTrace: stackTrace,
        context: {
          'endpoint': '/api/interview-grade-batch',
          'answerCount': nonEmptyAnswers.length,
        },
      );
    }
  }

  // Helper method to validate response data
  bool validateResponseData(Map<String, dynamic> data) {
    // Check that all required fields exist and have correct types
    if (!data.containsKey('score') ||
        !data.containsKey('feedback') ||
        !data.containsKey('suggestions')) {
      debugPrint('Missing required fields in response data');
      return false;
    }

    // Validate score is a number between 0 and 100
    final score = data['score'];
    if (score is! num || score < 0 || score > 100) {
      debugPrint('Invalid score in response: $score');
      return false;
    }

    // Validate feedback is a non-empty string
    if (data['feedback'] == null || (data['feedback'] as String).isEmpty) {
      debugPrint('Missing or empty feedback in response');
      return false;
    }

    // Validate suggestions is a list
    if (data['suggestions'] == null || data['suggestions'] is! List) {
      debugPrint('Missing or invalid suggestions in response');
      return false;
    }

    // Make sure suggestions list is not empty
    if ((data['suggestions'] as List).isEmpty) {
      debugPrint('Empty suggestions list in response');
      return false;
    }

    debugPrint('Response data validation passed');
    return true;
  }

  // Helper method to create a fallback answer
  InterviewAnswer createFallbackAnswer(InterviewAnswer answer) {
    // Create a fallback answer for when the API call fails
    return InterviewAnswer(
      questionId: answer.questionId,
      questionText: answer.questionText,
      userAnswer: answer.userAnswer,
      category: answer.category,
      difficulty: answer.difficulty,
      score: 50, // Middle score as fallback
      feedback: "We couldn't properly analyze your answer. Please try again later.",
      suggestions: [
        "Review the key concepts related to this topic",
        "Try to be more specific in your answer",
        "Structure your response more clearly"
      ],
    );
  }
}