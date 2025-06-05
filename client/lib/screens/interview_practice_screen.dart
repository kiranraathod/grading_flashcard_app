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
  int _timeTaken = 0;
  late InterviewService _interviewService;
  Timer? _timer;
  final TextEditingController _userAnswerController = TextEditingController();
  bool _isGrading = false;
  bool _isSubmittingBatch = false;
  bool _hasLoadedInitialAnswer = false;
  
  // ✨ NEW: Enhanced UI state variables
  final FocusNode _answerFocusNode = FocusNode();
  bool _isTextFieldFocused = false;

  // Map to store answers for all questions
  final Map<String, String> _userAnswers =
      {}; // Maps question ID to answer text

  // This field is set during grading and used for tracking the latest grade
  InterviewAnswer? _gradedAnswer;
  final InterviewApiService _interviewApiService = InterviewApiService();

  @override
  void initState() {
    super.initState();

    // Note: _loadCurrentAnswer() moved to didChangeDependencies()
    // to ensure _interviewService is initialized first

    // ✅ ADDED: Auto-save on text changes
    _userAnswerController.addListener(_autoSaveAnswer);

    // ✨ NEW: Enhanced UI focus listener
    _answerFocusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _answerFocusNode.hasFocus;
      });
    });

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
      if (savedAnswer.isNotEmpty) {
        // ✅ SYNC: Copy from global to local for future access
        _userAnswers[widget.question.id] = savedAnswer;
        debugPrint(
          '✓ Found in global storage and synced to local: "$savedAnswer" ($savedAnswer.length chars)',
        );
      }
    }

    // ✅ STEP 3: Load into UI
    if (savedAnswer.isNotEmpty) {
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

    // ✨ NEW: Dispose focus node
    _answerFocusNode.dispose();

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

  // Save the user's answer
  void _saveUserAnswer() {
    _saveCurrentAnswer();
    debugPrint('User answer saved: ${_userAnswerController.text}');
  }

  // Submit a single answer with word validation
  void _submitSingleAnswer() async {
    final wordCount = _getWordCount(_userAnswerController.text.trim());
    
    // Validate word length
    if (wordCount < 200 || wordCount > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wordCount < 200 
                ? 'Answer too short. Please write at least 200 words (currently $wordCount)'
                : 'Answer too long. Please keep it under 300 words (currently $wordCount)'
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
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
          category: widget.question.subtopic.isNotEmpty ? widget.question.subtopic : widget.question.category, // 🔧 Use subtopic for better navigation
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

      // ✨ AUTOMATIC COMPLETION: Always mark as completed when word requirements are met
      _interviewService.toggleCompletion(widget.question.id);

      // Record the view again with completed status
      context.read<RecentViewBloc>().add(
        RecordInterviewQuestionView(
          question: widget.question,
          category: widget.question.subtopic.isNotEmpty ? widget.question.subtopic : widget.question.category, // 🔧 Use subtopic for better navigation
          isCompleted: true,
        ),
      );
      debugPrint('Automatically marked question as completed due to word requirement compliance');

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
      if (globalAnswer.isNotEmpty) {
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
      if (globalAnswer.trim().isNotEmpty) {
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

    // ✅ STEP 4: Validate we have at least one valid answer (200-300 words)
    final validAnswers = allAnswers.entries
        .where((entry) {
          final wordCount = _getWordCount(entry.value.trim());
          return wordCount >= 200 && wordCount <= 300;
        })
        .toList();
    
    if (validAnswers.isEmpty) {
      debugPrint('❌ No valid answers found to submit (all answers must be 200-300 words)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide at least one answer with 200-300 words before submitting',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    debugPrint('Valid answers found: ${validAnswers.length}');

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

    // ✅ STEP 6: Filter for only valid answered questions for API call (200-300 words)
    final answeredQuestions =
        answersList
            .where((answer) {
              final wordCount = _getWordCount(answer.userAnswer.trim());
              return wordCount >= 200 && wordCount <= 300;
            })
            .toList();

    debugPrint('Valid questions being sent to API: ${answeredQuestions.length}');
    for (final answer in answeredQuestions) {
      final wordCount = _getWordCount(answer.userAnswer);
      debugPrint('- API $answer.questionId: $wordCount words (valid)');
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
          content: Text('Grading ${answeredQuestions.length} valid answers...'),
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

      // ✨ AUTOMATIC COMPLETION: Mark all submitted questions as completed
      for (final answer in gradedAnswers) {
        _interviewService.toggleCompletion(answer.questionId);
        debugPrint(
          '✓ Automatically marked $answer.questionId as completed (met word requirements)',
        );
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

  // ✨ NEW: Show example answer in a modal popup
  void _showExampleAnswer() {
    // Save current answer before showing example
    _saveUserAnswer();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DS.borderRadiusMedium),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: DS.spacingM),
                decoration: BoxDecoration(
                  color: context.onSurfaceVariantColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.spacingL, 0, DS.spacingL, DS.spacingS),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.visibility, color: Colors.white, size: 18),
                    ),
                    SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
                    Expanded(
                      child: Text(
                        'Example Answer',
                        style: context.titleMedium?.copyWith(
                          color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(DS.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User's answer display (if exists)
                      if (_userAnswerController.text.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(DS.spacingM),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0D9488).withValues(alpha: 0.1),
                                const Color(0xFF0D9488).withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                            border: Border.all(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0D9488),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 14),
                                  ),
                                  const SizedBox(width: DS.spacingXs),
                                  Expanded(
                                    child: Text(
                                      'Your Answer',
                                      style: context.titleSmall?.copyWith(
                                        color: const Color(0xFF0D9488),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getAnswerQualityColor().withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_getWordCount(_userAnswerController.text)} words',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _getAnswerQualityColor(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: DS.spacingS),
                              Text(
                                _userAnswerController.text,
                                style: context.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DS.spacingL),
                      ],
                      
                      // Example answer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(DS.spacingM),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              const Color(0xFF3B82F6).withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lightbulb, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: DS.spacingXs),
                                Expanded(
                                  child: Text(
                                    'Example Answer',
                                    style: context.titleSmall?.copyWith(
                                      color: const Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 12, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'High Quality',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: DS.spacingS),
                            Text(
                              widget.question.answer ?? 'No example answer available for this question.',
                              style: context.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
                    Expanded(
                      child: Text(
                        'Preparation Tips',
                        style: context.titleMedium?.copyWith(
                          color: context.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
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
    final validAnsweredCount = _getValidAnsweredQuestionCount();
    debugPrint(
      'Navigation summary: Valid answers $validAnsweredCount/${widget.questionList.length} questions',
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

  // Helper method to get valid answered question count (200-300 words)
  int _getValidAnsweredQuestionCount() {
    // Save current answer first to ensure accurate count
    final currentText = _userAnswerController.text.trim();
    final currentWordCount = _getWordCount(currentText);
    if (currentWordCount >= 200 && currentWordCount <= 300) {
      _userAnswers[widget.question.id] = currentText;
      _interviewService.saveUserAnswer(widget.question.id, currentText);
    }

    int count = 0;
    for (final question in widget.questionList) {
      final localAnswer = _userAnswers[question.id];
      final globalAnswer = _interviewService.getUserAnswer(question.id);

      String answer = localAnswer ?? globalAnswer;
      if (answer.isNotEmpty) {
        final wordCount = _getWordCount(answer);
        if (wordCount >= 200 && wordCount <= 300) {
          count++;
        }
      }
    }

    debugPrint(
      'Current valid answered question count: $count/${widget.questionList.length}',
    );
    return count;
  }

  // ✨ UPDATED: Word-based quality helpers (200-300 words required)
  Color _getAnswerQualityColor() {
    final wordCount = _getWordCount(_userAnswerController.text);
    if (wordCount >= 200 && wordCount <= 300) return const Color(0xFF10B981); // Green - Perfect
    if (wordCount >= 150 && wordCount < 200) return const Color(0xFF0D9488); // Teal - Close
    if (wordCount > 300) return const Color(0xFFF59E0B); // Amber - Too long
    return const Color(0xFFEF4444); // Red - Too short
  }

  // ✨ NEW: Helper method for difficulty gradient colors
  List<Color> _getDifficultyGradientColors() {
    switch (widget.question.difficulty) {
      case 'entry':
        return [const Color(0xFF10B981), const Color(0xFF6EE7B7)]; // Green gradient
      case 'mid':
        return [const Color(0xFFF59E0B), const Color(0xFFFDE68A)]; // Amber gradient
      case 'senior':
        return [const Color(0xFFEF4444), const Color(0xFFFCA5A5)]; // Red gradient
      default:
        return [const Color(0xFF64748B), const Color(0xFF94A3B8)]; // Gray gradient
    }
  }

  IconData _getAnswerQualityIcon() {
    final wordCount = _getWordCount(_userAnswerController.text);
    if (wordCount >= 200 && wordCount <= 300) return Icons.check_circle;
    if (wordCount >= 150 && wordCount < 200) return Icons.trending_up;
    if (wordCount > 300) return Icons.warning_amber;
    return Icons.edit;
  }

  String _getAnswerQualityText() {
    final wordCount = _getWordCount(_userAnswerController.text);
    if (wordCount >= 200 && wordCount <= 300) return 'Perfect length';
    if (wordCount >= 150 && wordCount < 200) return 'Almost there';
    if (wordCount > 300) return 'Too long';
    return 'Keep writing';
  }

  // ✨ NEW: Check if answer meets submission requirements
  bool _canSubmitAnswer() {
    final wordCount = _getWordCount(_userAnswerController.text);
    return wordCount >= 200 && wordCount <= 300;
  }

  int _getWordCount(String text) {
    return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
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
              category: widget.question.subtopic.isNotEmpty ? widget.question.subtopic : widget.question.category, // 🔧 Use subtopic for better navigation
            ),
          );
        });

        return Scaffold(
          // ✨ ENHANCED APP BAR
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      // Enhanced close button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: const Color(0xFF64748B),
                          onPressed: () {
                            if (_userAnswerController.text.trim().isNotEmpty) {
                              _saveCurrentAnswer();
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      
                      SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacingXs : 16),
                      
                      // Enhanced title with overflow protection
                      Expanded(
                        child: Text(
                          'Practice Mode',
                          style: TextStyle(
                            fontSize: DS.isExtraSmallScreen(context) ? 16 : 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      
                      SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacingXs : DS.spacingS),
                      
                      // Enhanced tips button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.lightbulb, size: 20),
                          color: Colors.white,
                          tooltip: 'View preparation tips',
                          onPressed: _showPreparationTips,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // ✨ NEW: Show Answer button as icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          color: Colors.white,
                          tooltip: 'View example answer',
                          onPressed: _showExampleAnswer,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Enhanced question indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.questionList.length > 1
                              ? 'Question ${widget.currentIndex + 1}/${widget.questionList.length}'
                              : 'Question 1/1',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // ✨ ENHANCED TIMER BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.05),
                          const Color(0xFF10B981).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Timer icon with background
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Timer text with overflow protection
                        Expanded(
                          child: Text(
                            'Time: ${_formatTime(_timeTaken)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        
                        SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),
                        
                        // Word count indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getAnswerQualityColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getAnswerQualityColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getAnswerQualityIcon(),
                                size: 16,
                                color: _getAnswerQualityColor(),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_getWordCount(_userAnswerController.text)}/200-300 words',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getAnswerQualityColor(),
                                ),
                              ),
                            ],
                          ),
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
                                // ✨ ENHANCED Category and difficulty tags with gradients
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      // Enhanced category tag with gradient
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: DS.isExtraSmallScreen(context) ? 6 : DS.spacingS,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF0D9488),
                                              const Color(0xFF5EEAD4),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _getCategoryName(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: DS.isExtraSmallScreen(context) ? 10 : 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),

                                      SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),

                                      // Subtopic with enhanced styling
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: DS.isExtraSmallScreen(context) ? 6 : 8, 
                                          vertical: 4
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF64748B).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          widget.question.subtopic,
                                          style: context.bodySmall?.copyWith(
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                            fontSize: DS.isExtraSmallScreen(context) ? 10 : 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),

                                      SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingS),

                                      // Enhanced difficulty tag with gradient
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: DS.isExtraSmallScreen(context) ? 6 : DS.spacingS,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _getDifficultyGradientColors(),
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getDifficultyGradientColors()[0].withValues(alpha: 0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _getDifficultyText(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: DS.isExtraSmallScreen(context) ? 10 : 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
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
                              
                              // ✨ ENHANCED Text field for user's answer with focus states
                              Container(
                                decoration: BoxDecoration(
                                  color: context.surfaceColor,
                                  borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                  border: Border.all(
                                    color: _isTextFieldFocused ? const Color(0xFF0D9488) : context.colorScheme.outline,
                                    width: _isTextFieldFocused ? 2 : 1,
                                  ),
                                  boxShadow: _isTextFieldFocused ? [
                                    BoxShadow(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      spreadRadius: 4,
                                    ),
                                  ] : null,
                                ),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _userAnswerController,
                                      focusNode: _answerFocusNode,
                                      maxLines: 8,
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

                                    // ✨ ENHANCED Character count bar with quality indicators
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: DS.spacingM,
                                        vertical: DS.spacingS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getAnswerQualityColor().withValues(alpha: 0.05),
                                        border: Border(
                                          top: BorderSide(
                                            color: context.colorScheme.outline.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Quality indicator
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getAnswerQualityColor().withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getAnswerQualityColor().withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getAnswerQualityIcon(),
                                                  size: 14,
                                                  color: _getAnswerQualityColor(),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getAnswerQualityText(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: _getAnswerQualityColor(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingM),
                                          
                                          // Word count requirement with overflow protection
                                          Expanded(
                                            child: Text(
                                              '${_getWordCount(_userAnswerController.text)} words',
                                              style: context.bodySmall?.copyWith(
                                                color: _getAnswerQualityColor(),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          
                                          SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingXs),
                                          
                                          // Requirement indicator with overflow protection
                                          Flexible(
                                            child: Text(
                                              '(200-300 required)',
                                              style: context.bodySmall?.copyWith(
                                                color: context.onSurfaceVariantColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: DS.spacingM),
                            ],
                          ),
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
                        // ✨ ENHANCED Bottom row: Navigation and Grade All with validation
                        Row(
                          children: [
                            // Previous button (secondary action)
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
                                          foregroundColor: context.onSurfaceVariantColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: DS.spacingM),
                                  ],
                                  
                                  // Next/Submit button (primary action with validation)
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: _canSubmitAnswer() 
                                            ? const LinearGradient(
                                                colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: _canSubmitAnswer() ? null : const Color(0xFF94A3B8),
                                        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                        boxShadow: _canSubmitAnswer() ? [
                                          BoxShadow(
                                            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ] : null,
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _canSubmitAnswer()
                                            ? (widget.currentIndex < widget.questionList.length - 1
                                                ? _moveToNextQuestion
                                                : _submitSingleAnswer)
                                            : null,
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
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: _canSubmitAnswer() ? Colors.white : const Color(0xFF64748B),
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(vertical: DS.spacingM),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Grade All button (enhanced styling)
                                  if (widget.questionList.length > 1) ...[
                                    const SizedBox(width: DS.spacingM),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: _getValidAnsweredQuestionCount() > 0
                                              ? const LinearGradient(
                                                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: _getValidAnsweredQuestionCount() > 0 
                                              ? null 
                                              : context.surfaceVariantColor,
                                          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                          boxShadow: _getValidAnsweredQuestionCount() > 0 ? [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ] : null,
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final validCount = _getValidAnsweredQuestionCount();
                                            if (validCount > 0) {
                                              _submitAllAnswers();
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Please provide at least one answer with 200-300 words before submitting'),
                                                  duration: Duration(seconds: 3),
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            _getValidAnsweredQuestionCount() > 0 ? Icons.grading : Icons.grading_outlined,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Grade All\n(${_getValidAnsweredQuestionCount()}/${widget.questionList.length})',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 11, height: 1.2),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: _getValidAnsweredQuestionCount() > 0
                                                ? Colors.white
                                                : context.onSurfaceVariantColor,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(vertical: DS.spacingS),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                                            ),
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
