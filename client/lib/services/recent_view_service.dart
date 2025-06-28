import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recently_viewed_item.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../models/interview_question.dart';
import 'reliable_operation_service.dart';
import 'supabase_service.dart';

class RecentViewService {
  static const String _storageKey = 'recently_viewed_items';
  static const int _maxItemsToStore = 50;
  
  // Singleton pattern
  static final RecentViewService _instance = RecentViewService._internal();
  
  factory RecentViewService() {
    return _instance;
  }
  
  RecentViewService._internal() {
    // Listen to Supabase sync status for recent activity sync
    _supabaseService.addListener(_onSyncStatusChanged);
  }
  
  final ReliableOperationService _reliableOps = ReliableOperationService();
  final SupabaseService _supabaseService = SupabaseService.instance;

  void _onSyncStatusChanged() {
    // Recent view sync is less critical, so we only sync when explicitly triggered
    // The activity data will sync periodically through the unified action tracker
  }

  /// Record a view of a flashcard with reliable operation
  Future<void> recordFlashcardView({
    required Flashcard flashcard,
    required FlashcardSet set,
    bool isCompleted = false,
  }) async {
    await _reliableOps.safely(
      operation: () async {
        final recentItem = RecentlyViewedItem.fromFlashcard(
          flashcardId: flashcard.id,
          setId: set.id,
          question: flashcard.question,
          setTitle: set.title,
          isCompleted: isCompleted || flashcard.isCompleted,
        );
        
        await _addRecentItem(recentItem);
        debugPrint('Recorded flashcard view: ${flashcard.id}, completed: ${flashcard.isCompleted}');
      },
      operationName: 'record_flashcard_view',
    );
  }

  /// Record a view of an interview question with reliable operation
  Future<void> recordInterviewQuestionView({
    required InterviewQuestion question,
    required String category,
    bool isCompleted = false,
  }) async {
    await _reliableOps.safely(
      operation: () async {
        final navigationCategory = question.subtopic.isNotEmpty ? question.subtopic : category;
        
        final recentItem = RecentlyViewedItem.fromInterviewQuestion(
          questionId: question.id,
          category: category,
          question: question.text,
          categoryTitle: navigationCategory,
          isCompleted: isCompleted,
        );
        
        await _addRecentItem(recentItem);
        
        debugPrint('Recorded interview question view: ${question.id}');
        debugPrint('   Original category: $category');
        debugPrint('   Navigation target: $navigationCategory');
        debugPrint('   Completed: $isCompleted');
      },
      operationName: 'record_interview_question_view',
    );
  }

  /// Get all recently viewed items with default empty list
  Future<List<RecentlyViewedItem>> getRecentlyViewedItems({int limit = 20}) async {
    return await _reliableOps.withDefault(
      operation: () async {
        final items = await _loadRecentItems();
        
        debugPrint('LOADED ${items.length} RECENT ITEMS');
        for (var item in items) {
          debugPrint('Item: ${item.type} - ${item.question.substring(0, min(20, item.question.length))}... - ${item.isCompleted ? "COMPLETED" : "not completed"}');
        }
        
        items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
        return items.take(limit).toList();
      },
      defaultValue: <RecentlyViewedItem>[],
      operationName: 'get_recently_viewed_items',
    );
  }

  /// Get recently viewed flashcards only with default empty list
  Future<List<RecentlyViewedItem>> getRecentlyViewedFlashcards({int limit = 20}) async {
    return await _reliableOps.withDefault(
      operation: () async {
        final items = await _loadRecentItems();
        
        final flashcards = items.where((item) => item.type == RecentItemType.flashcard).toList();
        flashcards.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
        return flashcards.take(limit).toList();
      },
      defaultValue: <RecentlyViewedItem>[],
      operationName: 'get_recently_viewed_flashcards',
    );
  }

  /// Get recently viewed interview questions only with default empty list
  Future<List<RecentlyViewedItem>> getRecentlyViewedInterviewQuestions({int limit = 20}) async {
    return await _reliableOps.withDefault(
      operation: () async {
        final items = await _loadRecentItems();
        
        final questions = items.where((item) => item.type == RecentItemType.interviewQuestion).toList();
        questions.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
        return questions.take(limit).toList();
      },
      defaultValue: <RecentlyViewedItem>[],
      operationName: 'get_recently_viewed_interview_questions',
    );
  }

  /// Clear all view history safely
  Future<void> clearViewHistory() async {
    await _reliableOps.safely(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
        debugPrint('Cleared view history');
      },
      operationName: 'clear_view_history',
    );
  }

  /// Synchronize completion status with recent views for flashcards
  Future<void> syncFlashcardProgress(List<FlashcardSet> sets) async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('SYNCHRONIZING FLASHCARD PROGRESS');
        debugPrint('  Sets to sync: ${sets.length}');
        
        final recentItems = await _loadRecentItems();
        debugPrint('  Loaded ${recentItems.length} existing items');
        
        bool needsSave = false;
        int updatedCount = 0;
        int createdCount = 0;
        
        final Set<String> trackedFlashcardIds = recentItems
            .where((item) => item.type == RecentItemType.flashcard)
            .map((item) => item.itemId)
            .toSet();
        
        debugPrint('  Found ${trackedFlashcardIds.length} already tracked flashcards');
        
        for (var set in sets) {
          for (var card in set.flashcards) {
            if (trackedFlashcardIds.contains(card.id)) {
              final index = recentItems.indexWhere(
                (item) => item.type == RecentItemType.flashcard && 
                          item.itemId == card.id
              );
              
              if (index >= 0 && recentItems[index].isCompleted != card.isCompleted && card.isCompleted) {
                final updatedItem = RecentlyViewedItem.fromFlashcard(
                  flashcardId: card.id,
                  setId: set.id,
                  question: card.question,
                  setTitle: set.title,
                  isCompleted: card.isCompleted,
                );
                
                recentItems[index] = updatedItem;
                needsSave = true;
                updatedCount++;
                debugPrint('  Updated completion status for card ${card.id} to ${card.isCompleted}');
              }
            } else if (card.isCompleted) {
              final newItem = RecentlyViewedItem.fromFlashcard(
                flashcardId: card.id,
                setId: set.id,
                question: card.question,
                setTitle: set.title,
                isCompleted: true,
              );
              
              recentItems.add(newItem);
              needsSave = true;
              createdCount++;
              debugPrint('  Added completed card ${card.id} to recent items');
            }
          }
        }
        
        if (needsSave) {
          await _saveRecentItems(recentItems);
        }
        
        debugPrint('SYNC COMPLETE: Updated $updatedCount, Created $createdCount');
      },
      operationName: 'sync_flashcard_progress',
    );
  }

  /// Private method to add a recently viewed item to storage using reliable operations
  Future<void> _addRecentItem(RecentlyViewedItem item) async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('ADDING RECENT ITEM: ${item.type} - ${item.question.substring(0, min(20, item.question.length))}... - ${item.isCompleted ? "COMPLETED" : "not completed"}');
        
        final items = await _loadRecentItems();
        debugPrint('  Found ${items.length} existing items');
        
        final existingIndex = items.indexWhere(
          (existing) => existing.itemId == item.itemId && existing.type == item.type
        );
        
        if (existingIndex >= 0) {
          debugPrint('  Updating existing item at index $existingIndex');
          items.removeAt(existingIndex);
        } else {
          debugPrint('  Adding as new item');
        }
        
        items.add(item);
        items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
        
        if (items.length > _maxItemsToStore) {
          debugPrint('  Trimming to $_maxItemsToStore items (removing ${items.length - _maxItemsToStore})');
          while (items.length > _maxItemsToStore) {
            items.removeLast();
          }
        }
        
        await _saveRecentItems(items);
        debugPrint('  Save SUCCESSFUL');
      },
      operationName: 'add_recent_item',
    );
  }

  /// Load recent items with default empty list
  Future<List<RecentlyViewedItem>> _loadRecentItems() async {
    return await _reliableOps.withDefault(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final String? itemsJson = prefs.getString(_storageKey);
        
        if (itemsJson == null) {
          return <RecentlyViewedItem>[];
        }
        
        final List<dynamic> itemsList = json.decode(itemsJson);
        return itemsList.map((item) => RecentlyViewedItem.fromJson(item)).toList();
      },
      defaultValue: <RecentlyViewedItem>[],
      operationName: 'load_recent_items',
    );
  }

  /// Save recent items to storage safely
  Future<void> _saveRecentItems(List<RecentlyViewedItem> items) async {
    await _reliableOps.safely(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final String itemsJson = json.encode(items.map((item) => item.toJson()).toList());
        await prefs.setString(_storageKey, itemsJson);
      },
      operationName: 'save_recent_items',
    );
  }

  /// Get recent view statistics with safe operations
  Map<String, int> getStatistics() {
    return _reliableOps.safelySync(
      operation: () {
        // This would need async access, so return basic stats
        return {
          'maxItemsToStore': _maxItemsToStore,
          'implementedMethods': 8,
        };
      },
      defaultValue: {
        'maxItemsToStore': _maxItemsToStore,
        'implementedMethods': 8,
      },
      operationName: 'get_statistics',
    ) ?? {
      'maxItemsToStore': _maxItemsToStore,
      'implementedMethods': 8,
    };
  }

  /// Sync recent activity to cloud (for analytics and cross-device tracking)
  Future<void> syncRecentActivity() async {
    if (!_supabaseService.isAuthenticated) return;

    await _reliableOps.safely(
      operation: () async {
        final recentItems = await getRecentlyViewedItems();
        
        for (final item in recentItems) {
          try {
            await _supabaseService.client!
                .from('user_activity')
                .upsert({
                  'user_id': _supabaseService.currentUserId!,
                  'activity_type': item.type.toString(),
                  'content_id': item.itemId,
                  'content_title': item.question,
                  'category': item.parentId,
                  'viewed_at': item.viewedAt.toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
          } catch (e) {
            debugPrint('❌ Error syncing activity item: $e');
            // Continue with other items even if one fails
          }
        }
        
        debugPrint('📱 Synced ${recentItems.length} recent activity items to cloud');
      },
      operationName: 'sync_recent_activity',
    );
  }

  /// Clean up resources
  void dispose() {
    _supabaseService.removeListener(_onSyncStatusChanged);
  }
}
