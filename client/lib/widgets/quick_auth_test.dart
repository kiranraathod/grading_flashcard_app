import 'package:flutter/material.dart';
import '../widgets/authentication_popup.dart';

/// Quick test widget for testing authentication popup
/// Can be added to any screen for immediate testing
class QuickAuthTest extends StatelessWidget {
  const QuickAuthTest({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _testAuthenticationPopup(context),
      tooltip: 'Test Auth Popup',
      backgroundColor: Colors.orange,
      child: const Icon(Icons.login),
    );
  }

  void _testAuthenticationPopup(BuildContext context) {
    debugPrint('🚨 QUICK TEST: Triggering authentication popup');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AuthenticationPopup(),
    );
  }
}
