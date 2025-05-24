# Task 5.5: Create Testing Data Utilities

## Objective

Implement comprehensive data generation utilities for automated testing, create predictable test data sets for consistent test results, and establish data validation utilities for quality assurance across the dynamic data system.

## Current State Analysis

**Testing Data Challenges:**
- Tests currently rely on hardcoded mock data that doesn't reflect dynamic system
- No standardized test data generation for different scenarios
- Inconsistent test data across different test files
- Limited data validation for quality assurance
- No performance testing data sets for load testing

**Testing Requirements:**
- Predictable data for unit tests
- Large data sets for performance testing
- Edge case data for robustness testing
- Realistic data for integration testing
- Data validation utilities for quality assurance

## Implementation Approach

### Step 1: Create Test Data Models

**Test Data Configuration:**
```dart
// lib/testing/test_data_config.dart
class TestDataConfig {
  final String scenario;
  final Map<String, dynamic> parameters;
  final int seed; // For reproducible random data
  
  TestDataConfig({
    required this.scenario,
    required this.parameters,
    required this.seed,
  });
  
  factory TestDataConfig.unit({
    String scenario = 'default',
    int seed = 12345,
  }) {
    return TestDataConfig(
      scenario: scenario,
      parameters: {
        'categoryCount': 5,
        'flashcardsPerCategory': 10,
        'userCount': 3,
        'activitiesPerUser': 20,
        'timeRange': 30, // days
      },
      seed: seed,
    );
  }
  
  factory TestDataConfig.integration({
    String scenario = 'realistic',
    int seed = 54321,
  }) {
    return TestDataConfig(
      scenario: scenario,
      parameters: {
        'categoryCount': 12,
        'flashcardsPerCategory': 50,
        'userCount': 10,
        'activitiesPerUser': 100,
        'timeRange': 90, // days
      },
      seed: seed,
    );
  }
  
  factory TestDataConfig.performance({
    String scenario = 'load_test',
    int seed = 98765,
  }) {
    return TestDataConfig(
      scenario: scenario,
      parameters: {
        'categoryCount': 50,
        'flashcardsPerCategory': 1000,
        'userCount': 1000,
        'activitiesPerUser': 10000,
        'timeRange': 365, // days
      },
      seed: seed,
    );
  }
  
  factory TestDataConfig.edgeCase({
    String scenario = 'edge_cases',
    int seed = 11111,
  }) {
    return TestDataConfig(
      scenario: scenario,
      parameters: {
        'categoryCount': 0, // Empty state
        'flashcardsPerCategory': 0,
        'userCount': 1,
        'activitiesPerUser': 0,
        'timeRange': 1,
        'includeCorruptData': true,
        'includeExtremeValues': true,
      },
      seed: seed,
    );
  }
}
```

### Step 2: Implement Data Generation Utilities

**Comprehensive Test Data Generator:**
```dart
// lib/testing/test_data_generator.dart
class TestDataGenerator {
  final Random _random;
  final TestDataConfig _config;
  
  TestDataGenerator(this._config) : _random = Random(_config.seed);
  
  // Generate complete test data set
  Future<TestDataSet> generateCompleteDataSet() async {
    final categories = generateCategories();
    final flashcards = generateFlashcardsForCategories(categories);
    final users = generateUsers();
    final activities = generateActivitiesForUsers(users, flashcards);
    final progress = generateProgressForUsers(users, activities);
    
    return TestDataSet(
      categories: categories,
      flashcards: flashcards,
      users: users,
      activities: activities,
      progress: progress,
      config: _config,
      generatedAt: DateTime.now(),
    );
  }
  
  // Generate categories with realistic data
  List<CategoryData> generateCategories() {
    final categoryCount = _config.parameters['categoryCount'] as int;
    final categories = <CategoryData>[];
    
    final categoryTemplates = [
      {'name': 'Data Science', 'icon': 'data_science', 'color': '0xFF1976D2'},
      {'name': 'Web Development', 'icon': 'web_dev', 'color': '0xFF388E3C'},
      {'name': 'System Design', 'icon': 'system_design', 'color': '0xFFF57C00'},
      {'name': 'Algorithms', 'icon': 'algorithms', 'color': '0xFF7B1FA2'},
      {'name': 'Databases', 'icon': 'database', 'color': '0xFFD32F2F'},
      {'name': 'Machine Learning', 'icon': 'ml', 'color': '0xFF303F9F'},
      {'name': 'DevOps', 'icon': 'devops', 'color': '0xFF455A64'},
      {'name': 'Mobile Development', 'icon': 'mobile', 'color': '0xFF00796B'},
      {'name': 'Security', 'icon': 'security', 'color': '0xFF5D4037'},
      {'name': 'Cloud Computing', 'icon': 'cloud', 'color': '0xFF1565C0'},
    ];
    
    for (int i = 0; i < categoryCount && i < categoryTemplates.length; i++) {
      final template = categoryTemplates[i];
      categories.add(CategoryData(
        id: 'test_category_${i + 1}',
        titleKey: 'category${template['name']!.replaceAll(' ', '')}',
        descriptionKey: 'category${template['name']!.replaceAll(' ', '')}Desc',
        iconPath: 'assets/icons/${template['icon']}.svg',
        primaryColor: Color(int.parse(template['color']!)),
        displayOrder: i + 1,
        isVisible: true,
        type: CategoryType.interview,
        metadata: {
          'isTestData': true,
          'difficulty': _random.nextBool() ? 'intermediate' : 'advanced',
          'estimatedTime': '${20 + _random.nextInt(40)} minutes',
        },
      ));
    }
    
    return categories;
  }
  
  // Generate flashcards for categories
  Map<String, List<FlashcardData>> generateFlashcardsForCategories(
    List<CategoryData> categories,
  ) {
    final flashcardsPerCategory = _config.parameters['flashcardsPerCategory'] as int;
    final flashcardsByCategory = <String, List<FlashcardData>>{};
    
    for (final category in categories) {
      final flashcards = <FlashcardData>[];
      
      for (int i = 0; i < flashcardsPerCategory; i++) {
        flashcards.add(FlashcardData(
          id: '${category.id}_flashcard_${i + 1}',
          question: _generateRealisticQuestion(category.titleKey, i + 1),
          answer: _generateRealisticAnswer(category.titleKey, i + 1),
          category: category.id,
          subcategory: _generateSubcategory(category.titleKey),
          difficulty: _generateDifficulty(),
          tags: _generateTags(category.titleKey),
          metadata: {
            'isTestData': true,
            'estimatedAnswerTime': '${1 + _random.nextInt(5)} minutes',
            'complexity': _random.nextInt(10) + 1,
          },
          createdAt: _generateRealisticDate(),
          source: 'test_generator',
          version: 1,
        ));
      }
      
      flashcardsByCategory[category.id] = flashcards;
    }
    
    return flashcardsByCategory;
  }
  
  // Generate test users
  List<TestUser> generateUsers() {
    final userCount = _config.parameters['userCount'] as int;
    final users = <TestUser>[];
    
    final firstNames = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry'];
    final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
    
    for (int i = 0; i < userCount; i++) {
      users.add(TestUser(
        id: 'test_user_${i + 1}',
        name: '${firstNames[i % firstNames.length]} ${lastNames[i % lastNames.length]}',
        email: 'test.user.${i + 1}@example.com',
        createdAt: _generateRealisticDate(),
        preferences: UserPreferences(
          weeklyGoal: 3 + _random.nextInt(5),
          dailyQuestionGoal: 5 + _random.nextInt(15),
          preferredDifficulty: _generateDifficulty(),
          favoriteCategories: _generateFavoriteCategories(),
        ),
      ));
    }
    
    return users;
  }
  
  // Generate activities for users
  Map<String, List<ActivityRecord>> generateActivitiesForUsers(
    List<TestUser> users,
    Map<String, List<FlashcardData>> flashcards,
  ) {
    final activitiesPerUser = _config.parameters['activitiesPerUser'] as int;
    final timeRange = _config.parameters['timeRange'] as int;
    final activitiesByUser = <String, List<ActivityRecord>>{};
    
    for (final user in users) {
      final activities = <ActivityRecord>[];
      
      for (int i = 0; i < activitiesPerUser; i++) {
        final category = flashcards.keys.elementAt(_random.nextInt(flashcards.keys.length));
        final categoryFlashcards = flashcards[category]!;
        final flashcard = categoryFlashcards[_random.nextInt(categoryFlashcards.length)];
        
        activities.add(ActivityRecord(
          id: '${user.id}_activity_${i + 1}',
          userId: user.id,
          flashcardId: flashcard.id,
          categoryId: category,
          date: DateTime.now().subtract(Duration(days: _random.nextInt(timeRange))),
          questionsAnswered: 1 + _random.nextInt(5),
          correctAnswers: _random.nextInt(5),
          score: _generateRealisticScore(),
          duration: Duration(minutes: 1 + _random.nextInt(10)),
          metadata: {
            'isTestData': true,
            'sessionType': _random.nextBool() ? 'study' : 'practice',
            'deviceType': _random.nextBool() ? 'mobile' : 'desktop',
          },
        ));
      }
      
      // Sort activities by date (most recent first)
      activities.sort((a, b) => b.date.compareTo(a.date));
      activitiesByUser[user.id] = activities;
    }
    
    return activitiesByUser;
  }
  
  // Generate realistic progress data
  Map<String, ProgressData> generateProgressForUsers(
    List<TestUser> users,
    Map<String, List<ActivityRecord>> activities,
  ) {
    final progressByUser = <String, ProgressData>{};
    
    for (final user in users) {
      final userActivities = activities[user.id] ?? [];
      progressByUser[user.id] = _calculateProgressFromActivities(user, userActivities);
    }
    
    return progressByUser;
  }
  
  // Helper methods for realistic data generation
  String _generateRealisticQuestion(String category, int index) {
    final questionTemplates = {
      'Data Science': [
        'What is the difference between supervised and unsupervised learning?',
        'Explain the concept of overfitting in machine learning.',
        'How do you handle missing data in a dataset?',
        'What is the purpose of cross-validation?',
      ],
      'Web Development': [
        'What is the difference between GET and POST requests?',
        'Explain the concept of responsive design.',
        'What are the benefits of using a CSS preprocessor?',
        'How does event bubbling work in JavaScript?',
      ],
    };
    
    final templates = questionTemplates[category] ?? ['Generic test question'];
    final template = templates[index % templates.length];
    
    return '$template (Test Question #$index)';
  }
  
  String _generateRealisticAnswer(String category, int index) {
    return 'This is a comprehensive answer to test question #$index in the $category category. '
           'The answer covers the key concepts and provides practical examples. '
           'This test data is generated to simulate realistic interview responses.';
  }
  
  Difficulty _generateDifficulty() {
    final difficulties = Difficulty.values;
    return difficulties[_random.nextInt(difficulties.length)];
  }
  
  double _generateRealisticScore() {
    // Generate scores with realistic distribution (most scores between 0.6-0.9)
    final base = 0.6 + (_random.nextDouble() * 0.3);
    return double.parse(base.toStringAsFixed(2));
  }
  
  DateTime _generateRealisticDate() {
    final daysAgo = _random.nextInt(365);
    return DateTime.now().subtract(Duration(days: daysAgo));
  }
}

class TestDataSet {
  final List<CategoryData> categories;
  final Map<String, List<FlashcardData>> flashcards;
  final List<TestUser> users;
  final Map<String, List<ActivityRecord>> activities;
  final Map<String, ProgressData> progress;
  final TestDataConfig config;
  final DateTime generatedAt;
  
  TestDataSet({
    required this.categories,
    required this.flashcards,
    required this.users,
    required this.activities,
    required this.progress,
    required this.config,
    required this.generatedAt,
  });
  
  // Utility methods for test data access
  int get totalFlashcards => flashcards.values.fold(0, (sum, cards) => sum + cards.length);
  int get totalActivities => activities.values.fold(0, (sum, acts) => sum + acts.length);
  
  List<FlashcardData> getAllFlashcards() {
    return flashcards.values.expand((cards) => cards).toList();
  }
  
  List<ActivityRecord> getAllActivities() {
    return activities.values.expand((acts) => acts).toList();
  }
  
  // Export data for persistence
  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((c) => c.toJson()).toList(),
      'flashcards': flashcards.map((key, value) => 
        MapEntry(key, value.map((f) => f.toJson()).toList())),
      'users': users.map((u) => u.toJson()).toList(),
      'activities': activities.map((key, value) =>
        MapEntry(key, value.map((a) => a.toJson()).toList())),
      'progress': progress.map((key, value) =>
        MapEntry(key, value.toJson())),
      'config': _config.toJson(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
```

### Step 3: Create Data Validation Utilities

**Data Quality Validation:**
```dart
// lib/testing/data_validation.dart
class DataValidation {
  static ValidationResult validateFlashcardData(FlashcardData flashcard) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required field validation
    if (flashcard.id.isEmpty) errors.add('Flashcard ID cannot be empty');
    if (flashcard.question.isEmpty) errors.add('Question cannot be empty');
    if (flashcard.answer.isEmpty) errors.add('Answer cannot be empty');
    if (flashcard.category.isEmpty) errors.add('Category cannot be empty');
    
    // Content quality validation
    if (flashcard.question.length < 10) {
      warnings.add('Question seems too short (${flashcard.question.length} chars)');
    }
    if (flashcard.answer.length < 20) {
      warnings.add('Answer seems too short (${flashcard.answer.length} chars)');
    }
    if (flashcard.question.length > 500) {
      warnings.add('Question might be too long (${flashcard.question.length} chars)');
    }
    
    // Tag validation
    if (flashcard.tags.isEmpty) {
      warnings.add('No tags specified - consider adding relevant tags');
    }
    
    // Metadata validation
    if (flashcard.metadata.isEmpty) {
      warnings.add('No metadata provided - consider adding difficulty explanation');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      itemType: 'FlashcardData',
      itemId: flashcard.id,
    );
  }
  
  static ValidationResult validateCategoryData(CategoryData category) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required field validation
    if (category.id.isEmpty) errors.add('Category ID cannot be empty');
    if (category.titleKey.isEmpty) errors.add('Title key cannot be empty');
    if (category.iconPath.isEmpty) errors.add('Icon path cannot be empty');
    
    // Order validation
    if (category.displayOrder < 0) {
      errors.add('Display order must be non-negative');
    }
    
    // Icon path validation
    if (!category.iconPath.endsWith('.svg')) {
      warnings.add('Icon should be SVG format for scalability');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      itemType: 'CategoryData',
      itemId: category.id,
    );
  }
  
  static ValidationResult validateProgressData(ProgressData progress) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Range validation
    if (progress.weeklyProgress.daysCompleted < 0 || 
        progress.weeklyProgress.daysCompleted > 7) {
      errors.add('Days completed must be between 0 and 7');
    }
    
    if (progress.weeklyProgress.averageScore < 0.0 || 
        progress.weeklyProgress.averageScore > 1.0) {
      errors.add('Average score must be between 0.0 and 1.0');
    }
    
    // Consistency validation
    if (progress.weeklyProgress.questionsAnswered > 0 && 
        progress.weeklyProgress.averageScore == 0.0) {
      warnings.add('Questions answered but average score is 0 - check calculation');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      itemType: 'ProgressData',
      itemId: progress.userId,
    );
  }
  
  static DataSetValidationResult validateCompleteDataSet(TestDataSet dataSet) {
    final results = <ValidationResult>[];
    
    // Validate categories
    for (final category in dataSet.categories) {
      results.add(validateCategoryData(category));
    }
    
    // Validate flashcards
    for (final flashcards in dataSet.flashcards.values) {
      for (final flashcard in flashcards) {
        results.add(validateFlashcardData(flashcard));
      }
    }
    
    // Validate progress data
    for (final progress in dataSet.progress.values) {
      results.add(validateProgressData(progress));
    }
    
    // Cross-validation checks
    final crossValidationResults = _performCrossValidation(dataSet);
    results.addAll(crossValidationResults);
    
    return DataSetValidationResult(
      individualResults: results,
      totalItems: results.length,
      validItems: results.where((r) => r.isValid).length,
      errorCount: results.map((r) => r.errors.length).fold(0, (a, b) => a + b),
      warningCount: results.map((r) => r.warnings.length).fold(0, (a, b) => a + b),
      isDataSetValid: results.every((r) => r.isValid),
    );
  }
  
  static List<ValidationResult> _performCrossValidation(TestDataSet dataSet) {
    final results = <ValidationResult>[];
    
    // Check that all flashcard categories exist
    final categoryIds = dataSet.categories.map((c) => c.id).toSet();
    for (final flashcards in dataSet.flashcards.values) {
      for (final flashcard in flashcards) {
        if (!categoryIds.contains(flashcard.category)) {
          results.add(ValidationResult(
            isValid: false,
            errors: ['Flashcard references non-existent category: ${flashcard.category}'],
            warnings: [],
            itemType: 'CrossValidation',
            itemId: flashcard.id,
          ));
        }
      }
    }
    
    // Check activity references
    final flashcardIds = dataSet.getAllFlashcards().map((f) => f.id).toSet();
    for (final activities in dataSet.activities.values) {
      for (final activity in activities) {
        if (!flashcardIds.contains(activity.flashcardId)) {
          results.add(ValidationResult(
            isValid: false,
            errors: ['Activity references non-existent flashcard: ${activity.flashcardId}'],
            warnings: [],
            itemType: 'CrossValidation',
            itemId: activity.id,
          ));
        }
      }
    }
    
    return results;
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String itemType;
  final String itemId;
  
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.itemType,
    required this.itemId,
  });
}

class DataSetValidationResult {
  final List<ValidationResult> individualResults;
  final int totalItems;
  final int validItems;
  final int errorCount;
  final int warningCount;
  final bool isDataSetValid;
  
  DataSetValidationResult({
    required this.individualResults,
    required this.totalItems,
    required this.validItems,
    required this.errorCount,
    required this.warningCount,
    required this.isDataSetValid,
  });
  
  double get validationScore => validItems / totalItems;
  
  void printSummary() {
    print('Data Validation Summary:');
    print('Total items: $totalItems');
    print('Valid items: $validItems');
    print('Validation score: ${(validationScore * 100).toStringAsFixed(1)}%');
    print('Errors: $errorCount');
    print('Warnings: $warningCount');
    print('Overall status: ${isDataSetValid ? "VALID" : "INVALID"}');
  }
}
```

### Step 4: Create Performance Testing Utilities

**Performance Testing Data:**
```dart
// lib/testing/performance_test_utils.dart
class PerformanceTestUtils {
  static Future<PerformanceTestResult> runDataProviderPerformanceTest({
    required DataProvider dataProvider,
    required int iterations,
    required TestDataConfig config,
  }) async {
    final results = <PerformanceMetric>[];
    
    // Test category loading
    final categoryMetric = await _measureOperation(
      'Load Categories',
      iterations,
      () => dataProvider.getCategories(),
    );
    results.add(categoryMetric);
    
    // Test flashcard loading
    final flashcardMetric = await _measureOperation(
      'Load Flashcards',
      iterations,
      () => dataProvider.getMockFlashcards('data_science'),
    );
    results.add(flashcardMetric);
    
    // Test progress calculation
    final progressMetric = await _measureOperation(
      'Calculate Progress',
      iterations,
      () => dataProvider.getUserProgress(),
    );
    results.add(progressMetric);
    
    return PerformanceTestResult(
      metrics: results,
      config: config,
      testDuration: results.fold(Duration.zero, (sum, m) => sum + m.totalDuration),
      memoryUsage: await _measureMemoryUsage(),
    );
  }
  
  static Future<PerformanceMetric> _measureOperation<T>(
    String operationName,
    int iterations,
    Future<T> Function() operation,
  ) async {
    final durations = <Duration>[];
    final stopwatch = Stopwatch();
    
    // Warm up
    await operation();
    
    // Measure iterations
    for (int i = 0; i < iterations; i++) {
      stopwatch.reset();
      stopwatch.start();
      await operation();
      stopwatch.stop();
      durations.add(stopwatch.elapsed);
    }
    
    // Calculate statistics
    final totalDuration = durations.fold(Duration.zero, (sum, d) => sum + d);
    final averageDuration = Duration(
      microseconds: totalDuration.inMicroseconds ~/ durations.length,
    );
    
    durations.sort((a, b) => a.compareTo(b));
    final medianDuration = durations[durations.length ~/ 2];
    final minDuration = durations.first;
    final maxDuration = durations.last;
    
    return PerformanceMetric(
      operationName: operationName,
      iterations: iterations,
      totalDuration: totalDuration,
      averageDuration: averageDuration,
      medianDuration: medianDuration,
      minDuration: minDuration,
      maxDuration: maxDuration,
    );
  }
  
  static Future<MemoryUsage> _measureMemoryUsage() async {
    // Simplified memory measurement
    // In a real implementation, this would use more sophisticated tools
    return MemoryUsage(
      heapUsed: 50 * 1024 * 1024, // 50MB placeholder
      heapTotal: 100 * 1024 * 1024, // 100MB placeholder
      external: 10 * 1024 * 1024, // 10MB placeholder
    );
  }
}

class PerformanceTestResult {
  final List<PerformanceMetric> metrics;
  final TestDataConfig config;
  final Duration testDuration;
  final MemoryUsage memoryUsage;
  
  PerformanceTestResult({
    required this.metrics,
    required this.config,
    required this.testDuration,
    required this.memoryUsage,
  });
  
  void printReport() {
    print('Performance Test Report');
    print('=====================');
    print('Test Scenario: ${config.scenario}');
    print('Total Test Duration: ${testDuration.inMilliseconds}ms');
    print('Memory Usage: ${memoryUsage.heapUsed ~/ (1024 * 1024)}MB');
    print('');
    
    for (final metric in metrics) {
      print('Operation: ${metric.operationName}');
      print('  Iterations: ${metric.iterations}');
      print('  Average: ${metric.averageDuration.inMilliseconds}ms');
      print('  Median: ${metric.medianDuration.inMilliseconds}ms');
      print('  Min: ${metric.minDuration.inMilliseconds}ms');
      print('  Max: ${metric.maxDuration.inMilliseconds}ms');
      print('');
    }
  }
}

class PerformanceMetric {
  final String operationName;
  final int iterations;
  final Duration totalDuration;
  final Duration averageDuration;
  final Duration medianDuration;
  final Duration minDuration;
  final Duration maxDuration;
  
  PerformanceMetric({
    required this.operationName,
    required this.iterations,
    required this.totalDuration,
    required this.averageDuration,
    required this.medianDuration,
    required this.minDuration,
    required this.maxDuration,
  });
}

class MemoryUsage {
  final int heapUsed;
  final int heapTotal;
  final int external;
  
  MemoryUsage({
    required this.heapUsed,
    required this.heapTotal,
    required this.external,
  });
}
```

### Step 5: Integration with Test Framework

**Test Helper Integration:**
```dart
// test/helpers/test_data_helper.dart
class TestDataHelper {
  static TestDataSet? _cachedDataSet;
  static TestDataConfig? _currentConfig;
  
  static Future<TestDataSet> getTestDataSet(TestDataConfig config) async {
    // Return cached data if same config
    if (_cachedDataSet != null && _currentConfig == config) {
      return _cachedDataSet!;
    }
    
    // Generate new data set
    final generator = TestDataGenerator(config);
    _cachedDataSet = await generator.generateCompleteDataSet();
    _currentConfig = config;
    
    // Validate data quality
    final validation = DataValidation.validateCompleteDataSet(_cachedDataSet!);
    if (!validation.isDataSetValid) {
      throw Exception('Generated test data is invalid: ${validation.errorCount} errors');
    }
    
    return _cachedDataSet!;
  }
  
  static void clearCache() {
    _cachedDataSet = null;
    _currentConfig = null;
  }
  
  static Future<void> setUpTestDataProvider(TestDataConfig config) async {
    final dataSet = await getTestDataSet(config);
    MockDataProvider.setTestData(dataSet);
  }
  
  static void tearDownTestDataProvider() {
    MockDataProvider.clearTestData();
    clearCache();
  }
}

// Usage in tests
group('Data Provider Tests', () {
  setUpAll(() async {
    await TestDataHelper.setUpTestDataProvider(TestDataConfig.unit());
  });
  
  tearDownAll(() {
    TestDataHelper.tearDownTestDataProvider();
  });
  
  testWidgets('loads categories correctly', (tester) async {
    final provider = MockDataProvider();
    final categories = await provider.getCategories();
    
    expect(categories, isNotEmpty);
    expect(categories.length, 5); // From unit test config
  });
});
```

## Testing Strategy

**Unit Tests for Test Utilities:**
```dart
// test/testing/test_data_generator_test.dart
group('TestDataGenerator Tests', () {
  testWidgets('generates consistent data with same seed', (tester) async {
    final config1 = TestDataConfig.unit(seed: 12345);
    final config2 = TestDataConfig.unit(seed: 12345);
    
    final generator1 = TestDataGenerator(config1);
    final generator2 = TestDataGenerator(config2);
    
    final dataSet1 = await generator1.generateCompleteDataSet();
    final dataSet2 = await generator2.generateCompleteDataSet();
    
    // Should generate identical data
    expect(dataSet1.categories.length, dataSet2.categories.length);
    expect(dataSet1.totalFlashcards, dataSet2.totalFlashcards);
  });
  
  testWidgets('validates generated data quality', (tester) async {
    final config = TestDataConfig.unit();
    final generator = TestDataGenerator(config);
    final dataSet = await generator.generateCompleteDataSet();
    
    final validation = DataValidation.validateCompleteDataSet(dataSet);
    
    expect(validation.isDataSetValid, isTrue);
    expect(validation.errorCount, 0);
  });
});
```

## Performance Considerations

**Efficient Data Generation:**
- Use seeds for reproducible test data
- Cache generated data sets to avoid regeneration
- Lazy generation of large data sets
- Memory-efficient data structures

**Testing Performance:**
- Automated performance regression testing
- Memory usage monitoring during tests
- Benchmark comparison across versions
- Load testing with realistic data volumes

## Success Criteria

- [ ] Comprehensive test data generation for all testing scenarios
- [ ] Predictable, reproducible test data using seeds
- [ ] Data validation utilities ensure quality assurance
- [ ] Performance testing utilities measure system efficiency
- [ ] Edge case data generation for robustness testing
- [ ] Integration with existing test framework is seamless
- [ ] Memory usage is optimized for large data sets
- [ ] Test data cleanup prevents test interference

## Next Steps

After completing Task 5.5:
1. **Integration Testing**: Combine all Task 5 components for end-to-end testing
2. **Documentation**: Create comprehensive documentation for data management system
3. **Performance Benchmarking**: Establish baseline performance metrics
4. **Production Readiness**: Prepare system for production deployment with remote data providers
