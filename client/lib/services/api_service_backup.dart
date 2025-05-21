import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/answer.dart' as answer_model;
import '../utils/config.dart';
import '../web/proxy.dart';

class ApiService {
  final ProxyClient client;
  
  // Constructor
  ApiService() : client = ProxyClient(AppConfig.apiBaseUrl) {
    debugPrint('API Service initialized with server connection: ${AppConfig.apiBaseUrl}');
  }

  Future<answer_model.Answer> gradeAnswer(answer_model.Answer answer) async {
    debugPrint('Grading answer: ${answer.question} => ${answer.userAnswer}');
    debugPrint('Correct answer: ${answer.correctAnswer}');
    
    // This is a backup implementation that always returns a mock response
    debugPrint('BACKUP SERVICE: Using mock grading response');
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return a mock graded answer
    return answer_model.Answer(
      flashcardId: answer.flashcardId,
      question: answer.question,
      userAnswer: answer.userAnswer,
      correctAnswer: answer.correctAnswer,
      grade: 'B',
      feedback: 'BACKUP SERVICE: This is a mock response. Your answer shows good understanding, but could be more detailed.',
      suggestions: [
        'This is a backup service response.',
        'The main API service is unavailable.',
        'Your actual answer would normally be evaluated.',
      ],
    );
  }
}