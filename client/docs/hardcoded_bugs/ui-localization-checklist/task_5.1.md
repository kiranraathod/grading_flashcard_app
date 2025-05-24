# Task 5.1: Data Provider Abstraction

## Objective

Create a comprehensive data provider abstraction layer to replace hardcoded mock data and default content with dynamic, maintainable data sources that can be easily configured for different environments and use cases.

## Implementation Approach

### Current State Analysis

**Hardcoded Data Issues:**
- Static mock data scattered throughout UI components
- Default categories with hardcoded counts in `home_screen.dart`
- Mock flashcards embedded in service files
- Progress values hardcoded in widget state
- No separation between data and presentation logic

**Files Requiring Data Provider Integration:**
```
lib/
├── screens/home_screen.dart (categories, progress data)
├── services/flashcard_service.dart (mock flashcards)
├── screens/create_interview_question_screen.dart (example templates)
├── widgets/progress_indicators.dart (default values)
└── utils/mock_data.dart (to be created)
```

### Data Provider Architecture

**Core Interface Design:**
```dart
abstract class DataProvider {
  Future<List<CategoryData>> getCategories();
  Future<List<FlashcardData>> getMockFlashcards(String category);
  Future<ProgressData> getUserProgress();
  Future<List<ExampleTemplate>> getExampleTemplates();
  Future<void> updateData(String key, dynamic value);
}
```

**Implementation Strategy:**
1. **MockDataProvider**: For development and testing with predictable data
2. **RemoteDataProvider**: For production with API-backed dynamic content
3. **HybridDataProvider**: Combines local and remote sources with fallbacks
4. **ConfigurableProvider**: Loads from configuration files or environment variables

### Data Models

**Category Data Model:**
```dart
class CategoryData {
  final String id;
  final String title;
  final String description;
  final int questionCount;
  final String iconPath;
  final Color? themeColor;
  final DateTime lastUpdated;
  
  CategoryData({
    required this.id,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.iconPath,
    this.themeColor,
    required this.lastUpdated,
  });
  
  factory CategoryData.fromJson(Map<String, dynamic> json) => /* implementation */;
  Map<String, dynamic> toJson() => /* implementation */;
}
```

**Progress Data Model:**
```dart
class ProgressData {
  final int weeklyGoal;
  final int daysCompleted;
  final int totalQuestionsAnswered;
  final double averageScore;
  final Map<String, int> categoryProgress;
  final DateTime lastActivity;
  
  ProgressData({
    required this.weeklyGoal,
    required this.daysCompleted,
    required this.totalQuestionsAnswered,
    required this.averageScore,
    required this.categoryProgress,
    required this.lastActivity,
  });
  
  factory ProgressData.fromJson(Map<String, dynamic> json) => /* implementation */;
  Map<String, dynamic> toJson() => /* implementation */;
}
```

## Implementation Steps

### Step 1: Create Data Provider Infrastructure

**Create Base Data Provider Interface:**
```dart
// lib/providers/data_provider.dart
abstract class DataProvider {
  Future<List<CategoryData>> getCategories();
  Future<List<FlashcardData>> getMockFlashcards(String category);
  Future<ProgressData> getUserProgress();
  Future<List<ExampleTemplate>> getExampleTemplates();
  Future<void> updateData(String key, dynamic value);
  Future<void> cacheData(String key, dynamic data, Duration ttl);
  Future<T?> getCachedData<T>(String key);
}

// Data provider factory
class DataProviderFactory {
  static DataProvider createProvider(Environment env) {
    switch (env) {
      case Environment.development:
        return MockDataProvider();
      case Environment.testing:
        return TestDataProvider();
      case Environment.production:
        return RemoteDataProvider();
      default:
        return HybridDataProvider();
    }
  }
}
```

**Create Mock Data Provider:**
```dart
// lib/providers/mock_data_provider.dart
class MockDataProvider implements DataProvider {
  final Map<String, dynamic> _cache = {};
  
  @override
  Future<List<CategoryData>> getCategories() async {
    // Load from JSON file or return hardcoded data
    return [
      CategoryData(
        id: 'data_science',
        title: 'Data Science Interview Questions',
        description: 'Comprehensive data science questions covering statistics, ML, and analytics',
        questionCount: await _getQuestionCount('data_science'),
        iconPath: 'assets/icons/data_science.svg',
        lastUpdated: DateTime.now(),
      ),
      // Additional categories...
    ];
  }
  
  @override
  Future<ProgressData> getUserProgress() async {
    return ProgressData(
      weeklyGoal: 7,
      daysCompleted: 5,
      totalQuestionsAnswered: 42,
      averageScore: 0.85,
      categoryProgress: {
        'data_science': 15,
        'web_development': 12,
        'system_design': 8,
      },
      lastActivity: DateTime.now().subtract(Duration(hours: 2)),
    );
  }
  
  Future<int> _getQuestionCount(String categoryId) async {
    // Dynamic count calculation
    final questions = await _loadQuestionsForCategory(categoryId);
    return questions.length;
  }
}
```

### Step 2: Create Remote Data Provider

**Remote Data Provider Implementation:**
```dart
// lib/providers/remote_data_provider.dart
class RemoteDataProvider implements DataProvider {
  final ApiService _apiService;
  final CacheManager _cacheManager;
  
  RemoteDataProvider({
    required ApiService apiService,
    required CacheManager cacheManager,
  }) : _apiService = apiService, _cacheManager = cacheManager;
  
  @override
  Future<List<CategoryData>> getCategories() async {
    try {
      // Try cache first
      final cachedData = await getCachedData<List<CategoryData>>('categories');
      if (cachedData != null) return cachedData;
      
      // Fetch from API
      final response = await _apiService.get('/api/categories');
      final categories = (response.data as List)
          .map((json) => CategoryData.fromJson(json))
          .toList();
      
      // Cache for future use
      await cacheData('categories', categories, Duration(hours: 6));
      
      return categories;
    } catch (e) {
      // Fallback to mock data
      return MockDataProvider().getCategories();
    }
  }
  
  @override
  Future<ProgressData> getUserProgress() async {
    try {
      final response = await _apiService.get('/api/user/progress');
      return ProgressData.fromJson(response.data);
    } catch (e) {
      // Fallback to mock data
      return MockDataProvider().getUserProgress();
    }
  }
}
```

### Step 3: Create Configuration System

**Data Provider Configuration:**
```dart
// lib/config/data_config.dart
class DataConfig {
  final String dataSource;
  final Duration cacheTimeout;
  final bool enableFallback;
  final Map<String, dynamic> providerConfig;
  
  DataConfig({
    required this.dataSource,
    required this.cacheTimeout,
    required this.enableFallback,
    required this.providerConfig,
  });
  
  factory DataConfig.fromEnvironment() {
    return DataConfig(
      dataSource: const String.fromEnvironment('DATA_SOURCE', defaultValue: 'mock'),
      cacheTimeout: const Duration(
        hours: int.fromEnvironment('CACHE_TIMEOUT_HOURS', defaultValue: 6),
      ),
      enableFallback: const bool.fromEnvironment('ENABLE_FALLBACK', defaultValue: true),
      providerConfig: {
        'apiBaseUrl': const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000'),
        'retryAttempts': const int.fromEnvironment('RETRY_ATTEMPTS', defaultValue: 3),
        'timeout': const int.fromEnvironment('API_TIMEOUT_MS', defaultValue: 5000),
      },
    );
  }
}
```

## Testing Strategy

**Unit Tests:**
```dart
// test/providers/data_provider_test.dart
group('DataProvider Tests', () {
  testWidgets('MockDataProvider returns expected categories', (tester) async {
    final provider = MockDataProvider();
    final categories = await provider.getCategories();
    
    expect(categories, isNotEmpty);
    expect(categories.first.title, isNotEmpty);
    expect(categories.first.questionCount, greaterThan(0));
  });
  
  testWidgets('RemoteDataProvider handles API failures gracefully', (tester) async {
    final mockApiService = MockApiService();
    when(mockApiService.get('/api/categories')).thenThrow(Exception('Network error'));
    
    final provider = RemoteDataProvider(
      apiService: mockApiService,
      cacheManager: MockCacheManager(),
    );
    
    // Should fallback to mock data
    final categories = await provider.getCategories();
    expect(categories, isNotEmpty);
  });
});
```

**Integration Tests:**
```dart
// test/integration/data_provider_integration_test.dart
group('Data Provider Integration', () {
  testWidgets('App loads with data provider integration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<DataProvider>(
          create: (_) => MockDataProvider(),
          child: HomeScreen(),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    
    // Verify categories are loaded from provider
    expect(find.text('Data Science Interview Questions'), findsOneWidget);
    expect(find.text('18'), findsWidgets); // Question count
  });
});
```

## Performance Considerations

**Caching Strategy:**
- Implement multi-level caching (memory, disk, network)
- Use TTL-based cache invalidation
- Implement cache warming for critical data
- Monitor cache hit rates and performance

**Loading Optimization:**
- Implement lazy loading for non-critical data
- Use pagination for large data sets
- Implement progressive loading with placeholders
- Optimize data serialization/deserialization

## Error Handling and Fallbacks

**Graceful Degradation:**
```dart
class HybridDataProvider implements DataProvider {
  final DataProvider primary;
  final DataProvider fallback;
  
  @override
  Future<List<CategoryData>> getCategories() async {
    try {
      return await primary.getCategories();
    } catch (e) {
      _logError('Primary data provider failed', e);
      return await fallback.getCategories();
    }
  }
}
```

## Success Criteria

- [ ] Data provider interface supports all required data types
- [ ] Mock data provider works for development and testing
- [ ] Remote data provider handles API integration with proper error handling
- [ ] Caching system improves performance and reduces API calls
- [ ] Configuration system allows environment-specific data provider selection
- [ ] Comprehensive testing covers all provider implementations
- [ ] Performance metrics show no degradation in app loading times
- [ ] Error handling provides graceful fallbacks for all failure scenarios

## Next Steps

After completing Task 5.1, proceed to:
1. **Task 5.2**: Extract category definitions using the new data provider system
2. **Task 5.3**: Replace hardcoded progress values with dynamic data
3. **Task 5.4**: Update mock flashcards to use the provider system
4. **Task 5.5**: Create testing utilities leveraging the data provider infrastructure
