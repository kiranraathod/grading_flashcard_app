import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// BLoC imports
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

// Navigation screens
import '../screens/create_flashcard_screen.dart';
import '../screens/create_interview_question_screen.dart';
import '../screens/job_description_question_generator_screen.dart';

/// Phase 5: BLoC-based Multi Action FAB
/// 
/// Pure BLoC widget for the floating action button that replaces
/// Provider patterns with BLoC state management. Shows different
/// actions based on authentication status.
class MultiActionFabBloc extends StatefulWidget {
  const MultiActionFabBloc({super.key});

  @override
  State<MultiActionFabBloc> createState() => _MultiActionFabBlocState();
}

class _MultiActionFabBlocState extends State<MultiActionFabBloc>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees rotation
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Background overlay
            if (_isExpanded) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleFab,
                  child: Container(
                    color: Colors.black26,
                  ),
                ),
              ),
            ],
            
            // Action buttons
            if (_isExpanded) ..._buildActionButtons(authState),
            
            // Main FAB
            FloatingActionButton(
              onPressed: _toggleFab,
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2.0 * 3.14159,
                    child: Icon(_isExpanded ? Icons.close : Icons.add),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildActionButtons(AuthState authState) {
    final List<Widget> buttons = [];
    const double spacing = 70.0;

    // Create Flashcard Set
    buttons.add(
      Positioned(
        bottom: spacing * 1,
        right: 0,
        child: _buildActionButton(
          icon: Icons.school,
          label: 'Create Deck',
          onPressed: () => _navigateToCreateFlashcard(),
        ),
      ),
    );

    // Create Interview Question (requires auth)
    if (authState is AuthStateAuthenticated) {
      buttons.add(
        Positioned(
          bottom: spacing * 2,
          right: 0,
          child: _buildActionButton(
            icon: Icons.quiz,
            label: 'Interview Question',
            onPressed: () => _navigateToCreateInterview(),
          ),
        ),
      );

      // Job Description Generator (requires auth)
      buttons.add(
        Positioned(
          bottom: spacing * 3,
          right: 0,
          child: _buildActionButton(
            icon: Icons.work,
            label: 'Job Questions',
            onPressed: () => _navigateToJobQuestions(),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Button
        FloatingActionButton(
          mini: true,
          heroTag: label, // Unique hero tag for each button
          onPressed: () {
            _toggleFab();
            onPressed();
          },
          child: Icon(icon),
        ),
      ],
    );
  }

  void _toggleFab() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToCreateFlashcard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateFlashcardScreen(),
      ),
    );
  }

  void _navigateToCreateInterview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateInterviewQuestionScreen(),
      ),
    );
  }

  void _navigateToJobQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JobDescriptionQuestionGeneratorScreen(),
      ),
    );
  }
}