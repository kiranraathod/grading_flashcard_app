import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'default_data_service.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final setsJson = prefs.getStringList('flashcard_sets');

      if (setsJson != null && setsJson.isNotEmpty) {
        _sets.clear();
        for (final setJson in setsJson) {
          final Map<String, dynamic> data = json.decode(setJson);
          _sets.add(FlashcardSet.fromJson(data));
        }
      } else {
        // Load default data from server if no saved sets
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
    
    // Create a minimal Python basics set as fallback
    _sets.add(
      FlashcardSet(
        id: 'fallback-python-001',
        title: 'Python Basics (Offline)',
        description: 'Basic Python concepts - offline mode',
        isDraft: false,
        rating: 4.5,
        ratingCount: 0,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'What is Python?',
            answer: 'Python is a high-level, interpreted programming language.',
            isCompleted: false,
          ),
          Flashcard(
            id: '2',
            question: 'How do you print in Python?',
            answer: 'print("Hello, World!")',
            isCompleted: false,
          ),
          Flashcard(
            id: '3',
            question: 'How do you comment in Python?',
            answer: 'Use # for single line comments',
            isCompleted: false,
          ),
        ],
      ),
    );
    
    notifyListeners();
  }

  Future<void> _saveSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert sets to JSON strings
      final setsJson = _sets.map((set) {
        final jsonStr = json.encode(set.toJson());
        debugPrint('Saving set: ${set.id} - ${set.title}');
        // Count completed flashcards for each set
        final completedCount = set.flashcards.where((card) => card.isCompleted).length;
        debugPrint('Set ${set.id} has $completedCount/${set.flashcards.length} completed cards');
        return jsonStr;
      }).toList();
      
      // Clear previous data and save new data
      await prefs.remove('flashcard_sets');
      final success = await prefs.setStringList('flashcard_sets', setsJson);
      
      debugPrint('Flashcard sets saved successfully: $success');
      
      // Verify the data was saved correctly
      final savedSetsJson = prefs.getStringList('flashcard_sets');
      if (savedSetsJson != null) {
        debugPrint('Verified saved data: ${savedSetsJson.length} sets found in storage');
      } else {
        debugPrint('WARNING: Failed to verify saved data!');
      }
    } catch (e) {
      debugPrint('Error saving flashcard sets: $e');
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