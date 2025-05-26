/// Utility class to map between internal category IDs and UI display categories
class CategoryMapper {
  // ✅ UPDATED: Maps internal category IDs to UI category names (aligned with server)
  static final Map<String, String> _internalToUICategory = {
    // Server-aligned mappings
    'data_analysis': 'Data Analysis',
    'machine_learning': 'Machine Learning', 
    'sql': 'SQL',
    'python': 'Python',
    'web_development': 'Web Development',
    'statistics': 'Statistics',
    // Legacy mappings for backward compatibility
    'technical': 'Data Analysis',
    'applied': 'Machine Learning',
    'behavioral': 'Python',
    'case': 'Statistics',
    'job': 'Web Development',
  };

  // ✅ UPDATED: Maps UI category names to internal IDs (aligned with server)
  static final Map<String, String> _uiToInternalCategory = {
    'Data Analysis': 'data_analysis',
    'Machine Learning': 'machine_learning',
    'SQL': 'sql',
    'Python': 'python',
    'Web Development': 'web_development',
    'Statistics': 'statistics',
    // Legacy support
    'Data Science': 'technical',
    'Data Visualization': 'applied',
  };

  // ✅ UPDATED: Map from internal category ID to UI category name (simplified)
  static String mapInternalToUICategory(String internalCategory) {
    return _internalToUICategory[internalCategory] ?? 'Data Analysis';
  }

  // Map from UI category name to internal category ID
  static String mapUIToInternalCategory(String uiCategory) {
    return _uiToInternalCategory[uiCategory] ?? 'technical';
  }

  // ✅ UPDATED: Get the mapping for new questions based on category
  static String getDefaultCategory(String internalCategory) {
    return _internalToUICategory[internalCategory] ?? 'Data Analysis';
  }

  // ✅ UPDATED: Get subtopic based on UI category
  static String getDefaultSubtopic(String uiCategory) {
    switch (uiCategory) {
      case 'SQL':
        return 'SQL & Database';
      case 'Python':
        return 'Python Fundamentals';
      case 'Data Analysis':
        return 'Data Cleaning & Preprocessing';
      case 'Machine Learning':
        return 'ML Algorithms';
      case 'Web Development':
        return 'API Development';
      case 'Statistics':
        return 'Statistical Analysis';
      default:
        return 'General Knowledge';
    }
  }
}