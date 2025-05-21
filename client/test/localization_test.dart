import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flashcard_app/utils/app_localizations_extension.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Improved mock implementation of AppLocalizations for testing
class MockAppLocalizations implements AppLocalizations {
  @override
  String get localeName => 'en';
  
  // Return empty string for all the localized strings we've added
  @override
  String get submitToTrackProgress => '';
  @override
  String get typeYourAnswer => '';
  @override
  String get stopListening => '';
  @override
  String get startSpeechToText => '';
  @override
  String get submitAnswerUpdateProgress => '';
  @override
  String get offlineMessage => '';
  @override
  String get serverConnectionError => '';
  @override
  String get search => '';
  
  // Default implementation for other methods
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // For getters, return empty string to avoid type errors
    if (invocation.isGetter) {
      return '';
    }
    return null;
  }
}
void main() {
  group('Localization Extension Tests', () {
    test('Extension methods access is properly implemented', () {
      // Create an instance of L10nExt with our mock
      final instance = L10nExt(MockAppLocalizations());
      
      // Verify that all the extension methods we added exist and return Strings
      try {
        // Access each localized string getter
        expect(instance.submitToTrackProgress, isA<String>());
        expect(instance.typeYourAnswer, isA<String>());
        expect(instance.stopListening, isA<String>());
        expect(instance.startSpeechToText, isA<String>());
        expect(instance.submitAnswerUpdateProgress, isA<String>());
        expect(instance.offlineMessage, isA<String>());
        expect(instance.serverConnectionError, isA<String>());
        expect(instance.search, isA<String>());
        
        // If we get here, all methods exist and return strings
        expect(true, isTrue); // Test passes
      } catch (e) {
        fail('One or more extension methods are missing or not returning strings: $e');
      }
    });
    
    test('L10nExt helper follows the expected pattern', () {
      // Create an instance of L10nExt with our mock
      final instance = L10nExt(MockAppLocalizations());
      
      // This test is primarily to verify that our implementation
      // follows the established pattern for localization
      expect(instance, isNotNull);
      
      // Check that search returns a string
      final searchValue = instance.search;
      expect(searchValue, isA<String>());
    });
  });
}