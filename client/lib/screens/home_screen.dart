import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../widgets/flashcard_deck_card.dart';
import '../widgets/create_deck_card.dart';
import '../widgets/recent/recent_tab_content.dart';
import '../widgets/multi_action_fab.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';
import 'create_flashcard_screen.dart';
import 'study_screen.dart';
import 'interview_questions_screen.dart';
import 'create_interview_question_screen.dart';
import 'job_description_question_generator_screen.dart';
import 'question_set_detail_screen.dart';
import '../models/flashcard_set.dart';
import '../models/question_set.dart';
import '../services/flashcard_service.dart';
import '../services/interview_service.dart';
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
      backgroundColor: context.backgroundColor,
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
                            
                            Color bgColor = context.surfaceVariantColor;
                            Color textColor = context.onSurfaceVariantColor;
                            Border? border;
                            
                            if (isToday) {
                              bgColor = context.primaryColor.withOpacityFix(0.1);
                              textColor = context.primaryColor;
                              border = Border.all(
                                color: context.primaryColor,
                                width: 2,
                              );
                            } else if (isPast) {
                              bgColor = context.primaryColor;
                              textColor = context.onPrimaryColor;
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
                                  style: context.bodySmall?.copyWith(
                                    color: context.onSurfaceVariantColor,
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
                              style: context.bodyMedium?.copyWith(
                                color: context.onSurfaceVariantColor,
                              ),
                            ),
                            Text(
                              '71%',
                              style: context.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 0.71,
                            backgroundColor: context.surfaceVariantColor,
                            valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
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
                            color: context.surfaceVariantColor,
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
                                    color: _activeTab == 'Decks' ? context.surfaceColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: _activeTab == 'Decks' && context.isDarkMode
                                        ? Border.all(
                                            color: context.primaryColor.withValues(alpha: 0.2),
                                            width: 1,
                                          )
                                        : null,
                                    boxShadow: _activeTab == 'Decks' ? [
                                      BoxShadow(
                                        color: context.isDarkMode 
                                            ? context.primaryColor.withValues(alpha: 0.1)
                                            : Colors.grey.withOpacityFix(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Text(
                                    'Decks',
                                    style: context.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: _activeTab == 'Decks' 
                                        ? context.primaryColor
                                        : context.onSurfaceVariantColor,
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
                                        color: _activeTab == 'Interview Questions' ? context.surfaceColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: _activeTab == 'Interview Questions' && context.isDarkMode
                                            ? Border.all(
                                                color: context.primaryColor.withValues(alpha: 0.2),
                                                width: 1,
                                              )
                                            : null,
                                        boxShadow: _activeTab == 'Interview Questions' ? [
                                          BoxShadow(
                                            color: context.isDarkMode 
                                                ? context.primaryColor.withValues(alpha: 0.1)
                                                : Colors.grey.withOpacityFix(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ] : null,
                                      ),
                                      child: Text(
                                        'Interview Questions',
                                        style: context.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: _activeTab == 'Interview Questions' 
                                            ? context.primaryColor
                                            : context.onSurfaceVariantColor,
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
                                        painter: ArrowPainter(color: context.errorColor),
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
                                    color: _activeTab == 'Recent' ? context.surfaceColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: _activeTab == 'Recent' && context.isDarkMode
                                        ? Border.all(
                                            color: context.primaryColor.withValues(alpha: 0.2),
                                            width: 1,
                                          )
                                        : null,
                                    boxShadow: _activeTab == 'Recent' ? [
                                      BoxShadow(
                                        color: context.isDarkMode 
                                            ? context.primaryColor.withValues(alpha: 0.1)
                                            : Colors.grey.withOpacityFix(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: Text(
                                    'Recent',
                                    style: context.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: _activeTab == 'Recent' 
                                        ? context.primaryColor
                                        : context.onSurfaceVariantColor,
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
                                border: Border.all(color: context.colorScheme.outline),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list, size: 16, color: context.onSurfaceVariantColor),
                                  SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: context.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.colorScheme.outline),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: context.onSurfaceVariantColor),
                                  SizedBox(width: 4),
                                  Text(
                                    'Last Updated',
                                    style: context.bodySmall,
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: context.onSurfaceVariantColor),
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
        backgroundColor: context.primaryColor,  // This will now use grey
        activeColor: context.isDarkMode 
            ? context.appTheme.primaryDarkHover ?? context.primaryColor 
            : context.primaryColor,
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
    final interviewService = Provider.of<InterviewService>(context);
    final questionSets = interviewService.questionSets;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Consolidated Data Science Interview Questions card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DS.spacingM),
          decoration: BoxDecoration(
            color: context.secondaryColor.withOpacityFix(0.1),
            borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
            border: Border.all(color: context.secondaryColor.withOpacityFix(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Science Interview Questions',
                style: context.titleLarge,
              ),
              const SizedBox(height: DS.spacingS),
              
              // Question count and update time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '64 questions total',
                    style: context.bodyMedium,
                  ),
                  Text(
                    'Updated 2d ago',
                    style: context.bodySmall,
                  ),
                ],
              ),
              
              const SizedBox(height: DS.spacingS),
              
              // Progress bar (empty for now)
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                // Progress bar would go here
              ),
              
              const SizedBox(height: 4),
              
              // Status text
              Text(
                'Not started',
                style: context.bodySmall,
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
                  backgroundColor: context.primaryColor,
                  foregroundColor: context.onPrimaryColor,
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
        
        // Question Sets from Job Descriptions
        Text(
          'Other Interview Categories',
          style: context.titleMedium,
        ),
        
        const SizedBox(height: DS.spacingM),
        
        // Show question sets if available, otherwise show topic categories
        questionSets.isEmpty
            ? _buildTopicCategories()
            : _buildQuestionSetGrid(questionSets),
      ],
    );
  }
  
  // Method to build a grid of question sets
  Widget _buildQuestionSetGrid(List<QuestionSet> questionSets) {
    return Column(
      children: [
        // Question sets grid - Updated to match Browse by Topic grid layout
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,  // Match the topic cards aspect ratio
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questionSets.length,
          itemBuilder: (context, index) {
            final set = questionSets[index];
            return Card(
              color: context.surfaceColor,
              elevation: context.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: context.colorScheme.outline.withOpacityFix(0.5),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionSetDetailScreen(setId: set.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Set title
                      Text(
                        set.title,
                        style: context.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Question count
                      Text(
                        '${set.questionIds.length} questions',
                        style: context.bodySmall?.copyWith(
                          color: context.onSurfaceVariantColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Add a button to create a new question set from a job description
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JobDescriptionQuestionGeneratorScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Questions from Job Description'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.primaryColor,
              side: BorderSide(color: context.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        // After question sets, show topic categories
        const SizedBox(height: 32),
        Text(
          'Browse by Topic',
          style: context.titleMedium,
        ),
        const SizedBox(height: 16),
        _buildTopicCategories(),
      ],
    );
  }
  
  // Method for displaying topic categories
  Widget _buildTopicCategories() {
    return GridView.count(
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
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
          border: Border.all(color: context.colorScheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: context.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count questions',
              style: context.bodySmall,
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
            color: context.onSurfaceVariantColor,
          ),
          const SizedBox(height: DS.spacingM),
          Text(
            title,
            style: context.titleLarge,
          ),
          const SizedBox(height: DS.spacingS),
          Text(
            subtitle,
            style: context.bodyMedium,
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