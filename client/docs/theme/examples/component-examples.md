# Component Examples

**Real-World Theme Implementation Examples**

## 🎯 Overview

This document showcases real component implementations using the FlashMaster theme system, demonstrating best practices and patterns.

## 🃏 Flashcard Component Example

```dart
class ThemedFlashcardWidget extends StatelessWidget {
  final String question;
  final String answer;
  final bool isFlipped;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ThemedComponents.cardDecorationWithGradient(
        context,
        isInterview: false, // Flashcard style gradient
      ),
      padding: context.cardPadding,
      child: Column(
        children: [
          Text(
            isFlipped ? answer : question,
            style: context.bodyLarge?.copyWith(
              color: AppColors.getTextPrimary(context.isDarkMode),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.componentSpacing / 2),
          Text(
            isFlipped ? 'Answer' : 'Question',
            style: context.labelMedium?.copyWith(
              color: AppColors.getTextSecondary(context.isDarkMode),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🎤 Interview Question Card

```dart
class ThemedInterviewCard extends StatelessWidget {
  final String question;
  final String category;
  final String difficulty;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ThemedComponents.cardDecorationWithGradient(
        context,
        isInterview: true, // Interview style gradient
      ),
      padding: context.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getCategoryColor(
                category,
                isDarkMode: context.isDarkMode,
              ).withValues(alpha: 0.1),
              borderRadius: context.smallBorderRadius,
            ),
            child: Text(
              category,
              style: context.labelSmall?.copyWith(
                color: AppColors.getCategoryColor(
                  category,
                  isDarkMode: context.isDarkMode,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Question text
          Text(
            question,
            style: context.bodyLarge?.copyWith(
              color: AppColors.getTextPrimary(context.isDarkMode),
            ),
          ),
          
          SizedBox(height: 8),
          
          // Difficulty indicator
          Row(
            children: [
              Icon(
                _getDifficultyIcon(difficulty),
                size: 16,
                color: AppColors.getDifficultyColor(
                  difficulty,
                  isDarkMode: context.isDarkMode,
                ),
              ),
              SizedBox(width: 4),
              Text(
                difficulty,
                style: context.labelMedium?.copyWith(
                  color: AppColors.getDifficultyColor(
                    difficulty,
                    isDarkMode: context.isDarkMode,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return Icons.trending_down;
      case 'medium': return Icons.trending_flat;
      case 'hard': return Icons.trending_up;
      default: return Icons.help_outline;
    }
  }
}
```

## 🔘 Themed Button Examples

```dart
class ThemedPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.primaryColor,
        foregroundColor: context.onPrimaryColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: context.buttonBorderRadius,
        ),
      ),
      child: isLoading
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(context.onPrimaryColor),
            ),
          )
        : Text(
            text,
            style: context.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
    );
  }
}

class ThemedSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: context.primaryColor),
        foregroundColor: context.primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: context.buttonBorderRadius,
        ),
      ),
      child: Text(
        text,
        style: context.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
```

## 📝 Themed Input Field

```dart
class ThemedTextFormField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  
  @override
  _ThemedTextFormFieldState createState() => _ThemedTextFormFieldState();
}

class _ThemedTextFormFieldState extends State<ThemedTextFormField> {
  bool _hasFocus = false;
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.obscureText,
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      style: context.bodyLarge?.copyWith(
        color: AppColors.getTextPrimary(context.isDarkMode),
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        labelStyle: context.bodyMedium?.copyWith(
          color: _hasFocus 
            ? context.primaryColor 
            : AppColors.getTextSecondary(context.isDarkMode),
        ),
        hintStyle: context.bodyMedium?.copyWith(
          color: AppColors.getTextSecondary(context.isDarkMode),
        ),
        border: OutlineInputBorder(
          borderRadius: context.buttonBorderRadius,
          borderSide: BorderSide(
            color: context.isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: context.buttonBorderRadius,
          borderSide: BorderSide(
            color: context.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: context.buttonBorderRadius,
          borderSide: BorderSide(color: context.errorColor),
        ),
        filled: true,
        fillColor: context.isDarkMode 
          ? AppColors.surfaceDark 
          : Colors.grey.shade50,
      ),
    );
  }
}
```

## 📊 Progress Indicator Example

```dart
class ThemedProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final bool showPercentage;
  
  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: context.bodyMedium?.copyWith(
                  color: AppColors.getTextPrimary(context.isDarkMode),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showPercentage)
                Text(
                  '$percentage%',
                  style: context.bodySmall?.copyWith(
                    color: AppColors.getProgressColor(
                      percentage,
                      isDarkMode: context.isDarkMode,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
        ],
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: context.isDarkMode 
            ? Colors.grey.shade700 
            : Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.getProgressColor(
              percentage,
              isDarkMode: context.isDarkMode,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
```

## 🎨 Status Badge Example

```dart
class ThemedStatusBadge extends StatelessWidget {
  final String status;
  final String text;
  
  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(
      status,
      isDarkMode: context.isDarkMode,
    );
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: context.smallBorderRadius,
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: context.labelMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

**These examples demonstrate proper theme integration patterns that can be adapted for other components throughout the application.**
