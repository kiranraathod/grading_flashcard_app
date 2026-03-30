import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// BLoC imports
import '../blocs/flashcard/flashcard_bloc.dart';
import '../blocs/flashcard/flashcard_state.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';

// Models and utilities
import '../models/flashcard_set.dart';
import '../utils/design_system.dart';
import '../screens/study_screen.dart';

/// Phase 5: BLoC-based Flashcard Deck Card
/// 
/// Pure BLoC widget that displays flashcard set information
/// without Provider dependencies. Shows progress, sync status,
/// and provides navigation to study mode.
class FlashcardDeckCardBloc extends StatelessWidget {
  final FlashcardSet set;
  final VoidCallback? onDelete;

  const FlashcardDeckCardBloc({
    super.key,
    required this.set,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToStudy(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(DS.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and menu
              _buildHeader(context),
              
              const SizedBox(height: DS.spacingS),
              
              // Description if available
              if (set.description.isNotEmpty) ...[
                Text(
                  set.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DS.spacingM),
              ],
              
              // Progress section with BLoC state
              _buildProgressSection(context),
              
              const SizedBox(height: DS.spacingM),
              
              // Sync status indicator
              _buildSyncStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            set.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'study',
              child: Row(
                children: [
                  Icon(Icons.school),
                  SizedBox(width: 8),
                  Text('Study'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final progress = _calculateProgress();
    final completedCount = set.flashcards.where((card) => card.isCompleted).length;
    final totalCount = set.flashcards.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedCount/$totalCount cards completed',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${progress}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: DS.spacingS),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 100 ? Colors.green : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus() {
    return BlocSelector<SyncBloc, SyncState, Widget>(
      selector: (state) {
        if (state is SyncInProgress) {
          return Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Syncing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          );
        } else if (state is SyncError) {
          return Row(
            children: [
              Icon(Icons.sync_problem, size: 12, color: Colors.red[600]),
              const SizedBox(width: 4),
              Text(
                'Sync error',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ],
          );
        } else if (state is SyncSuccess) {
          return Row(
            children: [
              Icon(Icons.cloud_done, size: 12, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                'Up to date',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      builder: (context, widget) => widget,
    );
  }

  int _calculateProgress() {
    if (set.flashcards.isEmpty) return 0;
    
    final completedCount = set.flashcards.where((card) => card.isCompleted).length;
    return (completedCount / set.flashcards.length * 100).round();
  }

  void _navigateToStudy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyScreen(flashcardSet: set),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'study':
        _navigateToStudy(context);
        break;
      case 'edit':
        // Navigate to edit screen
        // This would be implemented with proper navigation
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}