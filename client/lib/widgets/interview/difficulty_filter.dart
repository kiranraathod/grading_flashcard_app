import 'package:flutter/material.dart';
import '../../utils/design_system.dart';

class DifficultyFilter extends StatelessWidget {
  final String activeDifficulty;
  final Function(String) onDifficultySelected;
  
  const DifficultyFilter({
    super.key,
    required this.activeDifficulty,
    required this.onDifficultySelected,
  });
  
  @override
  Widget build(BuildContext context) {
    // Define difficulty levels
    final difficulties = [
      {'id': 'all', 'name': 'All'},
      {'id': 'entry', 'name': 'Entry Level'},
      {'id': 'mid', 'name': 'Mid Level'},
      {'id': 'senior', 'name': 'Senior Level'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DS.spacingXs),
          child: Text(
            'Difficulty:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Row(
          children: difficulties.map((difficulty) {
            final isActive = activeDifficulty == difficulty['id'];
            
            return Padding(
              padding: const EdgeInsets.only(right: DS.spacingXs),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onDifficultySelected(difficulty['id'].toString()),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DS.spacingM,
                      vertical: DS.spacing2xs,
                    ),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? Colors.blue.shade100
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive 
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      difficulty['name'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                        color: isActive 
                            ? Colors.blue.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}