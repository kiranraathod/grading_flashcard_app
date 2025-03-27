import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/flashcard_service.dart';
import '../services/user_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/user_progress_widget.dart';
import '../widgets/streak_calendar_widget.dart';
import '../widgets/flashcard_set_list_widget.dart';
import 'import_modal_screen.dart';
import 'profile_screen.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SearchBarWidget(),
                  ),
                  Consumer<UserService>(
                    builder: (context, userService, _) => UserProgressWidget(
                      level: userService.level,
                      xp: userService.xp,
                      maxXp: userService.maxXp,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<UserService>(
                    builder: (context, userService, _) => StreakCalendarWidget(
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
                      builder: (context, flashcardService, _) =>
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
    // Check if user is authenticated before allowing creation
    final userService = Provider.of<UserService>(context, listen: false);
    if (!userService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to create flashcards'),
          backgroundColor: Colors.red,
        ),
      );
      _showLoginScreen();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ImportModalScreen(),
    );
  }
}
