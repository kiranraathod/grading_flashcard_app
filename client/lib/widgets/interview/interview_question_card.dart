import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/interview_question.dart';
import '../../utils/design_system.dart';
import '../../utils/theme_utils.dart';
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
  Color _getCategoryColor(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    switch (question.category) {
      case 'technical':
        return AppColors.getCategoryColor('technical', isDarkMode: isDarkMode).withValues(alpha: 0.1);
      case 'applied':
        return AppColors.getCategoryColor('behavioral', isDarkMode: isDarkMode).withValues(alpha: 0.1);
      case 'case':
        return AppColors.getCategoryColor('leadership', isDarkMode: isDarkMode).withValues(alpha: 0.1);
      case 'behavioral':
        return AppColors.getCategoryColor('situational', isDarkMode: isDarkMode).withValues(alpha: 0.1);
      case 'job':
        return AppColors.getCategoryColor('general', isDarkMode: isDarkMode).withValues(alpha: 0.1);
      default:
        return AppColors.getCategoryColor('general', isDarkMode: isDarkMode).withValues(alpha: 0.1);
    }
  }
  
  // Helper method to get category name
  String _getCategoryName(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (question.category) {
      case 'technical':
        return localizations.technicalKnowledge;
      case 'applied':
        return localizations.appliedSkills;
      case 'case':
        return localizations.caseStudies;
      case 'behavioral':
        return localizations.behavioralQuestions;
      case 'job':
        return localizations.jobSpecific;
      default:
        return localizations.other;
    }
  }
  
  // Helper method to get difficulty style
  (Color, String) _getDifficultyStyle(BuildContext context) {
    final isDarkMode = context.isDarkMode;
    final localizations = AppLocalizations.of(context);
    switch (question.difficulty) {
      case 'entry':
        return (AppColors.getDifficultyColor('easy', isDarkMode: isDarkMode).withValues(alpha: 0.1), localizations.entryLevel);
      case 'mid':
        return (AppColors.getDifficultyColor('medium', isDarkMode: isDarkMode).withValues(alpha: 0.1), localizations.midLevel);
      case 'senior':
        return (AppColors.getDifficultyColor('hard', isDarkMode: isDarkMode).withValues(alpha: 0.1), localizations.seniorLevel);
      default:
        return (AppColors.getTextSecondary(isDarkMode).withValues(alpha: 0.1), localizations.unspecified);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final (difficultyColor, difficultyName) = _getDifficultyStyle(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DS.spacingM),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        border: Border.all(
          color: context.outlineColor,
        ),
        boxShadow: context.cardShadow,
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
                          fontSize: DS.bodyLarge.fontSize, // 16px from design system
                          fontWeight: FontWeight.w500,
                          color: ThemedColors.getTextPrimary(context),
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
                      iconSize: DS.iconSizeS, // 20px
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
                        borderRadius: BorderRadius.circular(DS.borderRadiusMedium + 4), // ~16px
                      ),
                      child: Text(
                        _getCategoryName(context),
                        style: TextStyle(
                          fontSize: DS.bodySmall.fontSize, // 12px from design system
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
                        fontSize: DS.bodySmall.fontSize! + 1, // 13px (12+1)
                        color: ThemedColors.getTextSecondary(context),
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
                        borderRadius: BorderRadius.circular(DS.borderRadiusMedium + 4), // ~16px
                      ),
                      child: Text(
                        difficultyName,
                        style: TextStyle(
                          fontSize: DS.bodySmall.fontSize, // 12px from design system
                          fontWeight: FontWeight.w500,
                          color: ThemedColors.getTextPrimary(context),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: DS.spacingXs, 
                          vertical: DS.spacing2xs * 0.5 // 2px
                        ),
                        margin: const EdgeInsets.only(right: DS.spacingS),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF34D399).withValues(alpha: 0.15)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(DS.borderRadiusXs),
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
                              size: DS.iconSizeXs - 2, // 14px
                              color: context.successColor,
                            ),
                            const SizedBox(width: DS.spacing2xs),
                            Text(
                              AppLocalizations.of(context).completedStatus,
                              style: TextStyle(
                                fontSize: DS.bodySmall.fontSize, // 12px
                                fontWeight: FontWeight.w500,
                                color: context.successColor,
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
                        size: DS.iconSizeXs,
                        color: context.primaryColor,
                      ),
                      label: Text(
                        AppLocalizations.of(context).practiceButton,
                        style: TextStyle(
                          fontSize: DS.bodyMedium.fontSize, // 14px
                          fontWeight: FontWeight.w500,
                          color: context.primaryColor,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: DS.spacingXs, vertical: DS.spacing2xs),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: context.primaryColor,
                        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DS.borderRadiusMedium + 4), // ~16px
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: DS.spacingL),
                    
                    // View Answer button
                    ElevatedButton(
                      onPressed: onViewAnswer,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: DS.spacingS, vertical: DS.spacing2xs + 2), // 12px, 6px
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        backgroundColor: context.isDarkMode 
                            ? context.successColor.withValues(alpha: 0.15)
                            : context.successColor.withValues(alpha: 0.1),
                        foregroundColor: context.successColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                          side: BorderSide(
                            color: context.successColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).viewAnswerButton,
                        style: TextStyle(
                          fontSize: DS.bodyLarge.fontSize,  // 16px from design system
                          fontWeight: FontWeight.w700,  // Bold for better readability
                          letterSpacing: 0.3,  // Slightly increased letter spacing
                          color: context.successColor,
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
                            size: DS.iconSizeXs + 2, // 18px
                            color: ThemedColors.getTextSecondary(context),
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: DS.iconSizeS,
                        ),
                        
                        const SizedBox(width: DS.spacingS),
                        
                        IconButton(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit,
                            size: DS.iconSizeXs + 2, // 18px
                            color: ThemedColors.getTextSecondary(context),
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: DS.iconSizeS,
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