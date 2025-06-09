import 'package:flutter/material.dart';
import 'default_data_service.dart';
import '../utils/category_theme.dart'; // Import new theme system
import 'simple_error_handler.dart';

class CategoryConfigService extends ChangeNotifier {
  static final CategoryConfigService _instance = CategoryConfigService._internal();
  factory CategoryConfigService() => _instance;
  CategoryConfigService._internal();

  final DefaultDataService _defaultDataService = DefaultDataService();
  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> get categories => _categories;

  Future<void> loadCategories() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        final serverCategories = await _defaultDataService.loadDefaultCategories();
        _categories = serverCategories.map((cat) => {
          'id': cat['id'],
          'name': cat['name'],
          // USE CLIENT-SIDE THEME SYSTEM INSTEAD OF HARDCODED VALUES:
          'color': CategoryTheme.getColor(cat['id']),
          'icon': CategoryTheme.getIcon(cat['id']),
          'subtopics': List<String>.from(cat['subtopics'] ?? []),
        }).toList();
        notifyListeners();
      },
      fallbackOperation: () async {
        _loadFallbackCategories();
      },
      operationName: 'load_categories',
    );
  }

  List<String> getSubtopics(String categoryId) {
    final category = _categories.firstWhere((c) => c['id'] == categoryId, orElse: () => {'subtopics': <String>[]});
    return List<String>.from(category['subtopics'] ?? []);
  }

  // Update helper method to use theme system
  Color getCategoryColor(BuildContext context, String categoryId) {
    return CategoryTheme.getContextAwareColor(context, categoryId);
  }

  IconData getCategoryIcon(String categoryId) {
    return CategoryTheme.getIcon(categoryId);
  }

  void _loadFallbackCategories() {
    _categories = [
      {
        'id': 'technical', 
        'name': 'Technical Knowledge', 
        'color': CategoryTheme.getColor('technical'),
        'icon': CategoryTheme.getIcon('technical'),
        'subtopics': ['Machine Learning', 'SQL', 'Python']
      },
      {
        'id': 'applied', 
        'name': 'Applied Skills', 
        'color': CategoryTheme.getColor('applied'),
        'icon': CategoryTheme.getIcon('applied'),
        'subtopics': ['Data Cleaning', 'Model Evaluation']
      },
      {
        'id': 'behavioral', 
        'name': 'Behavioral Questions', 
        'color': CategoryTheme.getColor('behavioral'),
        'icon': CategoryTheme.getIcon('behavioral'),
        'subtopics': ['Communication', 'Teamwork']
      },
      {
        'id': 'case', 
        'name': 'Case Studies', 
        'color': CategoryTheme.getColor('case'),
        'icon': CategoryTheme.getIcon('case'),
        'subtopics': ['Model Building', 'Business Problems']
      },
      {
        'id': 'job', 
        'name': 'Job-Specific', 
        'color': CategoryTheme.getColor('job'),
        'icon': CategoryTheme.getIcon('job'),
        'subtopics': ['Data Scientist', 'ML Engineer', 'Data Analyst']
      },
      // Add the 6+ UI categories that are expected
      {
        'id': 'data_analysis', 
        'name': 'Data Analysis', 
        'color': CategoryTheme.getColor('data_analysis'),
        'icon': CategoryTheme.getIcon('data_analysis'),
        'subtopics': ['Data Cleaning', 'Statistical Analysis']
      },
      {
        'id': 'web_development', 
        'name': 'Web Development', 
        'color': CategoryTheme.getColor('web_development'),
        'icon': CategoryTheme.getIcon('web_development'),
        'subtopics': ['Frontend', 'Backend', 'APIs']
      },
      {
        'id': 'machine_learning', 
        'name': 'Machine Learning', 
        'color': CategoryTheme.getColor('machine_learning'),
        'icon': CategoryTheme.getIcon('machine_learning'),
        'subtopics': ['Algorithms', 'Model Evaluation']
      },
      {
        'id': 'sql', 
        'name': 'SQL', 
        'color': CategoryTheme.getColor('sql'),
        'icon': CategoryTheme.getIcon('sql'),
        'subtopics': ['Queries', 'Database Design']
      },
      {
        'id': 'python', 
        'name': 'Python', 
        'color': CategoryTheme.getColor('python'),
        'icon': CategoryTheme.getIcon('python'),
        'subtopics': ['Fundamentals', 'Libraries']
      },
      {
        'id': 'statistics', 
        'name': 'Statistics', 
        'color': CategoryTheme.getColor('statistics'),
        'icon': CategoryTheme.getIcon('statistics'),
        'subtopics': ['Hypothesis Testing', 'Probability']
      },
    ];
    notifyListeners();
  }
}
