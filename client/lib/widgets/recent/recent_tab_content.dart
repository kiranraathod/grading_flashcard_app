import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../blocs/recent_view/recent_view_bloc.dart';
import '../../blocs/recent_view/recent_view_event.dart';
import '../../blocs/recent_view/recent_view_state.dart';
import '../../models/recently_viewed_item.dart';
import '../../utils/colors.dart';
import '../../screens/study_screen.dart';
import '../../screens/interview_questions_screen.dart';
import '../../services/flashcard_service.dart';

class RecentTabContent extends StatefulWidget {
  const RecentTabContent({super.key});

  @override
  State<RecentTabContent> createState() => _RecentTabContentState();
}

class _RecentTabContentState extends State<RecentTabContent>
    with AutomaticKeepAliveClientMixin {
  RecentItemType? _filterType;
  bool _hasInitialized = false;

  @override
  bool get wantKeepAlive => true; // Keep the tab's state when not visible

  // initState is no longer needed since we're loading in didChangeDependencies

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      // Load recently viewed items when the widget is initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshRecentItems();
      });
      _hasInitialized = true;
    }
  }

  // Method to force refresh the recent items
  void _refreshRecentItems() {
    context.read<RecentViewBloc>().add(
      LoadRecentViews(filterType: _filterType),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Try to refresh whenever the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('⭐ REFRESHING RECENT TAB CONTENT ⭐');
      _refreshRecentItems();
    });

    return BlocConsumer<RecentViewBloc, RecentViewState>(
      listener: (context, state) {
        if (state is RecentViewError) {
          // Show an error message when loading fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).errorLoadingRecentItems(state.message),
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: AppLocalizations.of(context).retry,
                textColor: Colors.white,
                onPressed: _refreshRecentItems,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        debugPrint(
          '⭐ Building RecentTabContent with state: ${state.runtimeType}',
        );

        if (state is RecentViewInitial || state is RecentViewLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RecentViewError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Recent Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _refreshRecentItems,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        } else if (state is RecentViewLoaded) {
          debugPrint('  Loaded state has ${state.recentItems.length} items');
          return _buildContent(state);
        } else {
          debugPrint('❌ Unknown state: ${state.runtimeType}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.amber.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unexpected State',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Recent tab encountered an unexpected state: ${state.runtimeType}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _refreshRecentItems,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(RecentViewLoaded state) {
    debugPrint('  Building content with ${state.recentItems.length} items');

    // If there are no items to display, show empty state
    if (state.recentItems.isEmpty) {
      debugPrint('  No items to display, showing empty state');
      return _buildEmptyState();
    }

    // Filter items based on the active filter
    final filteredItems = state.filteredItems;
    debugPrint('  After filtering: ${filteredItems.length} items');

    if (filteredItems.isEmpty) {
      debugPrint('  No items after filtering, showing empty filtered state');
      return _buildEmptyFilteredState();
    }

    // Calculate a reasonable height for the list view - this avoids layout errors
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = 190.0; // Approximate height for stats and filters
    final listHeight = screenHeight - headerHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:
          MainAxisSize
              .min, // Important: Use min to avoid the unbounded height issue
      children: [
        // Stats summary
        _buildStatsSummary(state.recentItems),

        const SizedBox(height: 16),

        // Filter controls
        _buildFilterControls(state),

        const SizedBox(height: 16),

        // List of recently viewed items - use SizedBox with fixed height
        SizedBox(
          height:
              listHeight > 300
                  ? listHeight
                  : 300, // Use calculated height with a minimum
          child: ListView.builder(
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildRecentItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary(List<RecentlyViewedItem> items) {
    final flashcardCount =
        items.where((item) => item.type == RecentItemType.flashcard).length;
    final interviewCount =
        items
            .where((item) => item.type == RecentItemType.interviewQuestion)
            .length;

    String lastStudiedText = 'Never';
    if (items.isNotEmpty) {
      final mostRecent = items.reduce(
        (a, b) => a.viewedAt.isAfter(b.viewedAt) ? a : b,
      );
      final now = DateTime.now();
      final difference = now.difference(mostRecent.viewedAt);

      if (difference.inMinutes < 60) {
        lastStudiedText =
            '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        lastStudiedText =
            '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else {
        lastStudiedText =
            '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _buildStatItem('Total Items', items.length.toString()),
          const SizedBox(width: 16),
          _buildStatItem(
            'Flashcards',
            flashcardCount.toString(),
            icon: Icons.style,
            color: AppColors.primary,
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            'Interview Questions',
            interviewCount.toString(),
            icon: Icons.question_answer,
            color: Colors.purple,
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            'Last Studied',
            lastStudiedText,
            icon: Icons.access_time,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color ?? Colors.grey.shade600),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(RecentViewLoaded state) {
    return Row(
      children: [
        _buildFilterButton(
          label: 'All',
          isActive: state.activeFilter == null,
          onPressed: () {
            setState(() {
              _filterType = null;
            });
            context.read<RecentViewBloc>().add(
              SetRecentViewFilter(filterType: null),
            );
          },
          icon: Icons.all_inclusive,
        ),
        const SizedBox(width: 12),
        _buildFilterButton(
          label: 'Flashcards',
          isActive:
              state.activeFilter != null &&
              state.activeFilter == RecentItemType.flashcard,
          onPressed: () {
            setState(() {
              _filterType = RecentItemType.flashcard;
            });
            context.read<RecentViewBloc>().add(
              SetRecentViewFilter(filterType: RecentItemType.flashcard),
            );
          },
          icon: Icons.style,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildFilterButton(
          label: 'Interview Questions',
          isActive:
              state.activeFilter != null &&
              state.activeFilter == RecentItemType.interviewQuestion,
          onPressed: () {
            setState(() {
              _filterType = RecentItemType.interviewQuestion;
            });
            context.read<RecentViewBloc>().add(
              SetRecentViewFilter(filterType: RecentItemType.interviewQuestion),
            );
          },
          icon: Icons.question_answer,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
  }) {
    final buttonColor = color ?? AppColors.primary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? buttonColor : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade700,
        elevation: isActive ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isActive ? buttonColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 8)],
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemCard(RecentlyViewedItem item) {
    final isFlashcard = item.type == RecentItemType.flashcard;

    // Format relative time
    final now = DateTime.now();
    final difference = now.difference(item.viewedAt);
    String timeAgo;

    if (difference.inMinutes < 60) {
      timeAgo =
          '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      timeAgo =
          '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      timeAgo =
          '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    // Type-specific icon and color
    final icon = isFlashcard ? Icons.style : Icons.question_answer;
    // Use green color for completed items
    final typeColor =
        item.isCompleted
            ? Colors.green
            : (isFlashcard ? AppColors.primary : Colors.purple);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type info, parent title, and time
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(
                      typeColor.r.toInt(),
                      typeColor.g.toInt(),
                      typeColor.b.toInt(),
                      0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color.fromRGBO(
                        typeColor.r.toInt(),
                        typeColor.g.toInt(),
                        typeColor.b.toInt(),
                        0.3,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    item.isCompleted ? Icons.check_circle : icon,
                    color: typeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isFlashcard ? 'Flashcard' : 'Interview Question',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                          // Add completed badge if item is completed
                          if (item.isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        item.parentTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

            // Question text
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                item.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _navigateToItem(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('View'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _navigateToItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFlashcard ? AppColors.primary : Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(isFlashcard ? 'Resume Study' : 'Practice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Recently Viewed Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start studying flashcards or practicing interview questions',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to flashcards
                  Navigator.of(context).pop(); // Go back to home screen
                },
                icon: const Icon(Icons.style),
                label: const Text('Study Flashcards'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to interview questions
                  Navigator.of(context).pop(); // Go back to home screen
                },
                icon: const Icon(Icons.question_answer),
                label: const Text('Practice Interviews'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    final bool isFlashcardFilter =
        _filterType != null && _filterType == RecentItemType.flashcard;
    final filterName = isFlashcardFilter ? 'flashcards' : 'interview questions';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFlashcardFilter ? Icons.style : Icons.question_answer,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Recently Viewed $filterName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start studying to see your recently viewed $filterName here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to the corresponding screen
              Navigator.of(context).pop(); // Go back to home screen
            },
            icon: Icon(isFlashcardFilter ? Icons.style : Icons.question_answer),
            label: Text(
              isFlashcardFilter ? 'Study Flashcards' : 'Practice Interviews',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isFlashcardFilter ? AppColors.primary : Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToItem(RecentlyViewedItem item) async {
    if (item.type == RecentItemType.flashcard) {
      // Get the flashcard set from the service
      final flashcardService = Provider.of<FlashcardService>(
        context,
        listen: false,
      );
      final set = flashcardService.getFlashcardSet(item.parentId);

      if (set != null) {
        // Navigate to study screen
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => StudyScreen(set: set)));

        // Explicitly refresh the list after returning
        _refreshRecentItems();
      } else {
        // Show error - set not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard set not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Navigate to interview questions screen with the category
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => InterviewQuestionsScreen(category: item.parentTitle),
        ),
      );

      // Explicitly refresh the list after returning
      _refreshRecentItems();
    }
  }
}
