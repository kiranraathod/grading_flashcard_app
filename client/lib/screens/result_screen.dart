import 'package:flutter/material.dart';
import '../models/answer.dart' as answer_model;
import '../widgets/suggestions_widget.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';

class ResultScreen extends StatefulWidget {
  final answer_model.Answer answer;
  final String correctAnswer;
  final VoidCallback onContinue;

  const ResultScreen({
    super.key,
    required this.answer,
    required this.correctAnswer,
    required this.onContinue,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Add a flag to prevent multiple clicks
  bool _continuePressed = false;

  Color _getGradeColor() {
    switch (widget.answer.grade) {
      case 'A':
        return AppColors.gradeA;
      case 'B':
        return AppColors.gradeB;
      case 'C':
        return AppColors.gradeC;
      case 'D':
        return AppColors.gradeD;
      case 'F':
        return AppColors.gradeF;
      case 'X': // System error indicator
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSystemError = widget.answer.grade == 'X';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DS.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(DS.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question:',
                      style: DS.headingSmall,
                    ),
                    SizedBox(height: DS.spacingXs),
                    Text(widget.answer.question, style: DS.bodyMedium),
                    SizedBox(height: DS.spacingM),
                    Text(
                      'Your Answer:',
                      style: DS.headingSmall,
                    ),
                    SizedBox(height: DS.spacingXs),
                    Text(widget.answer.userAnswer, style: DS.bodyMedium),
                    if (!isSystemError) ...[
                      SizedBox(height: DS.spacingM),
                      Text(
                        'Correct Answer:',
                        style: DS.headingSmall,
                      ),
                      SizedBox(height: DS.spacingXs),
                      Text(widget.correctAnswer, style: DS.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: DS.spacingM),
            Card(
              // Using RGBA values with fromRGBO instead of withOpacity
              color: Color.fromRGBO(
                _getGradeColor().red,
                _getGradeColor().green,
                _getGradeColor().blue,
                0.2,
              ),
              child: Padding(
                padding: EdgeInsets.all(DS.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _getGradeColor(),
                          child: Text(
                            isSystemError ? "!" : (widget.answer.grade ?? '?'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: DS.spacingM),
                        Text(
                          isSystemError ? 'System Error' : 'Your Grade',
                          style: DS.headingSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: DS.spacingM),
                    Text(
                      isSystemError ? 'Error Message:' : 'Feedback:',
                      style: DS.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: DS.spacingXs),
                    Text(
                      widget.answer.feedback ?? 'No feedback available',
                      style: TextStyle(
                        color: isSystemError ? Colors.red[700] : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: DS.spacingM),
            if (widget.answer.suggestions != null)
              SuggestionsWidget(
                suggestions: widget.answer.suggestions!,
                title: isSystemError ? 'Troubleshooting Steps' : 'Improvement Suggestions',
              ),
            SizedBox(height: DS.spacingL),
            Center(
              child: ElevatedButton(
                onPressed: _continuePressed ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: DS.spacingL,
                    vertical: DS.spacingS,
                  ),
                  // Disabled style
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  disabledForegroundColor: AppColors.textOnPrimary.withOpacity(0.5),
                ),
                child: Text(isSystemError ? 'Try Again Later' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleContinue() {
    // Prevent multiple clicks
    setState(() {
      _continuePressed = true;
    });
    
    // Call the continue callback
    widget.onContinue();
  }
}