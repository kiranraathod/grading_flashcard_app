import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/search/search_bloc.dart';
import '../../blocs/search/search_event.dart';
import '../../blocs/search/search_state.dart';
import '../../models/search_result_item.dart';
import '../../services/flashcard_service.dart';
import '../../services/interview_service.dart';
import '../../utils/theme_utils.dart';
// import '../../utils/design_system.dart'; // Removed unused import
import '../../widgets/app_header.dart';
import '../study_screen.dart';
import '../flashcard_screen.dart';
import '../interview_questions_screen.dart';
import '../question_set_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  
  const SearchResultsScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  
  // Active filter
  String _activeFilter = 'all';
  
  // Current search query
  String _currentQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
    
    // Execute the initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchBloc>().add(ExecuteSearch(widget.initialQuery));
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Column(
        children: [
          // App header
          const AppHeader(),
          
          // Search bar row with filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(Icons.arrow_back, color: context.onSurfaceColor),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                
                // Search input
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.surfaceVariantColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: context.onSurfaceColor),
                      decoration: InputDecoration(
                        hintText: 'Search flashcards and questions',
                        hintStyle: TextStyle(color: context.onSurfaceVariantColor),
                        prefixIcon: Icon(Icons.search, color: context.onSurfaceVariantColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: context.onSurfaceVariantColor),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<SearchBloc>().add(ClearSearch());
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _currentQuery = value;
                        });
                        context.read<SearchBloc>().add(SearchTextChanged(value));
                      },
                      onSubmitted: (value) {
                        context.read<SearchBloc>().add(ExecuteSearch(value));
                      },
                    ),
                  ),
                ),
                
                // Filter button
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.filter_list, color: context.onSurfaceColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      setState(() {
                        _activeFilter = value;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Results'),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Completed Items'),
                      ),
                      const PopupMenuItem(
                        value: 'not_completed',
                        child: Text('Not Completed'),
                      ),
                    ],
                    tooltip: 'Filter results',
                  ),
                ),
              ],
            ),
          ),
          
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                bottom: BorderSide(color: context.colorScheme.outline.withOpacityFix(0.2)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: context.primaryColor,
              unselectedLabelColor: context.onSurfaceVariantColor,
              indicatorColor: context.primaryColor,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Flashcards'),
                Tab(text: 'Interview Q\'s'),
              ],
            ),
          ),
          
          // Tab view content
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return _buildInitialState();
                } else if (state is SearchLoading) {
                  return _buildLoadingState();
                } else if (state is SearchEmpty) {
                  return _buildEmptyState(state.query);
                } else if (state is SearchResults) {
                  return _buildResultsState(state);
                } else if (state is SearchError) {
                  return _buildErrorState(state.message);
                } else {
                  return _buildInitialState();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Build initial state (no search executed yet)
  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: context.onSurfaceVariantColor.withOpacityFix(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for flashcards and interview questions',
              style: context.titleMedium?.copyWith(
                color: context.onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Type a term above to find matching content',
              style: context.bodyMedium?.copyWith(
                color: context.onSurfaceVariantColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  // Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  // Build empty state (no results found)
  Widget _buildEmptyState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.onSurfaceVariantColor.withOpacityFix(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: context.titleMedium?.copyWith(
                color: context.onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your spelling',
              style: context.bodyMedium?.copyWith(
                color: context.onSurfaceVariantColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                context.read<SearchBloc>().add(ClearSearch());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.onPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build error state
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error searching',
              style: context.titleMedium?.copyWith(
                color: context.onSurfaceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.bodyMedium?.copyWith(
                color: context.onSurfaceVariantColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<SearchBloc>().add(ExecuteSearch(_currentQuery));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.onPrimaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build results state
  Widget _buildResultsState(SearchResults state) {
    // Convert raw data into SearchResultItem objects
    final deckResults = state.deckResults.map((deck) => 
      SearchResultItem.fromDeck(deck, state.query)
    ).toList();
    
    final cardResults = <SearchResultItem>[];
    for (final card in state.cardResults) {
      // Find parent deck
      final flashcardService = context.read<FlashcardService>();
      final parentDeck = flashcardService.sets.firstWhere(
        (deck) => deck.flashcards.any((c) => c.id == card.id),
        orElse: () => flashcardService.sets.first, // Fallback
      );
      
      cardResults.add(SearchResultItem.fromFlashcard(card, parentDeck, state.query));
    }
    
    final questionResults = state.questionResults.map((question) =>
      SearchResultItem.fromInterviewQuestion(question, state.query)
    ).toList();
    
    // Apply filters
    final filteredDeckResults = _applyFilter(deckResults);
    final filteredCardResults = _applyFilter(cardResults);
    final filteredQuestionResults = _applyFilter(questionResults);
    
    // Combined results for "All" tab (sorted by relevance)
    final allResults = [...filteredDeckResults, ...filteredCardResults, ...filteredQuestionResults];
    allResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    return TabBarView(
      controller: _tabController,
      children: [
        // All results tab
        _buildResultsList(allResults, 'All Results'),
        
        // Flashcards tab (decks and cards)
        _buildResultsList([...filteredDeckResults, ...filteredCardResults], 'Flashcards'),
        
        // Interview questions tab
        _buildResultsList(filteredQuestionResults, 'Interview Questions'),
      ],
    );
  }
  
  // Apply the current filter to results
  List<SearchResultItem> _applyFilter(List<SearchResultItem> items) {
    switch (_activeFilter) {
      case 'completed':
        return items.where((item) => item.isCompleted).toList();
      case 'not_completed':
        return items.where((item) => !item.isCompleted).toList();
      case 'all':
      default:
        return items;
    }
  }
  
  // Build a list of search results
  Widget _buildResultsList(List<SearchResultItem> items, String title) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: context.onSurfaceVariantColor.withOpacityFix(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $title found',
              style: context.titleSmall?.copyWith(
                color: context.onSurfaceColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildSearchResultItem(item);
      },
    );
  }
  
  // Build an individual search result item card
  Widget _buildSearchResultItem(SearchResultItem item) {
    final bool isDeck = item.type == SearchResultType.deck;
    final bool isFlashcard = item.type == SearchResultType.flashcard;
    // Removed unused variable: final bool isQuestion = item.type == SearchResultType.interviewQuestion;
    
    // Choose icon based on type
    IconData iconData;
    if (isDeck) {
      iconData = Icons.style;
    } else if (isFlashcard) {
      iconData = Icons.note;
    } else {
      iconData = Icons.question_answer;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.colorScheme.outline.withOpacityFix(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          _handleItemTap(item);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and type indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacityFix(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: context.primaryColor,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDeck 
                            ? 'Deck' 
                            : isFlashcard 
                                ? 'Flashcard' 
                                : 'Interview Question',
                        style: context.bodySmall?.copyWith(
                          color: context.onSurfaceVariantColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Title
                    Text(
                      item.title,
                      style: context.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Subtitle (parent info or description)
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: context.bodySmall?.copyWith(
                          color: context.onSurfaceVariantColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                    const SizedBox(height: 4),
                    
                    // Preview content
                    Text(
                      item.content,
                      style: context.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Completion status indicator
              if (!isDeck)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    item.isCompleted 
                        ? Icons.check_circle 
                        : Icons.radio_button_unchecked,
                    color: item.isCompleted 
                        ? context.primaryColor 
                        : context.onSurfaceVariantColor.withOpacityFix(0.5),
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Handle tapping on a search result item
  void _handleItemTap(SearchResultItem item) {
    switch (item.type) {
      case SearchResultType.deck:
        if (item.deckObject != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudyScreen(
                set: item.deckObject!,
              ),
            ),
          );
        }
        break;
        
      case SearchResultType.flashcard:
        if (item.flashcardObject != null && item.parentId.isNotEmpty) {
          // Get the service to find the parent deck
          final flashcardService = context.read<FlashcardService>();
          final parentDeck = flashcardService.getFlashcardSet(item.parentId);
          
          if (parentDeck != null) {
            // Find the index of this card in the deck
            final cardIndex = parentDeck.flashcards.indexWhere((c) => c.id == item.id);
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashcardScreen.fromSet(
                  parentDeck,
                  key: null,
                  initialCardIndex: cardIndex >= 0 ? cardIndex : 0,
                ),
              ),
            );
          }
        }
        break;
        
      case SearchResultType.interviewQuestion:
        if (item.questionObject != null) {
          // If it's part of a question set, navigate to that set
          final interviewService = context.read<InterviewService>();
          final questionSets = interviewService.questionSets;
          
          // Find if this question belongs to any set
          // Fix constructor call with proper import
          final containingSet = questionSets.firstWhere(
            (set) => set.questionIds.contains(item.id),
            orElse: () => interviewService.questionSets.isEmpty ? 
              questionSets.first : 
              questionSets.first.copyWith(
                id: '',
                title: '',
                questionIds: [],
              ),
          );
          
          if (containingSet.id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuestionSetDetailScreen(
                  setId: containingSet.id,
                ),
              ),
            );
          } else {
            // Otherwise, navigate to the questions screen filtered by category
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InterviewQuestionsScreen(
                  category: item.questionObject!.category,
                ),
              ),
            );
          }
        }
        break;
    }
  }
}
