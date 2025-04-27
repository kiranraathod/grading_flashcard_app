import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_answer.dart';
import '../widgets/suggestions_widget.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import '../services/interview_service.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';

class InterviewResultScreen extends StatefulWidget {
  final InterviewAnswer answer;
  final VoidCallback onContinue;

  const InterviewResultScreen({
    super.key,
    required this.answer,
    required this.onContinue,
  });

  @override
  State<InterviewResultScreen> createState() => _InterviewResultScreenState();
}

class _InterviewResultScreenState extends State<InterviewResultScreen> {
  // Add a flag to prevent multiple clicks
  bool _continuePressed = false;

  // Get color based on score
  Color _getScoreColor() {
    final score = widget.answer.score ?? 0;
    
    if (score >= 90) return AppColors.gradeA;
    if (score >= 80) return AppColors.gradeB;
    if (score >= 70) return AppColors.gradeC;
    if (score >= 60) return AppColors.gradeD;
    return AppColors.gradeF;
  }

  @override
  Widget build(BuildContext context) {
    final bool isSystemError = widget.answer.feedback?.contains("couldn't properly analyze") ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Interview Answer Assessment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onContinue,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DS.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro paragraph
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(DS.spacingM),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interview Response Evaluation',
                    style: DS.headingSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: DS.spacingS),
                  Text(
                    'Your answer has been evaluated based on completeness, accuracy, and clarity. See below for your score, detailed feedback, and suggestions for improvement.',
                    style: DS.bodyMedium,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: DS.spacingL),
            
            // Question and answer card
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: EdgeInsets.all(DS.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interview Question:', style: DS.headingSmall),
                    SizedBox(height: DS.spacingXs),
                    Text(
                      widget.answer.questionText, 
                      style: DS.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: DS.spacingM),
                    Text('Your Answer:', style: DS.headingSmall),
                    SizedBox(height: DS.spacingXs),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(DS.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        widget.answer.userAnswer, 
                        style: DS.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: DS.spacingL),
            
            // Score card
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                side: BorderSide(
                  color: Color.fromRGBO(
                    _getScoreColor().r.toInt(),
                    _getScoreColor().g.toInt(),
                    _getScoreColor().b.toInt(),
                    0.5,
                  ),
                ),
              ),
              color: Color.fromRGBO(
                _getScoreColor().r.toInt(),
                _getScoreColor().g.toInt(),
                _getScoreColor().b.toInt(),
                0.2,
              ),
              child: Padding(
                padding: EdgeInsets.all(DS.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Score display as circular progress indicator
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: (widget.answer.score ?? 0) / 100,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
                                strokeWidth: 8,
                              ),
                              Center(
                                child: Text(
                                  '${widget.answer.score ?? 0}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: DS.spacingM),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSystemError ? 'System Error' : 'Your Score',
                              style: DS.headingSmall,
                            ),
                            Text(
                              _getScoreDescription(widget.answer.score ?? 0),
                              style: DS.bodySmall.copyWith(
                                color: Color.fromRGBO(
                                  _getScoreColor().r.toInt(),
                                  _getScoreColor().g.toInt(),
                                  _getScoreColor().b.toInt(),
                                  0.8,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: DS.spacingM),
                    Divider(
                      color: Color.fromRGBO(
                        _getScoreColor().r.toInt(),
                        _getScoreColor().g.toInt(),
                        _getScoreColor().b.toInt(),
                        0.3,
                      ),
                    ),
                    SizedBox(height: DS.spacingM),
                    Text(
                      isSystemError ? 'Error Message:' : 'Feedback:',
                      style: DS.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: DS.spacingS),
                    Text(
                      widget.answer.feedback ?? 'No feedback available',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isSystemError ? Colors.red[700] : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: DS.spacingL),
            
            // Suggestions section
            if (widget.answer.suggestions != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SuggestionsWidget(
                  suggestions: widget.answer.suggestions!,
                  title: isSystemError ? 'Troubleshooting Steps' : 'Improvement Suggestions',
                ),
              ),
              
            SizedBox(height: DS.spacingL),
              
            // Show progress update message when score is good
            if ((widget.answer.score ?? 0) >= 70)
              Container(
                padding: EdgeInsets.all(DS.spacingM),
                margin: EdgeInsets.only(bottom: DS.spacingM),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: DS.spacingS),
                    Expanded(
                      child: Text(
                        'Great job! This question has been marked as completed.',
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            // Continue button
            Center(
              child: ElevatedButton(
                onPressed: _continuePressed ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: DS.spacingL,
                    vertical: DS.spacingM,
                  ),
                  minimumSize: Size(200, 48),
                  // Use Color.fromARGB for disabled colors
                  disabledBackgroundColor: Color.fromARGB(
                    (AppColors.primary.a * 0.5).round(),
                    AppColors.primary.r.toInt(),
                    AppColors.primary.g.toInt(),
                    AppColors.primary.b.toInt(),
                  ),
                  disabledForegroundColor: Color.fromARGB(
                    (AppColors.textOnPrimary.a * 0.5).round(),
                    AppColors.textOnPrimary.r.toInt(),
                    AppColors.textOnPrimary.g.toInt(),
                    AppColors.textOnPrimary.b.toInt(),
                  ),
                ),
                child: Text(isSystemError ? 'Try Again Later' : 'Return to Questions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get description text based on score
  String _getScoreDescription(int score) {
    if (score >= 90) return 'Excellent Answer';
    if (score >= 80) return 'Good Answer';
    if (score >= 70) return 'Satisfactory Answer';
    if (score >= 60) return 'Needs Improvement';
    if (score > 0) return 'Incomplete Answer';
    return 'No Score';
  }

  void _handleContinue() {
    // Prevent multiple clicks
    setState(() {
      _continuePressed = true;
    });

    // Record this interview question view in the RecentViewBloc to ensure it appears in Recent tab
    try {
      // Find the original question from the answer
      final interviewService = Provider.of<InterviewService>(context, listen: false);
      final question = interviewService.getQuestionById(widget.answer.questionId);
      
      if (question != null) {
        // Record the view in the global RecentViewBloc
        context.read<RecentViewBloc>().add(
          RecordInterviewQuestionView(
            question: question,
            category: widget.answer.category,
          ),
        );
        debugPrint('Recorded interview question view from InterviewResultScreen');
      }
    } catch (e) {
      debugPrint('Error recording interview question view from InterviewResultScreen: $e');
    }

    // Call the continue callback
    widget.onContinue();
  }
}