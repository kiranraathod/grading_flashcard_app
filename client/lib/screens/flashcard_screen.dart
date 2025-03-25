import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/answer.dart';
import '../services/api_service.dart';
import '../services/speech_to_text_service.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _speechService.initialize();
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

  Future<void> _submitAnswer(String userAnswer) async {
    setState(() => _isLoading = true);

    try {
      final answer = Answer(
        flashcardId: widget.flashcards[_currentIndex].id,
        question: widget.flashcards[_currentIndex].question,
        userAnswer: userAnswer,
      );

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: Icon(
              widget.flashcards[_currentIndex].isMarkedForReview
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            onPressed: _toggleMarkForReview,
          ),
        ],
      ),
      body:
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
                              _currentIndex > 0 ? _navigateToPrevious : null,
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
    );
  }
}
