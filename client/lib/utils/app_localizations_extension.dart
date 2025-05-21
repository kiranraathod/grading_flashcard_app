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
  
  // Common widget strings
  String get search => 'Search';
  String get achievements => 'Achievements';
  String get profile => 'Profile';
  String get settings => 'Settings';
  String get logout => 'Logout';
  
  // Format methods for card counts and progress
  String cardsCount(int count) => '$count cards';
  String progressPercent(int progress) => '$progress% complete';
  String updatedTimeAgo(String time) => 'Updated $time ago';
  
  // Button text for flashcard decks
  String get startLearning => 'Start Learning';
  String get createNewDeck => 'Create New Deck';
  // Note: practiceQuestions is already defined in the ARB file
  
  // Answer input widget strings
  String get submitToTrackProgress => 'Submit your answer to track your progress';
  String get typeYourAnswer => 'Type your answer...';
  String get stopListening => 'Stop listening';
  String get startSpeechToText => 'Start speech to text';
  String get submitAnswerUpdateProgress => 'Submit Answer to Update Progress';
  
  // Connectivity banner strings
  String get offlineMessage => 'You are currently offline. Some features may be limited.';
  String get serverConnectionError => 'Cannot connect to server. Using offline mode.';
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
  
  // Common widget strings
  String get search => _l10n.search;
  String get achievements => _l10n.achievements;
  String get profile => _l10n.profile;
  String get settings => _l10n.settings;
  String get logout => _l10n.logout;
  
  // Format methods for card counts and progress
  String cardsCount(int count) => _l10n.cardsCount(count);
  String progressPercent(int progress) => _l10n.progressPercent(progress);
  String updatedTimeAgo(String time) => _l10n.updatedTimeAgo(time);
  
  // Button text for flashcard decks
  String get startLearning => _l10n.startLearning;
  String get createNewDeck => _l10n.createNewDeck;
  String get practiceQuestions => _l10n.practiceQuestions;
  String get notStarted => _l10n.notStarted;
  
  // Answer input widget strings
  String get submitToTrackProgress => _l10n.submitToTrackProgress;
  String get typeYourAnswer => _l10n.typeYourAnswer;
  String get stopListening => _l10n.stopListening;
  String get startSpeechToText => _l10n.startSpeechToText;
  String get submitAnswerUpdateProgress => _l10n.submitAnswerUpdateProgress;
  
  // Connectivity banner strings
  String get offlineMessage => _l10n.offlineMessage;
  String get serverConnectionError => _l10n.serverConnectionError;
  
  // Factory to create from context
  static L10nExt of(BuildContext context) {
    return L10nExt(AppLocalizations.of(context));
  }
}
