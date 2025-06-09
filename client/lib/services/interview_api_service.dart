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

  // Method to grade multiple interview answers in a batch
  Future<List<InterviewAnswer>> gradeBatchAnswers(List<InterviewAnswer> answers) async {
    AppConfig.logNetwork(
      'Grading batch of ${answers.length} interview answers',
      level: NetworkLogLevel.basic
    );
    
    // Filter out empty answers
    final nonEmptyAnswers = answers.where((a) => a.userAnswer.trim().isNotEmpty).toList();
    
    if (nonEmptyAnswers.isEmpty) {
      AppConfig.logNetwork(
        'No non-empty answers to grade',
        level: NetworkLogLevel.basic
      );
      return answers; // Return original answers without grading
    }

    return await SimpleErrorHandler.safe<List<InterviewAnswer>>(
      () async {
        final batchEndpoint = AppConfig.endpoints['interviewGradeBatch'] ?? '/api/interview-grade-batch';
        
        AppConfig.logNetwork(
          'Making batch API request to $batchEndpoint',
          level: NetworkLogLevel.basic
        );
        
        // Prepare batch request body
        final List<Map<String, dynamic>> requestItems = nonEmptyAnswers.map((answer) => {
          'questionId': answer.questionId,
          'questionText': answer.questionText,
          'userAnswer': answer.userAnswer,
          'category': answer.category,
          'difficulty': answer.difficulty,
        }).toList();
        
        final response = await client.post(
          batchEndpoint,
          body: {'answers': requestItems},
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = jsonDecode(response.body);
          AppConfig.logNetwork(
            'Received responses for ${responseData.length} answers',
            level: NetworkLogLevel.verbose
          );

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
          AppConfig.logNetwork(
            'API batch error: ${response.statusCode} - ${response.body}',
            level: NetworkLogLevel.errors
          );
          throw AppError.api(
            'Server returned an error for batch grading',
            code: 'server_error',
            severity: ErrorSeverity.warning,
            details: 'Status code: ${response.statusCode}',
          );
        }
      },
      fallback: answers, // Return original answers as fallback
      operationName: 'grade_batch_answers',
    );
  }

  // Helper method to validate response data
  bool validateResponseData(Map<String, dynamic> data) {
    // Check that all required fields exist and have correct types
    if (!data.containsKey('score') ||
        !data.containsKey('feedback') ||
        !data.containsKey('suggestions')) {
      AppConfig.logNetwork(
        'Missing required fields in response data',
        level: NetworkLogLevel.errors
      );
      return false;
    }

    // Validate score is a number between 0 and 100
    final score = data['score'];
    if (score is! num || score < 0 || score > 100) {
      AppConfig.logNetwork(
        'Invalid score in response: $score',
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