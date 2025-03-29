import 'package:flutter/material.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We never show login on startup - only show login when user creates more than 2 decks
    // Login will be shown as a popup from HomeScreen when needed
    return const HomeScreen();
  }
}

// This is a utility function that can be called from any screen to show the login modal
Future<void> showLoginScreen(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: LoginScreen(
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}
