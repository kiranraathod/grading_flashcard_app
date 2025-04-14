import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';
import 'services/flashcard_service.dart';
import 'services/user_service.dart';
import 'services/network_service.dart';
import 'services/api_service.dart';
import 'services/speech_to_text_service.dart';
import 'widgets/error_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create and register services
    final apiService = ApiService();
    final speechToTextService = SpeechToTextService();
    final flashcardService = FlashcardService();
    final userService = UserService();
    final networkService = NetworkService();

    return MultiProvider(
      providers: [
        // Services as Providers (for backward compatibility)
        ChangeNotifierProvider(create: (_) => flashcardService),
        ChangeNotifierProvider(create: (_) => userService),
        ChangeNotifierProvider(create: (_) => networkService),

        // Services as Repositories for BLoCs
        Provider<ApiService>.value(value: apiService),
        Provider<SpeechToTextService>.value(value: speechToTextService),
      ],
      child: ErrorHandler(
        child: MaterialApp(
          title: 'LLM Flashcards',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system,
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
