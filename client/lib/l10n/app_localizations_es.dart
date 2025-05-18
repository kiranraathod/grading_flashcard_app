// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FlashMaster';

  @override
  String get decksTab => 'Mazos';

  @override
  String get interviewQuestionsTab => 'Preguntas de Entrevista';

  @override
  String get recentTab => 'Reciente';

  @override
  String get createDeck => 'Crear Mazo';

  @override
  String get practiceQuestions => 'Practicar Preguntas';

  @override
  String weeklyGoalFormat(int completed, int goal) {
    return '$completed/$goal días';
  }

  @override
  String weeklyGoal(String weeklyGoal) {
    return 'Meta Semanal: $weeklyGoal';
  }

  @override
  String questionCount(int count) {
    return '$count preguntas';
  }

  @override
  String updatedAgo(String time) {
    return 'Actualizado hace $time';
  }

  @override
  String get notStarted => 'No iniciado';

  @override
  String get filter => 'Filtrar';

  @override
  String get lastUpdated => 'Última Actualización';

  @override
  String get dataScience => 'Ciencia de Datos';

  @override
  String get interviewQuestions => 'Preguntas de Entrevista';

  @override
  String get otherCategories => 'Otras Categorías de Entrevista';

  @override
  String get browseByTopic => 'Navegar por Tema';

  @override
  String get sunday => 'D';

  @override
  String get monday => 'L';

  @override
  String get tuesday => 'M';

  @override
  String get wednesday => 'X';

  @override
  String get thursday => 'J';

  @override
  String get friday => 'V';

  @override
  String get saturday => 'S';

  @override
  String get today => 'Hoy';
}
