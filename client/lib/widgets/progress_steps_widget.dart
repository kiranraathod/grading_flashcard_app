import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProgressStepsWidget extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const ProgressStepsWidget({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        // If even index, it's a step
        if (index % 2 == 0) {
          final stepIndex = (index ~/ 2) + 1;
          return Expanded(child: _buildStep(context, stepIndex, steps[index ~/ 2]));
        } 
        // If odd index, it's a connector
        else {
          return _buildConnector(context, currentStep > (index ~/ 2) + 1);
        }
      }),
    );
  }

  Widget _buildStep(BuildContext context, int step, String label) {
    final isActive = currentStep >= step;
    final isCurrentStep = currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: isCurrentStep
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrentStep
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnector(BuildContext context, bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}