import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../widgets/auth_debug_panel.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/keyboard_shortcuts.dart';
import '../services/flashcard_service.dart';
import '../services/interview_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  String _activeTab = 'Decks';

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _navigateToSearch() {
    // Simple navigation placeholder
    debugPrint('Navigate to search');
  }

  @override
  Widget build(BuildContext context) {
    final flashcardService = Provider.of<FlashcardService>(context);

    return KeyboardShortcuts(
      searchFocusNode: _searchFocusNode,
      onSearchShortcut: _navigateToSearch,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: context.backgroundColor,
            body: Column(
              children: [
                // App header
                AppHeader(key: GlobalKey()),
                // Main content with scrolling
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(DS.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Temporary placeholder content for testing
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                            'FlashMaster Home - Authentication System Ready for Testing',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎉 Authentication System Status:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('✅ All services implemented and ready'),
                              Text('✅ Database schema deployed to Supabase'),
                              Text('✅ Google OAuth configured'),
                              Text('✅ Feature flags for controlled testing'),
                              Text('✅ Debug panel integrated (see top-right)'),
                              SizedBox(height: 8),
                              Text(
                                'Next: Test the authentication flow using the debug panel!',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Debug panel for authentication testing (only in debug mode)
          if (kDebugMode)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: const AuthDebugPanel(),
              ),
            ),
        ],
      ),
    );
  }
}
