import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../services/interview_api_service.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';
import '../widgets/interview/practice_question_card.dart';
import 'interview_practice_screen.dart';
import 'interview_batch_result_screen.dart';

class InterviewPracticeBatchScreen extends StatefulWidget {
  final List<InterviewQuestion> questions;
  final String categoryName;

  const InterviewPracticeBatchScreen({
    super.key,
    required this.questions,
    required this.categoryName,
  });

  @override
  State<InterviewPracticeBatchScreen> createState() => _InterviewPracticeBatchScreenState();
}

class _InterviewPracticeBatchScreenState extends State<InterviewPracticeBatchScreen> {
  late InterviewService _interviewService;
  final InterviewApiService _apiService = InterviewApiService();
  bool _isLoading = false; // Changed to non-final for proper state management
  List<InterviewQuestion> _completedQuestions = [];
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);
    _updateCompletedQuestions();
  }
  
  // Helper method to update the list of completed questions
  void _updateCompletedQuestions() {
    setState(() {
      _completedQuestions = widget.questions.where((q) => q.isCompleted).toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Analysis Practice',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.onSurfaceColor,
          ),
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: context.backgroundColor,
        child: Column(
          children: [
            // Instructions card with consistent styling
            Container(
              margin: const EdgeInsets.fromLTRB(
                DS.spacingL, 
                DS.spacingM, 
                DS.spacingL, 
                DS.spacingM
              ),
              padding: const EdgeInsets.all(DS.spacingM),
              decoration: BoxDecoration(
                color: context.isDarkMode 
                    ? context.primaryColor.withValues(alpha: 0.1)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                border: Border.all(
                  color: context.isDarkMode
                      ? context.primaryColor.withValues(alpha: 0.2)
                      : Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline, 
                        color: context.isDarkMode
                            ? context.primaryColor
                            : Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: DS.spacingS),
                      Text(
                        'Practice Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DS.spacingS),
                  Text(
                    'You can answer the questions in any order. Your answers will be graded when you complete the practice session.',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: DS.spacingS),
                  Text(
                    'Click on any question to start practicing.',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Question list header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DS.spacingL,
                vertical: DS.spacingS,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions (${widget.questions.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Question list with our improved card design
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(DS.spacingL),
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  return PracticeQuestionCard(
                    question: question,
                    onTap: () {
                      // Navigate to individual practice screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterviewPracticeScreen(
                            question: question,
                            questionList: widget.questions,
                            currentIndex: index,
                          ),
                        ),
                      ).then((_) {
                        // Refresh the screen when returning
                        setState(() {
                          _updateCompletedQuestions();
                        });
                      });
                    },
                  );
                },
              ),
            ),
            
            // Complete all button with consistent styling
            Container(
              padding: const EdgeInsets.all(DS.spacingL),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startBatchGrading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: DS.spacingM),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Complete All Questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _startBatchGrading() async {
    // Check if there are any completed questions
    if (_completedQuestions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete at least one question before submitting for batch grading'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Collect all the answers for completed questions
      final answers = _interviewService.getAnswersForQuestionIds(
        _completedQuestions.map((q) => q.id).toList()
      );
      
      if (answers.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No answers found. Please try answering some questions first.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Grade the answers
      final gradedAnswers = await _apiService.gradeBatchAnswers(answers);
      
      if (!mounted) return;
      
      // Update completion status if needed
      for (final answer in gradedAnswers) {
        if (answer.score != null && answer.score! >= 70) {
          _interviewService.toggleCompletion(answer.questionId);
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to the batch results screen with the graded answers
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewBatchResultScreen(
            answers: gradedAnswers,
            onContinue: () {
              // Check if the widget is still mounted
              if (mounted) {
                Navigator.pop(context); // Close the result screen
              }
            },
          ),
        ),
      );
    } catch (e) {
      // Set loading to false
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error grading answers: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}