import 'package:flutter/material.dart';
import '../utils/app_localizations_extension.dart';
import '../utils/design_system.dart';

class CreateDeckCard extends StatelessWidget {
  final VoidCallback onTap;

  const CreateDeckCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Match sizing breakpoints from FlashcardDeckCard for consistency
        final isVerySmall = constraints.maxWidth < 200;
        final isSmall = constraints.maxWidth < 280;
        // Variable is used in the ternary height calculation below
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: constraints.maxWidth, // Explicitly set width to match parent constraint
            height: 201, // Increased to match FlashcardDeckCard and fix overflow
            margin: EdgeInsets.zero, // No margins to maximize space usage
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: DS.borderLarge,
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: isVerySmall ? 24 : (isSmall ? 28 : 32), color: Colors.grey.shade400),
                  SizedBox(height: isVerySmall ? 4 : 8),
                  Text(
                    L10nExt.of(context).createNewDeck,
                    style: TextStyle(
                      fontSize: isVerySmall ? 12 : 14, 
                      color: Colors.grey.shade500
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
