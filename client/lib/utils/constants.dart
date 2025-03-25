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

  static const Map<String, String> gradeDescriptions = {
    'A': 'Excellent understanding',
    'B': 'Good understanding with minor gaps',
    'C': 'Partial understanding with significant gaps',
    'D': 'Limited understanding',
    'F': 'Incorrect or insufficient answer',
  };
}
