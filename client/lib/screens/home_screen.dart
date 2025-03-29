import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../services/user_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/user_progress_widget.dart';
import '../widgets/streak_calendar_widget.dart';
import '../widgets/flashcard_set_list_widget.dart';
import 'import_modal_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/user_menu_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Check authentication and load data
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Simulate initial loading
    await Future.delayed(const Duration(milliseconds: 300));

    // Load data for both authenticated and non-authenticated users
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginScreen() {
    debugPrint('Showing login screen popup after creating more than 2 decks');
    
    // Show as a dialog with settings to indicate it's a popup
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: LoginScreen(
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'LLM Flashcards',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          // User menu widget
          UserMenuWidget(),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SearchBarWidget(),
                    ),
                    Consumer<UserService>(
                      builder:
                          (context, userService, _) => UserProgressWidget(
                            level: userService.level,
                            xp: userService.xp,
                            maxXp: userService.maxXp,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<UserService>(
                      builder:
                          (context, userService, _) => StreakCalendarWidget(
                            streakDays: userService.weeklyStreak,
                            currentDay: userService.currentDay,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFilterDropdown(),
                          Row(
                            children: [
                              const Text('Last Updated'),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.filter_list),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Consumer<FlashcardService>(
                        builder:
                            (context, flashcardService, _) =>
                                flashcardService.sets.isEmpty
                                    ? _buildEmptyState()
                                    : FlashcardSetListWidget(
                                      flashcardSets: flashcardService.sets,
                                    ),
                      ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateOptions(context);
        },
        backgroundColor: const Color(0xFF1A5E34),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'See saved/trash',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Press the + button to create',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final flashcardService = Provider.of<FlashcardService>(
      context,
      listen: false,
    );

    // Allow creation without login, but show login popup after creating more than two decks
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ImportModalScreen(),
    ).then((_) {
      // Check if user has created more than two decks and is not logged in
      if (flashcardService.createdDecksCount > 2 &&
          !userService.isAuthenticated) {
        // Show login popup only after user has created more than 2 decks
        _showLoginScreen();
      }
    });
  }
}
