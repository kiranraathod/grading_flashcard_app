import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/app_header.dart';
import '../widgets/auth_debug_panel.dart';
import '../widgets/authenticated_action.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/keyboard_shortcuts.dart';
import '../utils/emergency_auth_trigger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _searchFocusNode = FocusNode();

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
    // Check authentication status every time home screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EmergencyAuthTrigger.checkAndTrigger(context);
    });
    
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
                        // Demo Authentication System
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'FlashMaster - Enhanced Authentication System',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: DS.spacingM),
                                  const UsageStatusIndicator(),
                                ],
                              ),
                              const SizedBox(height: DS.spacingM),
                              Text(
                                'Try the interactive actions below to test the authentication system:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Interactive Demo Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Demo Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: DS.spacingM),
                              
                              // Study Flashcard Action
                              AuthenticatedAction(
                                actionType: 'study_flashcard',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Studying flashcard! 📚')),
                                  );
                                },
                                showUsageHint: true,
                                child: Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.quiz_outlined),
                                    title: const Text('Study Flashcards'),
                                    subtitle: const Text('Practice with interactive flashcards'),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: DS.spacingM),
                              
                              // Interview Practice Action
                              AuthenticatedAction(
                                actionType: 'interview_practice',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Starting interview practice! 🎯')),
                                  );
                                },
                                showUsageHint: true,
                                child: Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.psychology_outlined),
                                    title: const Text('Interview Practice'),
                                    subtitle: const Text('Practice with AI-powered questions'),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: DS.spacingM),
                              
                              // Create Content Action
                              AuthenticatedButton(
                                actionType: 'create_content',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Creating new content! ✨')),
                                  );
                                },
                                showUsageHint: true,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline),
                                    SizedBox(width: DS.spacingS),
                                    Text('Create New Content'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎉 Authentication System Status:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
