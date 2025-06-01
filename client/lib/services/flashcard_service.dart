import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'default_data_service.dart';
import 'storage_service.dart';
import 'dart:async';

class FlashcardService extends ChangeNotifier {
  final List<FlashcardSet> _sets = [];
  final DefaultDataService _defaultDataService = DefaultDataService();
  
  List<FlashcardSet> get sets => List.unmodifiable(_sets);
  
  FlashcardService() {
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      final setsData = StorageService.getFlashcardSets();

      if (setsData != null && setsData.isNotEmpty) {
        _sets.clear();
        for (final data in setsData) {
          _sets.add(FlashcardSet.fromJson(data));
        }
        debugPrint('Loaded ${_sets.length} flashcard sets from storage using StorageService');
      } else {
        // Load default data from server if no saved sets
        debugPrint('No saved sets found, loading default data from server...');
        await _loadDefaultData();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flashcard sets: $e');
      // Load default data from server if error
      await _loadDefaultData();
    }
  }

  Future<void> _loadDefaultData() async {
    try {
      debugPrint('Loading default flashcard sets from server...');
      final defaultSets = await _defaultDataService.loadDefaultFlashcardSets();
      
      _sets.clear();
      _sets.addAll(defaultSets);
      
      debugPrint('Loaded ${defaultSets.length} default flashcard sets from server');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading default data from server: $e');
      // If server fails, create a minimal fallback set
      _loadMinimalFallbackData();
    }
  }

  void _loadMinimalFallbackData() {
    debugPrint('Loading minimal fallback data...');
    _sets.clear();
    
    // Try to load from server with minimal dataset even if main load failed
    _loadMinimalServerFallback();
  }

  Future<void> _loadMinimalServerFallback() async {
    try {
      debugPrint('Attempting to load minimal server fallback data...');
      // Try to get at least one default set from server with minimal configuration
      final defaultSets = await _defaultDataService.loadDefaultFlashcardSets();
      
      if (defaultSets.isNotEmpty) {
        _sets.addAll(defaultSets);
        debugPrint('Loaded ${defaultSets.length} minimal sets from server fallback');
      } else {
        // Only if server completely fails, create absolute minimal offline set
        _createOfflineOnlyFallback();
      }
    } catch (e) {
      debugPrint('Server fallback also failed: $e, creating offline-only fallback');
      _createOfflineOnlyFallback();
    }
    
    notifyListeners();
  }

  void _createOfflineOnlyFallback() {
    // Create a truly minimal offline-only set as last resort
    _sets.add(
      FlashcardSet(
        id: 'offline-minimal-001',
        title: 'Offline Mode (Limited)',
        description: 'Minimal content available in offline mode',
        isDraft: false,
        rating: 4.0,
        ratingCount: 0,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'What is data analysis?',
            answer: 'Data analysis is the process of examining data to discover patterns and insights.',
            isCompleted: false,
          ),
          Flashcard(
            id: '2',
            question: 'What is machine learning?',
            answer: 'Machine learning is a type of AI that enables computers to learn from data.',
            isCompleted: false,
          ),
        ],
      ),
    );
    
    debugPrint('Created offline-only fallback with minimal content');
  }

  Future<void> _saveSets() async {
    try {
      // Log set details before saving
      for (final set in _sets) {
        debugPrint('Saving set: ${set.id} - ${set.title}');
        // Count completed flashcards for each set
        final completedCount = set.flashcards.where((card) => card.isCompleted).length;
        debugPrint('Set ${set.id} has $completedCount/${set.flashcards.length} completed cards');
      }
      
      // Save using simple StorageService
      final setsData = _sets.map((set) => set.toJson()).toList();
      await StorageService.saveFlashcardSets(setsData);
      
      debugPrint('Flashcard sets saved successfully');
      
      // Verify the data was saved correctly
      final savedSetsData = StorageService.getFlashcardSets();
      if (savedSetsData != null) {
        debugPrint('Verified saved data: ${savedSetsData.length} sets found in storage');
      } else {
        debugPrint('WARNING: Failed to verify saved data!');
      }
    } catch (e) {
      debugPrint('Error saving flashcard sets: $e');
      // Re-throw for proper error handling
      throw Exception('Failed to save flashcard sets: $e');
    }
  }

  Future<void> createFlashcardSet(FlashcardSet set) async {
    _sets.add(set);
    await _saveSets();
    notifyListeners();
  }

  Future<void> updateFlashcardSet(FlashcardSet set) async {
    final index = _sets.indexWhere((s) => s.id == set.id);
    if (index >= 0) {
      debugPrint('Updating flashcard set ${set.id}: ${set.title}');
      debugPrint('Found at index $index in sets list');
      
      // Count completed flashcards for logging
      int completedCount = set.flashcards.where((card) => card.isCompleted).length;
      debugPrint('Completed cards: $completedCount/${set.flashcards.length}');
      
      // Create a fresh copy with the current timestamp
      final updatedSet = set.copyWith(
        lastUpdated: DateTime.now(),
      );
      
      _sets[index] = updatedSet;
      await _saveSets();
      
      // Force UI refresh
      notifyListeners();
      debugPrint('Flashcard set updated and saved: ${set.id}');
    } else {
      debugPrint('Error: Could not find flashcard set with ID ${set.id}');
    }
  }

  Future<void> deleteFlashcardSet(String id) async {
    _sets.removeWhere((set) => set.id == id);
    await _saveSets();
    notifyListeners();
  }
  
  FlashcardSet? getFlashcardSet(String id) {
    try {
      return _sets.firstWhere((set) => set.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Update the rating of a flashcard set
  Future<void> rateFlashcardSet(String id, double rating) async {
    final index = _sets.indexWhere((s) => s.id == id);
    if (index >= 0) {
      final set = _sets[index];
      final newRatingCount = set.ratingCount + 1;
      final newRating = ((set.rating * set.ratingCount) + rating) / newRatingCount;
      
      _sets[index] = set.copyWith(
        rating: newRating,
        ratingCount: newRatingCount,
      );
      
      await _saveSets();
      notifyListeners();
    }
  }
  
  // Clear all flashcard sets (for testing)
  Future<void> clearAllSets() async {
    _sets.clear();
    await _saveSets();
    notifyListeners();
  }
  
  // Public method to reload sets from storage
  Future<void> reloadSets() async {
    debugPrint('Explicitly reloading flashcard sets from storage');
    await _loadSets();
  }
  
  // Search methods for the search feature
  Future<List<FlashcardSet>> searchDecks(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    
    // Return an empty list if the query is too short
    if (normalizedQuery.length < 3) {
      return [];
    }
    
    return _sets.where((set) {
      // Search in title, description, and flashcard content
      final titleMatch = set.title.toLowerCase().contains(normalizedQuery);
      final descriptionMatch = set.description.toLowerCase().contains(normalizedQuery);
      
      // Check if any flashcards match the query
      final hasMatchingFlashcards = set.flashcards.any((card) {
        return card.question.toLowerCase().contains(normalizedQuery) ||
               card.answer.toLowerCase().contains(normalizedQuery);
      });
      
      return titleMatch || descriptionMatch || hasMatchingFlashcards;
    }).toList();
  }

  Future<List<Flashcard>> searchCards(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    final results = <Flashcard>[];
    
    // Return an empty list if the query is too short
    if (normalizedQuery.length < 3) {
      return results;
    }
    
    for (final set in _sets) {
      final matchingCards = set.flashcards.where((card) {
        return card.question.toLowerCase().contains(normalizedQuery) ||
               card.answer.toLowerCase().contains(normalizedQuery);
      }).toList();
      
      // Add extra information to each card for display in search results
      for (final card in matchingCards) {
        // We can't modify the cards directly, so we're collecting them for now
        // In a real implementation, we'd want to wrap this in a SearchResultItem class 
        // that contains both the card and its parent set information
        results.add(card);
      }
    }
    
    return results;
  }
}