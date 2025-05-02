import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../widgets/flashcard_deck_card.dart';
import '../widgets/create_deck_card.dart';
import '../widgets/recent/recent_tab_content.dart';
import '../widgets/multi_action_fab.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';
import 'create_flashcard_screen.dart';
import 'study_screen.dart';
import 'interview_questions_screen.dart';
import 'create_interview_question_screen.dart';
import 'job_description_question_generator_screen.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../services/recent_view_service.dart';
import '../widgets/interview/arrow_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeTab = 'Decks';
  
  // Data for streak calendar
  final int _weeklyGoal = 7;
  final int _daysCompleted = 5;
  
  // Calculate the progress percentage based on completed flashcards
  int _calculateProgress(FlashcardSet set) {
    if (set.flashcards.isEmpty) return 0;
    
    // Count completed flashcards
    int completedCount = set.flashcards.where((card) => card.isCompleted).length;
    
    // Calculate percentage - always start at zero for clean state
    return (completedCount / set.flashcards.length * 100).round();
  }
  
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
                              
                              // Interview Questions tab with arrow
                              Stack(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _activeTab = 'Interview Questions';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _activeTab == 'Interview Questions' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: _activeTab == 'Interview Questions' ? [
                                          BoxShadow(
                                            color: const Color.fromRGBO(128, 128, 128, 0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
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
                                  
                                  // Arrow indicator (only show when tab is active)
                                  if (_activeTab == 'Interview Questions')
                                    Positioned(
                                      top: -15,
                                      right: 20,
                                      child: CustomPaint(
                                        size: const Size(20, 15),
                                        painter: ArrowPainter(color: Colors.red),
                                      ),
                                    ),
                                ],
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
      
      // Multi-action Floating Action Button
      floatingActionButton: MultiActionFab(
        backgroundColor: Colors.green,
        tooltip: 'Create new content',
        options: [
          MultiActionFabOption(
            label: 'Create Flashcards',
            icon: Icons.style,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFlashcardScreen(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          MultiActionFabOption(
            label: 'Create New Question',
            icon: Icons.add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInterviewQuestionScreen(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          MultiActionFabOption(
            label: 'Generate from Job Description',
            icon: Icons.description,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JobDescriptionQuestionGeneratorScreen(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
        ],
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
    // Get flashcard sets from service
    final flashcardSets = flashcardService.sets;
    
    // If no sets, show empty state
    if (flashcardSets.isEmpty) {
      return _buildEmptyState('No flashcard decks yet', 'Create your first deck');
    }
    
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
        ...flashcardSets.map((set) => FlashcardDeckCard(
              title: set.title,
              category: set.description.isNotEmpty ? set.description : 'Python',
              cardCount: set.flashcards.length,
              progressPercent: _calculateProgress(set),
              isStudyDeck: true,
              onTap: () async {
                // Navigate to study screen with the actual flashcard set
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StudyScreen(
                      set: set,
                    ),
                  ),
                ).then((_) {
                  // Check if the widget is still mounted before accessing context
                  if (mounted) {
                    // Explicitly reload flashcard sets after returning
                    final flashcardService = Provider.of<FlashcardService>(context, listen: false);
                    flashcardService.reloadSets(); // Use the public reload method
                    
                    // Extra safety - force state refresh
                    setState(() {
                      debugPrint('Forcing home screen refresh after returning from study');
                    });
                  }
                });
                
                // Force refresh after returning
                setState(() {
                  debugPrint('Refreshing home screen after study session');
                });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Consolidated Data Science Interview Questions card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DS.spacingM),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Science Interview Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: DS.spacingS),
              
              // Question count and update time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '64 questions total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Updated 2d ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DS.spacingS),
              
              // Progress bar (empty for now)
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                // Progress bar would go here
              ),
              
              const SizedBox(height: 4),
              
              // Status text
              Text(
                'Not started',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              
              const SizedBox(height: DS.spacingM),
              
              // Practice Questions button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InterviewQuestionsScreen(
                        category: 'Data Science',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DS.spacingM,
                    vertical: DS.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                  ),
                ),
                child: const Text('Practice Questions'),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: DS.spacingL),
        
        // Other interview categories in a grid (simplified)
        Text(
          'Other Interview Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: DS.spacingM),
        
        // Simplified grid
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: DS.spacingS,
          mainAxisSpacing: DS.spacingS,
          children: [
            _buildCategoryChip('Data Analysis', 18),
            _buildCategoryChip('Web Development', 15),
            _buildCategoryChip('Machine Learning', 22),
            _buildCategoryChip('SQL', 10),
            _buildCategoryChip('Python', 14),
            _buildCategoryChip('Data Visualization', 8),
          ],
        ),
      ],
    );
  }

  // Helper method for category chips
  Widget _buildCategoryChip(String title, int count) {
    return InkWell(
      onTap: () {
        // Navigate to interview questions for this category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InterviewQuestionsScreen(
              category: title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DS.spacingS,
          vertical: DS.spacing2xs,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count questions',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentTab() {
    // No longer need to create a new BlocProvider here,
    // since we're using the global one from main.dart
    return Builder(
      builder: (context) {
        // Force a refresh of recent items when the tab is selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Get flashcard service to sync completion status
          final flashcardService = Provider.of<FlashcardService>(context, listen: false);
          final recentViewService = Provider.of<RecentViewService>(context, listen: false);
          
          // DEBUG: Create a test recent view item if none exist
          if (flashcardService.sets.isNotEmpty && flashcardService.sets.first.flashcards.isNotEmpty) {
            debugPrint('⭐ CREATING TEST RECENT ITEM FOR DEBUGGING ⭐');
            final testSet = flashcardService.sets.first;
            final testCard = testSet.flashcards.first;
            
            // Record this as a recent view
            context.read<RecentViewBloc>().add(
              RecordFlashcardView(
                flashcard: testCard,
                set: testSet,
                isCompleted: true, // Mark it as completed for testing
              ),
            );
          }
          
          // First load recent views
          context.read<RecentViewBloc>().add(const LoadRecentViews());
          
          // Then sync flashcard progress to keep completion status updated
          recentViewService.syncFlashcardProgress(flashcardService.sets);
        });
        
        return const RecentTabContent();
      },
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