import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
          builder:
              (context) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add, color: AppColors.primary),
                      title: Text(
                        AppLocalizations.of(context).createNewQuestion,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const CreateInterviewQuestionScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.description,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        AppLocalizations.of(context).generateFromJobDescription,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const JobDescriptionQuestionGeneratorScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.upload_file,
                        color: AppColors.primary,
                      ),
                      title: Text(AppLocalizations.of(context).importQuestions),
                      onTap: () {
                        Navigator.pop(context);
                        // Handle import functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              ).importFunctionalityPlaceholder,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
        );
      },
      tooltip: AppLocalizations.of(context).addNewQuestions,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add),
    );
  }
}
