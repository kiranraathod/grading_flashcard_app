import 'package:flutter/material.dart';
import '../models/interview_question.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import 'interview_practice_screen.dart';

class InterviewPracticeBatchScreen extends StatefulWidget {
  final List<InterviewQuestion> questions;
  final String categoryName;
  
  const InterviewPracticeBatchScreen({
    Key? key,
    required this.questions,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<InterviewPracticeBatchScreen> createState() => _InterviewPracticeBatchScreenState();
}

class _InterviewPracticeBatchScreenState extends State<InterviewPracticeBatchScreen> {
  List<InterviewQuestion> _selectedQuestions = [];
  bool _showOnlyUncompleted = false;
  
  @override
  void initState() {
    super.initState();
    // Initially select all questions
    _selectedQuestions = List.from(widget.questions);
  }
  
  // Start practice with selected questions
  void _startPractice() {
    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one question to practice.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Navigate to the first question
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewPracticeScreen(
          question: _selectedQuestions[0],
          questionList: _selectedQuestions,
          currentIndex: 0,
        ),
      ),
    ).then((_) {
      // Refresh the question list when returning
      setState(() {});
    });
  }
  
  // Toggle selection of a question
  void _toggleQuestionSelection(InterviewQuestion question) {
    setState(() {
      if (_selectedQuestions.contains(question)) {
        _selectedQuestions.remove(question);
      } else {
        _selectedQuestions.add(question);
      }
    });
  }
  
  // Select or deselect all questions
  void _toggleSelectAll() {
    setState(() {
      if (_selectedQuestions.length == _getFilteredQuestions().length) {
        // If all are selected, deselect all
        _selectedQuestions.clear();
      } else {
        // Otherwise, select all
        _selectedQuestions = List.from(_getFilteredQuestions());
      }
    });
  }
  
  // Get filtered questions based on completion status
  List<InterviewQuestion> _getFilteredQuestions() {
    if (_showOnlyUncompleted) {
      return widget.questions.where((q) => !q.isCompleted).toList();
    }
    return widget.questions;
  }
  
  // Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
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
  
  // Get difficulty color
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
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
  
  // Get difficulty text
  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
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

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _getFilteredQuestions();
    
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
          // Practice setup options
          Container(
            padding: const EdgeInsets.all(DS.spacingM),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Practice Setup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: DS.spacingS),
                
                // Filter options
                Row(
                  children: [
                    // Show only uncompleted toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _showOnlyUncompleted,
                          onChanged: (value) {
                            setState(() {
                              _showOnlyUncompleted = value ?? false;
                              // Reset selections when filter changes
                              _selectedQuestions = _showOnlyUncompleted
                                ? widget.questions.where((q) => !q.isCompleted).toList()
                                : List.from(widget.questions);
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Text(
                          'Show only uncompleted',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Select all toggle
                    TextButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: Icon(
                        _selectedQuestions.length == filteredQuestions.length
                            ? Icons.check_box
                            : _selectedQuestions.isEmpty
                                ? Icons.check_box_outline_blank
                                : Icons.indeterminate_check_box,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        _selectedQuestions.length == filteredQuestions.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: DS.spacingM),
                
                // Start practice button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startPractice,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      'Start Practice (${_selectedQuestions.length} Questions)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: DS.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Questions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(DS.spacingM),
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = filteredQuestions[index];
                final isSelected = _selectedQuestions.contains(question);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: DS.spacingS),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _toggleQuestionSelection(question),
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.all(DS.spacingM),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkbox
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleQuestionSelection(question),
                            activeColor: AppColors.primary,
                          ),
                          
                          // Question content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question text
                                Text(
                                  question.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                
                                const SizedBox(height: DS.spacingS),
                                
                                // Question metadata
                                Row(
                                  children: [
                                    // Category
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(question.category),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        question.subtopic,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: DS.spacingXs),
                                    
                                    // Difficulty
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(question.difficulty),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getDifficultyText(question.difficulty),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    
                                    const Spacer(),
                                    
                                    // Completion status
                                    if (question.isCompleted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 10,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              'Completed',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}