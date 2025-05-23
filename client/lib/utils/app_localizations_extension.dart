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
  
  // Error handling strings
  String get errorTitle => 'Error';
  String get ok => 'OK';
  String get dismiss => 'Dismiss';
  
  // Flashcard set management strings
  String get deleteFlashcardSet => 'Delete Flashcard Set';
  String deleteConfirmation(String title) => 'Are you sure you want to delete "$title"? This action cannot be undone.';
  String get cancel => 'CANCEL';
  String get delete => 'DELETE';
  String setDeletedMessage(String title) => '$title has been deleted';
  String get editFlashcardSet => 'Edit Flashcard Set';
  String get moreOptions => 'More options';
  String termsCount(int count) => '$count terms';
  
  // Interview questions strings
  String get createNewQuestion => 'Create New Question';
  String get generateFromJobDescription => 'Generate from Job Description';
  String get importQuestions => 'Import Questions';
  String get importFunctionalityPlaceholder => 'Import functionality would be implemented here';
  String get addNewQuestions => 'Add new questions';
  
  // Theme toggle strings
  String get darkMode => 'Dark Mode';
  String get lightMode => 'Light Mode';
  String get switchToLightTheme => 'Switch to light theme';
  String get switchToDarkTheme => 'Switch to dark theme';
  String get switchToLightMode => 'Switch to Light Mode';
  String get switchToDarkMode => 'Switch to Dark Mode';
  
  // Answer view strings
  String get answerTitle => 'Answer';
  String get close => 'Close';
  String get markAsIncomplete => 'Mark as Incomplete';
  String get markAsCompleteButton => 'Mark as Complete';
  
  // Suggestions widget strings
  String get improvementSuggestionsTitle => 'Improvement Suggestions';
  
  // Recent items strings
  String errorLoadingRecentItems(String message) => 'Error loading recent items: $message';
  String get retry => 'Retry';
  String get tryAgain => 'Try Again';
  String get unexpectedState => 'Unexpected State';
  String get errorLoadingRecentItemsTitle => 'Error Loading Recent Items';
  String get totalItems => 'Total Items';
  String get flashcards => 'Flashcards';
  String get lastStudied => 'Last Studied';
  String get all => 'All';
  String get resumeStudy => 'Resume Study';
  String get practice => 'Practice';
  String get view => 'View';
  String get completedBadge => 'Completed';
  String get flashcard => 'Flashcard';
  String get interviewQuestion => 'Interview Question';
  String get noRecentlyViewedItems => 'No Recently Viewed Items';
  String get startStudyingMessage => 'Start studying flashcards or practicing interview questions';
  String get studyFlashcards => 'Study Flashcards';
  String get practiceInterviews => 'Practice Interviews';
  String get flashcardSetNotFound => 'Flashcard set not found';
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
  
  // Error handling strings
  String get errorTitle => _l10n.errorTitle;
  String get ok => _l10n.ok;
  String get dismiss => _l10n.dismiss;
  
  // Flashcard set management strings
  String get deleteFlashcardSet => _l10n.deleteFlashcardSet;
  String deleteConfirmation(String title) => _l10n.deleteConfirmation(title);
  String get cancel => _l10n.cancel;
  String get delete => _l10n.delete;
  String setDeletedMessage(String title) => _l10n.setDeletedMessage(title);
  String get editFlashcardSet => _l10n.editFlashcardSet;
  String get moreOptions => _l10n.moreOptions;
  String termsCount(int count) => _l10n.termsCount(count);
  
  // Interview questions strings
  String get createNewQuestion => _l10n.createNewQuestion;
  String get generateFromJobDescription => _l10n.generateFromJobDescription;
  String get importQuestions => _l10n.importQuestions;
  String get importFunctionalityPlaceholder => _l10n.importFunctionalityPlaceholder;
  String get addNewQuestions => _l10n.addNewQuestions;
  
  // Theme toggle strings
  String get darkMode => _l10n.darkMode;
  String get lightMode => _l10n.lightMode;
  String get switchToLightTheme => _l10n.switchToLightTheme;
  String get switchToDarkTheme => _l10n.switchToDarkTheme;
  String get switchToLightMode => _l10n.switchToLightMode;
  String get switchToDarkMode => _l10n.switchToDarkMode;
  
  // Answer view strings
  String get answerTitle => _l10n.answerTitle;
  String get close => _l10n.close;
  String get markAsIncomplete => _l10n.markAsIncomplete;
  String get markAsCompleteButton => _l10n.markAsCompleteButton;
  
  // Suggestions widget strings
  String get improvementSuggestionsTitle => _l10n.improvementSuggestionsTitle;
  
  // Recent items strings
  String errorLoadingRecentItems(String message) => _l10n.errorLoadingRecentItems(message);
  String get retry => _l10n.retry;
  String get tryAgain => _l10n.tryAgain;
  String get unexpectedState => _l10n.unexpectedState;
  String get errorLoadingRecentItemsTitle => _l10n.errorLoadingRecentItemsTitle;
  String get totalItems => _l10n.totalItems;
  String get flashcards => _l10n.flashcards;
  String get lastStudied => _l10n.lastStudied;
  String get all => _l10n.all;
  String get resumeStudy => _l10n.resumeStudy;
  String get practice => _l10n.practice;
  String get view => _l10n.view;
  String get completedBadge => _l10n.completedBadge;
  String get flashcard => _l10n.flashcard;
  String get interviewQuestion => _l10n.interviewQuestion;
  String get noRecentlyViewedItems => _l10n.noRecentlyViewedItems;
  String get startStudyingMessage => _l10n.startStudyingMessage;
  String get studyFlashcards => _l10n.studyFlashcards;
  String get practiceInterviews => _l10n.practiceInterviews;
  String get flashcardSetNotFound => _l10n.flashcardSetNotFound;
  
  // Factory to create from context
  static L10nExt of(BuildContext context) {
    return L10nExt(AppLocalizations.of(context));
  }
}
