# Task 5.2: Extract Category Definitions

## Objective

Move predefined categories from hardcoded lists to the data provider system, enabling dynamic category management, accurate question counts, and configuration-based category definitions.

## Current State Analysis

**Hardcoded Category Issues in `home_screen.dart`:**
```dart
// Lines 573-578: Static category definitions
List<Map<String, dynamic>> categories = [
  {'title': 'Data Science Interview Questions', 'count': 18},
  {'title': 'Web Development', 'count': 15},
  {'title': 'System Design', 'count': 12},
  {'title': 'Other Interview Categories', 'count': 25},
];
```

**Problems with Current Implementation:**
- Question counts are hardcoded and don't reflect actual data
- Categories cannot be added/removed without code changes
- No support for category metadata (descriptions, icons, themes)
- No internationalization support for category titles
- Limited customization options for different user types

## Implementation Approach

### Step 1: Create Category Data Models

**Enhanced Category Model:**
```dart
// lib/models/category_data.dart
class CategoryData {
  final String id;
  final String titleKey; // Localization key
  final String descriptionKey; // Localization key
  final String iconPath;
  final Color? primaryColor;
  final Color? accentColor;
  final int displayOrder;
  final bool isVisible;
  final CategoryType type;
  final Map<String, dynamic> metadata;
  
  // Dynamic properties
  late final Future<int> questionCount;
  late final Future<double> userProgress;
  late final Future<DateTime?> lastActivity;
  
  CategoryData({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.iconPath,
    this.primaryColor,
    this.accentColor,
    required this.displayOrder,
    required this.isVisible,
    required this.type,
    required this.metadata,
  }) {
    // Initialize dynamic data
    questionCount = _calculateQuestionCount();
    userProgress = _calculateUserProgress();
    lastActivity = _getLastActivity();
  }
  
  Future<int> _calculateQuestionCount() async {
    // Dynamic calculation based on actual data
    return InterviewQuestionService().getQuestionCount(id);
  }
  
  Future<double> _calculateUserProgress() async {
    return ProgressService().getCategoryProgress(id);
  }
  
  Future<DateTime?> _getLastActivity() async {
    return ActivityService().getLastCategoryActivity(id);
  }
}

enum CategoryType {
  interview,
  flashcard,
  study,
  practice,
  custom
}
```

### Step 2: Update Data Provider with Category Management

**Enhanced DataProvider Interface:**
```dart
// lib/providers/data_provider.dart
abstract class DataProvider {
  // Category management
  Future<List<CategoryData>> getCategories({CategoryType? type});
  Future<CategoryData> getCategory(String id);
  Future<void> updateCategory(CategoryData category);
  Future<void> addCategory(CategoryData category);
  Future<void> removeCategory(String id);
  Future<void> reorderCategories(List<String> orderedIds);
  
  // Category metadata
  Future<Map<String, int>> getCategoryQuestionCounts();
  Future<Map<String, double>> getCategoryProgressMap();
  Future<List<CategoryData>> getFeaturedCategories();
  Future<List<CategoryData>> getRecentCategories();
}
```

**Mock Category Provider Implementation:**
```dart
// lib/providers/category_provider.dart
class MockCategoryProvider extends DataProvider {
  final List<CategoryData> _categories = [
    CategoryData(
      id: 'data_science',
      titleKey: 'categoryDataScience',
      descriptionKey: 'categoryDataScienceDesc',
      iconPath: 'assets/icons/data_science.svg',
      primaryColor: AppColors.primary,
      displayOrder: 1,
      isVisible: true,
      type: CategoryType.interview,
      metadata: {
        'difficulty': 'intermediate',
        'estimatedTime': '30-45 minutes',
        'topics': ['statistics', 'machine_learning', 'analytics'],
      },
    ),
    CategoryData(
      id: 'web_development',
      titleKey: 'categoryWebDev',
      descriptionKey: 'categoryWebDevDesc',
      iconPath: 'assets/icons/web_dev.svg',
      primaryColor: Colors.blue,
      displayOrder: 2,
      isVisible: true,
      type: CategoryType.interview,
      metadata: {
        'difficulty': 'beginner',
        'estimatedTime': '20-30 minutes',
        'topics': ['html', 'css', 'javascript', 'frameworks'],
      },
    ),
    // Additional categories...
  ];
  
  @override
  Future<List<CategoryData>> getCategories({CategoryType? type}) async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate loading
    
    var filteredCategories = _categories.where((cat) => cat.isVisible);
    
    if (type != null) {
      filteredCategories = filteredCategories.where((cat) => cat.type == type);
    }
    
    return filteredCategories.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }
  
  @override
  Future<Map<String, int>> getCategoryQuestionCounts() async {
    final counts = <String, int>{};
    for (final category in _categories) {
      counts[category.id] = await category.questionCount;
    }
    return counts;
  }
}
```

### Step 3: Update Home Screen Integration

**Home Screen Category Widget:**
```dart
// In home_screen.dart - Replace hardcoded categories
class CategoryGridSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return FutureBuilder<List<CategoryData>>(
          future: dataProvider.getCategories(type: CategoryType.interview),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingGrid();
            }
            
            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error);
            }
            
            final categories = snapshot.data ?? [];
            return _buildCategoryGrid(categories);
          },
        );
      },
    );
  }
  
  Widget _buildCategoryGrid(List<CategoryData> categories) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: DS.getResponsiveColumnCount(context),
        childAspectRatio: 0.85,
        crossAxisSpacing: DS.spacingL,
        mainAxisSpacing: DS.spacingL,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return CategoryCard(category: categories[index]);
      },
    );
  }
  
  Widget _buildLoadingGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: DS.getResponsiveColumnCount(context),
        childAspectRatio: 0.85,
        crossAxisSpacing: DS.spacingL,
        mainAxisSpacing: DS.spacingL,
      ),
      itemCount: 4, // Placeholder count
      itemBuilder: (context, index) => CategoryCardSkeleton(),
    );
  }
}
```

**Category Card Component:**
```dart
// lib/widgets/category_card.dart
class CategoryCard extends StatelessWidget {
  final CategoryData category;
  
  const CategoryCard({Key? key, required this.category}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: category.questionCount,
      builder: (context, snapshot) {
        final questionCount = snapshot.data ?? 0;
        
        return GestureDetector(
          onTap: () => _onCategoryTap(context),
          child: Container(
            decoration: ThemedComponents.cardDecorationWithGradient(
              context,
              isInterview: category.type == CategoryType.interview,
            ),
            child: Padding(
              padding: context.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  SvgPicture.asset(
                    category.iconPath,
                    width: DS.icon.large,
                    height: DS.icon.large,
                    colorFilter: ColorFilter.mode(
                      category.primaryColor ?? context.primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  
                  SizedBox(height: DS.spacingM),
                  
                  // Category title (localized)
                  Text(
                    AppLocalizations.of(context).getString(category.titleKey),
                    style: context.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(context.isDarkMode),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: DS.spacingS),
                  
                  // Question count
                  Text(
                    AppLocalizations.of(context).questionCount(questionCount),
                    style: context.bodyMedium?.copyWith(
                      color: AppColors.getTextSecondary(context.isDarkMode),
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Progress indicator if user has activity
                  FutureBuilder<double>(
                    future: category.userProgress,
                    builder: (context, progressSnapshot) {
                      final progress = progressSnapshot.data ?? 0.0;
                      if (progress > 0) {
                        return LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            category.primaryColor ?? context.primaryColor,
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _onCategoryTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewQuestionsScreen(
          categoryId: category.id,
          categoryTitle: AppLocalizations.of(context).getString(category.titleKey),
        ),
      ),
    );
  }
}
```

### Step 4: Configuration-Based Categories

**Category Configuration System:**
```dart
// lib/config/category_config.dart
class CategoryConfig {
  static List<CategoryData> getDefaultCategories() {
    return [
      CategoryData(
        id: 'data_science',
        titleKey: 'categoryDataScience',
        descriptionKey: 'categoryDataScienceDesc',
        iconPath: 'assets/icons/data_science.svg',
        primaryColor: AppColors.primary,
        displayOrder: 1,
        isVisible: true,
        type: CategoryType.interview,
        metadata: {
          'difficulty': 'intermediate',
          'requiredLevel': 'junior',
          'topics': ['statistics', 'machine_learning', 'python', 'sql'],
          'industryRelevance': ['tech', 'finance', 'healthcare'],
        },
      ),
      // Additional categories...
    ];
  }
  
  static CategoryData createCustomCategory({
    required String title,
    required String description,
    String? iconPath,
    Color? primaryColor,
  }) {
    return CategoryData(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      titleKey: title, // For custom categories, use direct title
      descriptionKey: description,
      iconPath: iconPath ?? 'assets/icons/custom.svg',
      primaryColor: primaryColor,
      displayOrder: 999,
      isVisible: true,
      type: CategoryType.custom,
      metadata: {
        'isCustom': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

### Step 5: Localization Integration

**Add Category Strings to ARB:**
```json
// lib/l10n/app_en.arb
{
  "categoryDataScience": "Data Science Interview Questions",
  "@categoryDataScience": {
    "description": "Title for data science interview category"
  },
  "categoryDataScienceDesc": "Comprehensive questions covering statistics, machine learning, and data analytics",
  "@categoryDataScienceDesc": {
    "description": "Description for data science interview category"
  },
  "categoryWebDev": "Web Development",
  "@categoryWebDev": {
    "description": "Title for web development category"
  },
  "categoryWebDevDesc": "Frontend and backend development questions covering HTML, CSS, JavaScript, and frameworks",
  "@categoryWebDevDesc": {
    "description": "Description for web development category"
  },
  "questionCount": "{count, plural, =0{No questions} =1{1 question} other{{count} questions}}",
  "@questionCount": {
    "description": "Question count with pluralization",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

## Testing Strategy

**Unit Tests:**
```dart
// test/providers/category_provider_test.dart
group('Category Provider Tests', () {
  testWidgets('getCategories returns visible categories only', (tester) async {
    final provider = MockCategoryProvider();
    final categories = await provider.getCategories();
    
    expect(categories.every((cat) => cat.isVisible), isTrue);
    expect(categories, isNotEmpty);
  });
  
  testWidgets('categories are sorted by display order', (tester) async {
    final provider = MockCategoryProvider();
    final categories = await provider.getCategories();
    
    for (int i = 1; i < categories.length; i++) {
      expect(
        categories[i-1].displayOrder <= categories[i].displayOrder,
        isTrue,
      );
    }
  });
  
  testWidgets('question counts are calculated dynamically', (tester) async {
    final provider = MockCategoryProvider();
    final counts = await provider.getCategoryQuestionCounts();
    
    expect(counts, isNotEmpty);
    expect(counts.values.every((count) => count >= 0), isTrue);
  });
});
```

**Widget Tests:**
```dart
// test/widgets/category_card_test.dart
group('CategoryCard Widget Tests', () {
  testWidgets('displays category information correctly', (tester) async {
    final category = CategoryData(
      id: 'test',
      titleKey: 'testTitle',
      descriptionKey: 'testDesc',
      iconPath: 'assets/icons/test.svg',
      displayOrder: 1,
      isVisible: true,
      type: CategoryType.interview,
      metadata: {},
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(category: category),
        ),
      ),
    );
    
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing); // No progress initially
  });
});
```

## Performance Considerations

**Caching Strategy:**
- Cache category data for 6 hours to reduce API calls
- Implement memory caching for frequently accessed categories
- Use lazy loading for category metadata and counts
- Implement pagination for large category lists

**Loading Optimization:**
- Show skeleton loading states while data loads
- Implement progressive enhancement (basic info first, details later)
- Cache category icons and load them asynchronously
- Use background refresh to update stale data

## Success Criteria

- [ ] All hardcoded category definitions removed from UI components
- [ ] Category data loaded dynamically from data provider
- [ ] Question counts calculated accurately based on actual data
- [ ] Category management supports CRUD operations
- [ ] Localization system integrated for category titles and descriptions
- [ ] Performance maintained with caching and lazy loading
- [ ] Visual loading states provide good user experience
- [ ] Custom categories can be created and managed by users

## Next Steps

After completing Task 5.2, proceed to:
1. **Task 5.3**: Replace hardcoded progress values with dynamic calculation
2. **Task 5.4**: Update mock flashcards to use provider system
3. **Task 5.5**: Create comprehensive testing utilities
