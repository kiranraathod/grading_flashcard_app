/// Utility class to map between internal category IDs and UI display categories
class CategoryMapper {
  // Maps internal category IDs to UI category names
  static final Map<String, String> _internalToUICategory = {
    'technical': 'Data Science',
    'applied': 'Data Analysis',
    'behavioral': 'Python',
    'case': 'Machine Learning',
    'job': 'Web Development',
  };

  // Maps UI category names to internal IDs
  static final Map<String, String> _uiToInternalCategory = {
    'Data Science': 'technical',
    'Data Analysis': 'applied',
    'Python': 'behavioral', 
    'Machine Learning': 'case',
    'Web Development': 'job',
    'SQL': 'technical',
    'Data Visualization': 'applied',
  };

  // Map from internal category ID to UI category name
  static String mapInternalToUICategory(String internalCategory, String subtopic) {
    // Special case for SQL - if the subtopic contains SQL, map to SQL category
    if (subtopic.toLowerCase().contains('sql')) {
      return 'SQL';
    }
    
    // Special case for Data Visualization
    if (subtopic.toLowerCase().contains('visualization')) {
      return 'Data Visualization';
    }
    
    return _internalToUICategory[internalCategory] ?? 'Other';
  }

  // Map from UI category name to internal category ID
  static String mapUIToInternalCategory(String uiCategory) {
    return _uiToInternalCategory[uiCategory] ?? 'technical';
  }

  // Get the mapping for new questions based on category
  static String getDefaultCategory(String internalCategory) {
    return _internalToUICategory[internalCategory] ?? 'Data Science';
  }

  // Get subtopic based on UI category
  static String getDefaultSubtopic(String uiCategory) {
    switch (uiCategory) {
      case 'SQL':
        return 'SQL & Database';
      case 'Python':
        return 'Python Fundamentals';
      case 'Data Analysis':
        return 'Data Cleaning & Preprocessing';
      case 'Machine Learning':
        return 'Machine Learning Algorithms';
      case 'Web Development':
        return 'Front-end Development';
      case 'Data Visualization':
        return 'Data Visualization';
      default:
        return 'General Knowledge';
    }
  }
}