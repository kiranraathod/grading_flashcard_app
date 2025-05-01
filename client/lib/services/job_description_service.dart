import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/job_description_analysis.dart';
import '../models/interview_question.dart';
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../utils/constants.dart';
import '../utils/config.dart';
import '../web/proxy.dart';

class JobDescriptionService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();

  // Constructor
  JobDescriptionService() : client = ProxyClient(Constants.apiBaseUrl) {
    debugPrint(
      'Job Description Service initialized with server connection: ${Constants.apiBaseUrl}',
    );
  }
  
  // Analyze a job description
  Future<JobDescriptionAnalysis> analyzeJobDescription(String jobDescription) async {
    debugPrint('Analyzing job description...');
    
    try {
      final response = await client
          .post(
            '/api/job-description/analyze',
            body: {'job_description': jobDescription},
          )
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              throw AppError.api(
                'The server took too long to respond',
                code: 'api_timeout',
                severity: ErrorSeverity.warning,
              );
            },
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
    } catch (e, stackTrace) {
      if (e is AppError) {
        _errorService.reportError(e);
        rethrow;
      }
      
      // Check for network connectivity issues
      if (e.toString().contains('Failed to fetch') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        final error = AppError.api(
          'Network is not connected',
          code: 'network_error',
          severity: ErrorSeverity.warning,
          context: {'operation': 'analyzeJobDescription'},
        );
        _errorService.reportError(error);
        throw error;
      }
      
      final error = AppError.unknown(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'analyzeJobDescription'},
      );
      _errorService.reportError(error);
      throw error;
    }
  }
  
  // Generate interview questions based on job analysis
  Future<List<InterviewQuestion>> generateQuestions({
    required JobDescriptionAnalysis jobAnalysis,
    required List<String> categories,
    required List<String> difficultyLevels,
    int countPerCategory = 3,
  }) async {
    debugPrint('Generating interview questions...');
    
    try {
      final response = await client
          .post(
            '/api/job-description/generate-questions',
            body: {
              'job_analysis': jobAnalysis.toJson(),
              'categories': categories,
              'difficulty_levels': difficultyLevels,
              'count_per_category': countPerCategory,
            },
          )
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              throw AppError.api(
                'The server took too long to respond',
                code: 'api_timeout',
                severity: ErrorSeverity.warning,
              );
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
          final index = responseData.indexOf(questionData);
          return InterviewQuestion(
            id: "${DateTime.now().millisecondsSinceEpoch}_$index",
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
    } catch (e, stackTrace) {
      if (e is AppError) {
        _errorService.reportError(e);
        rethrow;
      }
      
      final error = AppError.unknown(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'generateQuestions'},
      );
      _errorService.reportError(error);
      throw error;
    }
  }
}