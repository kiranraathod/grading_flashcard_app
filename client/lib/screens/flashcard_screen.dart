import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../models/answer.dart';
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
import '../services/network_service.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/answer_input_widget.dart';
import 'result_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final List<Flashcard> flashcards;

  const FlashcardScreen({super.key, required this.flashcards});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  final SpeechToTextService _speechService = SpeechToTextService();
  bool _isLoading = false;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _speechService.initialize();

    // Check network status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final networkService = Provider.of<NetworkService>(
        context,
        listen: false,
      );
      networkService.checkConnectivity();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (_currentIndex < widget.flashcards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleMarkForReview() {
    setState(() {
      widget.flashcards[_currentIndex].isMarkedForReview =
          !widget.flashcards[_currentIndex].isMarkedForReview;
    });
  }

  void _toggleOfflineMode() {
    setState(() {
      _isOfflineMode = !_isOfflineMode;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOfflineMode
              ? 'Offline mode enabled - using local grading'
              : 'Online mode enabled - using LLM grading',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitAnswer(String userAnswer) async {
    setState(() => _isLoading = true);

    try {
      // Create initial answer object
      final answer = Answer(
        flashcardId: widget.flashcards[_currentIndex].id,
        question: widget.flashcards[_currentIndex].question,
        userAnswer: userAnswer,
      );

      // Check network status from provider
      final networkService = Provider.of<NetworkService>(
        context,
        listen: false,
      );
      final bool canUseOnlineGrading =
          networkService.isOnline &&
          networkService.isServerReachable &&
          !_isOfflineMode;

      if (canUseOnlineGrading) {
        // Try online grading
        try {
          final gradedAnswer = await _apiService.gradeAnswer(answer);

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ResultScreen(
                    answer: gradedAnswer,
                    correctAnswer: widget.flashcards[_currentIndex].answer,
                    onContinue: () {
                      Navigator.pop(context);
                      _navigateToNext();
                    },
                  ),
            ),
          );
        } catch (e) {
          if (!mounted) return;

          // Show LLM not connected error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'LLM is not connected. Please check your connection and try again.',
              ),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show LLM not connected message
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'LLM is not connected. Please check your connection and try again.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting answer: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Network status from provider
    final networkService = Provider.of<NetworkService>(context);
    final bool hasConnectivityIssues =
        !networkService.isOnline || !networkService.isServerReachable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          // Toggle offline mode button
          IconButton(
            icon: Icon(_isOfflineMode ? Icons.cloud_off : Icons.cloud),
            onPressed: _toggleOfflineMode,
            tooltip:
                _isOfflineMode
                    ? 'Switch to online mode'
                    : 'Switch to offline mode',
          ),

          // Bookmark button
          IconButton(
            icon: Icon(
              widget.flashcards[_currentIndex].isMarkedForReview
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            onPressed: _toggleMarkForReview,
            tooltip: 'Mark for review',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity banner with updated text
          if (hasConnectivityIssues && !_isOfflineMode)
            Container(
              width: double.infinity,
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'LLM is not connected. Grading feature unavailable.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => networkService.checkConnectivity(),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentIndex = index);
                            },
                            itemCount: widget.flashcards.length,
                            itemBuilder: (context, index) {
                              return FlashcardWidget(
                                flashcard: widget.flashcards[index],
                              );
                            },
                          ),
                        ),
                        AnswerInputWidget(
                          speechService: _speechService,
                          onSubmit: _submitAnswer,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    _currentIndex > 0
                                        ? _navigateToPrevious
                                        : null,
                                child: const Text('Previous'),
                              ),
                              Text(
                                '${_currentIndex + 1}/${widget.flashcards.length}',
                              ),
                              ElevatedButton(
                                onPressed:
                                    _currentIndex < widget.flashcards.length - 1
                                        ? _navigateToNext
                                        : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
