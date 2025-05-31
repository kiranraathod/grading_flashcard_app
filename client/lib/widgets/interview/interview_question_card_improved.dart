import 'package:flutter/material.dart';
import '../../models/interview_question.dart';
import '../../utils/design_system.dart';
import '../../utils/theme_utils.dart';

/// Improved version of InterviewQuestionCard that matches the UI style
/// from the "Turing data scientist" screen (first screenshot)
class InterviewQuestionCardImproved extends StatelessWidget {
  final InterviewQuestion question;
  final VoidCallback onPractice;
  final VoidCallback onViewAnswer;
  final VoidCallback onToggleStar;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback? onDelete; // Optional delete callback
  
  const InterviewQuestionCardImproved({
    super.key,
    required this.question,
    required this.onPractice,
    required this.onViewAnswer,
    required this.onToggleStar,
    required this.onShare,
    required this.onEdit,
    this.onDelete, // Optional delete functionality
  });
  
  // Helper method to get category color
  Color _getCategoryColor(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    switch (question.category) {
      case 'technical':
        return isDarkMode ? const Color(0xFF2D4BA7).withValues(alpha: 0.8) : Colors.blue.shade100;
      case 'applied':
        return isDarkMode ? const Color(0xFF1A6352).withValues(alpha: 0.8) : Colors.green.shade100;
      case 'case':
        return isDarkMode ? const Color(0xFF6D2FB2).withValues(alpha: 0.8) : Colors.purple.shade100;
      case 'behavioral':
        return isDarkMode ? const Color(0xFFA66119).withValues(alpha: 0.8) : Colors.yellow.shade100;
      case 'job':
        return isDarkMode ? const Color(0xFFB72424).withValues(alpha: 0.8) : Colors.red.shade100;
      default:
        return isDarkMode ? const Color(0xFF555B67).withValues(alpha: 0.8) : Colors.grey.shade100;
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
        return (isDarkMode ? const Color(0xFF1A6352).withValues(alpha: 0.8) : Colors.green.shade100, 'Entry Level');
      case 'mid':
        return (isDarkMode ? const Color(0xFFA66119).withValues(alpha: 0.8) : Colors.amber.shade100, 'Mid Level');
      case 'senior':
        return (isDarkMode ? const Color(0xFFB72424).withValues(alpha: 0.8) : Colors.red.shade100, 'Senior Level');
      default:
        return (isDarkMode ? const Color(0xFF555B67).withValues(alpha: 0.8) : Colors.grey.shade100, 'Unspecified');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final (difficultyColor, difficultyName) = _getDifficultyStyle(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DS.spacingM),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF2A2A30) : Colors.white,
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        border: Border.all(
          color: context.isDarkMode 
              ? Colors.white.withValues(alpha: 0.2)  
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode 
                ? Colors.black.withValues(alpha: 0.2)  
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
                          color: context.isDarkMode 
                              ? Colors.white  
                              : const Color(0xFF1F2937),
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
                
                // Category, subtopic, and difficulty as pill-shaped tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                    
                    // Subtopic as a pill (like in the first screenshot)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DS.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        question.subtopic,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.isDarkMode ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    
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
                          color: context.isDarkMode
                              ? const Color(0xFF34D399).withValues(alpha: 0.15)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: context.isDarkMode
                                ? const Color(0xFF34D399).withValues(alpha: 0.3)
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: context.isDarkMode
                                  ? const Color(0xFF34D399)
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.isDarkMode
                                    ? const Color(0xFF34D399)
                                    : Colors.green.shade700,
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
                            ? context.primaryColor.withValues(alpha: 0.2)
                            : Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: DS.spacingS),
                    
                    // View Answer button
                    TextButton(
                      onPressed: onViewAnswer,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: context.primaryColor,
                      ),
                      child: Text(
                        'View Answer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.primaryColor,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Share, Edit, and Delete buttons
                    Row(
                      children: [
                        IconButton(
                          onPressed: onShare,
                          icon: Icon(
                            Icons.share,
                            size: 18,
                            color: context.isDarkMode 
                                ? Colors.white.withValues(alpha: 0.7)
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
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade500,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                        
                        // Delete button (if callback provided)
                        if (onDelete != null) ...[
                          const SizedBox(width: DS.spacingS),
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                            ),
                            color: Colors.red,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                          ),
                        ],
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