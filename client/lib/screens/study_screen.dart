import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../models/answer.dart' as answer_model;
import '../services/speech_to_text_service.dart';
import '../services/api_service.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/answer_input_widget.dart';
import 'result_screen.dart';

class StudyScreen extends StatefulWidget {
  final FlashcardSet set;

  const StudyScreen({super.key, required this.set});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  final SpeechToTextService _speechService = SpeechToTextService();
  bool _isLoading = false;
  bool _isMarkedForReview = false;

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
    if (_currentIndex < widget.set.flashcards.length - 1) {
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
      _isMarkedForReview = !_isMarkedForReview;
    });
  }

  Future<void> _submitAnswer(String userAnswer) async {
    setState(() => _isLoading = true);

    try {
      // Using the explicit constructor from the Answer model
      final answerObj = answer_model.Answer(
        flashcardId: widget.set.flashcards[_currentIndex].id,
        question: widget.set.flashcards[_currentIndex].question,
        userAnswer: userAnswer,
      );

      final gradedAnswer = await _apiService.gradeAnswer(answerObj);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            answer: gradedAnswer,
            correctAnswer: widget.set.flashcards[_currentIndex].answer,
            onContinue: () {
              Navigator.pop(context);
              _navigateToNext();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting answer: $e')),
        );
      }
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
        title: Text(widget.set.title),
        actions: [
          IconButton(
            icon: Icon(
              _isMarkedForReview ? Icons.bookmark : Icons.bookmark_border,
              color: _isMarkedForReview ? Colors.orange : null,
            ),
            onPressed: _toggleMarkForReview,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _isMarkedForReview = false;
                      });
                    },
                    itemCount: widget.set.flashcards.length,
                    itemBuilder: (context, index) {
                      return FlashcardWidget(
                        flashcard: widget.set.flashcards[index],
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
                        onPressed: _currentIndex > 0 ? _navigateToPrevious : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Previous'),
                      ),
                      Text(
                        '${_currentIndex + 1}/${widget.set.flashcards.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _currentIndex < widget.set.flashcards.length - 1
                            ? _navigateToNext
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          foregroundColor: Colors.white,
                        ),
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
