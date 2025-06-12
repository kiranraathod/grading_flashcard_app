import 'interview_question.dart';
import 'interview_answer.dart';

class InterviewPracticeBatch {
  final String batchId;
  final List<InterviewQuestion> questions;
  final Map<String, InterviewAnswer> answers; // Maps question ID to answer
  
  InterviewPracticeBatch({
    required this.batchId,
    required this.questions,
    Map<String, InterviewAnswer>? answers,
  }) : answers = answers ?? {};
  
  // Check if all questions have been answered
  bool get isComplete => questions.every((q) => answers.containsKey(q.id));
  
  // Get number of answered questions
  int get answeredCount => answers.length;
  
  // Add or update an answer
  void addAnswer(InterviewAnswer answer) {
    answers[answer.questionId] = answer;
  }
  
  // Get a list of all answers in the same order as questions
  List<InterviewAnswer> getOrderedAnswers() {
    return questions.map((question) {
      if (answers.containsKey(question.id)) {
        return answers[question.id]!;
      } else {
        // Create a placeholder for unanswered questions
        return InterviewAnswer(
          questionId: question.id,
          questionText: question.text,
          userAnswer: "",
          category: question.category,
          difficulty: question.difficulty,
        );
      }
    }).toList();
  }
  
  // Calculate average score for all graded answers
  double get averageScore {
    final gradedAnswers = answers.values.where((a) => a.score != null);
    if (gradedAnswers.isEmpty) return 0;
    
    final totalScore = gradedAnswers.fold(0, (sum, answer) => sum + (answer.score ?? 0));
    return totalScore / gradedAnswers.length;
  }
  
  // Count how many questions have passing scores (>=70)
  int get completedCount {
    return answers.values.where((a) => a.score != null && a.score! >= 70).length;
  }
}