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
    
    // Add Python Basics flashcard set - 0% complete initially
    _sets.add(
      FlashcardSet(
        id: 'python-basics-001',
        title: 'Python Basics',
        description: 'Python',
        isDraft: false,
        rating: 4.5,
        ratingCount: 12,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'What is Python?',
            answer: 'Python is a high-level, interpreted programming language known for its readability and versatility.',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '2',
            question: 'How do you comment a single line in Python?',
            answer: 'Use the # symbol at the beginning of the line.',
          ),
          Flashcard(
            id: '3',
            question: 'How do you print text in Python?',
            answer: 'print("Hello, World!")',
          ),
          Flashcard(
            id: '4',
            question: 'What are the primitive data types in Python?',
            answer: 'Integers, floats, strings, booleans, and None.',
          ),
          Flashcard(
            id: '5',
            question: 'How do you define a variable in Python?',
            answer: 'variable_name = value',
          ),
          Flashcard(
            id: '6',
            question: 'What is indentation used for in Python?',
            answer: 'Indentation defines code blocks and is required for control structures like loops and conditionals.',
          ),
          Flashcard(
            id: '7',
            question: 'How do you create a multi-line string in Python?',
            answer: 'Use triple quotes: """multi-line string"""',
          ),
          Flashcard(
            id: '8',
            question: 'What is the difference between == and is?',
            answer: '== compares the values, while "is" compares the identity (memory location).',
          ),
          Flashcard(
            id: '9',
            question: 'How do you convert a string to an integer?',
            answer: 'int("42")',
          ),
          Flashcard(
            id: '10',
            question: 'How do you get the length of a string?',
            answer: 'len(my_string)',
          ),
          Flashcard(
            id: '11',
            question: 'What does the % operator do in Python?',
            answer: 'It returns the remainder of a division (modulo operation).',
          ),
          Flashcard(
            id: '12',
            question: 'How do you check if a value is in a list?',
            answer: 'value in my_list',
          ),
        ],
      ),
    );
    
    // Add Python Classes flashcard set - 0% complete initially
    _sets.add(
      FlashcardSet(
        id: 'python-classes-001',
        title: 'Python Classes',
        description: 'Python',
        isDraft: false,
        rating: 4.2,
        ratingCount: 8,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'How do you define a class in Python?',
            answer: 'class MyClass:',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '2',
            question: 'What is the __init__ method used for?',
            answer: 'It\'s the constructor method that initializes a new instance of a class.',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '3',
            question: 'What does self refer to in a method?',
            answer: 'It refers to the instance of the class that the method is being called on.',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '4',
            question: 'How do you create an instance of a class?',
            answer: 'my_instance = MyClass()',
          ),
          Flashcard(
            id: '5',
            question: 'What is inheritance in Python?',
            answer: 'It allows a class to inherit attributes and methods from another class.',
          ),
          Flashcard(
            id: '6',
            question: 'How do you define a subclass?',
            answer: 'class SubClass(ParentClass):',
          ),
          Flashcard(
            id: '7',
            question: 'What is a class method?',
            answer: 'A method that receives the class as an implicit first argument, decorated with @classmethod.',
          ),
          Flashcard(
            id: '8',
            question: 'What is a static method?',
            answer: 'A method that doesn\'t receive an implicit first argument, decorated with @staticmethod.',
          ),
        ],
      ),
    );
    
    // Add Python Data Types flashcard set - 0% complete initially
    _sets.add(
      FlashcardSet(
        id: 'python-data-types-001',
        title: 'Python Data Types',
        description: 'Python',
        isDraft: false,
        rating: 4.8,
        ratingCount: 15,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'What is a list in Python?',
            answer: 'An ordered, mutable collection of elements: [1, 2, 3]',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '2',
            question: 'What is a tuple in Python?',
            answer: 'An ordered, immutable collection of elements: (1, 2, 3)',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '3',
            question: 'What is a dictionary in Python?',
            answer: 'An unordered collection of key-value pairs: {"key": "value"}',
          ),
          Flashcard(
            id: '4',
            question: 'What is a set in Python?',
            answer: 'An unordered collection of unique elements: {1, 2, 3}',
          ),
          Flashcard(
            id: '5',
            question: 'How do you access an element in a list?',
            answer: 'my_list[index]',
          ),
          Flashcard(
            id: '6',
            question: 'How do you add an item to a list?',
            answer: 'my_list.append(item)',
          ),
          Flashcard(
            id: '7',
            question: 'How do you remove an item from a list?',
            answer: 'my_list.remove(item) or del my_list[index]',
          ),
          Flashcard(
            id: '8',
            question: 'How do you access a value in a dictionary?',
            answer: 'my_dict["key"] or my_dict.get("key")',
          ),
          Flashcard(
            id: '9',
            question: 'What is a list comprehension?',
            answer: 'A concise way to create lists: [x for x in range(10)]',
          ),
          Flashcard(
            id: '10',
            question: 'How do you check the type of a variable?',
            answer: 'type(variable)',
          ),
          Flashcard(
            id: '11',
            question: 'What is the difference between mutable and immutable data types?',
            answer: 'Mutable data types can be modified after creation; immutable ones cannot.',
          ),
          Flashcard(
            id: '12',
            question: 'What is typecasting in Python?',
            answer: 'Converting one data type to another, like int(), str(), float(), etc.',
          ),
          Flashcard(
            id: '13',
            question: 'How do you create an empty set?',
            answer: 'empty_set = set()',
          ),
          Flashcard(
            id: '14',
            question: 'What does the sorted() function do?',
            answer: 'Returns a new sorted list from an iterable.',
          ),
          Flashcard(
            id: '15',
            question: 'What is the None value in Python?',
            answer: 'A special constant representing the absence of a value or a null value.',
          ),
        ],
      ),
    );
    
    // Add Python Functions flashcard set - 0% complete initially
    _sets.add(
      FlashcardSet(
        id: 'python-functions-001',
        title: 'Python Functions',
        description: 'Python',
        isDraft: false,
        rating: 0.0,
        ratingCount: 0,
        flashcards: [
          Flashcard(
            id: '1',
            question: 'How do you define a function in Python?',
            answer: 'def function_name(parameters):',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '2',
            question: 'How do you return a value from a function?',
            answer: 'return value',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '3',
            question: 'What are default parameter values?',
            answer: 'Values assigned to parameters that are used if no argument is provided: def func(param=default):',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '4',
            question: 'What is a lambda function?',
            answer: 'An anonymous function defined with the lambda keyword: lambda x: x*2',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '5',
            question: 'What is the *args parameter?',
            answer: 'It allows a function to accept any number of positional arguments.',
            isCompleted: false,  // Not completed initially
          ),
          Flashcard(
            id: '6',
            question: 'What is the **kwargs parameter?',
            answer: 'It allows a function to accept any number of keyword arguments.',
          ),
          Flashcard(
            id: '7',
            question: 'What is a recursive function?',
            answer: 'A function that calls itself.',
          ),
          Flashcard(
            id: '8',
            question: 'What is a higher-order function?',
            answer: 'A function that takes another function as an argument or returns a function.',
          ),
          Flashcard(
            id: '9',
            question: 'What is the scope of a variable in a function?',
            answer: 'The region of code where the variable is accessible.',
          ),
          Flashcard(
            id: '10',
            question: 'What is a closure in Python?',
            answer: 'A function that remembers values from the enclosing lexical scope even when executed outside that scope.',
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
}