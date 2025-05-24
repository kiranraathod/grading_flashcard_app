# Task 5.4: Update Mock Flashcards

## Objective

Move demo flashcard data from hardcoded service files to separate configuration files, implementing a versioned mock data system that supports different data sets and easy updates without code changes.

## Current State Analysis

**Hardcoded Flashcard Issues in `flashcard_service.dart`:**
```dart
// Lines 296-356: Large block of hardcoded mock flashcards
List<Map<String, dynamic>> mockFlashcards = [
  {
    'question': 'What is the Central Limit Theorem?',
    'answer': 'The Central Limit Theorem states that...',
    'category': 'Statistics',
    'difficulty': 'Medium',
  },
  // 20+ more hardcoded flashcards...
];
```

**Problems with Current Implementation:**
- Mock data is embedded in service code, making updates difficult
- No versioning or variant support for different use cases
- Limited categorization and metadata
- No support for different skill levels or learning paths
- Maintenance requires code changes and redeployment

## Implementation Approach

### Step 1: Create Flashcard Data Models

**Enhanced Flashcard Model:**
```dart
// lib/models/flashcard_data.dart
class FlashcardData {
  final String id;
  final String question;
  final String answer;
  final String category;
  final String subcategory;
  final Difficulty difficulty;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String source;
  final int version;
  
  FlashcardData({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.subcategory,
    required this.difficulty,
    required this.tags,
    required this.metadata,
    required this.createdAt,
    required this.source,
    required this.version,
  });
  
  factory FlashcardData.fromJson(Map<String, dynamic> json) {
    return FlashcardData(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      difficulty: Difficulty.fromString(json['difficulty'] ?? 'medium'),
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      source: json['source'] ?? 'unknown',
      version: json['version'] ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'subcategory': subcategory,
      'difficulty': difficulty.toString(),
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'version': version,
    };
  }
}

enum Difficulty {
  beginner,
  intermediate,
  advanced,
  expert;
  
  static Difficulty fromString(String value) {
    return Difficulty.values.firstWhere(
      (d) => d.toString().split('.').last.toLowerCase() == value.toLowerCase(),
      orElse: () => Difficulty.intermediate,
    );
  }
}

class FlashcardSet {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<FlashcardData> flashcards;
  final FlashcardSetMetadata metadata;
  
  FlashcardSet({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.flashcards,
    required this.metadata,
  });
  
  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      flashcards: (json['flashcards'] as List)
          .map((card) => FlashcardData.fromJson(card))
          .toList(),
      metadata: FlashcardSetMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class FlashcardSetMetadata {
  final Difficulty targetDifficulty;
  final Duration estimatedStudyTime;
  final List<String> prerequisites;
  final List<String> learningObjectives;
  final String author;
  final DateTime lastUpdated;
  final int version;
  
  FlashcardSetMetadata({
    required this.targetDifficulty,
    required this.estimatedStudyTime,
    required this.prerequisites,
    required this.learningObjectives,
    required this.author,
    required this.lastUpdated,
    required this.version,
  });
  
  factory FlashcardSetMetadata.fromJson(Map<String, dynamic> json) {
    return FlashcardSetMetadata(
      targetDifficulty: Difficulty.fromString(json['targetDifficulty'] ?? 'intermediate'),
      estimatedStudyTime: Duration(minutes: json['estimatedStudyTimeMinutes'] ?? 30),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      learningObjectives: List<String>.from(json['learningObjectives'] ?? []),
      author: json['author'] ?? 'FlashMaster',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      version: json['version'] ?? 1,
    );
  }
}
```

### Step 2: Create Mock Data Configuration Files

**Data Science Flashcards (`assets/data/flashcards/data_science_basic.json`):**
```json
{
  "id": "data_science_basic",
  "name": "Data Science Fundamentals",
  "description": "Essential data science concepts for interviews",
  "category": "data_science",
  "metadata": {
    "targetDifficulty": "intermediate",
    "estimatedStudyTimeMinutes": 45,
    "prerequisites": ["statistics_basics", "python_basics"],
    "learningObjectives": [
      "Understand statistical concepts",
      "Apply machine learning principles",
      "Analyze data effectively"
    ],
    "author": "FlashMaster Data Team",
    "lastUpdated": "2024-01-15T10:00:00Z",
    "version": 2
  },
  "flashcards": [
    {
      "id": "ds_001",
      "question": "What is the Central Limit Theorem and why is it important in data science?",
      "answer": "The Central Limit Theorem states that the sampling distribution of the sample mean approaches a normal distribution as the sample size increases, regardless of the population distribution shape. This is crucial for statistical inference, hypothesis testing, and confidence intervals in data science.",
      "category": "data_science",
      "subcategory": "statistics",
      "difficulty": "intermediate",
      "tags": ["statistics", "distribution", "sampling", "theorem"],
      "metadata": {
        "expectedAnswerTime": "2-3 minutes",
        "followUpQuestions": [
          "What are the conditions for CLT to apply?",
          "How does sample size affect the CLT?"
        ],
        "difficulty_explanation": "Requires understanding of statistical distributions and sampling theory"
      },
      "createdAt": "2024-01-10T09:00:00Z",
      "source": "interview_prep_2024",
      "version": 1
    },
    {
      "id": "ds_002",
      "question": "Explain the bias-variance tradeoff in machine learning.",
      "answer": "The bias-variance tradeoff is a fundamental concept where:\n- Bias: Error from overly simplistic assumptions\n- Variance: Error from sensitivity to small fluctuations\n- High bias → underfitting\n- High variance → overfitting\nThe goal is to find the optimal balance to minimize total error.",
      "category": "data_science",
      "subcategory": "machine_learning",
      "difficulty": "intermediate",
      "tags": ["machine_learning", "overfitting", "underfitting", "model_selection"],
      "metadata": {
        "expectedAnswerTime": "3-4 minutes",
        "followUpQuestions": [
          "How do you detect overfitting?",
          "What techniques reduce variance?"
        ],
        "relatedConcepts": ["cross_validation", "regularization"]
      },
      "createdAt": "2024-01-10T09:15:00Z",
      "source": "interview_prep_2024",
      "version": 1
    }
  ]
}
```

**Web Development Flashcards (`assets/data/flashcards/web_dev_fundamentals.json`):**
```json
{
  "id": "web_dev_fundamentals",
  "name": "Web Development Fundamentals",
  "description": "Core web development concepts for interviews",
  "category": "web_development",
  "metadata": {
    "targetDifficulty": "beginner",
    "estimatedStudyTimeMinutes": 30,
    "prerequisites": ["html_basics", "css_basics"],
    "learningObjectives": [
      "Understand web fundamentals",
      "Know JavaScript concepts",
      "Grasp HTTP and browser mechanics"
    ],
    "author": "FlashMaster Web Team",
    "lastUpdated": "2024-01-15T14:00:00Z",
    "version": 1
  },
  "flashcards": [
    {
      "id": "web_001",
      "question": "What is the difference between == and === in JavaScript?",
      "answer": "== performs type coercion before comparison, while === performs strict comparison without type conversion.\nExample:\n'5' == 5 // true (coercion)\n'5' === 5 // false (different types)",
      "category": "web_development",
      "subcategory": "javascript",
      "difficulty": "beginner",
      "tags": ["javascript", "operators", "type_coercion", "comparison"],
      "metadata": {
        "expectedAnswerTime": "1-2 minutes",
        "codeExample": true,
        "commonMistakes": ["Confusing with assignment operator ="]
      },
      "createdAt": "2024-01-12T10:00:00Z",
      "source": "js_fundamentals_2024",
      "version": 1
    }
  ]
}
```

### Step 3: Create Mock Data Provider Service

**Mock Flashcard Provider:**
```dart
// lib/providers/mock_flashcard_provider.dart
class MockFlashcardProvider {
  static final Map<String, FlashcardSet> _cache = {};
  static final Map<String, List<FlashcardData>> _categoryCache = {};
  
  static Future<List<FlashcardSet>> getAllFlashcardSets() async {
    final setIds = await _getAvailableSetIds();
    final sets = <FlashcardSet>[];
    
    for (final setId in setIds) {
      final set = await getFlashcardSet(setId);
      if (set != null) sets.add(set);
    }
    
    return sets;
  }
  
  static Future<FlashcardSet?> getFlashcardSet(String setId) async {
    // Check cache first
    if (_cache.containsKey(setId)) {
      return _cache[setId];
    }
    
    try {
      // Load from assets
      final jsonString = await rootBundle.loadString(
        'assets/data/flashcards/$setId.json'
      );
      
      final jsonData = json.decode(jsonString);
      final flashcardSet = FlashcardSet.fromJson(jsonData);
      
      // Cache the result
      _cache[setId] = flashcardSet;
      
      return flashcardSet;
    } catch (e) {
      print('Error loading flashcard set $setId: $e');
      return null;
    }
  }
  
  static Future<List<FlashcardData>> getFlashcardsByCategory(String category) async {
    // Check cache first
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!;
    }
    
    final allSets = await getAllFlashcardSets();
    final categoryFlashcards = <FlashcardData>[];
    
    for (final set in allSets) {
      if (set.category == category) {
        categoryFlashcards.addAll(set.flashcards);
      }
    }
    
    // Cache the result
    _categoryCache[category] = categoryFlashcards;
    
    return categoryFlashcards;
  }
  
  static Future<List<FlashcardData>> getFlashcardsByDifficulty(
    Difficulty difficulty,
    {String? category}
  ) async {
    List<FlashcardData> allFlashcards;
    
    if (category != null) {
      allFlashcards = await getFlashcardsByCategory(category);
    } else {
      final allSets = await getAllFlashcardSets();
      allFlashcards = allSets.expand((set) => set.flashcards).toList();
    }
    
    return allFlashcards.where((card) => card.difficulty == difficulty).toList();
  }
  
  static Future<List<FlashcardData>> getRandomFlashcards(
    int count, {
    String? category,
    Difficulty? difficulty,
  }) async {
    List<FlashcardData> availableCards;
    
    if (category != null) {
      availableCards = await getFlashcardsByCategory(category);
    } else {
      final allSets = await getAllFlashcardSets();
      availableCards = allSets.expand((set) => set.flashcards).toList();
    }
    
    if (difficulty != null) {
      availableCards = availableCards.where((card) => card.difficulty == difficulty).toList();
    }
    
    // Shuffle and take requested count
    availableCards.shuffle();
    return availableCards.take(count).toList();
  }
  
  static Future<List<String>> _getAvailableSetIds() async {
    // In a real implementation, this could read from a manifest file
    // or scan the assets directory. For now, return known sets.
    return [
      'data_science_basic',
      'data_science_advanced',
      'web_dev_fundamentals',
      'web_dev_advanced',
      'system_design_basics',
      'behavioral_questions',
    ];
  }
  
  static void clearCache() {
    _cache.clear();
    _categoryCache.clear();
  }
  
  static Future<FlashcardStats> getFlashcardStats() async {
    final allSets = await getAllFlashcardSets();
    final allFlashcards = allSets.expand((set) => set.flashcards).toList();
    
    final categoryCount = <String, int>{};
    final difficultyCount = <Difficulty, int>{};
    
    for (final card in allFlashcards) {
      categoryCount[card.category] = (categoryCount[card.category] ?? 0) + 1;
      difficultyCount[card.difficulty] = (difficultyCount[card.difficulty] ?? 0) + 1;
    }
    
    return FlashcardStats(
      totalCount: allFlashcards.length,
      setCount: allSets.length,
      categoryCount: categoryCount,
      difficultyCount: difficultyCount,
      lastUpdated: DateTime.now(),
    );
  }
}

class FlashcardStats {
  final int totalCount;
  final int setCount;
  final Map<String, int> categoryCount;
  final Map<Difficulty, int> difficultyCount;
  final DateTime lastUpdated;
  
  FlashcardStats({
    required this.totalCount,
    required this.setCount,
    required this.categoryCount,
    required this.difficultyCount,
    required this.lastUpdated,
  });
}
```

### Step 4: Update Flashcard Service Integration

**Updated Flashcard Service:**
```dart
// lib/services/flashcard_service.dart
class FlashcardService {
  final ApiService _apiService;
  final MockFlashcardProvider _mockProvider;
  final bool _useRemoteData;
  
  FlashcardService({
    required ApiService apiService,
    bool useRemoteData = false,
  }) : _apiService = apiService,
       _mockProvider = MockFlashcardProvider(),
       _useRemoteData = useRemoteData;
  
  Future<List<FlashcardData>> getFlashcards({
    String? category,
    Difficulty? difficulty,
    int? limit,
  }) async {
    if (_useRemoteData) {
      return _getRemoteFlashcards(
        category: category,
        difficulty: difficulty,
        limit: limit,
      );
    } else {
      return _getMockFlashcards(
        category: category,
        difficulty: difficulty,
        limit: limit,
      );
    }
  }
  
  Future<List<FlashcardData>> _getMockFlashcards({
    String? category,
    Difficulty? difficulty,
    int? limit,
  }) async {
    List<FlashcardData> flashcards;
    
    if (category != null) {
      flashcards = await MockFlashcardProvider.getFlashcardsByCategory(category);
    } else {
      final allSets = await MockFlashcardProvider.getAllFlashcardSets();
      flashcards = allSets.expand((set) => set.flashcards).toList();
    }
    
    if (difficulty != null) {
      flashcards = flashcards.where((card) => card.difficulty == difficulty).toList();
    }
    
    if (limit != null) {
      flashcards = flashcards.take(limit).toList();
    }
    
    return flashcards;
  }
  
  Future<FlashcardSet?> getFlashcardSet(String setId) async {
    if (_useRemoteData) {
      // Implement remote data loading
      return null;
    } else {
      return MockFlashcardProvider.getFlashcardSet(setId);
    }
  }
  
  // Remove the old hardcoded mock data methods
  // List<Map<String, dynamic>> get mockFlashcards => [...]; // DELETE THIS
}
```

### Step 5: Create Data Generation Utilities

**Mock Data Generator for Testing:**
```dart
// lib/utils/mock_data_generator.dart
class MockDataGenerator {
  static List<FlashcardData> generateTestFlashcards({
    required String category,
    required int count,
    Difficulty? difficulty,
  }) {
    final flashcards = <FlashcardData>[];
    final random = Random();
    
    for (int i = 0; i < count; i++) {
      flashcards.add(FlashcardData(
        id: '${category}_test_${i + 1}',
        question: 'Test question ${i + 1} for $category',
        answer: 'Test answer ${i + 1}',
        category: category,
        subcategory: 'test_subcategory',
        difficulty: difficulty ?? Difficulty.values[random.nextInt(Difficulty.values.length)],
        tags: ['test', category, 'generated'],
        metadata: {
          'isGenerated': true,
          'generatedAt': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
        source: 'test_generator',
        version: 1,
      ));
    }
    
    return flashcards;
  }
  
  static FlashcardSet generateTestSet({
    required String id,
    required String category,
    required int cardCount,
  }) {
    return FlashcardSet(
      id: id,
      name: 'Test Set: $category',
      description: 'Generated test data for $category',
      category: category,
      flashcards: generateTestFlashcards(
        category: category,
        count: cardCount,
      ),
      metadata: FlashcardSetMetadata(
        targetDifficulty: Difficulty.intermediate,
        estimatedStudyTime: Duration(minutes: cardCount * 2),
        prerequisites: [],
        learningObjectives: ['Test objective 1', 'Test objective 2'],
        author: 'Test Generator',
        lastUpdated: DateTime.now(),
        version: 1,
      ),
    );
  }
}
```

## Testing Strategy

**Unit Tests:**
```dart
// test/providers/mock_flashcard_provider_test.dart
group('MockFlashcardProvider Tests', () {
  testWidgets('loads flashcard sets from JSON files', (tester) async {
    final set = await MockFlashcardProvider.getFlashcardSet('data_science_basic');
    
    expect(set, isNotNull);
    expect(set!.id, 'data_science_basic');
    expect(set.flashcards, isNotEmpty);
    expect(set.flashcards.first.question, isNotEmpty);
  });
  
  testWidgets('filters flashcards by category', (tester) async {
    final flashcards = await MockFlashcardProvider.getFlashcardsByCategory('data_science');
    
    expect(flashcards, isNotEmpty);
    expect(flashcards.every((card) => card.category == 'data_science'), isTrue);
  });
  
  testWidgets('filters flashcards by difficulty', (tester) async {
    final flashcards = await MockFlashcardProvider.getFlashcardsByDifficulty(
      Difficulty.intermediate,
    );
    
    expect(flashcards, isNotEmpty);
    expect(flashcards.every((card) => card.difficulty == Difficulty.intermediate), isTrue);
  });
});
```

## Performance Considerations

**Loading Optimization:**
- Lazy load flashcard sets only when needed
- Cache loaded sets in memory to avoid repeated JSON parsing
- Implement background preloading for popular categories
- Use asset bundling to optimize JSON file access

**Memory Management:**
- Clear cache when memory pressure is detected
- Implement LRU cache for flashcard sets
- Load only metadata initially, cards on demand
- Use pagination for large flashcard sets

## Success Criteria

- [ ] All hardcoded flashcard data moved to JSON configuration files
- [ ] Multiple flashcard sets supported with proper categorization
- [ ] Versioned data system allows easy updates and rollbacks
- [ ] Mock data provider supports filtering by category and difficulty
- [ ] Performance maintained with caching and lazy loading
- [ ] Data generation utilities support testing requirements
- [ ] JSON data structure is well-documented and maintainable

## Next Steps

After completing Task 5.4, proceed to:
1. **Task 5.5**: Create comprehensive testing utilities using the new data systems
2. **Integration**: Combine all Task 5 components into a cohesive data management system
3. **Documentation**: Update API documentation to reflect new data provider patterns
