import 'package:flutter/material.dart';
import '../../screens/create_interview_question_screen.dart';
import '../../screens/job_description_question_generator_screen.dart';
import '../../utils/colors.dart';

/// Custom Floating Action Button for Interview Questions section
/// 
/// This component encapsulates the FAB functionality specific to the Interview Questions
/// section, preventing conflicts with other FABs in the application.
class InterviewQuestionsFAB extends StatelessWidget {
  const InterviewQuestionsFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      // Use a unique heroTag to prevent conflicts with other FABs
      heroTag: 'interview_questions_fab',
      onPressed: () {
        // Show menu options when the FAB is pressed
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add, color: AppColors.primary),
                  title: const Text('Create New Question'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateInterviewQuestionScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: AppColors.primary),
                  title: const Text('Generate from Job Description'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const JobDescriptionQuestionGeneratorScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file, color: AppColors.primary),
                  title: const Text('Import Questions'),
                  onTap: () {
                    Navigator.pop(context);
                    // Handle import functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Import functionality would be implemented here'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      tooltip: 'Add new questions',
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add),
    );
  }
}
