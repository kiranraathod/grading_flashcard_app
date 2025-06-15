import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview_answer.dart';
import '../models/app_error.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_action_tracking_provider.dart';
import '../services/error_service.dart';
import '../services/simple_error_handler.dart';
import '../services/usage_limit_enforcer.dart';
import '../utils/config.dart';
import '../web/proxy.dart';

class InterviewApiService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();
  final WidgetRef? _ref; // Optional for backward compatibility

  // Constructor with optional Riverpod reference
  InterviewApiService({WidgetRef? ref})
    : client = ProxyClient(AppConfig.apiBaseUrl),
      _ref = ref {
    AppConfig.logNetwork(
      'Interview API Service initialized with server connection: ${AppConfig.apiBaseUrl}',
      level: NetworkLogLevel.basic,
    );
  }

  // Method for grading a single interview answer with authentication
  Future<InterviewAnswer> gradeInterviewAnswer(
    InterviewAnswer answer, {
    BuildContext? context,
  }) async {
    AppConfig.logNetwork(
      'Grading interview answer: ${answer.questionText} => ${answer.userAnswer}',
      level: NetworkLogLevel.verbose,
    );

    return await SimpleErrorHandler.safe<InterviewAnswer>(
      () async {
        // 🎯 NEW: Enhanced quota enforcement with automatic retry after authentication
        if (_ref != null && AuthConfig.enableUsageLimits) {
          final usageLimitEnforcer = _ref.read(usageLimitEnforcerProvider);

          // Check if user can perform action (handles authentication automatically)
          final canProceed = await usageLimitEnforcer.enforceLimit(
            ActionType.interviewPractice,
            context: context,
            source: 'InterviewApiService.gradeInterviewAnswer',
          );

          if (!canProceed) {
            debugPrint('🚫 Interview grading blocked - user cannot perform action');
            
            // Return appropriate fallback based on context availability
            if (context != null) {
              return _createAuthRequiredAnswer(answer);
            } else {
              return _createLimitReachedAnswer(answer);
            }
          }
          
          debugPrint('✅ Interview grading quota check passed - proceeding with API call');
        }

        final interviewGradeEndpoint =
            AppConfig.endpoints['interviewGrade'] ?? '/api/interview-grade';

        AppConfig.logNetwork(
          'Making API request to $interviewGradeEndpoint',
          level: NetworkLogLevel.basic,
        );

        final response = await client.post(
          interviewGradeEndpoint,
          body: {
            'questionId': answer.questionId,
            'questionText': answer.questionText,
            'userAnswer': answer.userAnswer,
            'category': answer.category,
            'difficulty': answer.difficulty,
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Validate response data
          if (responseData.containsKey('score') &&
              responseData.containsKey('feedback') &&
              responseData.containsKey('suggestions') &&
              responseData['score'] is num &&
              responseData['feedback'] is String &&
              responseData['suggestions'] is List) {
            // 🎯 NEW: Record successful action using centralized enforcer
            if (_ref != null && AuthConfig.enableUsageLimits) {
              final actionTracker = _ref.read(actionTrackerProvider.notifier);
              await actionTracker.recordAction(ActionType.interviewPractice);

              // Debug: Show updated usage
              final usageLimitEnforcer = _ref.read(usageLimitEnforcerProvider);
              final updatedSummary = usageLimitEnforcer.getUsageSummary();
              debugPrint('📊 Interview grading action recorded');
              debugPrint('📊 Updated total usage: ${updatedSummary['totalUsed']}/${updatedSummary['maxActions']}');
            }

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
            final error = AppError.api(
              'Invalid response format from server',
              code: 'invalid_response',
              severity: ErrorSeverity.warning,
              context: {
                'endpoint': interviewGradeEndpoint,
                'responseData': responseData,
              },
            );
            _errorService.reportError(error);
            return createFallbackAnswer(answer);
          }
        } else {
          final error = AppError.api(
            'Server returned an error',
            code: 'server_error',
            severity: ErrorSeverity.warning,
            details: 'Status code: ${response.statusCode}',
            context: {
              'endpoint': interviewGradeEndpoint,
              'statusCode': response.statusCode,
              'responseBody': response.body,
            },
          );
          _errorService.reportError(error);
          return createFallbackAnswer(answer);
        }
      },
      fallback: createFallbackAnswer(answer),
      operationName: 'grade_interview_answer',
    );
  }

  // Helper method to create a fallback answer
  InterviewAnswer createFallbackAnswer(InterviewAnswer answer) {
    AppConfig.logNetwork(
      'Creating fallback interview answer',
      level: NetworkLogLevel.basic,
    );

    return InterviewAnswer(
      questionId: answer.questionId,
      questionText: answer.questionText,
      userAnswer: answer.userAnswer,
      category: answer.category,
      difficulty: answer.difficulty,
      score: 50, // Middle score as fallback
      feedback:
          "We couldn't properly analyze your answer. Please try again later.",
      suggestions: [
        "Review the key concepts related to this topic",
        "Try to be more specific in your answer",
        "Structure your response more clearly",
      ],
    );
  }

  // Helper method for authentication required response
  InterviewAnswer _createAuthRequiredAnswer(InterviewAnswer answer) {
    AppConfig.logNetwork(
      'Creating authentication required answer',
      level: NetworkLogLevel.basic,
    );

    return InterviewAnswer(
      questionId: answer.questionId,
      questionText: answer.questionText,
      userAnswer: answer.userAnswer,
      category: answer.category,
      difficulty: answer.difficulty,
      score: null,
      feedback: "Please sign in to continue grading your interview answers.",
      suggestions: [
        "Create an account to get unlimited grading",
        "Sign in to save your progress",
        "Access premium features with an account",
      ],
    );
  }

  // Helper method for limit reached response
  InterviewAnswer _createLimitReachedAnswer(InterviewAnswer answer) {
    AppConfig.logNetwork(
      'Creating limit reached answer',
      level: NetworkLogLevel.basic,
    );

    return InterviewAnswer(
      questionId: answer.questionId,
      questionText: answer.questionText,
      userAnswer: answer.userAnswer,
      category: answer.category,
      difficulty: answer.difficulty,
      score: null,
      feedback:
          "You've reached your daily limit for interview practice. Sign in for unlimited access!",
      suggestions: [
        "Create an account for unlimited practice",
        "Sign in to continue practicing",
        "Upgrade to premium for advanced features",
      ],
    );
  }
}
