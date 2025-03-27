import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  // Dynamic base URL depending on platform
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Point to the proxy server
    } else {
      return 'http://10.0.2.2:5000';
    }
  }

  // Supabase configuration
  static const String supabaseUrl = 'https://cdigijaqeovvtybvtbpl.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkaWdpamFxZW92dnR5YnZ0YnBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5NzY1MjksImV4cCI6MjA1ODU1MjUyOX0.j-AxiO_0hpkFqZ93Af9vfbDNaGP5YU1CSfTJLSk3ceQ';

  static const Map<String, String> gradeDescriptions = {
    'A': 'Excellent understanding',
    'B': 'Good understanding with minor gaps',
    'C': 'Partial understanding with significant gaps',
    'D': 'Limited understanding',
    'F': 'Incorrect or insufficient answer',
  };
  
  // Default suggestions for different grades
  static const Map<String, List<String>> defaultSuggestions = {
    'A': [
      'Great job! Try exploring more advanced concepts on this topic',
      'Consider creating more challenging flashcards on this subject'
    ],
    'B': [
      'Review the minor details you missed',
      'Try rephrasing your answer for more clarity'
    ],
    'C': [
      'Focus on the key concepts you missed',
      'Try creating additional flashcards on this topic',
      'Review related material to strengthen your understanding'
    ],
    'D': [
      'Consider revisiting the fundamental concepts',
      'Break down this topic into smaller, more manageable parts',
      'Try using different learning resources for this topic'
    ],
    'F': [
      'Review the core material thoroughly',
      'Try a different approach to learning this topic',
      'Consider seeking additional help or resources'
    ],
  };
}
