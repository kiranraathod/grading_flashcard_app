import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recently_viewed_item.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../models/interview_question.dart';

class RecentViewService {
  static const String _storageKey = 'recently_viewed_items';
  static const int _maxItemsToStore = 50; // Limit the number of items to prevent excessive storage
  
  // Singleton pattern
  static final RecentViewService _instance = RecentViewService._internal();
  
  factory RecentViewService() {
    return _instance;
  }
  
  RecentViewService._internal();
  
  /// Record a view of a flashcard
  Future<void> recordFlashcardView({
    required Flashcard flashcard,
    required FlashcardSet set,
    bool isCompleted = false,
  }) async {
    try {
      // Create a recently viewed item with completion status
      final recentItem = RecentlyViewedItem.fromFlashcard(
        flashcardId: flashcard.id,
        setId: set.id,
        question: flashcard.question,
        setTitle: set.title,
        isCompleted: isCompleted || flashcard.isCompleted, // Use parameter or existing status
      );
      
      // Add to storage
      await _addRecentItem(recentItem);
      
      debugPrint('Recorded flashcard view: ${flashcard.id}, completed: ${flashcard.isCompleted}');
    } catch (e) {
      debugPrint('Error recording flashcard view: $e');
    }
  }
  
  /// Record a view of an interview question
  Future<void> recordInterviewQuestionView({
    required InterviewQuestion question,
    required String category,
    bool isCompleted = false,
  }) async {
    try {
      // Create a recently viewed item with completion status
      final recentItem = RecentlyViewedItem.fromInterviewQuestion(
        questionId: question.id,
        category: category,
        question: question.text,
        categoryTitle: category,
        isCompleted: isCompleted, // Track completion status
      );
      
      // Add to storage
      await _addRecentItem(recentItem);
      
      debugPrint('Recorded interview question view: ${question.id}, completed: $isCompleted');
    } catch (e) {
      debugPrint('Error recording interview question view: $e');
    }
  }
  
  /// Get all recently viewed items
  Future<List<RecentlyViewedItem>> getRecentlyViewedItems({int limit = 20}) async {
    try {
      final items = await _loadRecentItems();
      
      // Log item count for debugging
      debugPrint('⭐ LOADED ${items.length} RECENT ITEMS ⭐');
      for (var item in items) {
        debugPrint('Item: ${item.type} - ${item.question.substring(0, min(20, item.question.length))}... - ${item.isCompleted ? "COMPLETED" : "not completed"}');
      }
      
      // Sort by viewedAt (most recent first) and limit
      items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      return items.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting recently viewed items: $e');
      return [];
    }
  }
  
  /// Get recently viewed flashcards only
  Future<List<RecentlyViewedItem>> getRecentlyViewedFlashcards({int limit = 20}) async {
    try {
      final items = await _loadRecentItems();
      
      // Filter for flashcards only, sort, and limit
      final flashcards = items.where((item) => item.type == RecentItemType.flashcard).toList();
      flashcards.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      return flashcards.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recently viewed flashcards: $e');
      return [];
    }
  }
  
  /// Get recently viewed interview questions only
  Future<List<RecentlyViewedItem>> getRecentlyViewedInterviewQuestions({int limit = 20}) async {
    try {
      final items = await _loadRecentItems();
      
      // Filter for interview questions only, sort, and limit
      final questions = items.where((item) => item.type == RecentItemType.interviewQuestion).toList();
      questions.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      return questions.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recently viewed interview questions: $e');
      return [];
    }
  }
  
  /// Clear all view history
  Future<void> clearViewHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      debugPrint('Cleared view history');
    } catch (e) {
      debugPrint('Error clearing view history: $e');
    }
  }
  
  /// Synchronize completion status with recent views for flashcards
  Future<void> syncFlashcardProgress(List<FlashcardSet> sets) async {
    try {
      debugPrint('⭐ SYNCHRONIZING FLASHCARD PROGRESS ⭐');
      debugPrint('  Sets to sync: ${sets.length}');
      
      // Load existing items
      final recentItems = await _loadRecentItems();
      debugPrint('  Loaded ${recentItems.length} existing items');
      
      bool needsSave = false;
      int updatedCount = 0;
      int createdCount = 0;
      
      // Create a set of already tracked flashcard IDs
      final Set<String> trackedFlashcardIds = recentItems
          .where((item) => item.type == RecentItemType.flashcard)
          .map((item) => item.itemId)
          .toSet();
      
      debugPrint('  Found ${trackedFlashcardIds.length} already tracked flashcards');
      
      // Update completion status for flashcards
      for (var set in sets) {
        for (var card in set.flashcards) {
          // Check if this card is already tracked
          if (trackedFlashcardIds.contains(card.id)) {
            final index = recentItems.indexWhere(
              (item) => item.type == RecentItemType.flashcard && 
                        item.itemId == card.id
            );
            
            if (index >= 0 && recentItems[index].isCompleted != card.isCompleted && card.isCompleted) {
              // Create updated item with current timestamp and completion status
              // We only update when card is completed to avoid overwriting progress
              final updatedItem = RecentlyViewedItem.fromFlashcard(
                flashcardId: card.id,
                setId: set.id,
                question: card.question,
                setTitle: set.title,
                isCompleted: card.isCompleted,
              );
              
              // Replace the old item
              recentItems[index] = updatedItem;
              needsSave = true;
              updatedCount++;
              debugPrint('  Updated completion status for card ${card.id} to ${card.isCompleted}');
            }
          } 
          // If not already tracked and is completed, add it
          else if (card.isCompleted) {
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
            debugPrint('  Created new recent item for completed card ${card.id}');
          }
          // Make sure we have at least one recent item even if not completed
          else if (recentItems.isEmpty) {
            final newItem = RecentlyViewedItem.fromFlashcard(
              flashcardId: card.id,
              setId: set.id,
              question: card.question,
              setTitle: set.title,
              isCompleted: false,
            );
            
            recentItems.add(newItem);
            needsSave = true;
            createdCount++;
            debugPrint('  Created new recent item for first card ${card.id} to ensure we have one');
            break; // Just add one to get started
          }
        }
        
        // If we've created at least one item, we can stop checking more sets
        if (createdCount > 0) {
          break;
        }
      }
      
      // Save if changes were made
      if (needsSave) {
        await _saveRecentItemsWithRetry(recentItems);
        debugPrint('  Saved synchronized completion status: Updated $updatedCount, Created $createdCount');
      } else {
        debugPrint('  No changes needed');
      }
    } catch (e) {
      debugPrint('❌ Error synchronizing flashcard progress: $e');
    }
  }
  
  /// Private method to add a recently viewed item to storage
  Future<void> _addRecentItem(RecentlyViewedItem item) async {
    try {
      debugPrint('⭐ ADDING RECENT ITEM: ${item.type} - ${item.question.substring(0, min(20, item.question.length))}... - ${item.isCompleted ? "COMPLETED" : "not completed"}');
      
      // Load existing items
      final items = await _loadRecentItems();
      debugPrint('  Found ${items.length} existing items');
      
      // Check if this item already exists (based on itemId and type)
      final existingIndex = items.indexWhere(
        (existing) => existing.itemId == item.itemId && existing.type == item.type
      );
      
      // If it exists, remove it (we'll add the updated one)
      if (existingIndex >= 0) {
        debugPrint('  Updating existing item at index $existingIndex');
        items.removeAt(existingIndex);
      } else {
        debugPrint('  Adding as new item');
      }
      
      // Add the new item
      items.add(item);
      
      // Always sort by viewedAt (most recent first), not just when maxItems is reached
      items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      
      // Keep only the most recent items
      if (items.length > _maxItemsToStore) {
        debugPrint('  Trimming to $_maxItemsToStore items (removing ${items.length - _maxItemsToStore})');
        // Keep only the most recent _maxItemsToStore items
        while (items.length > _maxItemsToStore) {
          items.removeLast();
        }
      }
      
      // Save back to storage with retry mechanism
      final success = await _saveRecentItemsWithRetry(items);
      debugPrint('  Save ${success ? "SUCCESSFUL ✅" : "FAILED ❌"}');
    } catch (e) {
      debugPrint('❌ Error adding recent item: $e');
    }
  }
  
  // Add a new method with retry mechanism for more reliable storage
  Future<bool> _saveRecentItemsWithRetry(List<RecentlyViewedItem> items, {int retries = 3}) async {
    int attempts = 0;
    bool success = false;
    
    while (attempts < retries && !success) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = RecentlyViewedItem.listToJson(items);
        final jsonString = json.encode(jsonList);
        
        success = await prefs.setString(_storageKey, jsonString);
        
        if (success) {
          debugPrint('Successfully saved recent items on attempt ${attempts + 1}');
        } else {
          debugPrint('Failed to save recent items on attempt ${attempts + 1}');
        }
      } catch (e) {
        debugPrint('Error saving recent items on attempt ${attempts + 1}: $e');
      }
      
      attempts++;
      
      if (!success && attempts < retries) {
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 200 * attempts));
      }
    }
    
    return success;
  }
  
  /// Private method to load recently viewed items from storage with error handling
  Future<List<RecentlyViewedItem>> _loadRecentItems() async {
    try {
      debugPrint('⭐ LOADING RECENT ITEMS FROM STORAGE ⭐');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('  No items found in storage (key: $_storageKey)');
        // Create a test item if none exist
        final testItem = RecentlyViewedItem(
          id: 'test-item-${DateTime.now().millisecondsSinceEpoch}',
          itemId: 'test-flashcard-id',
          type: RecentItemType.flashcard,
          parentId: 'test-set-id',
          viewedAt: DateTime.now(),
          question: 'This is a test flashcard created because no items were found in storage',
          parentTitle: 'Test Flashcard Set',
          isCompleted: true,
        );
        
        // Save the test item
        List<RecentlyViewedItem> testItems = [testItem];
        await _saveRecentItemsWithRetry(testItems);
        debugPrint('  Created and saved a test item');
        return testItems;
      }
      
      try {
        debugPrint('  Found data in storage, parsing JSON');
        final jsonList = json.decode(jsonString) as List<dynamic>;
        debugPrint('  JSON parsed successfully, ${jsonList.length} items found');
        final items = RecentlyViewedItem.listFromJson(jsonList);
        debugPrint('  Converted to ${items.length} RecentlyViewedItem objects');
        
        // Always sort by viewedAt (most recent first) for consistency
        items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
        
        return items;
      } catch (jsonError) {
        debugPrint('❌ Error parsing JSON for recent items: $jsonError');
        debugPrint('  JSON string: ${jsonString.substring(0, min(100, jsonString.length))}...');
        // If JSON parsing fails, clear the corrupted data
        await prefs.remove(_storageKey);
        debugPrint('  Cleared corrupted data from storage');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error loading recent items: $e');
      return [];
    }
  }
  
  // The _saveRecentItems method was removed as it's no longer used
  // We're now using _saveRecentItemsWithRetry method instead
}
