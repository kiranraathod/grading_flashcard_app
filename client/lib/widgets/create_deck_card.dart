import 'package:flutter/material.dart';
import '../utils/app_localizations_extension.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';

class CreateDeckCard extends StatefulWidget {
  final VoidCallback onTap;

  const CreateDeckCard({super.key, required this.onTap});

  @override
  State<CreateDeckCard> createState() => _CreateDeckCardState();
}

class _CreateDeckCardState extends State<CreateDeckCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Match sizing breakpoints from FlashcardDeckCard for consistency
          final isVerySmall = constraints.maxWidth < DS.breakpointXs * 0.56; // ~200px
          final isSmall = constraints.maxWidth < DS.breakpointSm * 0.44;     // ~280px
          
          return GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: DS.durationMedium, // 300ms smooth transition to match FlashcardDeckCard
              curve: Curves.easeOutCubic, // Enhanced smooth curve for better feel  
              transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0), // Match FlashcardDeckCard lift
              width: constraints.maxWidth, // Explicitly set width to match parent constraint
              height: DS.cardHeight, // Use design system card height (201px) - SAME as FlashcardDeckCard
              margin: EdgeInsets.zero, // No margins to maximize space usage
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall), // STANDARDIZED - same as FlashcardDeckCard
                border: Border.all(
                  color: context.isDarkMode 
                      ? context.colorScheme.outline.withValues(alpha: 0.3) // IMPROVED contrast - match FlashcardDeckCard
                      : context.colorScheme.outline,
                  width: context.isDarkMode ? 1.2 : 1.0, // MATCH FlashcardDeckCard border width
                ),
                // ENHANCED and STANDARDIZED shadow system - enhanced version of FlashcardDeckCard
                boxShadow: _isHovered ? (
                  context.isDarkMode 
                    ? [
                        // Enhanced dark mode hover shadow with subtle glow effect
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: context.shadowColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        // Enhanced light mode hover shadow with depth
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                ) : (
                  context.isDarkMode ? DS.getShadow(DS.elevationS, color: context.shadowColor) : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      duration: DS.durationMedium,
                      curve: Curves.elasticOut, // More playful bounce effect to match FlashcardDeckCard
                      scale: _isHovered ? 1.15 : 1.0, // Slightly more scale for better feedback
                      child: AnimatedContainer(
                        duration: DS.durationMedium,
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.all(_isHovered ? DS.spacingXs : DS.spacing2xs),
                        decoration: _isHovered ? BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ) : null,
                        child: Icon(
                          Icons.add, 
                          size: isVerySmall ? DS.iconSizeL : (isSmall ? DS.iconSizeL + 4 : DS.buttonHeightS), // 32-36px range
                          color: _isHovered 
                              ? context.primaryColor // Enhanced color on hover
                              : context.isDarkMode
                                  ? context.onSurfaceColor.withValues(alpha: 0.85) // Better contrast
                                  : context.onSurfaceColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    SizedBox(height: isVerySmall ? DS.spacing2xs : DS.spacingXs),
                    AnimatedDefaultTextStyle(
                      duration: DS.durationMedium,
                      curve: Curves.easeOutCubic,
                      style: (isVerySmall ? context.bodySmall : context.bodyMedium)?.copyWith(
                        color: _isHovered 
                            ? context.primaryColor // Enhanced color on hover  
                            : context.isDarkMode
                                ? context.onSurfaceColor.withValues(alpha: 0.85) // Better contrast
                                : context.onSurfaceColor.withValues(alpha: 0.75),
                        fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500, // Enhanced weight on hover for better feedback
                      ) ?? const TextStyle(),
                      child: Text(
                        L10nExt.of(context).createNewDeck,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
