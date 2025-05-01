class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();
  
  // API configuration
  static const Duration apiTimeout = Duration(seconds: 60);
  static const int maxRetryAttempts = 3;
  
  // Network configuration
  static const Duration networkCheckInterval = Duration(seconds: 30);
  static const Duration connectivityTimeout = Duration(seconds: 5);
  
  // Algorithm configuration
  static const double strongMatchThreshold = 0.8;
  static const double partialMatchThreshold = 0.5;
  static const double keyElementsMatchThreshold = 0.3;
  
  // Storage keys
  static const String flashcardSetsKey = 'flashcard_sets';
  // Removed level and XP related keys
  static const String userStreakKey = 'weeklyStreak';
}