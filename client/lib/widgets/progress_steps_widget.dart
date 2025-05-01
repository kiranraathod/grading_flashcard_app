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
          return Expanded(child: _buildStep(stepIndex, steps[index ~/ 2]));
        } 
        // If odd index, it's a connector
        else {
          return _buildConnector(currentStep > (index ~/ 2) + 1);
        }
      }),
    );
  }

  Widget _buildStep(int step, String label) {
    final isActive = currentStep >= step;
    final isCurrentStep = currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            border: isCurrentStep
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrentStep
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
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
            color: isActive ? AppColors.textPrimary : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );
  }
}