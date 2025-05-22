import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../widgets/flashcard_deck_card.dart';
import '../widgets/create_deck_card.dart';
import '../widgets/recent/recent_tab_content.dart';
import '../widgets/multi_action_fab.dart';
import '../utils/theme_utils.dart';
import '../utils/design_system.dart';
import '../utils/spacing_components.dart';
import '../utils/keyboard_shortcuts.dart';
import '../utils/responsive_helpers.dart';
import '../blocs/recent_view/recent_view_bloc.dart';
import '../blocs/recent_view/recent_view_event.dart';
import '../screens/search/search_results_screen.dart';
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  // Focus node for search functionality
  final FocusNode _searchFocusNode = FocusNode();

  // Calculate the progress percentage based on completed flashcards
  int _calculateProgress(FlashcardSet set) {
    if (set.flashcards.isEmpty) return 0;

    // Count completed flashcards
    int completedCount =
        set.flashcards.where((card) => card.isCompleted).length;

    // Calculate percentage - always start at zero for clean state
    return (completedCount / set.flashcards.length * 100).round();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Navigate to the search screen
  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchResultsScreen(initialQuery: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flashcardService = Provider.of<FlashcardService>(context);

    return KeyboardShortcuts(
      searchFocusNode: _searchFocusNode,
      onSearchShortcut: _navigateToSearch,
      child: Scaffold(
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
                              // Get the current day of the week
                              final now = DateTime.now();

                              // Convert between different day-of-week systems:
                              // - Our display array: ['S', 'M', 'T', 'W', 'T', 'F', 'S'] (0=Sun, 1=Mon, ..., 6=Sat)
                              // - DateTime.weekday: (1=Mon, 2=Tue, ..., 7=Sun)
                              int currentWeekdayIndex;

                              // Map DateTime.weekday to our array index
                              switch (now.weekday) {
                                case 1: // Monday maps to index 1
                                  currentWeekdayIndex = 1;
                                  break;
                                case 2: // Tuesday maps to index 2
                                  currentWeekdayIndex = 2;
                                  break;
                                case 3: // Wednesday maps to index 3
                                  currentWeekdayIndex = 3;
                                  break;
                                case 4: // Thursday maps to index 4
                                  currentWeekdayIndex = 4;
                                  break;
                                case 5: // Friday maps to index 5
                                  currentWeekdayIndex = 5;
                                  break;
                                case 6: // Saturday maps to index 6
                                  currentWeekdayIndex = 6;
                                  break;
                                case 7: // Sunday maps to index 0
                                  currentWeekdayIndex = 0;
                                  break;
                                default:
                                  currentWeekdayIndex = 0;
                              }

                              // Determine the day style dynamically based on the current day
                              bool isToday = index == currentWeekdayIndex;
                              bool isPast =
                                  index <
                                  currentWeekdayIndex; // Days before today

                              Color bgColor = context.surfaceVariantColor;
                              Color textColor = context.onSurfaceVariantColor;
                              Border? border;

                              if (isToday) {
                                bgColor = context.primaryColor.withOpacityFix(
                                  0.1,
                                );
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
                                    width: DS.avatarSizeM,
                                    height: DS.avatarSizeM,
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      shape: BoxShape.circle,
                                      border: border,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getDayAbbreviation(context, index),
                                        style: TextStyle(
                                          fontSize: DS.isSmallScreen(context) ? 12 : 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DSSpacing.verticalXS,
                                  Text(
                                    isToday
                                        ? AppLocalizations.of(context).today
                                        : '',
                                    style: context.bodySmall?.copyWith(
                                      color: context.onSurfaceVariantColor,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),

                          DSSpacing.verticalXL,

                          // Progress bar with dynamic calculation
                          Builder(
                            builder: (context) {
                              // Calculate percentage dynamically
                              final double progressPercentage =
                                  _daysCompleted / _weeklyGoal;
                              final int progressPercent =
                                  (progressPercentage * 100).round();

                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).weeklyGoalFormat(
                                          _daysCompleted,
                                          _weeklyGoal,
                                        ),
                                        style: context.bodyMedium?.copyWith(
                                          color: context.onSurfaceVariantColor,
                                        ),
                                      ),
                                      Text(
                                        '$progressPercent%',
                                        style: context.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  DSSpacing.verticalS,
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progressPercentage,
                                      backgroundColor:
                                          context.surfaceVariantColor,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.primaryColor,
                                      ),
                                      minHeight: DS.spacingXs,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    DSSpacing.verticalL,

                    // Tabs styled to match React code
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: DS.spacingL,
                      ), // mt-6 in Tailwind is 1.5rem (24px)
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align everything to the left
                        children: [
                          // Tabs and filters in a single row with space between
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Tabs aligned to the left
                              Container(
                                decoration: BoxDecoration(
                                  color: context.surfaceVariantColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min, // Don't expand beyond needed
                                  children: [
                                // Decks tab
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _activeTab = 'Decks';
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DS.spacingM,
                                      vertical: DS.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _activeTab == 'Decks'
                                              ? context.surfaceColor
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          _activeTab == 'Decks' &&
                                                  context.isDarkMode
                                              ? Border.all(
                                                color: context.primaryColor
                                                    .withValues(alpha: 0.2),
                                                width: 1,
                                              )
                                              : null,
                                      boxShadow:
                                          _activeTab == 'Decks'
                                              ? [
                                                BoxShadow(
                                                  color:
                                                      context.isDarkMode
                                                          ? context.primaryColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                          : Colors.grey
                                                              .withOpacityFix(
                                                                0.1,
                                                              ),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).decksTab,
                                      style: context.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _activeTab == 'Decks'
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
                                        padding: EdgeInsets.symmetric(
                                          horizontal: DS.spacingM,
                                          vertical: DS.spacingXs,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _activeTab ==
                                                      'Interview Questions'
                                                  ? context.surfaceColor
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border:
                                              _activeTab ==
                                                          'Interview Questions' &&
                                                      context.isDarkMode
                                                  ? Border.all(
                                                    color: context.primaryColor
                                                        .withValues(alpha: 0.2),
                                                    width: 1,
                                                  )
                                                  : null,
                                          boxShadow:
                                              _activeTab ==
                                                      'Interview Questions'
                                                  ? [
                                                    BoxShadow(
                                                      color:
                                                          context.isDarkMode
                                                              ? context
                                                                  .primaryColor
                                                                  .withValues(
                                                                    alpha: 0.1,
                                                                  )
                                                              : Colors.grey
                                                                  .withOpacityFix(
                                                                    0.1,
                                                                  ),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).interviewQuestionsTab,
                                          style: context.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color:
                                                _activeTab ==
                                                        'Interview Questions'
                                                    ? context.primaryColor
                                                    : context
                                                        .onSurfaceVariantColor,
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
                                          painter: ArrowPainter(
                                            color: context.errorColor,
                                          ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: DS.spacingM,
                                      vertical: DS.spacingXs,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _activeTab == 'Recent'
                                              ? context.surfaceColor
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          _activeTab == 'Recent' &&
                                                  context.isDarkMode
                                              ? Border.all(
                                                color: context.primaryColor
                                                    .withValues(alpha: 0.2),
                                                width: 1,
                                              )
                                              : null,
                                      boxShadow:
                                          _activeTab == 'Recent'
                                              ? [
                                                BoxShadow(
                                                  color:
                                                      context.isDarkMode
                                                          ? context.primaryColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                          : Colors.grey
                                                              .withOpacityFix(
                                                                0.1,
                                                              ),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).recentTab,
                                      style: context.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            _activeTab == 'Recent'
                                                ? context.primaryColor
                                                : context.onSurfaceVariantColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Filter and Sort controls aligned to the right
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Check if we have enough space for both filters side by side
                              final availableWidth = constraints.maxWidth;
                              final shouldStack = availableWidth < 300; // Threshold for stacking
                              
                              if (shouldStack) {
                                // Stack vertically on narrow screens
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFilterButton(context),
                                    DSSpacing.verticalS,
                                    _buildSortButton(context),
                                  ],
                                );
                              } else {
                                // Display horizontally without flexible sizing to avoid constraints issues
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildFilterButton(context),
                                    DSSpacing.horizontalS,
                                    _buildSortButton(context),
                                  ],
                                );
                              }
                            },
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
          backgroundColor: context.primaryColor, // This will now use grey
          activeColor:
              context.isDarkMode
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
                    builder:
                        (context) =>
                            const JobDescriptionQuestionGeneratorScreen(),
                  ),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get day abbreviation
  String _getDayAbbreviation(BuildContext context, int index) {
    final localizations = AppLocalizations.of(context);
    switch (index) {
      case 0:
        return localizations.sunday;
      case 1:
        return localizations.monday;
      case 2:
        return localizations.tuesday;
      case 3:
        return localizations.wednesday;
      case 4:
        return localizations.thursday;
      case 5:
        return localizations.friday;
      case 6:
        return localizations.saturday;
      default:
        return '';
    }
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
      return _buildEmptyState(
        'No flashcard decks yet',
        'Create your first deck',
      );
    }

    // CRITICAL FIX: Account for parent padding in width calculations
    final parentPadding = DS.spacingL * 2; // SingleChildScrollView padding on both sides
    final effectiveScreenWidth = context.getEffectiveWidth(horizontalPadding: parentPadding);
    
    // Ultra-minimal horizontal padding to maximize content width
    final horizontalPadding = DS.spacing2xs * 0.25;  // Optimized for card layout (1.0px)
    // Ultra-minimal spacing between cards to maximize usable space  
    final cardSpacing = DS.spacing2xs * 0.75;  // Optimized for card layout (3.0px)
    
    // Calculate the optimal number of columns using design system breakpoints
    final optimalColumns = DS.getCardColumnCount(effectiveScreenWidth);
    
    // Calculate optimal card width with controlled maximum size
    double getAdaptiveCardWidth() {
      // Calculate available width precisely using EFFECTIVE screen width
      final availableWidth = effectiveScreenWidth - (horizontalPadding * 2);
      
      // For multi-column layouts, calculate exact width distribution
      final totalGapWidth = (optimalColumns - 1) * cardSpacing;
      
      // Calculate card width with perfect distribution
      final remainingWidth = availableWidth - totalGapWidth;
      final calculatedCardWidth = remainingWidth / optimalColumns;
      
      // Apply maximum card width constraint for better visual balance
      final maxCardWidth = 365.0; // Target card width for optimal appearance
      final cardWidth = calculatedCardWidth > maxCardWidth ? maxCardWidth : calculatedCardWidth;
      
      // Return controlled width for better visual balance
      return cardWidth;
    }

    return Container(
      // CRITICAL FIX: Use effective screen width for container constraints
      width: effectiveScreenWidth,
      constraints: BoxConstraints(
        minWidth: effectiveScreenWidth,
        maxWidth: effectiveScreenWidth,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
        children: [
            // If the number of items doesn't match the column count exactly,
            // add spacer items to ensure proper distribution
            Builder(builder: (context) {
            final List<Widget> items = [
              ...flashcardSets.map((set) => SizedBox(
                width: getAdaptiveCardWidth(),
                height: DS.cardHeight, // Use design system card height
                child: FlashcardDeckCard(
                  title: set.title,
                  category: set.description.isNotEmpty ? set.description : 'Python',
                  cardCount: set.flashcards.length,
                  progressPercent: _calculateProgress(set),
                  isStudyDeck: true,
                  onTap: () async {
                    // Store service reference before async operation to avoid BuildContext across async gaps
                    final flashcardService = Provider.of<FlashcardService>(
                      context,
                      listen: false,
                    );
                    
                    // Navigate to study screen with the actual flashcard set
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StudyScreen(set: set),
                      ),
                    );

                    // Check if the widget is still mounted after navigation
                    if (!mounted) return;

                    // Reload flashcard sets using stored service reference
                    flashcardService.reloadSets(); // Use the public reload method

                    // Extra safety - force state refresh
                    setState(() {
                      debugPrint(
                        'Forcing home screen refresh after returning from study',
                      );
                    });
                  },
                ),
              )),
              // Create Deck Card - also needs fixed width
              SizedBox(
                width: getAdaptiveCardWidth(),
                height: DS.cardHeight, // Use design system card height
                child: CreateDeckCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateFlashcardScreen(),
                      ),
                    );
                  },
                ),
              ),
            ];
            
            // No special handling needed for single-column - just use consistent width calculation
            var updatedItems = List<Widget>.from(items);
            
            // Add placeholders when needed for multi-row layouts
            if (optimalColumns > 1) {
              final totalItems = flashcardSets.length + 1; // +1 for create deck card
              final totalRows = (totalItems / optimalColumns).ceil();
              final lastRowItems = totalItems % optimalColumns == 0 ? optimalColumns : totalItems % optimalColumns;
              
              // Only add placeholders when there's a partial last row
              if (totalRows > 1 && lastRowItems != optimalColumns) {
                final placeholdersNeeded = optimalColumns - lastRowItems;
                for (int i = 0; i < placeholdersNeeded; i++) {
                  updatedItems.add(SizedBox(
                    width: getAdaptiveCardWidth(),
                    height: 0, // Zero height to not affect layout
                  ));
                }
              }
            }
            
            return SizedBox(
              // CRITICAL FIX: Use effective width for Wrap constraint
              width: effectiveScreenWidth - (horizontalPadding * 2),
              child: Wrap(
                spacing: cardSpacing,
                runSpacing: cardSpacing,
                // Always use start alignment to ensure consistent spacing
                alignment: WrapAlignment.start,
                children: updatedItems,
              ),
            );
          }),
        ],
      ),
      ),
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
            border: Border.all(
              color: context.secondaryColor.withOpacityFix(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context).dataScience} ${AppLocalizations.of(context).interviewQuestions}',
                style: context.titleLarge,
              ),
              DSSpacing.verticalM,

              // Question count and update time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).questionCount(64),
                    style: context.bodyMedium,
                  ),
                  Text(
                    AppLocalizations.of(context).updatedAgo('2d'),
                    style: context.bodySmall,
                  ),
                ],
              ),

              DSSpacing.verticalM,

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

              DSSpacing.screenSection,

              // Status text
              Text(
                AppLocalizations.of(context).notStarted,
                style: context.bodySmall,
              ),

              const SizedBox(height: DS.spacingM),

              // Practice Questions button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const InterviewQuestionsScreen(
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
                child: Text(AppLocalizations.of(context).practiceQuestions),
              ),
            ],
          ),
        ),

        DSSpacing.screenSection,

        // Question Sets from Job Descriptions
        Text(
          AppLocalizations.of(context).otherCategories,
          style: context.titleMedium,
        ),

        DSSpacing.verticalL,

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
        // Question sets grid - Updated to use responsive design system breakpoints
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.responsiveValue(
              xs: 1,
              sm: 1, 
              md: 2,
              lg: 3,
              xl: 3,
            ),
            childAspectRatio: 2.5, // Match the topic cards aspect ratio
            crossAxisSpacing: context.orientationAwareSpacing,
            mainAxisSpacing: context.orientationAwareSpacing,
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
                      builder:
                          (context) => QuestionSetDetailScreen(setId: set.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(context.isPhone ? 12 : 16),
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
        DSSpacing.verticalL,
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const JobDescriptionQuestionGeneratorScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Questions from Job Description'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.primaryColor,
              side: BorderSide(color: context.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: DS.spacingS),
            ),
          ),
        ),

        // After question sets, show topic categories
        DSSpacing.vertical3XL,
        Text(
          AppLocalizations.of(context).browseByTopic,
          style: context.titleMedium,
        ),
        DSSpacing.verticalL,
        _buildTopicCategories(),
      ],
    );
  }

  // Method for displaying topic categories
  Widget _buildTopicCategories() {
    final interviewService = Provider.of<InterviewService>(context);

    // Get predefined categories
    List<Map<String, dynamic>> defaultCategories = [
      {'title': 'Data Analysis', 'count': 18},
      {'title': 'Web Development', 'count': 15},
      {'title': 'Machine Learning', 'count': 22},
      {'title': 'SQL', 'count': 10},
      {'title': 'Python', 'count': 14},
      {'title': 'Data Visualization', 'count': 8},
    ];

    // Get all unique subtopics
    List<String> allSubtopics = interviewService.getAllUniqueSubtopics();
    debugPrint('All unique subtopics: ${allSubtopics.join(", ")}');

    // Filter out subtopics that are already represented by default categories
    List<String> standardSubtopics = [
      'Data Cleaning & Preprocessing',
      'Front-end Development',
      'Machine Learning Algorithms',
      'SQL & Database',
      'Python Fundamentals',
      'Data Visualization',
    ];

    // Find custom subtopics (those not in standardSubtopics)
    List<String> customSubtopics =
        allSubtopics
            .where((subtopic) => !standardSubtopics.contains(subtopic))
            .toList();

    debugPrint(
      'Found ${customSubtopics.length} custom subtopics: ${customSubtopics.join(", ")}',
    );

    // Create category items for custom subtopics
    List<Map<String, dynamic>> customCategories =
        customSubtopics
            .map(
              (subtopic) => {
                'title': subtopic,
                'count': interviewService.getQuestionCountForSubtopic(subtopic),
              },
            )
            .toList();

    debugPrint(
      'Created ${customCategories.length} custom category cards to display',
    );

    // Combine default and custom categories
    List<Map<String, dynamic>> allCategories = [
      ...defaultCategories,
      ...customCategories,
    ];

    // Filter out categories with zero questions
    allCategories =
        allCategories.where((category) => category['count'] > 0).toList();

    debugPrint(
      'Found ${allCategories.length} categories to display after filtering',
    );

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsiveValue(
          xs: 1,
          sm: 1,
          md: 2,
          lg: 3,
          xl: 3,
        ),
        childAspectRatio: 2.5,
        crossAxisSpacing: context.orientationAwareSpacing,
        mainAxisSpacing: context.orientationAwareSpacing,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allCategories.length,
      itemBuilder: (context, index) {
        final category = allCategories[index];
        return _buildCategoryChip(category['title'], category['count']);
      },
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
            builder: (context) => InterviewQuestionsScreen(category: title),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.isPhone ? DS.spacingXs : DS.spacingS,
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
              style: context.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              AppLocalizations.of(context).questionCount(count),
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
          final flashcardService = Provider.of<FlashcardService>(
            context,
            listen: false,
          );
          final recentViewService = Provider.of<RecentViewService>(
            context,
            listen: false,
          );

          // DEBUG: Create a test recent view item if none exist
          if (flashcardService.sets.isNotEmpty &&
              flashcardService.sets.first.flashcards.isNotEmpty) {
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
            size: DS.iconSize2xl + 16, // 64px total
            color: context.onSurfaceVariantColor,
          ),
          DSSpacing.verticalL,
          Text(title, style: context.titleLarge),
          DSSpacing.verticalM,
          Text(subtitle, style: context.bodyMedium),
          DSSpacing.screenSection,
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
            child: Text(AppLocalizations.of(context).createDeck),
          ),
        ],
      ),
    );
  }

  // Helper method to build filter button
  Widget _buildFilterButton(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: context.isPhone ? 100 : 120), // Responsive constraint
      padding: EdgeInsets.symmetric(
        horizontal: DS.spacingS,
        vertical: DS.spacing2xs + 2, // 6px total
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(DS.borderRadiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            size: DS.iconSizeM,
            color: context.onSurfaceVariantColor,
          ),
          DSSpacing.horizontalXS,
          Text(
            AppLocalizations.of(context).filter,
            style: context.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to build sort button
  Widget _buildSortButton(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: context.isPhone ? 160 : 180), // Responsive constraint
      padding: EdgeInsets.symmetric(
        horizontal: DS.spacingS,
        vertical: DS.spacing2xs + 2, // 6px total
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(DS.borderRadiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: DS.iconSizeM,
            color: context.onSurfaceVariantColor,
          ),
          DSSpacing.horizontalXS,
          Text(
            AppLocalizations.of(context).lastUpdated,
            style: context.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          DSSpacing.horizontalXS,
          Icon(
            Icons.keyboard_arrow_down,
            size: DS.iconSizeM,
            color: context.onSurfaceVariantColor,
          ),
        ],
      ),
    );
  }
}
