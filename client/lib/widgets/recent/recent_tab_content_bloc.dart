import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// BLoC imports
import '../../blocs/recent_view/recent_view_bloc.dart';
import '../../blocs/recent_view/recent_view_state.dart';
import '../../blocs/recent_view/recent_view_event.dart';

// Models
import '../../models/recently_viewed_item.dart';

// Utilities and design system
import '../../utils/design_system.dart';

/// Phase 5: BLoC-based Recent Tab Content
/// 
/// Pure BLoC widget that displays recent activity without
/// Provider dependencies. Shows recently studied flashcards
/// and interview sessions.
class RecentTabContentBloc extends StatefulWidget {
  const RecentTabContentBloc({super.key});

  @override
  State<RecentTabContentBloc> createState() => _RecentTabContentBlocState();
}

class _RecentTabContentBlocState extends State<RecentTabContentBloc> {
  @override
  void initState() {
    super.initState();
    // Request recent data when widget initializes
    context.read<RecentViewBloc>().add(RecentViewRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentViewBloc, RecentViewState>(
      builder: (context, state) {
        if (state is RecentViewLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (state is RecentViewError) {
          return _buildErrorState(state.message);
        }
        
        if (state is RecentViewLoaded) {
          if (state.recentItems.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildRecentItems(state);
        }
        
        return _buildEmptyState();
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: DS.spacingM),
          Text(
            'Error loading recent activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DS.spacingS),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DS.spacingL),
          ElevatedButton.icon(
            onPressed: () {
              context.read<RecentViewBloc>().add(RecentViewRequested());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: DS.spacingM),
          Text(
            'No recent activity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DS.spacingS),
          Text(
            'Start studying flashcards to see your recent activity here',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItems(RecentViewLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecentViewBloc>().add(RecentViewRequested());
      },
      child: ListView.builder(
        itemCount: state.recentItems.length,
        itemBuilder: (context, index) {
          final item = state.recentItems[index];
          return _buildRecentItemCard(item);
        },
      ),
    );
  }

  Widget _buildRecentItemCard(RecentlyViewedItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: DS.spacingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getItemColor(item.type),
          child: Icon(
            _getItemIcon(item.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          item.parentTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.question.length > 50 
                ? '${item.question.substring(0, 50)}...'
                : item.question,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(item.viewedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: _buildItemStatus(item),
        onTap: () => _handleItemTap(item),
      ),
    );
  }

  Widget _buildItemStatus(RecentlyViewedItem item) {
    if (item.isCompleted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            'Completed',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    
    return const Icon(Icons.arrow_forward_ios, size: 16);
  }

  Color _getItemColor(RecentItemType type) {
    switch (type) {
      case RecentItemType.flashcard:
        return Colors.blue;
      case RecentItemType.interviewQuestion:
        return Colors.green;
    }
  }

  IconData _getItemIcon(RecentItemType type) {
    switch (type) {
      case RecentItemType.flashcard:
        return Icons.school;
      case RecentItemType.interviewQuestion:
        return Icons.quiz;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleItemTap(RecentlyViewedItem item) {
    // Handle navigation based on item type
    switch (item.type) {
      case RecentItemType.flashcard:
        // Navigate to flashcard study
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening flashcard: ${item.parentTitle}')),
        );
        break;
      case RecentItemType.interviewQuestion:
        // Navigate to interview practice
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening interview question: ${item.question}')),
        );
        break;
    }
  }
}