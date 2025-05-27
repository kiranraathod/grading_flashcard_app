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
  State<InterviewPracticeScreen> createState() =>
      _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  // State variables
  bool _showAnswer = false;
  bool _isCompleted = false;
  int _timeTaken = 0;
  late InterviewService _interviewService;
  Timer? _timer;
  final TextEditingController _userAnswerController = TextEditingController();
  bool _isGrading = false;
  bool _isSubmittingBatch = false;
  bool _hasLoadedInitialAnswer = false;

  // Map to store answers for all questions
  final Map<String, String> _userAnswers =
      {}; // Maps question ID to answer text

  // This field is set during grading and used for tracking the latest grade
  InterviewAnswer? _gradedAnswer;
  final InterviewApiService _interviewApiService = InterviewApiService();

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.question.isCompleted;

    // Note: _loadCurrentAnswer() moved to didChangeDependencies()
    // to ensure _interviewService is initialized first

    // ✅ ADDED: Auto-save on text changes
    _userAnswerController.addListener(_autoSaveAnswer);

    // Start a timer to track how long the user spends on this question
    _startTimer();
  }

  // Load any saved answer for the current question
  void _loadCurrentAnswer() {
    debugPrint('=== LOADING ANSWER FOR ${widget.question.id} ===');

    String? savedAnswer;

    // ✅ STEP 1: Check local storage first
    if (_userAnswers.containsKey(widget.question.id)) {
      savedAnswer = _userAnswers[widget.question.id]!;
      debugPrint(
        '✓ Found in local storage: "$savedAnswer" ($savedAnswer.length chars)',
      );
    }
    // ✅ STEP 2: Check global service storage
    else {
      savedAnswer = _interviewService.getUserAnswer(widget.question.id);
      if (savedAnswer != null && savedAnswer.isNotEmpty) {
        // ✅ SYNC: Copy from global to local for future access
        _userAnswers[widget.question.id] = savedAnswer;
        debugPrint(
          '✓ Found in global storage and synced to local: "$savedAnswer" ($savedAnswer.length chars)',
        );
      }
    }

    // ✅ STEP 3: Load into UI
    if (savedAnswer != null && savedAnswer.isNotEmpty) {
      _userAnswerController.text = savedAnswer;
      debugPrint(
        '✓ Loaded into text controller: "${_userAnswerController.text}"',
      );
    } else {
      _userAnswerController.clear();
      debugPrint('⚠️ No saved answer found, cleared text controller');
    }

    debugPrint('Current local answers count: ${_userAnswers.length}');
    debugPrint('Current local answers: ${_userAnswers.keys.toList()}');
    debugPrint('=== LOAD COMPLETE ===');
  }

  // Save the current answer to our map
  void _saveCurrentAnswer() {
    final answerText = _userAnswerController.text.trim();
    debugPrint('=== SAVING ANSWER FOR ${widget.question.id} ===');
    debugPrint('Answer text: "$answerText" ($answerText.length chars)');

    if (answerText.isNotEmpty) {
      // ✅ DUAL STORAGE: Save to both local and global with confirmation
      _userAnswers[widget.question.id] = answerText;
      _interviewService.saveUserAnswer(widget.question.id, answerText);

      debugPrint(
        '✓ Saved to local storage: ${_userAnswers[widget.question.id]}',
      );
      debugPrint(
        '✓ Saved to global storage: ${_interviewService.getUserAnswer(widget.question.id)}',
      );
      debugPrint('✓ Total local answers: ${_userAnswers.length}');
      debugPrint('✓ Local answers map: ${_userAnswers.keys.toList()}');
    } else {
      debugPrint('⚠️ Empty answer, not saving');
    }
    debugPrint('=== SAVE COMPLETE ===');
  }

  // ✅ ADDED: Auto-save on text changes
  void _autoSaveAnswer() {
    // Save answer automatically as user types (with debouncing)
    if (_userAnswerController.text.trim().isNotEmpty) {
      _saveCurrentAnswer();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);

    // ✅ FIXED: Load answer after service is initialized
    if (!_hasLoadedInitialAnswer) {
      _loadCurrentAnswer();
      _hasLoadedInitialAnswer = true;
    }
  }

  @override
  void dispose() {
    debugPrint('=== DISPOSING PRACTICE SCREEN ===');

    // Remove listener first
    _userAnswerController.removeListener(_autoSaveAnswer);

    // ✅ FINAL SAVE: Ensure current answer is saved before disposing
    final currentText = _userAnswerController.text.trim();
    if (currentText.isNotEmpty) {
      _userAnswers[widget.question.id] = currentText;
      _interviewService.saveUserAnswer(widget.question.id, currentText);
      debugPrint('✓ Final save on dispose: ${widget.question.id}');
    }

    // Cancel timer and dispose controller
    _timer?.cancel();
    _userAnswerController.dispose();

    // Show final summary
    debugPrint(
      'Final disposal - Local answers: ${_userAnswers.length}/${widget.questionList.length}',
    );
    debugPrint('Local answers: ${_userAnswers.keys.toList()}');

    // Save gradedAnswer data to service if needed
    if (_gradedAnswer != null) {
      debugPrint('Saving graded answer data for ${_gradedAnswer!.questionId}');
    }
    debugPrint('=== DISPOSAL COMPLETE ===');

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
      final gradedAnswer = await _interviewApiService.gradeInterviewAnswer(
        answer,
      );

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
          builder:
              (context) => InterviewResultScreen(
                answer: gradedAnswer,
                onContinue: () {
                  // Make sure to check if the widget is still mounted before using context
                  if (mounted) {
                    Navigator.pop(context); // Close the result screen
                    Navigator.pop(
                      context,
                    ); // Go back to the interview questions screen
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
    debugPrint('=== BATCH GRADING DEBUG START ===');

    // ✅ STEP 1: Save current answer first (critical!)
    _saveCurrentAnswer();
    debugPrint('✓ Current answer saved for question ${widget.question.id}');

    // ✅ STEP 2: Sync between local and global storage to ensure we have ALL answers
    debugPrint('Synchronizing local and global answer storage...');

    // First, push all local answers to global storage
    for (final entry in _userAnswers.entries) {
      _interviewService.saveUserAnswer(entry.key, entry.value);
      debugPrint(
        '✓ Synced local->global: $entry.key = $entry.value.length chars',
      );
    }

    // Then, pull any global answers that might not be in local storage
    for (final question in widget.questionList) {
      final globalAnswer = _interviewService.getUserAnswer(question.id);
      if (globalAnswer != null && globalAnswer.isNotEmpty) {
        if (!_userAnswers.containsKey(question.id) ||
            _userAnswers[question.id]!.isEmpty) {
          _userAnswers[question.id] = globalAnswer;
          debugPrint(
            '✓ Synced global->local: $question.id = $globalAnswer.length chars',
          );
        }
      }
    }

    // ✅ STEP 3: Collect ALL answers using BOTH sources for maximum coverage
    final Map<String, String> allAnswers = {};

    // Collect from local state first
    allAnswers.addAll(_userAnswers);
    debugPrint('Local answers collected: ${_userAnswers.length}');

    // Ensure we haven't missed any from global storage
    for (final question in widget.questionList) {
      final globalAnswer = _interviewService.getUserAnswer(question.id);
      if (globalAnswer != null && globalAnswer.trim().isNotEmpty) {
        // Use global answer if local is empty or doesn't exist
        if (!allAnswers.containsKey(question.id) ||
            allAnswers[question.id]!.trim().isEmpty) {
          allAnswers[question.id] = globalAnswer;
          debugPrint(
            '✓ Using global answer for $question.id: $globalAnswer.length chars',
          );
        }
      }
    }

    debugPrint('Total questions in list: ${widget.questionList.length}');
    debugPrint('Total answers collected: ${allAnswers.length}');
    debugPrint('Local _userAnswers map: $_userAnswers');
    debugPrint('Final allAnswers map: $allAnswers');

    // ✅ STEP 4: Validate we have at least one answer
    final nonEmptyAnswers =
        allAnswers.values.where((answer) => answer.trim().isNotEmpty).toList();
    if (nonEmptyAnswers.isEmpty) {
      debugPrint('❌ No answers found to submit');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer at least one question before submitting',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    debugPrint('Non-empty answers found: ${nonEmptyAnswers.length}');

    // ✅ STEP 5: Create answer objects for ALL questions (including empty ones for tracking)
    final List<InterviewAnswer> answersList =
        widget.questionList.map((question) {
          final userAnswer = allAnswers[question.id] ?? "";

          debugPrint(
            'Creating answer object for $question.id: "$userAnswer" ($userAnswer.length chars)',
          );

          return InterviewAnswer(
            questionId: question.id,
            questionText: question.text,
            userAnswer: userAnswer,
            category: question.category,
            difficulty: question.difficulty,
          );
        }).toList();

    // ✅ STEP 6: Filter for only answered questions for API call
    final answeredQuestions =
        answersList
            .where((answer) => answer.userAnswer.trim().isNotEmpty)
            .toList();

    debugPrint('Questions being sent to API: ${answeredQuestions.length}');
    for (final answer in answeredQuestions) {
      debugPrint('- API $answer.questionId: $answer.userAnswer.length chars');
    }
    debugPrint('=== BATCH GRADING DEBUG END ===');

    // ✅ STEP 7: Proceed with API call
    setState(() {
      _isSubmittingBatch = true;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grading ${answeredQuestions.length} answers...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Grade all answered questions as a batch
      final gradedAnswers = await _interviewApiService.gradeBatchAnswers(
        answeredQuestions,
      );

      debugPrint('✅ Received ${gradedAnswers.length} graded answers from API');

      // Check if widget is still mounted before using BuildContext
      if (!mounted) return;

      // Mark questions as completed if they have a passing score
      for (final answer in gradedAnswers) {
        if (answer.score != null && answer.score! >= 70) {
          _interviewService.toggleCompletion(answer.questionId);
          debugPrint(
            '✓ Marked $answer.questionId as completed (score: $answer.score)',
          );
        }
      }

      setState(() {
        _isSubmittingBatch = false;
      });

      // Navigate to batch results screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InterviewBatchResultScreen(
                answers: gradedAnswers,
                onContinue: () {
                  if (mounted) {
                    Navigator.pop(context); // Close result screen
                    Navigator.pop(context); // Go back to questions screen
                  }
                },
              ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error during batch grading: $e');

      // Check if widget is still mounted before using BuildContext
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

  // Show preparation tips in a modal popup
  void _showPreparationTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45, // Reduced from 0.6
        minChildSize: 0.3,      // Reduced from 0.4
        maxChildSize: 0.7,      // Reduced from 0.8
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DS.borderRadiusMedium),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Added to minimize height
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: DS.spacingM),
                decoration: BoxDecoration(
                  color: context.onSurfaceVariantColor.withOpacityFix(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.spacingL, 0, DS.spacingL, DS.spacingM), // Reduced bottom padding
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: context.primaryColor),
                    const SizedBox(width: DS.spacingS),
                    Text(
                      'Preparation Tips',
                      style: context.titleMedium?.copyWith(
                        color: context.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1), // Reduced divider height
              
              // Tips content - wrapped in Flexible instead of Expanded
              Flexible(
                child: SingleChildScrollView( // Changed from ListView to SingleChildScrollView
                  controller: scrollController,
                  padding: const EdgeInsets.all(DS.spacingL),
                  child: _buildPrepTips(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigate to the previous question
  void _moveToPreviousQuestion() {
    debugPrint('=== NAVIGATION TO PREVIOUS QUESTION ===');
    
    // Save current answer before navigating
    _saveCurrentAnswer();
    
    if (widget.currentIndex > 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => InterviewPracticeScreen(
            question: widget.questionList[widget.currentIndex - 1],
            questionList: widget.questionList,
            currentIndex: widget.currentIndex - 1,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from left animation for "previous"
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
    
    debugPrint('=== PREVIOUS NAVIGATION COMPLETE ===');
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
    debugPrint('=== NAVIGATION TO NEXT QUESTION ===');

    // ✅ CRITICAL: Save current answer before navigating
    _saveCurrentAnswer();

    // Show summary of current state
    final answeredCount = _getAnsweredQuestionCount();
    debugPrint(
      'Navigation summary: Answered $answeredCount/${widget.questionList.length} questions',
    );
    debugPrint('Local answers: ${_userAnswers.keys.toList()}');

    if (widget.currentIndex < widget.questionList.length - 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => InterviewPracticeScreen(
            question: widget.questionList[widget.currentIndex + 1],
            questionList: widget.questionList,
            currentIndex: widget.currentIndex + 1,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide from right animation for "next"
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else {
      // Last question - go back to questions list
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'ve completed all questions in this set!'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    debugPrint('=== NAVIGATION COMPLETE ===');
  }

  // Toggle question completion status
  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
    });

    // Update in the service
    _interviewService.toggleCompletion(widget.question.id);
  }

  // Helper method to get actual answered question count
  int _getAnsweredQuestionCount() {
    // Save current answer first to ensure accurate count
    final currentText = _userAnswerController.text.trim();
    if (currentText.isNotEmpty) {
      _userAnswers[widget.question.id] = currentText;
      _interviewService.saveUserAnswer(widget.question.id, currentText);
    }

    int count = 0;
    for (final question in widget.questionList) {
      final localAnswer = _userAnswers[question.id];
      final globalAnswer = _interviewService.getUserAnswer(question.id);

      if ((localAnswer != null && localAnswer.trim().isNotEmpty) ||
          (globalAnswer != null && globalAnswer.trim().isNotEmpty)) {
        count++;
      }
    }

    debugPrint(
      'Current answered question count: $count/${widget.questionList.length}',
    );
    return count;
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
            title: Text('Practice Mode', style: context.titleLarge),
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
              // Tips popup icon
              IconButton(
                icon: Icon(
                  Icons.lightbulb_outline,
                  color: context.primaryColor,
                ),
                tooltip: 'View preparation tips',
                onPressed: _showPreparationTips,
              ),
              const SizedBox(width: DS.spacingS),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: DS.spacingL,
                      vertical: DS.spacingS,
                    ),
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
                        Text('Mark as Complete', style: context.bodyMedium),
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
                              borderRadius: BorderRadius.circular(
                                DS.borderRadiusSmall,
                              ),
                              border: Border.all(
                                color: context.colorScheme.outline,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.shadowColor.withOpacityFix(
                                    0.05,
                                  ),
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
                                          color: _getDifficultyTextColor(
                                            context,
                                          ),
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

                          // Answer input area
                          if (!_showAnswer) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        maxLines: 8, // Increased from 6 since we have more space
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

                                      // Character count bar
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: DS.spacingM,
                                          vertical: DS.spacingXs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.surfaceVariantColor,
                                          border: Border(
                                            top: BorderSide(
                                              color: context.colorScheme.outline,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
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
                                          side: BorderSide(
                                            color: context.colorScheme.outline,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: DS.spacingM,
                                          ),
                                        ),
                                        child: Text('Clear'),
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
                                            borderRadius: BorderRadius.circular(
                                              DS.borderRadiusSmall,
                                            ),
                                          ),
                                        ),
                                        child: Text('Show Answer'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ] else ...[
                            Column(
                              children: [
                                // User's answer display
                                if (_userAnswerController.text.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(
                                      bottom: DS.spacingM,
                                    ),
                                    padding: const EdgeInsets.all(DS.spacingM),
                                    decoration: BoxDecoration(
                                      color: context.successColor
                                          .withOpacityFix(0.1),
                                      borderRadius: BorderRadius.circular(
                                        DS.borderRadiusSmall,
                                      ),
                                      border: Border.all(
                                        color: context.successColor
                                            .withOpacityFix(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              style: context.titleMedium
                                                  ?.copyWith(
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
                                    borderRadius: BorderRadius.circular(
                                      DS.borderRadiusSmall,
                                    ),
                                    border: Border.all(
                                      color: context.colorScheme.outline,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            child: Text('Back to Practice'),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: DS.spacingM),

                                      // Divider
                                      Divider(
                                        color: context.colorScheme.outline,
                                      ),

                                      const SizedBox(height: DS.spacingM),

                                      // Answer content
                                      Text(
                                        widget.question.answer ??
                                            'No answer available for this question.',
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: Mark as Complete
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _toggleCompletion,
                                icon: Icon(
                                  _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                                  size: 18,
                                  color: _isCompleted ? context.successColor : context.onSurfaceVariantColor,
                                ),
                                label: Text(
                                  _isCompleted ? 'Completed' : 'Mark as Complete',
                                  style: TextStyle(
                                    color: _isCompleted ? context.successColor : context.onSurfaceVariantColor,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _isCompleted ? context.successColor : context.colorScheme.outline,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: DS.spacingS),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: DS.spacingM),
                        
                        // Bottom row: Navigation and Grade All
                        _isSubmittingBatch || _isGrading
                            ? const CircularProgressIndicator()
                            : Row(
                                children: [
                                  // Previous button
                                  if (widget.currentIndex > 0) ...[
                                    Expanded(
                                      flex: 2,
                                      child: OutlinedButton.icon(
                                        onPressed: _moveToPreviousQuestion,
                                        icon: const Icon(Icons.arrow_back, size: 18),
                                        label: const Text('Previous'),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: context.colorScheme.outline),
                                          padding: const EdgeInsets.symmetric(vertical: DS.spacingM),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: DS.spacingM),
                                  ],
                                  
                                  // Next button (primary action)
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton.icon(
                                      onPressed: widget.currentIndex < widget.questionList.length - 1
                                          ? _moveToNextQuestion
                                          : _submitSingleAnswer,
                                      icon: Icon(
                                        widget.currentIndex < widget.questionList.length - 1
                                            ? Icons.arrow_forward
                                            : Icons.check,
                                        size: 18,
                                      ),
                                      label: Text(
                                        widget.currentIndex < widget.questionList.length - 1
                                            ? 'Next Question'
                                            : 'Submit Answer',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.primaryColor,
                                        foregroundColor: context.onPrimaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: DS.spacingM),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                                  
                                  // Grade All button (secondary action)
                                  if (widget.questionList.length > 1) ...[
                                    const SizedBox(width: DS.spacingM),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          final answeredCount = _getAnsweredQuestionCount();
                                          if (answeredCount > 0) {
                                            _submitAllAnswers();
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Please answer at least one question before submitting'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          _getAnsweredQuestionCount() > 0 ? Icons.grading : Icons.grading_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Grade All\n(${_getAnsweredQuestionCount()}/${widget.questionList.length})',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _getAnsweredQuestionCount() > 0
                                              ? context.successColor
                                              : context.surfaceVariantColor,
                                          foregroundColor: _getAnsweredQuestionCount() > 0
                                              ? context.onPrimaryColor
                                              : context.onSurfaceVariantColor,
                                          padding: const EdgeInsets.symmetric(vertical: DS.spacingS),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.primaryColor,
                          ),
                        ),
                        const SizedBox(height: DS.spacingM),
                        Text(
                          _isSubmittingBatch
                              ? 'Grading all answers...'
                              : 'Grading your answer...',
                          style: context.bodyLarge?.copyWith(
                            color: context.onSurfaceColor,
                          ),
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
      children:
          tips.map((tip) {
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
                  Expanded(child: Text(tip, style: context.bodyMedium)),
                ],
              ),
            );
          }).toList(),
    );
  }
}
