import 'dart:async';
import 'dart:convert';
import '../models/job_description_analysis.dart';
import '../models/interview_question.dart';
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../services/id_service.dart';
import '../utils/config.dart';
import '../web/proxy.dart';
import 'simple_error_handler.dart';

class JobDescriptionService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();

  // Constructor
  JobDescriptionService() : client = ProxyClient(AppConfig.apiBaseUrl) {
    AppConfig.logNetwork(
      'Job Description Service initialized with server connection: ${AppConfig.apiBaseUrl}',
      level: NetworkLogLevel.basic
    );
  }
  
  // Analyze a job description
  Future<JobDescriptionAnalysis> analyzeJobDescription(String jobDescription) async {
    AppConfig.logNetwork(
      'Analyzing job description...',
      level: NetworkLogLevel.basic
    );
    
    return await SimpleErrorHandler.safe<JobDescriptionAnalysis>(
      () async {
        final analyzeEndpoint = AppConfig.endpoints['jobDescriptionAnalyze'] ?? '/api/job-description/analyze';
        
        final response = await client.post(
          analyzeEndpoint,
          body: {'job_description': jobDescription},
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return JobDescriptionAnalysis.fromJson(responseData);
        } else {
          throw AppError.api(
            'Error analyzing job description: ${response.body}',
            code: 'server_error',
            severity: ErrorSeverity.warning,
            details: 'Status code: ${response.statusCode}',
          );
        }
      },
      fallbackOperation: () async {
        // Handle different error types and report them
        final error = AppError.api(
          'Failed to analyze job description',
          code: 'analysis_error',
          severity: ErrorSeverity.warning,
          context: {'operation': 'analyzeJobDescription'},
        );
        _errorService.reportError(error);
        throw error;
      },
      operationName: 'analyze_job_description',
    );
  }
  
  // Generate interview questions based on job analysis
  Future<List<InterviewQuestion>> generateQuestions({
    required JobDescriptionAnalysis jobAnalysis,
    required List<String> categories,
    required List<String> difficultyLevels,
    int countPerCategory = 3,
  }) async {
    AppConfig.logNetwork(
      'Generating interview questions...',
      level: NetworkLogLevel.basic
    );
    
    return await SimpleErrorHandler.safe<List<InterviewQuestion>>(
      () async {
        final generateEndpoint = AppConfig.endpoints['jobDescriptionGenerate'] ?? '/api/job-description/generate-questions';
        
        final response = await client.post(
          generateEndpoint,
          body: {
            'job_analysis': jobAnalysis.toJson(),
            'categories': categories,
            'difficulty_levels': difficultyLevels,
            'count_per_category': countPerCategory,
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> responseData = jsonDecode(response.body);
          
          // Check if we got fallback questions
          bool containsFallback = responseData.any((q) => 
              q['text'] != null && 
              q['text'].toString().contains('FALLBACK QUESTION'));
              
          if (containsFallback) {
            throw AppError.api(
              'Error generating questions. Server returned fallback content.',
              code: 'generation_error',
              severity: ErrorSeverity.warning,
            );
          }
          
          // Convert to InterviewQuestion objects
          return responseData.map((questionData) {
            return InterviewQuestion(
              id: IdService.custom('job_'),
              text: questionData['text'],
              category: questionData['category'],
              subtopic: questionData['subtopic'],
              difficulty: questionData['difficulty'],
              answer: questionData['answer'],
              isDraft: true, // Mark as draft by default
            );
          }).toList();
        } else {
          throw AppError.api(
            'Error generating questions: ${response.body}',
            code: 'server_error',
            severity: ErrorSeverity.warning,
            details: 'Status code: ${response.statusCode}',
          );
        }
      },
      fallbackOperation: () async {
        final error = AppError.api(
          'Failed to generate interview questions',
          code: 'generation_error',
          severity: ErrorSeverity.warning,
          context: {'operation': 'generateQuestions'},
        );
        _errorService.reportError(error);
        throw error;
      },
      operationName: 'generate_interview_questions',
    );
  }
}