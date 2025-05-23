import 'package:flutter/material.dart';
import '../utils/app_localizations_extension.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';

class CreateDeckCard extends StatelessWidget {
  final VoidCallback onTap;

  const CreateDeckCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Match sizing breakpoints from FlashcardDeckCard for consistency
        final isVerySmall = constraints.maxWidth < DS.breakpointXs * 0.56; // ~200px
        final isSmall = constraints.maxWidth < DS.breakpointSm * 0.44;     // ~280px
        // Variable is used in the ternary height calculation below
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: constraints.maxWidth, // Explicitly set width to match parent constraint
            height: DS.cardHeight, // Use design system card height (201px)
            margin: EdgeInsets.zero, // No margins to maximize space usage
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: DS.borderLarge,
              border: Border.all(
                color: context.colorScheme.outline,
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add, 
                    size: isVerySmall ? DS.iconSizeL : (isSmall ? DS.iconSizeL + 4 : DS.buttonHeightS), // 32-36px range
                    color: context.onSurfaceVariantColor,
                  ),
                  SizedBox(height: isVerySmall ? DS.spacing2xs : DS.spacingXs),
                  Text(
                    L10nExt.of(context).createNewDeck,
                    style: (isVerySmall ? context.bodySmall : context.bodyMedium)?.copyWith(
                      color: context.onSurfaceVariantColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
