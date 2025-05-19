import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension on AppLocalizations to provide additional string getters
/// until the gen-l10n generator can be run to properly update the localization files.
extension AppLocalizationsExtension on AppLocalizations {
  // Study screen strings
  String get study => 'Study';
  String get editSet => 'Edit this flashcard set';
  String get markForReview => 'Mark for review';
  String get editSetMenuItem => 'Edit Set';
  String get back => 'Back';
  String get processingAnswer => 'Processing your answer...';
  String get previous => 'Previous';
  String get gradingAnswer => 'Grading your answer...';
  
  // Method to format card count
  String cardCountFormat(int current, int total) => '$current/$total';
  
  // Result screen strings
  String get results => 'Results';
  String get question => 'Question:';
  String get yourAnswerLabel => 'Your Answer:';
  String get correctAnswer => 'Correct Answer:';
  String get systemError => 'System Error';
  String get yourGrade => 'Your Grade';
  String get feedbackLabel => 'Feedback:';
  String get errorMessage => 'Error Message:';
  String get noFeedback => 'No feedback available';
  String get improvementSuggestions => 'Improvement Suggestions';
  String get troubleshootingSteps => 'Troubleshooting Steps';
  String get progressUpdated => 'Your progress has been updated!';
  
  // Note: 'continue' is a reserved keyword in Dart, so using a different name
  String get continueButton => 'Continue';
  String get tryAgainLater => 'Try Again Later';
}

// Helper class for localization access - alternative to extension methods
// This can be used if extension methods cause analyzer issues
class L10nExt {
  final AppLocalizations _l10n;
  
  L10nExt(this._l10n);
  
  // Study screen strings
  String get study => _l10n.study;
  String get editSet => _l10n.editSet;
  String get markForReview => _l10n.markForReview;
  String get editSetMenuItem => _l10n.editSetMenuItem;
  String get back => _l10n.back;
  String get processingAnswer => _l10n.processingAnswer;
  String get previous => _l10n.previous;
  String get gradingAnswer => _l10n.gradingAnswer;
  
  // Method to format card count
  String cardCountFormat(int current, int total) => _l10n.cardCountFormat(current, total);
  
  // Result screen strings
  String get results => _l10n.results;
  String get question => _l10n.question;
  String get yourAnswerLabel => _l10n.yourAnswerLabel;
  String get correctAnswer => _l10n.correctAnswer;
  String get systemError => _l10n.systemError;
  String get yourGrade => _l10n.yourGrade;
  String get feedbackLabel => _l10n.feedbackLabel;
  String get errorMessage => _l10n.errorMessage;
  String get noFeedback => _l10n.noFeedback;
  String get improvementSuggestions => _l10n.improvementSuggestions;
  String get troubleshootingSteps => _l10n.troubleshootingSteps;
  String get progressUpdated => _l10n.progressUpdated;
  
  // Note: 'continue' is a reserved keyword in Dart, so using a different name
  String get continueButton => 'Continue';
  String get tryAgainLater => _l10n.tryAgainLater;
  
  // Factory to create from context
  static L10nExt of(BuildContext context) {
    return L10nExt(AppLocalizations.of(context));
  }
}
