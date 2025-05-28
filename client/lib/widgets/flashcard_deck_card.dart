import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/spacing_components.dart';
import 'themed_gradient_container.dart';

class FlashcardDeckCard extends StatefulWidget {
  final String title;
  final int cardCount;
  final int progressPercent;
  final VoidCallback onTap;
  final bool isStudyDeck; // True for study deck, false for interview questions

  const FlashcardDeckCard({
    super.key,
    required this.title,
    required this.cardCount,
    required this.progressPercent,
    required this.onTap,
    this.isStudyDeck = true,
  });

  @override
  State<FlashcardDeckCard> createState() => _FlashcardDeckCardState();
}

class _FlashcardDeckCardState extends State<FlashcardDeckCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints based on card width - using design system inspired values
          final isVerySmall = constraints.maxWidth < DS.breakpointXs * 0.56; // ~200px
          final isSmall = constraints.maxWidth < DS.breakpointSm * 0.44;     // ~280px  
          final isMedium = constraints.maxWidth < DS.breakpointMd * 0.46;    // ~350px
          
          // Adaptive sizing based on available width - using design system spacing
          final contentPadding = isVerySmall ? DS.spacing2xs : (isSmall ? DS.spacing2xs + 2 : (isMedium ? DS.spacingXs : DS.spacingS)); // 4-12px range
          final titleStyle = isVerySmall ? 
                            context.bodySmall?.copyWith(fontWeight: FontWeight.bold) :
                            (isSmall ? 
                              context.bodyMedium?.copyWith(fontWeight: FontWeight.bold) :
                              (isMedium ? 
                                context.bodyLarge?.copyWith(fontWeight: FontWeight.bold) :
                                context.titleMedium));
          
          return AnimatedContainer(
            duration: DS.durationMedium, // 300ms smooth transition
            curve: Curves.easeOutCubic, // Enhanced smooth curve for better feel
            transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0), // Slightly more lift
            width: constraints.maxWidth, // Explicitly set width to match parent constraint
            height: DS.cardHeight, // Use design system card height (201px)
            clipBehavior: Clip.antiAlias, // Ensure nothing overflows
            margin: EdgeInsets.zero, // No margins to maximize space usage
            decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
          border: Border.all(
            color: context.isDarkMode 
                ? context.colorScheme.outline.withValues(alpha: 0.3) // Improved contrast
                : context.colorScheme.outline,
            width: context.isDarkMode ? 1.2 : 1.0,
          ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with themed gradient
            ThemedGradientContainer(
              isInterview: !widget.isStudyDeck,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(DS.borderRadiusSmall),
                topRight: Radius.circular(DS.borderRadiusSmall),
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.title,
                          style: titleStyle,
                          maxLines: isVerySmall ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Play button (visible on hover with enhanced animation)
                    AnimatedOpacity(
                      duration: DS.durationMedium,
                      curve: Curves.easeOutCubic, // Smoother animation curve
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: AnimatedScale(
                        duration: DS.durationMedium,
                        curve: Curves.elasticOut, // More playful bounce effect
                        scale: _isHovered ? 1.0 : 0.7, // Start smaller for more dramatic entrance
                        child: AnimatedContainer(
                          duration: DS.durationMedium,
                          curve: Curves.easeOutCubic,
                          height: DS.buttonHeightS,
                          width: DS.buttonHeightS,
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (widget.isStudyDeck 
                                ? context.primaryColor 
                                : context.secondaryColor).withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: _isHovered ? [
                              BoxShadow(
                                color: (widget.isStudyDeck 
                                  ? context.primaryColor 
                                  : context.secondaryColor).withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_arrow,
                              size: DS.iconSizeXs,
                              color: widget.isStudyDeck
                                  ? context.primaryColor
                                  : context.secondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Card info section
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card count (always show)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isStudyDeck
                            ? AppLocalizations.of(context).cardsCount(widget.cardCount)
                            : AppLocalizations.of(context).questionCount(widget.cardCount),
                        style: isVerySmall ? 
                          context.bodySmall?.copyWith(fontSize: 9) : context.bodySmall,
                      ),
                      if (!widget.isStudyDeck)
                        Text(
                          AppLocalizations.of(context).updatedTimeAgo('2d'),
                          style: context.labelSmall,
                        ),
                    ],
                  ),
                  
                  // Always show progress bar, but with zero width for 0%
                  SizedBox(height: isVerySmall ? DS.spacing2xs : (isSmall ? DS.spacing2xs + 2 : DS.spacingXs)),
                  Container(
                    height: isVerySmall ? DS.spacing2xs : DS.spacing2xs + 2, // 4-6px
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DS.borderRadiusXs * 0.75), // ~3px
                      color: context.isDarkMode
                          ? context.surfaceVariantColor.withValues(alpha: 0.3)
                          : context.surfaceVariantColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DS.borderRadiusXs * 0.75), // ~3px
                      child: LinearProgressIndicator(
                        value: widget.progressPercent > 0 ? widget.progressPercent / 100 : 0.001,
                        backgroundColor: Colors.transparent, // Background handled by container
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.progressPercent == 100 
                              ? context.successColor // Special color for completion
                              : context.primaryColor
                        ),
                        minHeight: double.infinity, // Fill container height
                      ),
                    ),
                  ),
                  
                  // Text status below progress bar
                  DSSpacing.verticalXS,
                  Text(
                    widget.progressPercent > 0 
                        ? AppLocalizations.of(context).progressPercent(widget.progressPercent)
                        : AppLocalizations.of(context).notStarted,
                    style: (isVerySmall ? 
                      context.bodySmall?.copyWith(
                        fontSize: 9,
                        color: widget.progressPercent == 100
                            ? context.successColor // Special color for completion
                            : widget.progressPercent > 0
                                ? context.primaryColor
                                : context.isDarkMode
                                    ? context.onSurfaceColor.withValues(alpha: 0.85) // WCAG AA compliant contrast
                                    : context.onSurfaceColor.withValues(alpha: 0.75),
                        fontWeight: widget.progressPercent > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ) : 
                      context.bodySmall?.copyWith(
                        color: widget.progressPercent == 100
                            ? context.successColor // Special color for completion
                            : widget.progressPercent > 0
                                ? context.primaryColor
                                : context.isDarkMode
                                    ? context.onSurfaceColor.withValues(alpha: 0.85) // WCAG AA compliant contrast
                                    : context.onSurfaceColor.withValues(alpha: 0.75),
                        fontWeight: widget.progressPercent > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      )),
                  ),
                ],
              ),
            ),
            
            // Spacer to push the button to the bottom with minimum height
            Expanded(
              child: SizedBox(
                height: DS.spacingXs + 2, // 10px - compact but sufficient
              ),
            ),
            
            // Action button with enhanced hover effects
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.isDarkMode
                        ? context.colorScheme.outline.withValues(alpha: 0.3)
                        : context.colorScheme.outline,
                  ),
                ),
              ),
              child: AnimatedContainer(
                duration: DS.durationMedium, // Add smooth animation
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.isDarkMode
                          ? context.colorScheme.outline.withValues(alpha: 0.3)
                          : context.colorScheme.outline,
                    ),
                  ),
                ),
                child: TextButton(
                  onPressed: widget.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: _isHovered 
                        ? context.primaryColor // Enhanced color on hover
                        : context.isDarkMode
                            ? context.onSurfaceColor.withValues(alpha: 0.85) // Improved contrast
                            : context.onSurfaceColor.withValues(alpha: 0.75),
                    backgroundColor: _isHovered 
                        ? context.primaryColor.withValues(alpha: 0.08) // More subtle background on hover
                        : Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    vertical: DS.spacing2xs + 2  // 6px - compact but accessible
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(DS.borderRadiusSmall),
                      bottomRight: Radius.circular(DS.borderRadiusSmall),
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isVerySmall ? DS.spacing2xs + 2 : (isSmall ? DS.spacingXs : (isMedium ? DS.spacingS : DS.spacingM))
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isStudyDeck ? AppLocalizations.of(context).startLearning : AppLocalizations.of(context).practiceQuestions,
                      style: (isVerySmall ? 
                        context.bodySmall?.copyWith(fontSize: 10) : 
                        context.bodySmall)?.copyWith(
                        fontWeight: _isHovered ? FontWeight.w500 : FontWeight.normal, // Enhanced weight on hover
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
        }
      ),
    );
  }
}