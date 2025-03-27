import 'package:flutter/material.dart';
import '../models/answer.dart' as answer_model;
import '../widgets/suggestions_widget.dart';
import '../utils/theme.dart';

class ResultScreen extends StatelessWidget {
  final answer_model.Answer answer;
  final String correctAnswer;
  final VoidCallback onContinue;

  const ResultScreen({
    super.key,
    required this.answer,
    required this.correctAnswer,
    required this.onContinue,
  });

  Color _getGradeColor() {
    final grade = answer.grade ?? '';
    
    if (grade.startsWith('A')) {
      return AppTheme.gradeA;
    } else if (grade.startsWith('B')) {
      return AppTheme.gradeB;
    } else if (grade.startsWith('C')) {
      return AppTheme.gradeC;
    } else if (grade.startsWith('D')) {
      return AppTheme.gradeD;
    } else if (grade.startsWith('F')) {
      return AppTheme.gradeF;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(answer.question),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(answer.userAnswer),
                    const SizedBox(height: 16),
                    const Text(
                      'Correct Answer:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(correctAnswer),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: _getGradeColor().withAlpha(50),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getGradeColor(),
                          child: Text(
                            // Truncate long grade strings to prevent overflow
                            (answer.grade?.length ?? 0) > 3 
                                ? answer.grade!.substring(0, 2) 
                                : (answer.grade ?? '?'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Your Grade',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Feedback:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(answer.feedback ?? 'No feedback available'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (answer.suggestions != null)
              SuggestionsWidget(suggestions: answer.suggestions!),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
