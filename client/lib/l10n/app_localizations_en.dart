// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FlashMaster';

  @override
  String get decksTab => 'Decks';

  @override
  String get interviewQuestionsTab => 'Interview Questions';

  @override
  String get recentTab => 'Recent';

  @override
  String get createDeck => 'Create Deck';

  @override
  String get practiceQuestions => 'Practice Questions';

  @override
  String weeklyGoalFormat(int completed, int goal) {
    return '$completed/$goal days';
  }

  @override
  String weeklyGoal(String weeklyGoal) {
    return 'Weekly Goal: $weeklyGoal';
  }

  @override
  String questionCount(int count) {
    return '$count questions';
  }

  @override
  String updatedAgo(String time) {
    return 'Updated $time ago';
  }

  @override
  String get notStarted => 'Not started';

  @override
  String get filter => 'Filter';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get dataScience => 'Data Science';

  @override
  String get interviewQuestions => 'Interview Questions';

  @override
  String get otherCategories => 'Other Interview Categories';

  @override
  String get browseByTopic => 'Browse by Topic';

  @override
  String get sunday => 'S';

  @override
  String get monday => 'M';

  @override
  String get tuesday => 'T';

  @override
  String get wednesday => 'W';

  @override
  String get thursday => 'T';

  @override
  String get friday => 'F';

  @override
  String get saturday => 'S';

  @override
  String get today => 'Today';
}
