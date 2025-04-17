import 'package:flutter/material.dart';
import '../../models/interview_question.dart';
import '../../utils/design_system.dart';
import '../../utils/colors.dart';

class InterviewQuestionCard extends StatelessWidget {
  final InterviewQuestion question;
  final VoidCallback onPractice;
  final VoidCallback onViewAnswer;
  final VoidCallback onToggleStar;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  
  const InterviewQuestionCard({
    super.key,
    required this.question,
    required this.onPractice,
    required this.onViewAnswer,
    required this.onToggleStar,
    required this.onShare,
    required this.onEdit,
  });
  
  // Helper method to get category color
  Color _getCategoryColor() {
    switch (question.category) {
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
    switch (question.category) {
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
  
  // Helper method to get difficulty style
  (Color, String) _getDifficultyStyle() {
    switch (question.difficulty) {
      case 'entry':
        return (Colors.green.shade100, 'Entry Level');
      case 'mid':
        return (Colors.yellow.shade100, 'Mid Level');
      case 'senior':
        return (Colors.red.shade100, 'Senior Level');
      default:
        return (Colors.grey.shade100, 'Unspecified');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final (difficultyColor, difficultyName) = _getDifficultyStyle();
    
    return Container(
      margin: const EdgeInsets.only(bottom: DS.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Container(
            padding: const EdgeInsets.all(DS.spacingM),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.primary, 
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text and star
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        question.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleStar,
                      icon: Icon(
                        question.isStarred ? Icons.star : Icons.star_border,
                        color: question.isStarred ? Colors.amber : Colors.grey.shade400,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: DS.spacingS),
                
                // Category and difficulty
                Row(
                  children: [
                    // Category badge
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
                      '• ${question.subtopic}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DS.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        difficultyName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: DS.spacingM),
                
                // Action buttons
                Row(
                  children: [
                    // Practice button
                    TextButton(
                      onPressed: onPractice,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Practice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: DS.spacingL),
                    
                    // View Answer button
                    TextButton(
                      onPressed: onViewAnswer,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'View Answer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Share and Edit buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: onShare,
                          icon: Icon(
                            Icons.share,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                        
                        const SizedBox(width: DS.spacingS),
                        
                        IconButton(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}