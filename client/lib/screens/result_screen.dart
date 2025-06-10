import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/answer.dart' as answer_model;
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/id_service.dart';
import '../widgets/suggestions_widget.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import '../utils/app_localizations_extension.dart';
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

  Color _getScoreColor() {
    final score = widget.answer.score ?? 0;
    
    if (score >= 90) return AppColors.gradeA;
    if (score >= 80) return AppColors.gradeB;
    if (score >= 70) return AppColors.gradeC;
    if (score >= 60) return AppColors.gradeD;
    return AppColors.gradeF;
  }

  String _getScoreDescription() {
    final score = widget.answer.score ?? 0;
    if (score >= 90) return 'Excellent Answer';
    if (score >= 80) return 'Good Answer';
    if (score >= 70) return 'Satisfactory Answer';
    if (score >= 60) return 'Needs Improvement';
    if (score > 0) return 'Incomplete Answer';
    return 'No Score';
  }

  @override
  void initState() {
    super.initState();
    
    // Add post-frame callback to record view as soon as result screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Don't try to access StudyBloc directly - it's causing errors
        // Instead, use the information we already have in the widget
                
        // Check if the answer is correct (score >= 70)
        bool isCompleted = (widget.answer.score ?? 0) >= 70;
        
        // Record the view in the global RecentViewBloc with the info we have
        context.read<RecentViewBloc>().add(
          RecordFlashcardView(
            // Create a minimal Flashcard with the information we have
            flashcard: Flashcard(
              id: IdService.flashcard(),
              question: widget.answer.question,
              answer: widget.correctAnswer,
              isCompleted: isCompleted,
            ),
            // Create a minimal FlashcardSet
            set: FlashcardSet(
              id: IdService.set(),
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
    final bool isSystemError = widget.answer.score == null;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).results)),
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
                    Text(AppLocalizations.of(context).question, style: DS.headingSmall),
                    SizedBox(height: DS.spacingXs),
                    Text(widget.answer.question, style: DS.bodyMedium),
                    SizedBox(height: DS.spacingM),
                    Text(AppLocalizations.of(context).yourAnswerLabel, style: DS.headingSmall),
                    SizedBox(height: DS.spacingXs),
                    Text(widget.answer.userAnswer, style: DS.bodyMedium),
                    if (!isSystemError) ...[
                      SizedBox(height: DS.spacingM),
                      Text(AppLocalizations.of(context).correctAnswer, style: DS.headingSmall),
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
                _getScoreColor().r.toInt(), // Convert from double to int
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
                        // Score circle - matching interview design
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,  // Clean white background
                            border: Border.all(color: _getScoreColor(), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              isSystemError ? "!" : '${widget.answer.score ?? 0}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: DS.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSystemError ? 'System Error' : 'Your Score',
                                style: DS.headingSmall,
                              ),
                              Text(
                                isSystemError ? 'Error' : _getScoreDescription(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _getScoreColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DS.spacingM),
                    Text(
                      isSystemError 
                        ? AppLocalizations.of(context).errorMessage 
                        : AppLocalizations.of(context).feedbackLabel,
                      style: DS.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: DS.spacingXs),
                    Text(
                      widget.answer.feedback ?? AppLocalizations.of(context).noFeedback,
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
                title: isSystemError
                    ? AppLocalizations.of(context).troubleshootingSteps
                    : AppLocalizations.of(context).improvementSuggestions,
              ),
            SizedBox(height: DS.spacingL),
            // Show progress update message when answer is correct
            if ((widget.answer.score ?? 0) >= 70)
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
                        AppLocalizations.of(context).progressUpdated,
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
                child: Text(isSystemError 
                    ? AppLocalizations.of(context).tryAgainLater 
                    : L10nExt.of(context).continueButton),
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
      
      // Check if the answer is correct (score >= 70)
      bool isCompleted = (widget.answer.score ?? 0) >= 70;
      
      // Record the view in the global RecentViewBloc
      context.read<RecentViewBloc>().add(
        RecordFlashcardView(
          // Create a minimal Flashcard with the information we have
          flashcard: Flashcard(
            id: IdService.flashcard(),
            question: widget.answer.question,
            answer: widget.correctAnswer,
            isCompleted: isCompleted,
          ),
          // Create a minimal FlashcardSet
          set: FlashcardSet(
            id: IdService.set(),
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
