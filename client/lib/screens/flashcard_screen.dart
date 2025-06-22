import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard.dart';
import '../models/answer.dart';
import '../models/flashcard_set.dart';
import '../models/simple_auth_state.dart';
import '../services/api_service.dart';
import '../services/network_service.dart';
import '../services/unified_action_middleware.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/answer_input_widget.dart';
import 'result_screen.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final List<Flashcard> flashcards;
  final int initialCardIndex;
  final String? setTitle; // Optional set title for display

  const FlashcardScreen({
    super.key, 
    required this.flashcards,
    this.initialCardIndex = 0,
    this.setTitle,
  });

  // Factory constructor to create from a set
  static FlashcardScreen fromSet(FlashcardSet set, {Key? key, int initialCardIndex = 0}) {
    return FlashcardScreen(
      key: key,
      flashcards: set.flashcards,
      setTitle: set.title,
      initialCardIndex: initialCardIndex,
    );
  }

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  late int _currentIndex;
  String _userAnswer = '';
  bool _isSubmitting = false;
  bool _showAnswer = false;
  late ApiService _apiService;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialCardIndex;
    // Initialize services directly since we're using Riverpod now
    _apiService = ApiService();
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < widget.flashcards.length - 1) {
        _currentIndex++;
        _userAnswer = '';
        _showAnswer = false;
      }
    });
  }  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _userAnswer = '';
        _showAnswer = false;
      }
    });
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _handleUserAnswer(String answer) {
    setState(() {
      _userAnswer = answer;
    });
  }

  Future<void> _submitAnswer() async {
    if (_userAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an answer'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check network connectivity
      final networkService = NetworkService();
      
      if (!networkService.isOnline) {
        // Handle offline mode
        _toggleAnswer();
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final currentCard = widget.flashcards[_currentIndex];
      final answer = Answer(
        flashcardId: currentCard.id,
        question: currentCard.question,
        userAnswer: _userAnswer,
        correctAnswer: currentCard.answer,
      );

      // 🎯 UPDATED: Use unified action middleware for authentication and quota enforcement
      final middleware = ref.read(unifiedActionMiddlewareProvider);
      
      // Log current state for testing
      final usageSummary = middleware.getUsageSummary();
      debugPrint('🔍 Testing Auth Trigger - Current usage: ${usageSummary['totalUsage']}/${usageSummary['totalLimit']}');
      debugPrint('🔍 Can perform action: ${middleware.canPerformAction(ActionType.flashcardGrading)}');
      
      // Use executeWithQuota for atomic quota check and consumption
      final gradedAnswer = await middleware.executeWithQuota<Answer>(
        ActionType.flashcardGrading,
        () async {
          debugPrint('🔍 Proceeding with grading - calling API');
          return await _apiService.gradeAnswer(answer);
        },
        context: context,
        source: 'FlashcardScreen.submitAnswer',
      );
      
      if (gradedAnswer == null) {
        // Action was blocked by quota enforcement
        debugPrint('❌ Grading action blocked by quota enforcement');
        final statusMessage = middleware.getStatusMessage();
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMessage),
            backgroundColor: Colors.blue,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      
      debugPrint('✅ Grading completed successfully');
      final updatedSummary = middleware.getUsageSummary();
      debugPrint('📊 Updated usage: ${updatedSummary['totalUsage']}/${updatedSummary['totalLimit']}');
      
      if (!mounted) return;
      
      // Navigate to result screen for this card
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            answer: gradedAnswer,
            correctAnswer: currentCard.answer,
            onContinue: _nextCard,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Fallback to showing the answer directly
      _toggleAnswer();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = widget.flashcards[_currentIndex];
    final networkService = NetworkService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setTitle ?? 'Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _toggleAnswer,
            tooltip: 'Show Answer',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlashcardWidget(
              flashcard: currentCard,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentIndex > 0 ? _previousCard : null,
                  tooltip: 'Previous Card',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _nextCard,
                  tooltip: 'Next Card',
                ),
              ],
            ),
          ),
          AnswerInputWidget(
            onSubmit: (value) {
              _handleUserAnswer(value);
              _submitAnswer();
            },
            isDisabled: _isSubmitting || !networkService.isOnline,
          ),
        ],
      ),
    );
  }
}