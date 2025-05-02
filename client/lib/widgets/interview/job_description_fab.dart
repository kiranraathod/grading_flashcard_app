import 'package:flutter/material.dart';

/// Custom Floating Action Button for Job Description Question Generator
/// 
/// This component handles the FAB functionality specific to the Job Description
/// Question Generator screen, preventing conflicts with other FABs.
class JobDescriptionFAB extends StatelessWidget {
  final VoidCallback onPressed;
  
  const JobDescriptionFAB({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      // Use a unique heroTag to prevent conflicts with other FABs
      heroTag: 'job_description_generator_fab',
      onPressed: onPressed,
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
  }
}
