import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';

class FlashcardService extends ChangeNotifier {
  final List<FlashcardSet> _sets = [];
  
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
        // Load demo data if no saved sets
        _loadDemoData();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flashcard sets: $e');
      // Load demo data if error
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    _sets.clear();
    
    // Add a demo flashcard set
    _sets.add(
      FlashcardSet(
        id: 'demo1',
        title: '(Draft) Untitled',
        description: '',
        isDraft: true,
        rating: 0.0,
        ratingCount: 0,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'What is the capital of France?',
            answer: 'Paris',
          ),
          Flashcard(
            id: '2',
            question: 'What is the formula for calculating the area of a circle?',
            answer: 'A = πr²',
          ),
          Flashcard(
            id: '3',
            question: 'Who wrote "Romeo and Juliet"?',
            answer: 'William Shakespeare',
          ),
          Flashcard(
            id: '4',
            question: 'What is the main function of mitochondria in a cell?',
            answer: 'To produce energy through cellular respiration',
          ),
        ],
      ),
    );
    
    notifyListeners();
  }

  Future<void> _saveSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final setsJson = _sets.map((set) => json.encode(set.toJson())).toList();
      await prefs.setStringList('flashcard_sets', setsJson);
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
      _sets[index] = set;
      await _saveSets();
      notifyListeners();
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
}
