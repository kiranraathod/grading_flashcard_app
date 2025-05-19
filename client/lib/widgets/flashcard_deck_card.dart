import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/theme_utils.dart';
import 'themed_gradient_container.dart';

class FlashcardDeckCard extends StatefulWidget {
  final String title;
  final String category;
  final int cardCount;
  final int progressPercent;
  final VoidCallback onTap;
  final bool isStudyDeck; // True for study deck, false for interview questions

  const FlashcardDeckCard({
    super.key,
    required this.title,
    required this.category,
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
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.isDarkMode 
                ? context.colorScheme.outline.withValues(alpha: 0.2)
                : context.colorScheme.outline,
            width: context.isDarkMode ? 1.2 : 1.0,
          ),
          boxShadow: _isHovered ? (
            context.isDarkMode ? [
              BoxShadow(
                color: const Color(0x99000000), // rgba(0, 0, 0, 0.6) for hover
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : context.cardShadow
          ) : (
            context.isDarkMode ? [
              BoxShadow(
                color: const Color(0x66000000), // rgba(0, 0, 0, 0.4) for normal state
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with themed gradient
            ThemedGradientContainer(
              isInterview: !widget.isStudyDeck,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.category,
                            style: context.bodySmall,
                          ),
                        ),
                        // Title
                        Text(
                          widget.title,
                          style: context.titleMedium,
                        ),
                      ],
                    ),
                    // Play button (visible on hover)
                    if (_isHovered)
                      Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_arrow,
                            size: 16,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card count (always show)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isStudyDeck
                            ? AppLocalizations.of(context).cardsCount(widget.cardCount)
                            : AppLocalizations.of(context).questionCount(widget.cardCount),
                        style: context.bodySmall,
                      ),
                      if (!widget.isStudyDeck)
                        Text(
                          AppLocalizations.of(context).updatedTimeAgo('2d'),
                          style: context.labelSmall,
                        ),
                    ],
                  ),
                  
                  // Always show progress bar, but with zero width for 0%
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? context.surfaceVariantColor.withValues(alpha: 0.3)
                          : context.surfaceVariantColor,
                      borderRadius: BorderRadius.circular(3),
                      border: context.isDarkMode ? Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.5,
                      ) : null,
                    ),
                    child: Row(
                      children: [
                        // Progress bar - visible even at 0%
                        Container(
                          width: (MediaQuery.of(context).size.width / 4 - 32) * 
                              (widget.progressPercent > 0 ? widget.progressPercent / 100 : 0.001),
                          decoration: BoxDecoration(
                            color: context.primaryColor,  // This will now use grey
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Text status below progress bar
                  const SizedBox(height: 4),
                  Text(
                    widget.progressPercent > 0 
                        ? AppLocalizations.of(context).progressPercent(widget.progressPercent)
                        : AppLocalizations.of(context).notStarted,
                    style: context.bodySmall?.copyWith(
                      color: widget.progressPercent > 0
                          ? context.primaryColor
                          : context.onSurfaceVariantColor,
                      fontWeight: widget.progressPercent > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            
            // Spacer to push the button to the bottom
            const Spacer(),
            
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isStudyDeck ? AppLocalizations.of(context).startLearning : AppLocalizations.of(context).practiceQuestions,
                      style: context.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}