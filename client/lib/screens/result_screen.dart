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
    switch (answer.grade) {
      case 'A':
        return AppTheme.gradeA;
      case 'B':
        return AppTheme.gradeB;
      case 'C':
        return AppTheme.gradeC;
      case 'D':
        return AppTheme.gradeD;
      case 'F':
        return AppTheme.gradeF;
      case 'X': // System error indicator
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSystemError = answer.grade == 'X';
    
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
                    if (!isSystemError) ...[
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
                            isSystemError ? "!" : (answer.grade ?? '?'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isSystemError ? 'System Error' : 'Your Grade',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSystemError ? 'Error Message:' : 'Feedback:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answer.feedback ?? 'No feedback available',
                      style: TextStyle(
                        color: isSystemError ? Colors.red[700] : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (answer.suggestions != null)
              SuggestionsWidget(
                suggestions: answer.suggestions!,
                title: isSystemError ? 'Troubleshooting Steps' : 'Improvement Suggestions',
              ),
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
                child: Text(isSystemError ? 'Try Again Later' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
