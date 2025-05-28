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
          
          return Container(
            width: constraints.maxWidth, // Explicitly set width to match parent constraint
            height: DS.cardHeight, // Use design system card height (201px)
            clipBehavior: Clip.antiAlias, // Ensure nothing overflows
            margin: EdgeInsets.zero, // No margins to maximize space usage
            decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
          border: Border.all(
            color: context.isDarkMode 
                ? context.colorScheme.outline.withValues(alpha: 0.2)
                : context.colorScheme.outline,
            width: context.isDarkMode ? 1.2 : 1.0,
          ),
          boxShadow: _isHovered ? (
            context.isDarkMode ? DS.getShadow(DS.elevationM, color: context.shadowColor) : context.cardShadow
          ) : (
            context.isDarkMode ? DS.getShadow(DS.elevationS, color: context.shadowColor) : null
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
                    // Play button (visible on hover)
                    if (_isHovered)
                      Container(
                        height: DS.buttonHeightS,
                        width: DS.buttonHeightS,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
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
                  SizedBox(
                    height: isVerySmall ? DS.spacing2xs : DS.spacing2xs + 2, // 4-6px
                    child: LinearProgressIndicator(
                      value: widget.progressPercent > 0 ? widget.progressPercent / 100 : 0.001,
                      backgroundColor: context.isDarkMode
                          ? context.surfaceVariantColor.withValues(alpha: 0.3)
                          : context.surfaceVariantColor,
                      valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                      borderRadius: BorderRadius.circular(DS.borderRadiusXs * 0.75), // ~3px
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
                        color: widget.progressPercent > 0
                            ? context.primaryColor
                            : context.onSurfaceVariantColor,
                        fontWeight: widget.progressPercent > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ) : 
                      context.bodySmall?.copyWith(
                        color: widget.progressPercent > 0
                            ? context.primaryColor
                            : context.onSurfaceVariantColor,
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
            
            // Action button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.colorScheme.outline),
                ),
              ),
              child: TextButton(
                onPressed: widget.onTap,
                style: TextButton.styleFrom(
                  foregroundColor: context.onSurfaceVariantColor,
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
                      style: isVerySmall ? 
                        context.bodySmall?.copyWith(fontSize: 10) : 
                        context.bodySmall,
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