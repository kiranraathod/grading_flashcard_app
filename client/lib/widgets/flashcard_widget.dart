import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/flashcard.dart';
import '../utils/design_system.dart';
import '../utils/spacing_components.dart';

class FlashcardWidget extends StatefulWidget {
  final Flashcard flashcard;

  const FlashcardWidget({super.key, required this.flashcard});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: DS.durationMedium, // 300ms from design system
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_showAnswer) {
      _animationController.reverse().then((_) {
        setState(() {
          _showAnswer = false;
        });
      });
    } else {
      setState(() {
        _showAnswer = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final transform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_animation.value * math.pi);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child:
                _animation.value < 0.5
                    ? _buildFrontCard()
                    : Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildBackCard(),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Card(
      elevation: DS.elevationS, // 2.0 from design system
      margin: EdgeInsets.all(DS.spacingM),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.borderRadiusLarge)),
      child: Container(
        padding: EdgeInsets.all(DS.spacingL),
        width: double.infinity,
        height: 300, // Keep specific height for flashcard functionality
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.flashcard.question.isNotEmpty 
                  ? widget.flashcard.question 
                  : 'No question available. Please edit this flashcard.',
              style: TextStyle(fontSize: DS.bodyLarge.fontSize! + 4, fontWeight: FontWeight.bold), // 20px
              textAlign: TextAlign.center,
            ),
            DSSpacing.verticalL,
            Text(
              'Tap to reveal answer',
              style: TextStyle(fontSize: DS.bodyMedium.fontSize, color: Colors.grey),
            ),
            // Add a hint icon to encourage user interaction
            Container(
              margin: EdgeInsets.only(top: DS.spacingXs),
              width: DS.avatarSizeM,
              height: DS.avatarSizeM,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Icon(
                Icons.touch_app,
                color: Colors.grey.shade600,
                size: DS.iconSizeS,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Card(
      elevation: DS.elevationS, // 2.0 from design system
      margin: EdgeInsets.all(DS.spacingM),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.borderRadiusLarge)),
      child: Container(
        padding: EdgeInsets.all(DS.spacingL),
        width: double.infinity,
        height: 300, // Keep specific height for flashcard functionality
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Answer',
              style: TextStyle(
                fontSize: DS.bodyLarge.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            DSSpacing.verticalL,
            Text(
              widget.flashcard.answer.isNotEmpty
                  ? widget.flashcard.answer
                  : 'No answer available. Please edit this flashcard.',
              style: TextStyle(fontSize: DS.bodyLarge.fontSize! + 4), // 20px
              textAlign: TextAlign.center,
            ),
            DSSpacing.verticalL,
            Text(
              'Tap to see question',
              style: TextStyle(fontSize: DS.bodyMedium.fontSize, color: Colors.grey),
            ),
            // Add a hint icon to encourage user interaction
            Container(
              margin: EdgeInsets.only(top: DS.spacingXs),
              width: DS.avatarSizeM,
              height: DS.avatarSizeM,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Icon(
                Icons.flip,
                color: Colors.grey.shade600,
                size: DS.iconSizeS,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
