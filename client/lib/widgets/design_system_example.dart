// Example usage of the design system in a UI component

import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../utils/responsive_helpers.dart';

class ResponsiveCardExample extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ResponsiveCardExample({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Using context extension methods for responsive values
    final isSmallScreen = context.isPhone;
    final padding = context.responsivePadding;
    
    return Card(
      // Using elevation from design system
      elevation: DS.elevationS,
      // Using border radius from design system
      shape: RoundedRectangleBorder(
        borderRadius: DS.borderMedium,
      ),
      child: Padding(
        // Using responsive padding
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  // Using responsive icon size
                  size: isSmallScreen ? DS.iconSizeM : DS.iconSizeL,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: DS.spacingS),
                Expanded(
                  child: Text(
                    title,
                    // Using typography from design system
                    style: isSmallScreen ? DS.headingSmall : DS.headingMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: DS.spacingM),
            Text(
              subtitle,
              style: DS.bodyMedium,
            ),
            SizedBox(height: DS.spacingL),
            // Using button style from design system
            ElevatedButton(
              style: DS.primaryButtonStyle,
              onPressed: () {},
              child: const Text('Action'),
            ),
          ],
        ),
      ),
    );
  }
}

// Example of responsive grid layout using design system
class ResponsiveGridExample extends StatelessWidget {
  const ResponsiveGridExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Using breakpoints from design system for responsive grid
    return GridView.builder(
      padding: EdgeInsets.all(context.spacingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        // Using responsive value helper for grid columns
        crossAxisCount: DS.responsiveValue(
          context,
          xs: 1,  // 1 column for extra small screens
          sm: 2,  // 2 columns for small screens
          md: 3,  // 3 columns for medium screens
          lg: 4,  // 4 columns for large screens
        ),
        childAspectRatio: 1.2,
        // Using spacing from design system
        crossAxisSpacing: context.gridSpacing,
        mainAxisSpacing: context.gridSpacing,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return ResponsiveCardExample(
          title: 'Card $index',
          subtitle: 'This is a responsive card example using the design system',
          icon: Icons.star,
        );
      },
    );
  }
}
