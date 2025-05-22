import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/interview_question.dart';
import '../../utils/design_system.dart';
import '../../utils/theme_utils.dart';

/// Practice Question Card that follows the same design as InterviewQuestionCardImproved
/// to be used in the Practice screen
class PracticeQuestionCard extends StatelessWidget {
  final InterviewQuestion question;
  final VoidCallback onTap;
  final bool isSelected;
  
  const PracticeQuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    this.isSelected = false,
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
        return (isDarkMode ? const Color(0xFF1A6352).withValues(alpha: 0.8) : Colors.green.shade100, localizations.entryLevel);
      case 'mid':
        return (isDarkMode ? const Color(0xFFA66119).withValues(alpha: 0.8) : Colors.amber.shade100, localizations.midLevel);
      case 'senior':
        return (isDarkMode ? const Color(0xFFB72424).withValues(alpha: 0.8) : Colors.red.shade100, localizations.seniorLevel);
      default:
        return (isDarkMode ? const Color(0xFF555B67).withValues(alpha: 0.8) : Colors.grey.shade100, localizations.unspecified);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final (difficultyColor, difficultyName) = _getDifficultyStyle(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DS.spacingM),
      decoration: BoxDecoration(
        color: isSelected
            ? context.primaryColor.withValues(alpha: 0.05)
            : (context.isDarkMode ? const Color(0xFF2A2A30) : Colors.white),
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        border: Border.all(
          color: isSelected
              ? context.primaryColor
              : (context.isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
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
                    // Question text
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            question.text,
                            style: TextStyle(
                              fontSize: DS.bodyLarge.fontSize, // 16px from design system
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode 
                                  ? Colors.white  
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        // Status indicator
                        if (question.isCompleted)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: DS.iconSizeS, // 20px
                          ),
                        
                        // Navigation chevron - replaced with the original style
                        Icon(
                          Icons.arrow_forward_ios,
                          size: DS.iconSizeXs,
                          color: context.isDarkMode 
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: DS.spacingS),
                    
                    // Category, subtopic, and difficulty as pill-shaped tags
                    Wrap(
                      spacing: DS.spacingXs,
                      runSpacing: DS.spacingXs,
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
                              fontSize: DS.bodySmall.fontSize, // 12px
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
                            borderRadius: BorderRadius.circular(DS.borderRadiusMedium + 4), // ~16px
                          ),
                          child: Text(
                            difficultyName,
                            style: TextStyle(
                              fontSize: DS.bodySmall.fontSize, // 12px
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        
                        // Completion status
                        if (question.isCompleted)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DS.spacingXs, 
                              vertical: DS.spacing2xs * 0.5 // 2px
                            ),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? const Color(0xFF34D399).withValues(alpha: 0.15)
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(DS.borderRadiusMedium + 4), // ~16px
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
                                  color: context.isDarkMode
                                      ? const Color(0xFF34D399)
                                      : Colors.green.shade700,
                                ),
                                const SizedBox(width: DS.spacing2xs),
                                Text(
                                  AppLocalizations.of(context).completedStatus,
                                  style: TextStyle(
                                    fontSize: DS.bodySmall.fontSize, // 12px
                                    fontWeight: FontWeight.w500,
                                    color: context.isDarkMode
                                        ? const Color(0xFF34D399)
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: DS.spacingM),
                    
                    // Action buttons consistent with the first screenshot
                    Row(
                      children: [
                        // Practice button
                        TextButton.icon(
                          onPressed: onTap,
                          icon: Icon(
                            Icons.play_circle_outline,
                            size: DS.iconSizeXs,
                            color: context.isDarkMode ? Colors.white : null,
                          ),
                          label: Text(
                            AppLocalizations.of(context).practiceButton,
                            style: TextStyle(
                              fontSize: DS.bodyMedium.fontSize, // 14px
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode ? Colors.white : null,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: DS.spacingXs, vertical: DS.spacing2xs),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: context.primaryColor,
                            backgroundColor: context.isDarkMode 
                                ? context.primaryColor.withValues(alpha: 0.2)
                                : Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DS.borderRadiusMedium + 4), // ~16px
                            ),
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
  }
}