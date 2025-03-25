import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
    }
    return _isInitialized;
  }

  Future<String> startListening() async {
    String recognizedText = '';

    if (await initialize()) {
      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
        },
      );

      // Wait for speech recognition to complete or timeout
      await Future.delayed(const Duration(seconds: 10));
      _speech.stop();
    }

    return recognizedText;
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
