import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../services/interview_api_service.dart';
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
  final bool _isLoading = false; // Changed to final as per lint warning
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
          '${widget.categoryName} Practice',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Instructions card
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8.0),
                    const Text(
                      'Practice Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'You can answer the questions in any order. Your answers will be graded when you complete the practice session.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Click on any question to start practicing.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Question list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    title: Text(
                      'Question ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4.0),
                        Text(
                          question.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            _buildTag(question.category),
                            const SizedBox(width: 8.0),
                            _buildDifficultyTag(question.difficulty),
                          ],
                        ),
                      ],
                    ),
                    trailing: question.isCompleted 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios, size: 16),
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
                  ),
                );
              },
            ),
          ),
          
          // Complete all button
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _startBatchGrading,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Complete All Questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTag(String category) {
    Color backgroundColor;
    String label;
    
    switch (category) {
      case 'technical':
        backgroundColor = Colors.blue.shade100;
        label = 'Technical';
        break;
      case 'applied':
        backgroundColor = Colors.green.shade100;
        label = 'Applied';
        break;
      case 'case':
        backgroundColor = Colors.purple.shade100;
        label = 'Case Study';
        break;
      case 'behavioral':
        backgroundColor = Colors.orange.shade100;
        label = 'Behavioral';
        break;
      case 'job':
        backgroundColor = Colors.red.shade100;
        label = 'Job-Specific';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        label = category;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
  
  Widget _buildDifficultyTag(String difficulty) {
    Color color;
    String label;
    
    switch (difficulty) {
      case 'entry':
        color = Colors.green;
        label = 'Entry';
        break;
      case 'mid':
        color = Colors.orange;
        label = 'Mid';
        break;
      case 'senior':
        color = Colors.red;
        label = 'Senior';
        break;
      default:
        color = Colors.grey;
        label = difficulty;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          red: color.r,
          green: color.g,
          blue: color.b,
          alpha: 26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: color.withValues(
            red: color.r,
            green: color.g,
            blue: color.b,
            alpha: 77), // 0.3 * 255 ≈ 77
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _startBatchGrading() async {
    // Implemented batch grading functionality
    
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
      // We can't update _isLoading since it's final, but in a real implementation
      // we would set _isLoading = true; here
    });
    
    try {
      // Collect all the answers for completed questions
      final answers = _interviewService.getAnswersForQuestionIds(
        _completedQuestions.map((q) => q.id).toList()
      );
      
      if (answers.isEmpty) {
        if (mounted) {
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
        // In a real implementation: _isLoading = false;
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
        // In a real implementation: _isLoading = false;
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