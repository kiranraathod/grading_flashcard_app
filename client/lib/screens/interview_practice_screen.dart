import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../models/interview_answer.dart';
import '../services/interview_service.dart';
import '../services/interview_api_service.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import 'dart:async';
import 'interview_result_screen.dart';
import 'interview_batch_result_screen.dart';

class InterviewPracticeScreen extends StatefulWidget {
  final InterviewQuestion question;
  final List<InterviewQuestion> questionList;
  final int currentIndex;

  const InterviewPracticeScreen({
    super.key,
    required this.question,
    required this.questionList,
    required this.currentIndex,
  });

  @override
  State<InterviewPracticeScreen> createState() => _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  // State variables
  bool _showAnswer = false;
  bool _isCompleted = false;
  int _timeTaken = 0;
  late InterviewService _interviewService;
  Timer? _timer;
  final TextEditingController _userAnswerController = TextEditingController();
  bool _isListening = false;
  bool _isGrading = false;
  bool _isSubmittingBatch = false;
  
  // Map to store answers for all questions
  final Map<String, String> _userAnswers = {}; // Maps question ID to answer text
  
  // This field is set during grading and used for tracking the latest grade
  InterviewAnswer? _gradedAnswer;
  final InterviewApiService _interviewApiService = InterviewApiService();

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.question.isCompleted;
    
    // Load any previously entered answer for this question
    _loadCurrentAnswer();
    
    // Start a timer to track how long the user spends on this question
    _startTimer();
  }
  
  // Load any saved answer for the current question
  void _loadCurrentAnswer() {
    if (_userAnswers.containsKey(widget.question.id)) {
      _userAnswerController.text = _userAnswers[widget.question.id]!;
      debugPrint('Loaded saved answer for question ${widget.question.id}');
    } else {
      _userAnswerController.clear();
    }
  }
  
  // Save the current answer to our map
  void _saveCurrentAnswer() {
    final answerText = _userAnswerController.text.trim();
    if (answerText.isNotEmpty) {
      _userAnswers[widget.question.id] = answerText;
      debugPrint('Saved answer for question ${widget.question.id}');
      debugPrint('Total answers: ${_userAnswers.length}/${widget.questionList.length}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userAnswerController.dispose();
    // Save gradedAnswer data to service if needed
    if (_gradedAnswer != null) {
      debugPrint('Saving graded answer data for ${_gradedAnswer!.questionId}');
    }
    super.dispose();
  }
  
  // Clear the user's answer
  void _clearUserAnswer() {
    setState(() {
      _userAnswerController.clear();
    });
  }
  
  // Save the user's answer
  void _saveUserAnswer() {
    _saveCurrentAnswer();
    debugPrint('User answer saved: ${_userAnswerController.text}');
  }
  
  // Submit a single answer
  void _submitSingleAnswer() async {
    if (_userAnswerController.text.trim().isEmpty) {
      // Show a message if the answer is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an answer before submitting'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isGrading = true;
    });
    
    // Show a loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grading your answer...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      // Save current answer to our map
      _saveCurrentAnswer();
      
      // Create an InterviewAnswer object to grade
      final answer = InterviewAnswer(
        questionId: widget.question.id,
        questionText: widget.question.text,
        userAnswer: _userAnswerController.text,
        category: widget.question.category,
        difficulty: widget.question.difficulty,
      );
      
      // Record the view in the global RecentViewBloc to ensure it appears in Recent tab
      context.read<RecentViewBloc>().add(
        RecordInterviewQuestionView(
          question: widget.question,
          category: widget.question.category,
        ),
      );
      debugPrint('Recorded interview question view from submitSingleAnswer');
      
      // Grade the answer using the specialized interview API service
      final gradedAnswer = await _interviewApiService.gradeInterviewAnswer(answer);
      
      // Fixed: Added mounted check before updating state after async operation
      if (!mounted) return;
      
      // Update the state with the graded answer
      setState(() {
        _gradedAnswer = gradedAnswer;
        _isGrading = false;
      });
      
      // Mark the question as completed if the score is good (70 or above)
      if ((gradedAnswer.score ?? 0) >= 70) {
        _interviewService.toggleCompletion(widget.question.id);
        setState(() {
          _isCompleted = true;
        });
        
        // Record the view again with completed status
        context.read<RecentViewBloc>().add(
          RecordInterviewQuestionView(
            question: widget.question,
            category: widget.question.category,
            isCompleted: true,
          ),
        );
        debugPrint('Recorded completed interview question view');
      }
      
      // Show the results screen - no need for mounted check here as we already checked above
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewResultScreen(
            answer: gradedAnswer,
            onContinue: () {
              // Make sure to check if the widget is still mounted before using context
              if (mounted) {
                Navigator.pop(context); // Close the result screen
                Navigator.pop(context); // Go back to the interview questions screen
              }
            },
          ),
        ),
      );
    } catch (e) {
      // Fixed: Added mounted check before updating state after async operation
      if (!mounted) return;
      
      // Handle errors
      setState(() {
        _isGrading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error grading answer: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Submit all answers for batch grading
  void _submitAllAnswers() async {
    // Save the current answer first
    _saveCurrentAnswer();
    
    // Check if any questions have been answered
    if (_userAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer at least one question before submitting'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmittingBatch = true;
    });
    
    try {
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grading all your answers...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Create answer objects for all questions
      final List<InterviewAnswer> answersList = widget.questionList.map((question) {
        // Use the saved answer if available, otherwise empty string
        final userAnswer = _userAnswers[question.id] ?? "";
        
        return InterviewAnswer(
          questionId: question.id,
          questionText: question.text,
          userAnswer: userAnswer,
          category: question.category,
          difficulty: question.difficulty,
        );
      }).toList();
      
      // Grade all answers as a batch
      final gradedAnswers = await _interviewApiService.gradeBatchAnswers(answersList);
      
      // Fixed: Added mounted check before using BuildContext after async operation
      if (!mounted) return;
      
      // Mark questions as completed if they have a passing score
      for (final answer in gradedAnswers) {
        if (answer.score != null && answer.score! >= 70) {
          _interviewService.toggleCompletion(answer.questionId);
        }
      }
      
      setState(() {
        _isSubmittingBatch = false;
      });
      
      // Navigate to the batch results screen - Fixed: Use as a class, not a method
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewBatchResultScreen(
            answers: gradedAnswers,
            onContinue: () {
              // Make sure to check if the widget is still mounted before using context
              if (mounted) {
                Navigator.pop(context); // Close the result screen
                Navigator.pop(context); // Go back to the interview questions screen
              }
            },
          ),
        ),
      );
    } catch (e) {
      // Fixed: Added mounted check before updating state after async operation
      if (!mounted) return;
      
      setState(() {
        _isSubmittingBatch = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error grading answers: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Start voice recognition
  void _startListening() {
    // This would use a speech recognition package in a real implementation
    // For example: speech_to_text package
    setState(() {
      _isListening = true;
    });
    
    // Simulate voice recognition for demo purposes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice recording started - this would use the device microphone in a real implementation'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // After a few seconds, stop the simulated recording
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _stopListening();
      }
    });
  }
  
  // Stop voice recognition
  void _stopListening() {
    setState(() {
      _isListening = false;
      
      // Add some simulated text for demo purposes
      _userAnswerController.text = '${_userAnswerController.text}${_userAnswerController.text.isEmpty ? '' : ' '}Voice input would appear here in a real implementation.';
    });
  }

  // Start the timer to track practice time
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeTaken++;
      });
    });
  }

  // Format the time in MM:SS format
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Navigate to the next question
  void _moveToNextQuestion() {
    // Save the current answer before navigating
    _saveCurrentAnswer();
    
    if (widget.currentIndex < widget.questionList.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InterviewPracticeScreen(
            question: widget.questionList[widget.currentIndex + 1],
            questionList: widget.questionList,
            currentIndex: widget.currentIndex + 1,
          ),
        ),
      );
    } else {
      // If this is the last question, go back to the questions list
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'ve completed all questions in this set!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Toggle question completion status
  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
    });
    
    // Update in the service
    _interviewService.toggleCompletion(widget.question.id);
  }

  // Helper method to get difficulty color
  Color _getDifficultyColor(BuildContext context) {
    switch (widget.question.difficulty) {
      case 'entry':
        return context.successColor.withOpacityFix(0.1);
      case 'mid':
        return context.warningColor.withOpacityFix(0.1);
      case 'senior':
        return context.errorColor.withOpacityFix(0.1);
      default:
        return context.surfaceVariantColor;
    }
  }

  // Helper method to get difficulty text color
  Color _getDifficultyTextColor(BuildContext context) {
    switch (widget.question.difficulty) {
      case 'entry':
        return context.successColor;
      case 'mid':
        return context.warningColor;
      case 'senior':
        return context.errorColor;
      default:
        return context.onSurfaceVariantColor;
    }
  }

  // Helper method to get difficulty text
  String _getDifficultyText() {
    switch (widget.question.difficulty) {
      case 'entry':
        return 'Entry Level';
      case 'mid':
        return 'Mid Level';
      case 'senior':
        return 'Senior Level';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get category color
  Color _getCategoryColor(BuildContext context) {
    switch (widget.question.category) {
      case 'technical':
        return context.secondaryColor.withOpacityFix(0.1);
      case 'applied':
        return context.successColor.withOpacityFix(0.1);
      case 'case':
        return context.secondaryColor.withOpacityFix(0.15);
      case 'behavioral':
        return context.warningColor.withOpacityFix(0.1);
      case 'job':
        return context.errorColor.withOpacityFix(0.1);
      default:
        return context.surfaceVariantColor;
    }
  }

  // Helper method to get category name
  String _getCategoryName() {
    switch (widget.question.category) {
      case 'technical':
        return 'Technical Knowledge';
      case 'applied':
        return 'Applied Skills';
      case 'case':
        return 'Case Studies';
      case 'behavioral':
        return 'Behavioral Questions';
      case 'job':
        return 'Job-Specific';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Record view when the screen first loads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<RecentViewBloc>().add(
            RecordInterviewQuestionView(
              question: widget.question,
              category: widget.question.category,
            ),
          );
        });
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Practice Mode',
              style: context.titleLarge,
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Check if any answer has been entered
                if (_userAnswerController.text.trim().isNotEmpty) {
                  // Save the answer before leaving
                  _saveCurrentAnswer();
                }
                Navigator.of(context).pop();
              },
            ),
            actions: [
              // Progress indicator
              Center(
                child: Text(
                  widget.questionList.length > 1
                      ? 'Question ${widget.currentIndex + 1}/${widget.questionList.length}'
                      : 'Question 1/1',
                  style: context.bodyMedium,
                ),
              ),
              const SizedBox(width: DS.spacingM),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Timer bar at the top
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: DS.spacingL, vertical: DS.spacingS),
                    color: context.primaryColor.withOpacityFix(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: context.primaryColor,
                        ),
                        const SizedBox(width: DS.spacingS),
                        Text(
                          'Time: ${_formatTime(_timeTaken)}',
                          style: context.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        // Completion status
                        Checkbox(
                          value: _isCompleted,
                          onChanged: (value) => _toggleCompletion(),
                          activeColor: context.primaryColor,
                        ),
                        Text(
                          'Mark as Complete',
                          style: context.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  
                  // Main content area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(DS.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(DS.spacingM),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                              border: Border.all(color: context.colorScheme.outline),
                              boxShadow: [
                                BoxShadow(
                                  color: context.shadowColor.withOpacityFix(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category and difficulty tags
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: DS.spacingS,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(context),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _getCategoryName(),
                                        style: context.labelMedium,
                                      ),
                                    ),
                                    
                                    const SizedBox(width: DS.spacingXs),
                                    
                                    // Subtopic
                                    Text(
                                      '• ${widget.question.subtopic}',
                                      style: context.bodySmall,
                                    ),
                                    
                                    const Spacer(),
                                    
                                    // Difficulty
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: DS.spacingS,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(context),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _getDifficultyText(),
                                        style: context.labelMedium?.copyWith(
                                          color: _getDifficultyTextColor(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: DS.spacingM),
                                
                                // Question text
                                Text(
                                  widget.question.text,
                                  style: context.titleLarge,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: DS.spacingL),
                          
                          // Preparation area
                          if (!_showAnswer) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(DS.spacingM),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withOpacityFix(0.05),
                                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                border: Border.all(color: context.primaryColor.withOpacityFix(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preparation Guide',
                                    style: context.titleMedium?.copyWith(
                                      color: context.primaryColor,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: DS.spacingS),
                                  
                                  // Tips based on category
                                  _buildPrepTips(),
                                  
                                  const SizedBox(height: DS.spacingM),
                                  
                                  // User answer input area
                                  Text(
                                    'Your Answer:',
                                    style: context.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: DS.spacingXs),
                                  
                                  // Text field for user's answer
                                  Container(
                                    decoration: BoxDecoration(
                                      color: context.surfaceColor,
                                      borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                      border: Border.all(color: context.colorScheme.outline),
                                    ),
                                    child: Column(
                                      children: [
                                        TextField(
                                          controller: _userAnswerController,
                                          maxLines: 6,
                                          style: context.bodyLarge,
                                          decoration: InputDecoration(
                                            hintText: 'Type your answer here...',
                                            hintStyle: context.bodyLarge?.copyWith(
                                              color: context.onSurfaceVariantColor,
                                            ),
                                            contentPadding: const EdgeInsets.all(DS.spacingM),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        
                                        // Voice input button and character count
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: DS.spacingM,
                                            vertical: DS.spacingXs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.surfaceVariantColor,
                                            border: Border(
                                              top: BorderSide(color: context.colorScheme.outline),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Voice input button
                                              IconButton(
                                                onPressed: _isListening ? _stopListening : _startListening,
                                                icon: Icon(
                                                  _isListening ? Icons.mic : Icons.mic_none,
                                                  color: _isListening ? context.errorColor : context.onSurfaceVariantColor,
                                                ),
                                                tooltip: _isListening ? 'Stop recording' : 'Start voice input',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              
                                              const SizedBox(width: DS.spacingXs),
                                              
                                              Text(
                                                _isListening ? 'Recording...' : 'Voice input',
                                                style: context.bodySmall?.copyWith(
                                                  color: _isListening ? context.errorColor : context.onSurfaceVariantColor,
                                                ),
                                              ),
                                              
                                              const Spacer(),
                                              
                                              // Character count
                                              Text(
                                                '${_userAnswerController.text.length} chars',
                                                style: context.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: DS.spacingM),
                                  
                                  // Show answer button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _clearUserAnswer,
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: context.colorScheme.outline),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: DS.spacingM,
                                            ),
                                          ),
                                          child: const Text('Clear'),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: DS.spacingM),
                                      
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Save the user's answer if needed
                                            _saveUserAnswer();
                                            
                                            setState(() {
                                              _showAnswer = true;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context.primaryColor,
                                            foregroundColor: context.onPrimaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: DS.spacingM,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                            ),
                                          ),
                                          child: const Text('Show Answer'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Column(
                              children: [
                                // User's answer display
                                if (_userAnswerController.text.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: DS.spacingM),
                                    padding: const EdgeInsets.all(DS.spacingM),
                                    decoration: BoxDecoration(
                                      color: context.successColor.withOpacityFix(0.1),
                                      borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                      border: Border.all(color: context.successColor.withOpacityFix(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: context.successColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: DS.spacingXs),
                                            Text(
                                              'Your Answer',
                                              style: context.titleMedium?.copyWith(
                                                color: context.successColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: DS.spacingM),
                                        
                                        Text(
                                          _userAnswerController.text,
                                          style: context.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                // Example answer area
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(DS.spacingM),
                                  decoration: BoxDecoration(
                                    color: context.surfaceColor,
                                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                    border: Border.all(color: context.colorScheme.outline),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb,
                                            color: context.primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: DS.spacingXs),
                                          Text(
                                            'Example Answer',
                                            style: context.titleMedium,
                                          ),
                                          const Spacer(),
                                          // Hide answer button
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAnswer = false;
                                              });
                                            },
                                            child: const Text('Back to Practice'),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: DS.spacingM),
                                      
                                      // Divider
                                      Divider(color: context.colorScheme.outline),
                                      
                                      const SizedBox(height: DS.spacingM),
                                      
                                      // Answer content
                                      Text(
                                        widget.question.answer ?? 'No answer available for this question.',
                                        style: context.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom navigation bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DS.spacingL,
                      vertical: DS.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: context.shadowColor.withOpacityFix(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mark complete button
                        OutlinedButton.icon(
                          onPressed: _toggleCompletion,
                          icon: Icon(
                            _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                            size: 18,
                            color: _isCompleted ? context.primaryColor : context.onSurfaceVariantColor,
                          ),
                          label: Text(
                            _isCompleted ? 'Completed' : 'Mark Complete',
                            style: TextStyle(
                              color: _isCompleted ? context.primaryColor : context.onSurfaceVariantColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isCompleted ? context.primaryColor : context.colorScheme.outline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                            ),
                          ),
                        ),
                        
                        // Show different buttons based on context
                        _isSubmittingBatch || _isGrading 
                        ? const CircularProgressIndicator()
                        : Row(
                            children: [
                              // Next/Submit single button
                              ElevatedButton.icon(
                                onPressed: widget.questionList.length > 1 && widget.currentIndex < widget.questionList.length - 1 
                                    ? _moveToNextQuestion 
                                    : _submitSingleAnswer,
                                icon: Icon(
                                  widget.questionList.length > 1 && widget.currentIndex < widget.questionList.length - 1 
                                      ? Icons.arrow_forward
                                      : Icons.check,
                                  size: 18,
                                ),
                                label: Text(
                                  widget.questionList.length > 1 && widget.currentIndex < widget.questionList.length - 1 
                                      ? 'Next Question' 
                                      : 'Submit This Answer'
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primaryColor,
                                  foregroundColor: context.onPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                  ),
                                ),
                              ),
                              
                              // Only add space if the Grade All button will be shown
                              if (widget.questionList.length > 1)
                                const SizedBox(width: DS.spacingM),
                              
                              // Submit all button - only show when there are multiple questions
                              if (widget.questionList.length > 1)
                                ElevatedButton.icon(
                                  onPressed: _submitAllAnswers,
                                  icon: const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Grade All (${_userAnswers.length}/${widget.questionList.length})'
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.successColor,
                                    foregroundColor: context.onPrimaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Show loading overlay during grading or batch submission
              if (_isGrading || _isSubmittingBatch)
                Container(
                  color: context.surfaceColor.withOpacityFix(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                        const SizedBox(height: DS.spacingM),
                        Text(
                          _isSubmittingBatch 
                              ? 'Grading all answers...' 
                              : 'Grading your answer...',
                          style: context.bodyLarge?.copyWith(color: context.onSurfaceColor),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Build preparation tips based on question category
  Widget _buildPrepTips() {
    List<String> tips = [];
    
    switch (widget.question.category) {
      case 'technical':
        tips = [
          'Focus on explaining the core concepts clearly',
          'Use concrete examples to demonstrate your understanding',
          'Mention real-world applications if relevant',
          'Be prepared to discuss advantages and limitations',
        ];
        break;
      case 'applied':
        tips = [
          'Structure your answer with a clear methodology',
          'Explain why you would choose certain approaches',
          'Discuss how you would handle edge cases',
          'Consider mentioning tools or techniques you would use',
        ];
        break;
      case 'case':
        tips = [
          'Break down the problem systematically',
          'Think about the business context and requirements',
          'Consider multiple approaches and their trade-offs',
          'Explain how you would evaluate the solution\'s effectiveness',
        ];
        break;
      case 'behavioral':
        tips = [
          'Use the STAR method: Situation, Task, Action, Result',
          'Be specific about your personal contribution',
          'Quantify results where possible',
          'Reflect on what you learned from the experience',
        ];
        break;
      case 'job':
        tips = [
          'Connect your skills to the specific role requirements',
          'Highlight relevant experience and accomplishments',
          'Demonstrate knowledge of industry-specific tools and practices',
          'Show awareness of current trends in the field',
        ];
        break;
      default:
        tips = [
          'Structure your answer clearly with a beginning, middle, and end',
          'Use specific examples to support your points',
          'Keep your answer concise and relevant to the question',
          'Consider different perspectives on the topic',
        ];
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: DS.spacingXs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: context.primaryColor,
              ),
              const SizedBox(width: DS.spacingXs),
              Expanded(
                child: Text(
                  tip,
                  style: context.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}