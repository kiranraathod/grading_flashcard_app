import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/flashcard_deck_card.dart';
import '../widgets/create_deck_card.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import 'create_flashcard_screen.dart';
import 'study_screen.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeTab = 'Decks';
  
  // Mock data for streak calendar
  final int _weeklyGoal = 7;
  final int _daysCompleted = 5;
  
  @override
  Widget build(BuildContext context) {
    final flashcardService = Provider.of<FlashcardService>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // App header
          const AppHeader(),
          
          // Main content with scrolling
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DS.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Streak calendar (simplified version from reference)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Streak calendar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (index) {
                            // Determine the day style
                            bool isToday = index == 1; // Mock: Monday is today
                            bool isPast = index < 1; // Days before today
                            
                            Color bgColor = Colors.grey.shade100;
                            Color textColor = Colors.grey.shade400;
                            Border? border;
                            
                            if (isToday) {
                              bgColor = Color.fromRGBO(16, 185, 129, 0.1);
                              textColor = AppColors.primary;
                              border = Border.all(
                                color: AppColors.primary,
                                width: 2,
                              );
                            } else if (isPast) {
                              bgColor = AppColors.primary;
                              textColor = Colors.white;
                            }
                            
                            return Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    shape: BoxShape.circle,
                                    border: border,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isToday ? 'Today' : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Progress bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weekly Goal: $_daysCompleted/$_weeklyGoal days',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '71%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 0.71,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DS.spacingM),
                  
                  // Tabs styled to match React code
                  Container(
                    margin: EdgeInsets.only(bottom: 24), // mt-6 in Tailwind is 1.5rem (24px)
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tabs in a container with gray background
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Decks tab
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeTab = 'Decks';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'Decks' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _activeTab == 'Decks' ? [
                                      BoxShadow(
                                        color: Color.fromRGBO(128, 128, 128, 0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Text(
                                    'Decks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _activeTab == 'Decks' 
                                        ? AppColors.primary
                                        : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Interview Questions tab
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeTab = 'Interview Questions';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'Interview Questions' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _activeTab == 'Interview Questions' ? [
                                      BoxShadow(
                                        color: Color.fromRGBO(128, 128, 128, 0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Text(
                                    'Interview Questions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _activeTab == 'Interview Questions' 
                                        ? AppColors.primary
                                        : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Recent tab
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeTab = 'Recent';
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 'Recent' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _activeTab == 'Recent' ? [
                                      BoxShadow(
                                        color: Color.fromRGBO(128, 128, 128, 0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Text(
                                    'Recent',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _activeTab == 'Recent' 
                                        ? AppColors.primary
                                        : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Filter and Sort
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    'Last Updated',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DS.spacingL),
                  
                  // Tab content
                  _buildTabContent(flashcardService),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating action button (simplified like reference)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateFlashcardScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildTabContent(FlashcardService flashcardService) {
    switch (_activeTab) {
      case 'Decks':
        return _buildDecksTab(flashcardService);
      case 'Interview Questions':
        return _buildInterviewTab();
      case 'Recent':
        return _buildRecentTab();
      default:
        return _buildDecksTab(flashcardService);
    }
  }
  
  Widget _buildDecksTab(FlashcardService flashcardService) {
    // Get flashcard sets from service or use mock data
    final flashcardSets = flashcardService.sets;
    
    // If no sets, show empty state
    if (flashcardSets.isEmpty) {
      return _buildEmptyState('No flashcard decks yet', 'Create your first deck');
    }
    
    // Mock data for decks (replace with actual data in production)
    final List<Map<String, dynamic>> decks = [
      {'title': 'Python Basics', 'category': 'Python', 'cards': 12, 'progress': 75},
      {'title': 'Python Classes', 'category': 'Python', 'cards': 8, 'progress': 25},
      {'title': 'Python Data Types', 'category': 'Python', 'cards': 15, 'progress': 40},
      {'title': 'Python Functions', 'category': 'Python', 'cards': 10, 'progress': 0},
    ];
    
    // Responsive grid layout similar to the React code
    // (grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6)
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    
    if (screenWidth >= 1024) { // lg breakpoint
      crossAxisCount = 4;
    } else if (screenWidth >= 640) { // sm breakpoint
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 0.85, // Cards are slightly taller than wide
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 24, // gap-6 in Tailwind is 1.5rem (24px)
      mainAxisSpacing: 24, // gap-6
      children: [
        ...decks.map((deck) => FlashcardDeckCard(
              title: deck['title'],
              category: deck['category'],
              cardCount: deck['cards'],
              progressPercent: deck['progress'],
              isStudyDeck: true,
              onTap: () {
                // Navigate to study screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudyScreen(
                      set: FlashcardSet(
                        id: '1',
                        title: deck['title'],
                        flashcards: [],
                      ),
                    ),
                  ),
                );
              },
            )),
        CreateDeckCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateFlashcardScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildInterviewTab() {
    // Mock data for interview decks
    final List<Map<String, dynamic>> interviewDecks = [
      {'title': 'Data Scientist Interview', 'category': 'Data Science', 'cards': 24},
      {'title': 'Data Analyst', 'category': 'Data Analysis', 'cards': 18},
      {'title': 'Junior Developer', 'category': 'Web Development', 'cards': 15},
      {'title': 'ML Engineer', 'category': 'Machine Learning', 'cards': 22},
    ];
    
    // Responsive grid layout similar to the React code
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    
    if (screenWidth >= 1024) { // lg breakpoint
      crossAxisCount = 4;
    } else if (screenWidth >= 640) { // sm breakpoint
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 0.85, // Cards are slightly taller than wide
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DS.spacingS,
      mainAxisSpacing: DS.spacingS,
      children: interviewDecks.map((deck) => FlashcardDeckCard(
            title: deck['title'],
            category: deck['category'],
            cardCount: deck['cards'],
            progressPercent: 0,
            isStudyDeck: false,
            onTap: () {
              // Navigate to interview practice screen
              // This would be implemented similarly to study screen
            },
          )).toList(),
    );
  }
  
  Widget _buildRecentTab() {
    // Matches the React code: "flex items-center justify-center h-40 bg-gray-50 rounded-lg border border-dashed"
    return Container(
      width: double.infinity,
      height: 160, // h-40 in Tailwind is 10rem (160px)
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8), // rounded-lg
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'Your recently viewed flashcards will appear here',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: DS.spacingM),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: DS.spacingS),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: DS.spacingL),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFlashcardScreen(),
                ),
              );
            },
            style: DS.primaryButtonStyle,
            child: const Text('Create Deck'),
          ),
        ],
      ),
    );
  }
}