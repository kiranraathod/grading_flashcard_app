import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../utils/responsive_helpers.dart';
import '../utils/responsive_text.dart';
import 'responsive_layout.dart';

/// Example widget that demonstrates the use of responsive helpers
class ResponsiveHelpersExample extends StatelessWidget {
  const ResponsiveHelpersExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Responsive Helpers', style: context.headingMedium),
      ),
      body: ResponsiveLayout(
        // Phone layout
        phoneBuilder: (context) => _buildPhoneLayout(context),
        
        // Tablet layout
        tabletBuilder: (context) => _buildTabletLayout(context),
        
        // Desktop layout
        desktopBuilder: (context) => _buildDesktopLayout(context),
        
        // Default layout (fallback)
        defaultBuilder: (context) => _buildPhoneLayout(context),
      ),
    );
  }
  
  Widget _buildPhoneLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsiveScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phone Layout', style: context.headingLarge),
          SizedBox(height: DS.spacingM),
          _buildDeviceInfo(context),
          SizedBox(height: DS.spacingL),
          _buildResponsiveCards(context, isVertical: true),
        ],
      ),
    );
  }
  
  Widget _buildTabletLayout(BuildContext context) {
    // Use extension override to resolve ambiguity
    final isPortrait = ResponsiveContext(context).isPortrait;
    
    return SingleChildScrollView(
      padding: context.responsiveScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tablet Layout', style: context.headingLarge),
          SizedBox(height: DS.spacingM),
          _buildDeviceInfo(context),
          SizedBox(height: DS.spacingL),
          isPortrait
              ? _buildResponsiveCards(context, isVertical: true)
              : _buildResponsiveCards(context, isVertical: false),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: context.responsiveScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Desktop Layout', style: context.headingLarge),
          SizedBox(height: DS.spacingM),
          _buildDeviceInfo(context),
          SizedBox(height: DS.spacingL),
          _buildResponsiveCards(context, isVertical: false),
        ],
      ),
    );
  }
  
  Widget _buildDeviceInfo(BuildContext context) {
    return Card(
      elevation: DS.elevationS,
      shape: RoundedRectangleBorder(borderRadius: DS.borderMedium),
      child: Padding(
        padding: EdgeInsets.all(DS.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Information', style: context.headingMedium),
            SizedBox(height: DS.spacingS),
            _buildInfoRow('Device Type:', context.deviceType.toString()),
            _buildInfoRow('Screen Size:', '${ResponsiveContext(context).screenWidth.toInt()} × ${ResponsiveContext(context).screenHeight.toInt()}'),
            _buildInfoRow('Screen Category:', context.screenSizeCategory.toString()),
            _buildInfoRow('Orientation:', ResponsiveContext(context).isPortrait ? 'Portrait' : 'Landscape'),
            // Using textScaler instead of textScaleFactor
            _buildInfoRow('Text Scale Factor:', MediaQuery.of(context).textScaler.scale(1.0).toStringAsFixed(2)),
            _buildInfoRow('Grid Columns:', context.gridColumnCount.toString()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DS.spacingXs),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: DS.spacingS),
          Text(value),
        ],
      ),
    );
  }
  
  Widget _buildResponsiveCards(BuildContext context, {required bool isVertical}) {
    final cards = [
      _buildFeatureCard(
        context,
        title: 'Screen-Aware Dimension Scaling',
        description: 'Dimensions that automatically scale based on screen size for consistent UI across devices.',
        icon: Icons.aspect_ratio,
      ),
      _buildFeatureCard(
        context,
        title: 'Adaptive Spacing',
        description: 'Spacing values that adjust based on device size to maintain proper visual hierarchy.',
        icon: Icons.space_bar,
      ),
      _buildFeatureCard(
        context,
        title: 'Orientation-Aware Layouts',
        description: 'Layouts that respond to device orientation changes for optimal content display.',
        icon: Icons.screen_rotation,
      ),
      _buildFeatureCard(
        context,
        title: 'Responsive Text Scaling',
        description: 'Typography that scales appropriately for different screen sizes while respecting user preferences.',
        icon: Icons.text_fields,
      ),
    ];
    
    if (isVertical) {
      return Column(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: DS.spacingM),
          child: card,
        )).toList(),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - (DS.spacingM * (context.gridColumnCount - 1))) / context.gridColumnCount;
          
          return Wrap(
            spacing: DS.spacingM,
            runSpacing: DS.spacingM,
            children: cards.map((card) => SizedBox(
              width: cardWidth,
              child: card,
            )).toList(),
          );
        },
      );
    }
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      elevation: DS.elevationS,
      shape: RoundedRectangleBorder(borderRadius: DS.borderMedium),
      child: Padding(
        padding: EdgeInsets.all(DS.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: DS.iconSizeL, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: DS.spacingS),
                Expanded(
                  child: Text(title, style: context.headingSmall),
                ),
              ],
            ),
            SizedBox(height: DS.spacingM),
            Text(
              description, 
              style: context.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}