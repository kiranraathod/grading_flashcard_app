import 'dart:async';
import 'dart:convert';
import '../models/interview_answer.dart';
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../services/simple_error_handler.dart';
import '../utils/config.dart';
import '../web/proxy.dart';

class InterviewApiService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();

  // Constructor
  InterviewApiService() : client = ProxyClient(AppConfig.apiBaseUrl) {
    AppConfig.logNetwork(
      'Interview API Service initialized with server connection: ${AppConfig.apiBaseUrl}',
      level: NetworkLogLevel.basic
    );
  }

  // Method for grading a single interview answer
  Future<InterviewAnswer> gradeInterviewAnswer(InterviewAnswer answer) async {
    AppConfig.logNetwork(
      'Grading interview answer: ${answer.questionText} => ${answer.userAnswer}',
      level: NetworkLogLevel.verbose
    );
    
    return await SimpleErrorHandler.safe<InterviewAnswer>(
      () async {
        final interviewGradeEndpoint = AppConfig.endpoints['interviewGrade'] ?? '/api/interview-grade';
        
        AppConfig.logNetwork(
          'Making API request to $interviewGradeEndpoint',
          level: NetworkLogLevel.basic
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
          
          // Validate response data - simple inline validation
          if (responseData.containsKey('score') && 
              responseData.containsKey('feedback') && 
              responseData.containsKey('suggestions') &&
              responseData['score'] is num &&
              responseData['feedback'] is String &&
              responseData['suggestions'] is List) {
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
    // Create a fallback answer for when the API call fails
    AppConfig.logNetwork(
      'Creating fallback interview answer',
      level: NetworkLogLevel.basic
    );
    
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