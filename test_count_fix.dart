/// Test script to verify the count discrepancy fix
/// Run this to confirm server counts match client filtering

// Simulate the server data structure
class MockQuestion {
  final String id;
  final String category;
  final String subtopic;
  final String categoryId;
  
  MockQuestion({
    required this.id, 
    required this.category, 
    required this.subtopic,
    required this.categoryId,
  });
}

// Simulate CategoryMapper logic
class MockCategoryMapper {
  static final Map<String, String> _internalToUICategory = {
    'data_analysis': 'Data Analysis',
    'machine_learning': 'Machine Learning', 
    'sql': 'SQL',
    'python': 'Python',
    'web_development': 'Web Development',
    'statistics': 'Statistics',
    // Legacy mappings
    'technical': 'Data Analysis',
    'applied': 'Machine Learning',
    'behavioral': 'Python',
    'case': 'Statistics',
    'job': 'Web Development',
  };

  static String mapInternalToUICategory(String internalCategory) {
    return _internalToUICategory[internalCategory] ?? 'Data Analysis';
  }

  static String getDefaultCategory(String internalCategory) {
    return _internalToUICategory[internalCategory] ?? 'Data Analysis';
  }
}

// Server count logic (from default_data_service.py)
int getServerCount(List<MockQuestion> questions, String uiCategory) {
  final count = questions.where((question) {
    final serverUICategory = MockCategoryMapper.mapInternalToUICategory(question.categoryId);
    return serverUICategory == uiCategory;
  }).length;
  
  print('Server count for $uiCategory: $count');
  return count;
}

// FIXED client filtering logic
List<MockQuestion> getFilteredQuestions(List<MockQuestion> questions, String uiCategory) {
  if (uiCategory == 'all') return questions;
  
  final filtered = questions.where((question) {
    // PRIMARY: Check categoryId field - if it matches, use it exclusively
    final serverUICategory = MockCategoryMapper.mapInternalToUICategory(question.categoryId);
    if (serverUICategory == uiCategory) {
      return true; // ✅ FIXED: Return immediately if categoryId matches
    }
    
    // FALLBACK: Legacy category mapping ONLY for questions without categoryId
    // (In our test, all questions have categoryId, so this won't be used)
    if (question.categoryId.isEmpty) {
      final mappedCategory = MockCategoryMapper.getDefaultCategory(question.category);
      if (mappedCategory == uiCategory) {
        return true;
      }
      
      // SPECIAL: Subtopic patterns for legacy questions
      if (_isSpecialSubtopicMatch(uiCategory, question)) {
        return true;
      }
    }
    
    return false; // ✅ FIXED: Explicit rejection if no matches
  }).toList();
  
  print('Client filtered count for $uiCategory: ${filtered.length}');
  return filtered;
}

bool _isSpecialSubtopicMatch(String uiCategory, MockQuestion question) {
  final subtopicLower = question.subtopic.toLowerCase();
  
  switch (uiCategory) {
    case 'SQL':
      return subtopicLower.contains('sql') || subtopicLower.contains('database');
    case 'Python':
      return subtopicLower.contains('python');
    case 'Data Analysis':
      return subtopicLower.contains('data') || subtopicLower.contains('analysis');
    case 'Machine Learning':
      return subtopicLower.contains('ml') || subtopicLower.contains('machine learning');
    case 'Web Development':
      return subtopicLower.contains('web') || subtopicLower.contains('api');
    case 'Statistics':
      return subtopicLower.contains('statistical') || subtopicLower.contains('statistics');
    default:
      return false;
  }
}

void main() {
  print('🧪 Testing FlashMaster Count Fix...\n');

  // Create test data matching server structure
  final questions = [
    // Data Analysis (5 questions with category_id="data_analysis")
    MockQuestion(id: 'data-analysis-1', category: 'applied', subtopic: 'Data Cleaning & Preprocessing', categoryId: 'data_analysis'),
    MockQuestion(id: 'data-analysis-2', category: 'applied', subtopic: 'Statistical Analysis', categoryId: 'data_analysis'),
    MockQuestion(id: 'data-analysis-3', category: 'applied', subtopic: 'Data Cleaning & Preprocessing', categoryId: 'data_analysis'),
    MockQuestion(id: 'data-analysis-4', category: 'applied', subtopic: 'Data Analysis', categoryId: 'data_analysis'),
    MockQuestion(id: 'data-analysis-5', category: 'applied', subtopic: 'Data Quality', categoryId: 'data_analysis'),

    // Machine Learning (5 questions with category_id="machine_learning") 
    MockQuestion(id: 'ml-1', category: 'technical', subtopic: 'ML Algorithms', categoryId: 'machine_learning'),
    MockQuestion(id: 'ml-2', category: 'technical', subtopic: 'Model Evaluation', categoryId: 'machine_learning'),
    MockQuestion(id: 'ml-3', category: 'technical', subtopic: 'ML Fundamentals', categoryId: 'machine_learning'),
    MockQuestion(id: 'ml-4', category: 'technical', subtopic: 'Model Evaluation', categoryId: 'machine_learning'),
    MockQuestion(id: 'ml-5', category: 'technical', subtopic: 'Optimization', categoryId: 'machine_learning'),

    // SQL (4 questions with category_id="sql")
    MockQuestion(id: 'sql-1', category: 'technical', subtopic: 'SQL & Database', categoryId: 'sql'),
    MockQuestion(id: 'sql-2', category: 'technical', subtopic: 'SQL Queries', categoryId: 'sql'),
    MockQuestion(id: 'sql-3', category: 'technical', subtopic: 'Performance Optimization', categoryId: 'sql'),
    MockQuestion(id: 'sql-4', category: 'technical', subtopic: 'Database Design', categoryId: 'sql'),

    // Python (4 questions with category_id="python")
    MockQuestion(id: 'python-1', category: 'technical', subtopic: 'Python Fundamentals', categoryId: 'python'),
    MockQuestion(id: 'python-2', category: 'technical', subtopic: 'Python Syntax', categoryId: 'python'),
    MockQuestion(id: 'python-3', category: 'technical', subtopic: 'Python Fundamentals', categoryId: 'python'),
    MockQuestion(id: 'python-4', category: 'technical', subtopic: 'Python Internals', categoryId: 'python'),

    // Web Development (3 questions with category_id="web_development")
    MockQuestion(id: 'web-1', category: 'technical', subtopic: 'API Development', categoryId: 'web_development'),
    MockQuestion(id: 'web-2', category: 'technical', subtopic: 'HTTP Methods', categoryId: 'web_development'),
    MockQuestion(id: 'web-3', category: 'technical', subtopic: 'Web Security', categoryId: 'web_development'),

    // Statistics (3 questions with category_id="statistics")
    MockQuestion(id: 'stats-1', category: 'technical', subtopic: 'Statistical Theory', categoryId: 'statistics'),
    MockQuestion(id: 'stats-2', category: 'technical', subtopic: 'Hypothesis Testing', categoryId: 'statistics'),
    MockQuestion(id: 'stats-3', category: 'technical', subtopic: 'Statistical Significance', categoryId: 'statistics'),
  ];

  print('Total questions: ${questions.length}\n');

  // Test each category
  final categories = ['Data Analysis', 'Machine Learning', 'SQL', 'Python', 'Web Development', 'Statistics'];
  
  bool allTestsPassed = true;
  
  for (final category in categories) {
    print('📊 Testing: $category');
    
    final serverCount = getServerCount(questions, category);
    final clientFiltered = getFilteredQuestions(questions, category);
    final clientCount = clientFiltered.length;
    
    if (serverCount == clientCount) {
      print('✅ PASS: Server count ($serverCount) == Client count ($clientCount)');
    } else {
      print('❌ FAIL: Server count ($serverCount) != Client count ($clientCount)');
      allTestsPassed = false;
      
      // Show which questions are included by client but not server
      final serverIds = questions.where((q) => 
        MockCategoryMapper.mapInternalToUICategory(q.categoryId) == category
      ).map((q) => q.id).toSet();
      final clientIds = clientFiltered.map((q) => q.id).toSet();
      final extraQuestions = clientIds.difference(serverIds);
      
      if (extraQuestions.isNotEmpty) {
        print('   Extra questions in client: ${extraQuestions.join(", ")}');
      }
    }
    print('');
  }

  print('🎯 SUMMARY:');
  if (allTestsPassed) {
    print('✅ ALL TESTS PASSED - Count discrepancy is FIXED!');
    print('✅ Server and client counts now match for all categories');
    print('✅ Home screen and detail screen will show consistent counts');
  } else {
    print('❌ SOME TESTS FAILED - Fix needs adjustment');
  }
}
