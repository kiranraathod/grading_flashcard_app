import 'package:flutter/foundation.dart';
import '../../models/category.dart' as models;

/// CategoryMigrationHelper provides utilities for converting between 
/// legacy CategoryMapper format and Supabase-compatible Category model.
class CategoryMigrationHelper {
  
  // ===== DEFAULT CATEGORIES MIGRATION =====
  
  /// Create default categories for a guest user based on CategoryMapper
  static List<models.Category> createDefaultCategoriesForGuest(String guestSessionId) {
    final defaultInternalIds = [
      'data_analysis',
      'machine_learning', 
      'sql',
      'python',
      'web_development',
      'statistics',
    ];
    
    final categories = <models.Category>[];
    
    for (int i = 0; i < defaultInternalIds.length; i++) {
      try {
        final category = models.Category.fromCategoryMapper(
          id: 'guest-category-${defaultInternalIds[i]}-${DateTime.now().millisecondsSinceEpoch}',
          internalId: defaultInternalIds[i],
          guestSessionId: guestSessionId,
          isGuestData: true,
        );
        categories.add(category);
      } catch (e) {
        debugPrint('⚠️ Failed to create default category ${defaultInternalIds[i]}: $e');
      }
    }
    
    debugPrint('✅ Created ${categories.length} default categories for guest session');
    return categories;
  }
  
  /// Create default categories for an authenticated user
  static List<models.Category> createDefaultCategoriesForUser(String userId) {
    final defaultInternalIds = [
      'data_analysis',
      'machine_learning', 
      'sql',
      'python',
      'web_development',
      'statistics',
    ];
    
    final categories = <models.Category>[];
    
    for (int i = 0; i < defaultInternalIds.length; i++) {
      try {
        final now = DateTime.now();
        final category = models.Category(
          id: 'user-category-${defaultInternalIds[i]}-${now.millisecondsSinceEpoch}',
          name: _getUINameFromInternalId(defaultInternalIds[i]),
          description: _getDescriptionFromInternalId(defaultInternalIds[i]),
          internalId: defaultInternalIds[i],
          displayOrder: _getDisplayOrderFromInternalId(defaultInternalIds[i]),
          isDefault: _isDefaultCategory(defaultInternalIds[i]),
          colorScheme: _getColorSchemeFromInternalId(defaultInternalIds[i]),
          iconName: _getIconNameFromInternalId(defaultInternalIds[i]),
          userId: userId,
          guestSessionId: null,
          isGuestData: false,
          createdAt: now,
          updatedAt: now,
        );
        categories.add(category);
      } catch (e) {
        debugPrint('⚠️ Failed to create default category ${defaultInternalIds[i]}: $e');
      }
    }
    
    debugPrint('✅ Created ${categories.length} default categories for user');
    return categories;
  }
  
  // ===== OWNERSHIP TRANSFER UTILITIES =====
  
  /// Transfer guest categories to authenticated user format
  static List<models.Category> transferGuestCategoriesToUser(
    List<models.Category> guestCategories, {
    required String userId,
  }) {
    final transferredCategories = <models.Category>[];
    
    for (int i = 0; i < guestCategories.length; i++) {
      try {
        if (guestCategories[i].isGuestData) {
          final transferred = guestCategories[i].copyAsAuthenticatedUserData(userId);
          transferredCategories.add(transferred);
        } else {
          debugPrint('⚠️ Skipping non-guest category: ${guestCategories[i].name}');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to transfer category ${i + 1}/${guestCategories.length}: $e');
      }
    }
    
    debugPrint('✅ Successfully transferred ${transferredCategories.length} guest categories to user $userId');
    return transferredCategories;
  }
  
  // ===== CATEGORY LOOKUP UTILITIES =====
  
  /// Find category by internal ID (for CategoryMapper compatibility)
  static models.Category? findCategoryByInternalId(List<models.Category> categories, String internalId) {
    try {
      return categories.firstWhere((category) => category.internalId == internalId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get or create category by internal ID for guest user
  static models.Category getOrCreateCategoryForGuest({
    required List<models.Category> existingCategories,
    required String internalId,
    required String guestSessionId,
  }) {
    // Try to find existing category
    final existing = findCategoryByInternalId(existingCategories, internalId);
    if (existing != null && existing.isGuestData && existing.guestSessionId == guestSessionId) {
      return existing;
    }
    
    // Create new category
    return models.Category.fromCategoryMapper(
      id: 'guest-category-$internalId-${DateTime.now().millisecondsSinceEpoch}',
      internalId: internalId,
      guestSessionId: guestSessionId,
      isGuestData: true,
    );
  }
  
  /// Get or create category by internal ID for authenticated user
  static models.Category getOrCreateCategoryForUser({
    required List<models.Category> existingCategories,
    required String internalId,
    required String userId,
  }) {
    // Try to find existing category
    final existing = findCategoryByInternalId(existingCategories, internalId);
    if (existing != null && !existing.isGuestData && existing.userId == userId) {
      return existing;
    }
    
    // Create new category
    final now = DateTime.now();
    return models.Category(
      id: 'user-category-$internalId-${now.millisecondsSinceEpoch}',
      name: _getUINameFromInternalId(internalId),
      description: _getDescriptionFromInternalId(internalId),
      internalId: internalId,
      displayOrder: _getDisplayOrderFromInternalId(internalId),
      isDefault: _isDefaultCategory(internalId),
      colorScheme: _getColorSchemeFromInternalId(internalId),
      iconName: _getIconNameFromInternalId(internalId),
      userId: userId,
      guestSessionId: null,
      isGuestData: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // ===== LEGACY INTEGRATION =====
  
  /// Convert category to format compatible with existing CategoryMapper usage
  static Map<String, String> convertToLegacyFormat(models.Category category) {
    return {
      'id': category.id,
      'internalId': category.internalId,
      'name': category.name,
      'description': category.description,
    };
  }
  
  /// Get category ID from internal ID (for backward compatibility)
  static String? getCategoryIdFromInternalId(List<models.Category> categories, String internalId) {
    final category = findCategoryByInternalId(categories, internalId);
    return category?.id;
  }
  
  // ===== HELPER METHODS FOR CATEGORY MAPPING =====
  
  static String _getUINameFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'Data Analysis',
      'machine_learning': 'Machine Learning',
      'sql': 'SQL',
      'python': 'Python',
      'web_development': 'Web Development',
      'statistics': 'Statistics',
      'technical': 'Data Analysis',
      'applied': 'Machine Learning',
      'behavioral': 'Python',
      'case': 'Statistics',
      'job': 'Web Development',
    };
    return mapping[internalId] ?? 'General';
  }
  
  static String _getDescriptionFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'Data cleaning, preprocessing, and exploratory analysis',
      'machine_learning': 'ML algorithms, model training, and evaluation',
      'sql': 'Database queries, joins, and data manipulation',
      'python': 'Python programming fundamentals and libraries',
      'web_development': 'API development and web technologies',
      'statistics': 'Statistical analysis and inference',
    };
    return mapping[internalId] ?? 'General category for study materials';
  }
  
  static String _getColorSchemeFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'blue',
      'machine_learning': 'green',
      'sql': 'orange',
      'python': 'purple',
      'web_development': 'red',
      'statistics': 'teal',
    };
    return mapping[internalId] ?? 'gray';
  }
  
  static String _getIconNameFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'analytics',
      'machine_learning': 'psychology',
      'sql': 'storage',
      'python': 'code',
      'web_development': 'web',
      'statistics': 'trending_up',
    };
    return mapping[internalId] ?? 'category';
  }
  
  static int _getDisplayOrderFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 1,
      'machine_learning': 2,
      'sql': 3,
      'python': 4,
      'web_development': 5,
      'statistics': 6,
    };
    return mapping[internalId] ?? 99;
  }
  
  static bool _isDefaultCategory(String internalId) {
    return ['data_analysis', 'machine_learning', 'sql', 'python'].contains(internalId);
  }
}
