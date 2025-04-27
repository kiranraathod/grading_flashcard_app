import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/answer.dart' as answer_model;
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../widgets/suggestions_widget.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';

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
  void initState() {
    super.initState();
    
    // Add post-frame callback to record view as soon as result screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Don't try to access StudyBloc directly - it's causing errors
        // Instead, use the information we already have in the widget
                
        // Check if the answer is correct (grade A, B, or C)
        bool isCompleted = widget.answer.grade == 'A' || 
                           widget.answer.grade == 'B' || 
                           widget.answer.grade == 'C';
        
        // Record the view in the global RecentViewBloc with the info we have
        context.read<RecentViewBloc>().add(
          RecordFlashcardView(
            // Create a minimal Flashcard with the information we have
            flashcard: Flashcard(
              id: 'flashcard-${DateTime.now().millisecondsSinceEpoch}',
              question: widget.answer.question,
              answer: widget.correctAnswer,
              isCompleted: isCompleted,
            ),
            // Create a minimal FlashcardSet
            set: FlashcardSet(
              id: 'set-${DateTime.now().millisecondsSinceEpoch}',
              title: 'Study Session',
              description: '',
              flashcards: [],
            ),
            isCompleted: isCompleted,
          ),
        );
        debugPrint('Recorded flashcard view when ResultScreen appeared (using available info)');
      } catch (e) {
        debugPrint('Error recording flashcard view in ResultScreen initState: $e');
      }
    });
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
                    Text('Question:', style: DS.headingSmall),
                    SizedBox(height: DS.spacingXs),
                    Text(widget.answer.question, style: DS.bodyMedium),
                    SizedBox(height: DS.spacingM),
                    Text('Your Answer:', style: DS.headingSmall),
                    SizedBox(height: DS.spacingXs),
                    Text(widget.answer.userAnswer, style: DS.bodyMedium),
                    if (!isSystemError) ...[
                      SizedBox(height: DS.spacingM),
                      Text('Correct Answer:', style: DS.headingSmall),
                      SizedBox(height: DS.spacingXs),
                      Text(widget.correctAnswer, style: DS.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: DS.spacingM),
            Card(
              // Using constructor with individual color components
              color: Color.fromRGBO(
                _getGradeColor().r.toInt(), // Convert from double to int
                _getGradeColor().g.toInt(),
                _getGradeColor().b.toInt(),
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
                title:
                    isSystemError
                        ? 'Troubleshooting Steps'
                        : 'Improvement Suggestions',
              ),
            SizedBox(height: DS.spacingL),
            // Show progress update message when answer is correct
            if (widget.answer.grade == 'A' ||
                widget.answer.grade == 'B' ||
                widget.answer.grade == 'C')
              Container(
                padding: EdgeInsets.all(DS.spacingM),
                margin: EdgeInsets.only(bottom: DS.spacingM),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: DS.spacingS),
                    Expanded(
                      child: Text(
                        'Your progress has been updated!',
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
              ),

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
                  // Instead of using withValues or withOpacity, create new Color objects
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

    // Record this flashcard view in the RecentViewBloc to ensure it appears in Recent tab
    try {
      // Don't try to access StudyBloc - use the information we have
      
      // Check if the answer is correct (grade A, B, or C)
      bool isCompleted = widget.answer.grade == 'A' || 
                         widget.answer.grade == 'B' || 
                         widget.answer.grade == 'C';
      
      // Record the view in the global RecentViewBloc
      context.read<RecentViewBloc>().add(
        RecordFlashcardView(
          // Create a minimal Flashcard with the information we have
          flashcard: Flashcard(
            id: 'flashcard-${DateTime.now().millisecondsSinceEpoch}',
            question: widget.answer.question,
            answer: widget.correctAnswer,
            isCompleted: isCompleted,
          ),
          // Create a minimal FlashcardSet
          set: FlashcardSet(
            id: 'set-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Study Session',
            description: '',
            flashcards: [],
          ),
          isCompleted: isCompleted,
        ),
      );
      debugPrint('Recorded flashcard view from ResultScreen (using available info)');
    } catch (e) {
      debugPrint('Error recording flashcard view from ResultScreen: $e');
    }

    // Call the continue callback
    widget.onContinue();
  }
}
