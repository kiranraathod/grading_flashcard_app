import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'supabase_service.dart';

class FlashcardService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final List<FlashcardSet> _sets = [];
  
  List<FlashcardSet> get sets => List.unmodifiable(_sets);
  
  FlashcardService() {
    // Load demo data immediately
    _loadDemoData();
    
    // Then load sets from storage/API
    _loadSets();
    
    // Listen for auth state changes
    _supabaseService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _loadSets();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _sets.clear();
        _loadDemoData(); // Reload demo data when signed out
        notifyListeners();
      }
    });
  }

  Future<void> _loadSets() async {
    try {
      // Always start by loading demo data to ensure users see something
      _loadDemoData();
      
      if (_supabaseService.isAuthenticated) {
        // Load additional sets from Supabase
        final userId = _supabaseService.currentUser!.id;
        final setsResponse = await _supabaseService.client
            .from('flashcard_sets')
            .select('*, flashcards(*)')
            .or('user_id.eq.$userId,is_public.eq.true')
            .order('date_created', ascending: false);
        
        if (setsResponse != null && setsResponse.isNotEmpty) {
          for (final setData in setsResponse) {
            final List<Flashcard> cards = [];
            
            // Process flashcards if any
            if (setData['flashcards'] != null) {
              for (final cardData in setData['flashcards']) {
                cards.add(Flashcard(
                  id: cardData['id'],
                  question: cardData['question'],
                  answer: cardData['answer'],
                  hint: cardData['hint'],
                  imageUrl: cardData['image_url'],
                ));
              }
            }
            
            _sets.add(FlashcardSet(
              id: setData['id'],
              title: setData['title'],
              description: setData['description'] ?? '',
              isDraft: setData['is_draft'] ?? true,
              isPublic: setData['is_public'] ?? false,
              rating: setData['rating']?.toDouble() ?? 0.0,
              ratingCount: setData['rating_count'] ?? 0,
              ownerId: setData['user_id'],
              isOwned: setData['user_id'] == userId,
              flashcards: cards,
            ));
          }
        }
      } else {
        // Load additional sets from local storage if not authenticated
        final prefs = await SharedPreferences.getInstance();
        final setsJson = prefs.getStringList('flashcard_sets');

        if (setsJson != null && setsJson.isNotEmpty) {
          for (final setJson in setsJson) {
            final Map<String, dynamic> data = json.decode(setJson);
            _sets.add(FlashcardSet.fromJson(data));
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flashcard sets: $e');
      // Load demo data if error
      _loadDemoData();
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
    
    // Add the "Basic" flashcard deck
    _sets.add(
      FlashcardSet(
        id: 'basic1',
        title: 'Basic',
        description: 'A collection of fundamental concepts across different subjects',
        isDraft: false,
        isPublic: true,
        rating: 4.5,
        ratingCount: 120,
        flashcards: [
          Flashcard(
            id: 'b1',
            question: 'What is the Pythagorean theorem?',
            answer: 'In a right triangle, the square of the length of the hypotenuse equals the sum of the squares of the lengths of the other two sides (a² + b² = c²)',
            hint: 'It relates to right triangles',
          ),
          Flashcard(
            id: 'b2',
            question: 'What is the first law of thermodynamics?',
            answer: 'Energy cannot be created or destroyed, only transformed from one form to another',
            hint: 'Conservation principle',
          ),
          Flashcard(
            id: 'b3',
            question: 'What is photosynthesis?',
            answer: 'The process by which green plants and some other organisms convert light energy into chemical energy',
            hint: 'Plants use this to make food',
          ),
          Flashcard(
            id: 'b4',
            question: 'What is the difference between DNA and RNA?',
            answer: 'DNA is double-stranded and contains thymine, while RNA is single-stranded and contains uracil instead of thymine',
            hint: 'They differ in structure and one base pair',
          ),
          Flashcard(
            id: 'b5',
            question: 'Who is Isaac Newton?',
            answer: 'An English mathematician, physicist, and astronomer who formulated the laws of motion and universal gravitation',
            hint: 'Famous for a story about an apple',
          ),
          Flashcard(
            id: 'b6',
            question: 'What is the periodic table of elements?',
            answer: 'A tabular arrangement of chemical elements, organized by atomic number, electron configuration, and recurring chemical properties',
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
            answer: 'A simile compares things using "like" or "as," while a metaphor directly states that one thing is another',
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
      if (!_supabaseService.isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        final setsJson = _sets.map((set) => json.encode(set.toJson())).toList();
        await prefs.setStringList('flashcard_sets', setsJson);
      }
    } catch (e) {
      debugPrint('Error saving flashcard sets: $e');
    }
  }

  Future<void> createFlashcardSet(FlashcardSet set) async {
    if (_supabaseService.isAuthenticated) {
      try {
        final userId = _supabaseService.currentUser!.id;
        
        // Create the set in Supabase
        final response = await _supabaseService.client
            .from('flashcard_sets')
            .insert({
              'title': set.title,
              'description': set.description,
              'is_draft': set.isDraft,
              'is_public': set.isPublic,
              'user_id': userId,
            })
            .select()
            .single();
        
        if (response != null) {
          final String setId = response['id'];
          
          // Create flashcards
          if (set.flashcards.isNotEmpty) {
            final cardsData = set.flashcards.map((card) => {
              'set_id': setId,
              'question': card.question,
              'answer': card.answer,
              'hint': card.hint,
              'image_url': card.imageUrl,
              'position': set.flashcards.indexOf(card),
            }).toList();
            
            await _supabaseService.client
                .from('flashcards')
                .insert(cardsData);
          }
          
          // Reload sets to get the updated data
          await _loadSets();
        }
      } catch (e) {
        debugPrint('Error creating flashcard set in Supabase: $e');
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
    if (_supabaseService.isAuthenticated && set.id.length > 10) {  // Assuming UUID format for Supabase IDs
      try {
        // Update the set in Supabase
        await _supabaseService.client
            .from('flashcard_sets')
            .update({
              'title': set.title,
              'description': set.description,
              'is_draft': set.isDraft,
              'is_public': set.isPublic,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', set.id);
        
        // Handle flashcards updates
        // 1. Delete all existing cards
        await _supabaseService.client
            .from('flashcards')
            .delete()
            .eq('set_id', set.id);
        
        // 2. Insert new cards
        if (set.flashcards.isNotEmpty) {
          final cardsData = set.flashcards.map((card) => {
            'set_id': set.id,
            'question': card.question,
            'answer': card.answer,
            'hint': card.hint,
            'image_url': card.imageUrl,
            'position': set.flashcards.indexOf(card),
          }).toList();
          
          await _supabaseService.client
              .from('flashcards')
              .insert(cardsData);
        }
        
        // Reload sets to get the updated data
        await _loadSets();
      } catch (e) {
        debugPrint('Error updating flashcard set in Supabase: $e');
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
    if (_supabaseService.isAuthenticated && id.length > 10) {  // Assuming UUID format for Supabase IDs
      try {
        // Delete the set in Supabase
        await _supabaseService.client
            .from('flashcard_sets')
            .delete()
            .eq('id', id);
        
        // Remove from local list
        _sets.removeWhere((set) => set.id == id);
        notifyListeners();
      } catch (e) {
        debugPrint('Error deleting flashcard set in Supabase: $e');
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
    if (_supabaseService.isAuthenticated && id.length > 10) {  // Assuming UUID format for Supabase IDs
      try {
        // Get current set data from Supabase
        final response = await _supabaseService.client
            .from('flashcard_sets')
            .select('rating, rating_count')
            .eq('id', id)
            .single();
        
        if (response != null) {
          final currentRating = response['rating'] ?? 0.0;
          final currentCount = response['rating_count'] ?? 0;
          
          final newRatingCount = currentCount + 1;
          final newRating = ((currentRating * currentCount) + rating) / newRatingCount;
          
          // Update rating in Supabase
          await _supabaseService.client
              .from('flashcard_sets')
              .update({
                'rating': newRating,
                'rating_count': newRatingCount,
              })
              .eq('id', id);
          
          // Update local list
          final index = _sets.indexWhere((s) => s.id == id);
          if (index >= 0) {
            _sets[index] = _sets[index].copyWith(
              rating: newRating,
              ratingCount: newRatingCount,
            );
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Error rating flashcard set in Supabase: $e');
        // Fall back to local rating update
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
    } else {
      // Update locally if not authenticated
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
  }
  
  // Clear all flashcard sets (for testing)
  Future<void> clearAllSets() async {
    if (_supabaseService.isAuthenticated) {
      try {
        final userId = _supabaseService.currentUser!.id;
        
        // Delete all sets owned by the user
        await _supabaseService.client
            .from('flashcard_sets')
            .delete()
            .eq('user_id', userId);
        
        // Remove user's sets but keep demo sets
        _sets.removeWhere((set) => 
          set.id != 'demo1' && 
          set.id != 'basic1' && 
          (set.ownerId == userId || set.ownerId == null)
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Error clearing flashcard sets in Supabase: $e');
      }
    } else {
      // Clear local sets but keep demo sets
      _sets.removeWhere((set) => 
        set.id != 'demo1' && 
        set.id != 'basic1'
      );
      await _saveSets();
      notifyListeners();
    }
    
    // Ensure demo data is always available
    if (!_sets.any((set) => set.id == 'demo1' || set.id == 'basic1')) {
      _loadDemoData();
    }
  }
}
