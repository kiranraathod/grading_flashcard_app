import 'package:flutter/material.dart';
import 'default_data_service.dart';

class CategoryConfigService extends ChangeNotifier {
  static final CategoryConfigService _instance = CategoryConfigService._internal();
  factory CategoryConfigService() => _instance;
  CategoryConfigService._internal();

  final DefaultDataService _defaultDataService = DefaultDataService();
  List<Map<String, dynamic>> _categories = [];

  List<Map<String, dynamic>> get categories => _categories;

  Future<void> loadCategories() async {
    try {
      final serverCategories = await _defaultDataService.loadDefaultCategories();
      _categories = serverCategories.map((cat) => {
        'id': cat['id'],
        'name': cat['name'],
        'color': Colors.blue.shade100,
        'icon': Icons.category,
        'subtopics': List<String>.from(cat['subtopics'] ?? []),
      }).toList();
      notifyListeners();
    } catch (e) {
      _loadFallbackCategories();
    }
  }

  List<String> getSubtopics(String categoryId) {
    final category = _categories.firstWhere((c) => c['id'] == categoryId, orElse: () => {'subtopics': <String>[]});
    return List<String>.from(category['subtopics'] ?? []);
  }

  void _loadFallbackCategories() {
    _categories = [
      {'id': 'technical', 'name': 'Technical Knowledge', 'color': Colors.blue.shade100, 'icon': Icons.article, 'subtopics': ['Machine Learning', 'SQL', 'Python']},
      {'id': 'applied', 'name': 'Applied Skills', 'color': Colors.green.shade100, 'icon': Icons.build, 'subtopics': ['Data Cleaning', 'Model Evaluation']},
      {'id': 'behavioral', 'name': 'Behavioral Questions', 'color': Colors.yellow.shade100, 'icon': Icons.people, 'subtopics': ['Communication', 'Teamwork']},
      {'id': 'case', 'name': 'Case Studies', 'color': Colors.purple.shade100, 'icon': Icons.assessment, 'subtopics': ['Model Building', 'Business Problems']},
      {'id': 'job', 'name': 'Job-Specific', 'color': Colors.red.shade100, 'icon': Icons.work, 'subtopics': ['Data Scientist', 'ML Engineer', 'Data Analyst']},
    ];
    notifyListeners();
  }
}
