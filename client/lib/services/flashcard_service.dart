import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'local_auth_service.dart';
import 'local_api_service.dart';

class FlashcardService extends ChangeNotifier {
  final LocalAuthService _authService = LocalAuthService();
  final LocalApiService _apiService = LocalApiService();
  final List<FlashcardSet> _sets = [];
  int _createdDecksCount = 0; // Track number of decks created by user

  List<FlashcardSet> get sets => List.unmodifiable(_sets);
  int get createdDecksCount => _createdDecksCount;

  FlashcardService() {
    // Load demo data immediately
    _loadDemoData();

    // Then load sets from storage/API
    _loadSets();

    // Load created decks count
    _loadCreatedDecksCount();

    // Listen for auth state changes
    _authService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedIn || 
          event.event == AuthChangeEvent.signedUp) {
        _loadSets();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _sets.clear();
        _loadDemoData(); // Reload demo data when signed out
        notifyListeners();
      }
    });
  }

  // Load created decks count from shared preferences
  Future<void> _loadCreatedDecksCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _createdDecksCount = prefs.getInt('created_decks_count') ?? 0;
    } catch (e) {
      debugPrint('Error loading created decks count: $e');
    }
  }

  // Save created decks count to shared preferences
  Future<void> _saveCreatedDecksCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('created_decks_count', _createdDecksCount);
    } catch (e) {
      debugPrint('Error saving created decks count: $e');
    }
  }

  Future<void> _loadSets() async {
    try {
      // Always start by loading demo data to ensure users see something
      _loadDemoData();

      if (_authService.isAuthenticated) {
        // Load sets from API
        try {
          final setsData = await _apiService.getFlashcardSets();
          
          for (final setData in setsData) {
            final List<Flashcard> cards = [];

            // Process flashcards if any
            if (setData['flashcards'] != null) {
              for (final cardData in setData['flashcards']) {
                cards.add(
                  Flashcard(
                    id: cardData['id'],
                    question: cardData['question'],
                    answer: cardData['answer'],
                    hint: cardData['hint'],
                    imageUrl: cardData['image_url'],
                  ),
                );
              }
            }

            // Check if we already have this set (to avoid duplicates)
            if (!_sets.any((s) => s.id == setData['id'])) {
              _sets.add(
                FlashcardSet(
                  id: setData['id'],
                  title: setData['title'],
                  description: setData['description'] ?? '',
                  isDraft: setData['is_draft'] ?? true,
                  isPublic: setData['is_public'] ?? false,
                  rating: setData['rating']?.toDouble() ?? 0.0,
                  ratingCount: setData['rating_count'] ?? 0,
                  ownerId: setData['user_id'],
                  isOwned: setData['user_id'] == _authService.userId,
                  flashcards: cards,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('Error loading flashcard sets from API: $e');
          // Load from local storage if API fails
          await _loadLocalSets();
        }
      } else {
        // Load from local storage if not authenticated
        await _loadLocalSets();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flashcard sets: $e');
      // Load demo data if error
      _loadDemoData();
    }
  }

  // Load sets from local storage
  Future<void> _loadLocalSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final setsJson = prefs.getStringList('flashcard_sets');

      if (setsJson != null && setsJson.isNotEmpty) {
        for (final setJson in setsJson) {
          final Map<String, dynamic> data = json.decode(setJson);
          
          // Check if we already have this set (to avoid duplicates)
          if (!_sets.any((s) => s.id == data['id'])) {
            _sets.add(FlashcardSet.fromJson(data));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading local flashcard sets: $e');
    }
  }

  void _loadDemoData() {
    // Remove any existing demo data first to prevent duplicates
    _sets.removeWhere((set) => set.id == 'demo1' || set.id == 'basic1');

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
            question:
                'What is the formula for calculating the area of a circle?',
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

    // Add the "Basic" flashcard deck
    _sets.add(
      FlashcardSet(
        id: 'basic1',
        title: 'Basic',
        description:
            'A collection of fundamental concepts across different subjects',
        isDraft: false,
        isPublic: true,
        rating: 4.5,
        ratingCount: 120,
        flashcards: [
          Flashcard(
            id: 'b1',
            question: 'What is the Pythagorean theorem?',
            answer:
                'In a right triangle, the square of the length of the hypotenuse equals the sum of the squares of the lengths of the other two sides (a² + b² = c²)',
            hint: 'It relates to right triangles',
          ),
          Flashcard(
            id: 'b2',
            question: 'What is the first law of thermodynamics?',
            answer:
                'Energy cannot be created or destroyed, only transformed from one form to another',
            hint: 'Conservation principle',
          ),
          Flashcard(
            id: 'b3',
            question: 'What is photosynthesis?',
            answer:
                'The process by which green plants and some other organisms convert light energy into chemical energy',
            hint: 'Plants use this to make food',
          ),
          Flashcard(
            id: 'b4',
            question: 'What is the difference between DNA and RNA?',
            answer:
                'DNA is double-stranded and contains thymine, while RNA is single-stranded and contains uracil instead of thymine',
            hint: 'They differ in structure and one base pair',
          ),
          Flashcard(
            id: 'b5',
            question: 'Who is Isaac Newton?',
            answer:
                'An English mathematician, physicist, and astronomer who formulated the laws of motion and universal gravitation',
            hint: 'Famous for a story about an apple',
          ),
          Flashcard(
            id: 'b6',
            question: 'What is the periodic table of elements?',
            answer:
                'A tabular arrangement of chemical elements, organized by atomic number, electron configuration, and recurring chemical properties',
            hint: 'Organizes chemical elements',
          ),
          Flashcard(
            id: 'b7',
            question: 'What is the capital of Japan?',
            answer: 'Tokyo',
            hint: 'It\'s on the island of Honshu',
          ),
          Flashcard(
            id: 'b8',
            question: 'What is the difference between a simile and a metaphor?',
            answer:
                'A simile compares things using "like" or "as," while a metaphor directly states that one thing is another',
            hint: 'Both are literary devices for comparison',
          ),
        ],
      ),
    );

    notifyListeners();
  }

  Future<void> _saveSets() async {
    try {
      // Only save locally if not authenticated
      final prefs = await SharedPreferences.getInstance();
      final setsJson = _sets
          .where((set) => set.id != 'demo1' && set.id != 'basic1') // Don't save demo sets
          .map((set) => json.encode(set.toJson()))
          .toList();
      await prefs.setStringList('flashcard_sets', setsJson);
    } catch (e) {
      debugPrint('Error saving flashcard sets: $e');
    }
  }

  Future<void> createFlashcardSet(FlashcardSet set) async {
    // Increment the deck counter when user creates a new set (excluding demo and basic sets)
    if (set.id != 'demo1' && set.id != 'basic1') {
      _createdDecksCount++;
      await _saveCreatedDecksCount(); // Save the updated count
      debugPrint('Created decks count: $_createdDecksCount'); // Debug log
    }

    if (_authService.isAuthenticated) {
      try {
        // Prepare data for API
        final setData = {
          'title': set.title,
          'description': set.description,
          'is_draft': set.isDraft,
          'is_public': set.isPublic,
          'flashcards': set.flashcards.map((card) => {
            'question': card.question,
            'answer': card.answer,
            'hint': card.hint,
            'image_url': card.imageUrl,
            'position': set.flashcards.indexOf(card),
          }).toList(),
        };

        // Create via API
        final result = await _apiService.createFlashcardSet(setData);
        
        // Convert API response to FlashcardSet
        final List<Flashcard> cards = [];
        if (result['flashcards'] != null) {
          for (final cardData in result['flashcards']) {
            cards.add(
              Flashcard(
                id: cardData['id'],
                question: cardData['question'],
                answer: cardData['answer'],
                hint: cardData['hint'],
                imageUrl: cardData['image_url'],
              ),
            );
          }
        }
        
        final newSet = FlashcardSet(
          id: result['id'],
          title: result['title'],
          description: result['description'] ?? '',
          isDraft: result['is_draft'] ?? true,
          isPublic: result['is_public'] ?? false,
          ownerId: result['user_id'],
          isOwned: true,
          flashcards: cards,
        );
        
        _sets.add(newSet);
        notifyListeners();
      } catch (e) {
        debugPrint('Error creating flashcard set via API: $e');
        // Fall back to local storage
        _sets.add(set);
        await _saveSets();
        notifyListeners();
      }
    } else {
      // Save locally if not authenticated
      _sets.add(set);
      await _saveSets();
      notifyListeners();
    }
  }

  Future<void> updateFlashcardSet(FlashcardSet set) async {
    if (_authService.isAuthenticated && set.id.length > 10) {
      // Assuming UUID format for API IDs
      try {
        // Prepare data for API
        final setData = {
          'title': set.title,
          'description': set.description,
          'is_draft': set.isDraft,
          'is_public': set.isPublic,
          'flashcards': set.flashcards.map((card) => {
            'question': card.question,
            'answer': card.answer,
            'hint': card.hint,
            'image_url': card.imageUrl,
            'position': set.flashcards.indexOf(card),
          }).toList(),
        };

        // Update via API
        await _apiService.updateFlashcardSet(set.id, setData);
        
        // Update local list
        final index = _sets.indexWhere((s) => s.id == set.id);
        if (index >= 0) {
          _sets[index] = set;
          notifyListeners();
        } else {
          // If not found, add it
          _sets.add(set);
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error updating flashcard set via API: $e');
        // Fall back to local update
        final index = _sets.indexWhere((s) => s.id == set.id);
        if (index >= 0) {
          _sets[index] = set;
          await _saveSets();
          notifyListeners();
        }
      }
    } else {
      // Update locally if not authenticated or demo set
      final index = _sets.indexWhere((s) => s.id == set.id);
      if (index >= 0) {
        _sets[index] = set;
        await _saveSets();
        notifyListeners();
      }
    }
  }

  Future<void> deleteFlashcardSet(String id) async {
    if (_authService.isAuthenticated && id.length > 10) {
      // Assuming UUID format for API IDs
      try {
        // Delete via API
        await _apiService.deleteFlashcardSet(id);
        
        // Remove from local list
        _sets.removeWhere((set) => set.id == id);
        notifyListeners();
      } catch (e) {
        debugPrint('Error deleting flashcard set via API: $e');
        // Fall back to local deletion
        _sets.removeWhere((set) => set.id == id);
        await _saveSets();
        notifyListeners();
      }
    } else {
      // Delete locally if not authenticated or demo set
      _sets.removeWhere((set) => set.id == id);
      await _saveSets();
      notifyListeners();
    }
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
    if (_authService.isAuthenticated && id.length > 10) {
      // Assuming UUID format for API IDs
      try {
        // Update rating via API
        final result = await _apiService.rateFlashcardSet(id, rating);
        
        // Update local list
        final index = _sets.indexWhere((s) => s.id == id);
        if (index >= 0) {
          _sets[index] = _sets[index].copyWith(
            rating: result['rating']?.toDouble() ?? 0.0,
            ratingCount: result['rating_count'] ?? 0,
          );
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error rating flashcard set via API: $e');
        // Fall back to local rating update
        final index = _sets.indexWhere((s) => s.id == id);
        if (index >= 0) {
          final set = _sets[index];
          final newRatingCount = set.ratingCount + 1;
          final newRating =
              ((set.rating * set.ratingCount) + rating) / newRatingCount;

          _sets[index] = set.copyWith(
            rating: newRating,
            ratingCount: newRatingCount,
          );

          await _saveSets();
          notifyListeners();
        }
      }
    } else {
      // Update locally if not authenticated
      final index = _sets.indexWhere((s) => s.id == id);
      if (index >= 0) {
        final set = _sets[index];
        final newRatingCount = set.ratingCount + 1;
        final newRating =
            ((set.rating * set.ratingCount) + rating) / newRatingCount;

        _sets[index] = set.copyWith(
          rating: newRating,
          ratingCount: newRatingCount,
        );

        await _saveSets();
        notifyListeners();
      }
    }
  }

  // Clear all flashcard sets (for testing)
  Future<void> clearAllSets() async {
    if (_authService.isAuthenticated) {
      try {
        // We can't use an API call here since we'd need a custom endpoint
        // Instead, we'll just delete each set owned by the user
        final ownedSets = _sets.where((set) => 
          set.id != 'demo1' && 
          set.id != 'basic1' && 
          set.isOwned
        ).toList();
        
        for (final set in ownedSets) {
          await deleteFlashcardSet(set.id);
        }
      } catch (e) {
        debugPrint('Error clearing flashcard sets: $e');
      }
    } else {
      // Clear local sets but keep demo sets
      _sets.removeWhere((set) => set.id != 'demo1' && set.id != 'basic1');
      await _saveSets();
      notifyListeners();
    }

    // Ensure demo data is always available
    if (!_sets.any((set) => set.id == 'demo1' || set.id == 'basic1')) {
      _loadDemoData();
    }
  }
}
