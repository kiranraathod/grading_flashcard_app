import 'package:flutter/material.dart';
import '../../models/interview_question.dart';
import '../../utils/design_system.dart';
import '../../utils/colors.dart';
import '../../utils/theme_utils.dart';

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
  Color _getCategoryColor(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    switch (question.category) {
      case 'technical':
        return isDarkMode ? const Color(0xFF1E3A8A) : Colors.blue.shade100;
      case 'applied':
        return isDarkMode ? const Color(0xFF064E3B) : Colors.green.shade100;
      case 'case':
        return isDarkMode ? const Color(0xFF4C1D95) : Colors.purple.shade100;
      case 'behavioral':
        return isDarkMode ? const Color(0xFF854D0E) : Colors.yellow.shade100;
      case 'job':
        return isDarkMode ? const Color(0xFF991B1B) : Colors.red.shade100;
      default:
        return isDarkMode ? const Color(0xFF374151) : Colors.grey.shade100;
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
  (Color, String) _getDifficultyStyle(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    switch (question.difficulty) {
      case 'entry':
        return (isDarkMode ? const Color(0xFF064E3B) : Colors.green.shade100, 'Entry Level');
      case 'mid':
        return (isDarkMode ? const Color(0xFF854D0E) : Colors.yellow.shade100, 'Mid Level');
      case 'senior':
        return (isDarkMode ? const Color(0xFF991B1B) : Colors.red.shade100, 'Senior Level');
      default:
        return (isDarkMode ? const Color(0xFF374151) : Colors.grey.shade100, 'Unspecified');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final (difficultyColor, difficultyName) = _getDifficultyStyle(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DS.spacingM),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        border: Border.all(
          color: context.isDarkMode 
              ? Colors.white.withValues(red: 255.0, green: 255.0, blue: 255.0, alpha: 25.0)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode 
                ? Colors.black.withValues(red: 0.0, green: 0.0, blue: 0.0, alpha: 76.0)
                : const Color.fromRGBO(0, 0, 0, 0.05),
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
                  color: context.primaryColor, 
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.onSurfaceColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleStar,
                      icon: Icon(
                        question.isStarred ? Icons.star : Icons.star_border,
                        color: question.isStarred ? Colors.amber : context.onSurfaceVariantColor,
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
                        color: _getCategoryColor(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCategoryName(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: DS.spacingXs),
                    
                    // Subtopic
                    Text(
                      '• ${question.subtopic}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceVariantColor,
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
                          color: context.isDarkMode ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: DS.spacingM),
                
                // Status and action buttons
                Row(
                  children: [
                    // Completion indicator
                    if (question.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 2
                        ),
                        margin: const EdgeInsets.only(right: DS.spacingS),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
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
                    // Practice button
                    TextButton.icon(
                      onPressed: onPractice,
                      icon: Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: context.isDarkMode ? Colors.white : null,
                      ),
                      label: Text(
                        'Practice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode ? Colors.white : null,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: context.primaryColor,
                        backgroundColor: context.isDarkMode 
                            ? context.primaryColor.withOpacity(0.2)
                            : Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                        foregroundColor: context.isDarkMode 
                            ? context.primaryColor
                            : AppColors.primary,
                      ),
                      child: Text(
                        'View Answer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode 
                              ? context.primaryColor
                              : null,
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
                            color: context.isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade500,
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
                            color: context.isDarkMode 
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade500,
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