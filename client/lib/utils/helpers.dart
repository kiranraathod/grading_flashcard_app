import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class Helpers {
  /// Formats a score for display
  static String formatScore(int? score) {
    if (score == null) return 'N/A';
    return score.toString();
  }

  /// Converts a score to a color
  static Color scoreToColor(int? score) {
    if (score == null) return Colors.grey;

    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.amber;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Gets score description text
  static String getScoreDescription(int? score) {
    if (score == null) return 'No Score';
    
    if (score >= 90) return 'Excellent Answer';
    if (score >= 80) return 'Good Answer';
    if (score >= 70) return 'Satisfactory Answer';
    if (score >= 60) return 'Needs Improvement';
    if (score > 0) return 'Incomplete Answer';
    return 'No Score';
  }

  /// Converts a score to a letter grade (for backward compatibility)
  static String scoreToGrade(int? score) {
    if (score == null) return 'F';
    
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Legacy grade functions (keeping for compatibility)
  /// Formats a grade for display
  static String formatGrade(String? grade) {
    if (grade == null) return 'N/A';
    return grade;
  }

  /// Converts a string grade to a color
  static Color gradeToColor(String? grade) {
    if (grade == null) return Colors.grey;

    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.amber;
      case 'D':
        return Colors.orange;
      case 'F':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// Formats a list of suggestions for display
  static String formatSuggestions(List<String>? suggestions) {
    if (suggestions == null || suggestions.isEmpty) {
      return 'No suggestions available.';
    }
    return suggestions.join('\n• ');
  }

  /// Filters flashcards by review status
  static List<Flashcard> filterFlashcards(
    List<Flashcard> flashcards,
    bool showMarkedOnly,
  ) {
    if (!showMarkedOnly) return flashcards;
    return flashcards.where((card) => card.isMarkedForReview).toList();
  }

  /// Generates a unique ID for a flashcard
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Shows a snackbar with a message
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  /// Shows a loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  /// Hides the current dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
}
