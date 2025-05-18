import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FlashMaster'**
  String get appTitle;

  /// Label for the Decks tab in the main navigation
  ///
  /// In en, this message translates to:
  /// **'Decks'**
  String get decksTab;

  /// Label for the Interview Questions tab in the main navigation
  ///
  /// In en, this message translates to:
  /// **'Interview Questions'**
  String get interviewQuestionsTab;

  /// Label for the Recent tab in the main navigation
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentTab;

  /// Button text to create a new flashcard deck
  ///
  /// In en, this message translates to:
  /// **'Create Deck'**
  String get createDeck;

  /// Button text to practice interview questions
  ///
  /// In en, this message translates to:
  /// **'Practice Questions'**
  String get practiceQuestions;

  /// Weekly goal progress format
  ///
  /// In en, this message translates to:
  /// **'{completed}/{goal} days'**
  String weeklyGoalFormat(int completed, int goal);

  /// Weekly goal display
  ///
  /// In en, this message translates to:
  /// **'Weekly Goal: {weeklyGoal}'**
  String weeklyGoal(String weeklyGoal);

  /// Number of questions in a category
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionCount(int count);

  /// Time since last update
  ///
  /// In en, this message translates to:
  /// **'Updated {time} ago'**
  String updatedAgo(String time);

  /// Status for tasks that haven't been started
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// Filter button label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort option for last updated time
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// Category name for Data Science
  ///
  /// In en, this message translates to:
  /// **'Data Science'**
  String get dataScience;

  /// Title for interview questions section
  ///
  /// In en, this message translates to:
  /// **'Interview Questions'**
  String get interviewQuestions;

  /// Header for other interview categories section
  ///
  /// In en, this message translates to:
  /// **'Other Interview Categories'**
  String get otherCategories;

  /// Header for browsing questions by topic
  ///
  /// In en, this message translates to:
  /// **'Browse by Topic'**
  String get browseByTopic;

  /// Short form of Sunday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sunday;

  /// Short form of Monday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get monday;

  /// Short form of Tuesday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tuesday;

  /// Short form of Wednesday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wednesday;

  /// Short form of Thursday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get thursday;

  /// Short form of Friday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get friday;

  /// Short form of Saturday for weekly calendar
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get saturday;

  /// Label for current day in calendar
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
