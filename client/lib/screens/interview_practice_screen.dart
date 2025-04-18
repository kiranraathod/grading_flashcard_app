import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import 'dart:async';

class InterviewPracticeScreen extends StatefulWidget {
  final InterviewQuestion question;
  final List<InterviewQuestion> questionList;
  final int currentIndex;

  const InterviewPracticeScreen({
    Key? key,
    required this.question,
    required this.questionList,
    required this.currentIndex,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.question.isCompleted;
    // Start a timer to track how long the user spends on this question
    _startTimer();
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
    super.dispose();
  }
  
  // Clear the user's answer
  void _clearUserAnswer() {
    setState(() {
      _userAnswerController.clear();
    });
  }
  
  // Save the user's answer (could be extended to store in the service)
  void _saveUserAnswer() {
    // Currently just saving to memory, but could be extended to persist
    // For example: _interviewService.saveUserAnswer(widget.question.id, _userAnswerController.text);
    debugPrint('User answer saved: ${_userAnswerController.text}');
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
      _userAnswerController.text = _userAnswerController.text + 
          ((_userAnswerController.text.isEmpty) ? '' : ' ') +
          'Voice input would appear here in a real implementation.';
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
  Color _getDifficultyColor() {
    switch (widget.question.difficulty) {
      case 'entry':
        return Colors.green.shade100;
      case 'mid':
        return Colors.yellow.shade100;
      case 'senior':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // Helper method to get difficulty text color
  Color _getDifficultyTextColor() {
    switch (widget.question.difficulty) {
      case 'entry':
        return Colors.green.shade800;
      case 'mid':
        return Colors.yellow.shade800;
      case 'senior':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
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
  Color _getCategoryColor() {
    switch (widget.question.category) {
      case 'technical':
        return Colors.blue.shade100;
      case 'applied':
        return Colors.green.shade100;
      case 'case':
        return Colors.purple.shade100;
      case 'behavioral':
        return Colors.yellow.shade100;
      case 'job':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Practice Mode',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Progress indicator
          Center(
            child: Text(
              'Question ${widget.currentIndex + 1}/${widget.questionList.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: DS.spacingM),
        ],
      ),
      body: Column(
        children: [
          // Timer bar at the top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DS.spacingL, vertical: DS.spacingS),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(
                  Icons.timer,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: DS.spacingS),
                Text(
                  'Time: ${_formatTime(_timeTaken)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                // Completion status
                Checkbox(
                  value: _isCompleted,
                  onChanged: (value) => _toggleCompletion(),
                  activeColor: AppColors.primary,
                ),
                const Text(
                  'Mark as Complete',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                                color: _getCategoryColor(),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getCategoryName(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: DS.spacingXs),
                            
                            // Subtopic
                            Text(
                              '• ${widget.question.subtopic}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Difficulty
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DS.spacingS,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _getDifficultyText(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getDifficultyTextColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: DS.spacingM),
                        
                        // Question text
                        Text(
                          widget.question.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preparation Guide',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          
                          const SizedBox(height: DS.spacingS),
                          
                          // Tips based on category
                          _buildPrepTips(),
                          
                          const SizedBox(height: DS.spacingM),
                          
                          // User answer input area
                          const Text(
                            'Your Answer:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          
                          const SizedBox(height: DS.spacingXs),
                          
                          // Text field for user's answer
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _userAnswerController,
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer here...',
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
                                    color: Colors.grey.shade50,
                                    border: Border(
                                      top: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Voice input button
                                      IconButton(
                                        onPressed: _isListening ? _stopListening : _startListening,
                                        icon: Icon(
                                          _isListening ? Icons.mic : Icons.mic_none,
                                          color: _isListening ? Colors.red : Colors.grey.shade700,
                                        ),
                                        tooltip: _isListening ? 'Stop recording' : 'Start voice input',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      
                                      const SizedBox(width: DS.spacingXs),
                                      
                                      Text(
                                        _isListening ? 'Recording...' : 'Voice input',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _isListening ? Colors.red : Colors.grey.shade700,
                                        ),
                                      ),
                                      
                                      const Spacer(),
                                      
                                      // Character count
                                      Text(
                                        '${_userAnswerController.text.length} chars',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
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
                                    side: BorderSide(color: Colors.grey.shade400),
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
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
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
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: DS.spacingXs),
                                    const Text(
                                      'Your Answer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: DS.spacingM),
                                
                                Text(
                                  _userAnswerController.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        // Example answer area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(DS.spacingM),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: DS.spacingXs),
                                  const Text(
                                    'Example Answer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
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
                              Divider(color: Colors.grey.shade200),
                              
                              const SizedBox(height: DS.spacingM),
                              
                              // Answer content
                              Text(
                                widget.question.answer ?? 'No answer available for this question.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textPrimary,
                                ),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                    color: _isCompleted ? AppColors.primary : Colors.grey.shade600,
                  ),
                  label: Text(
                    _isCompleted ? 'Completed' : 'Mark Complete',
                    style: TextStyle(
                      color: _isCompleted ? AppColors.primary : Colors.grey.shade600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _isCompleted ? AppColors.primary : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    ),
                  ),
                ),
                
                // Next question button
                ElevatedButton.icon(
                  onPressed: _moveToNextQuestion,
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                  ),
                  label: const Text('Next Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: DS.spacingXs),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}