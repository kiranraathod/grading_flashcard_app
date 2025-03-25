import 'dart:convert';
import '../models/answer.dart' as answer_model;
import '../utils/constants.dart';
import '../web/proxy.dart';

class ApiService {
  final ProxyClient client = ProxyClient(Constants.apiBaseUrl);

  Future<answer_model.Answer> gradeAnswer(answer_model.Answer answer) async {
    try {
      final response = await client.post(
        '/api/grade',
        body: {
          'flashcardId': answer.flashcardId,
          'question': answer.question,
          'userAnswer': answer.userAnswer,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return answer_model.Answer(
          flashcardId: answer.flashcardId,
          question: answer.question,
          userAnswer: answer.userAnswer,
          grade: responseData['grade'],
          feedback: responseData['feedback'],
          suggestions: List<String>.from(responseData['suggestions']),
        );
      } else {
        throw Exception('Failed to grade answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error grading answer: $e');
    }
  }
}
