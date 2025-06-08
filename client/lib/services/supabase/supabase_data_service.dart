import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/flashcard_set.dart';
import '../../models/flashcard.dart';
import '../../models/category.dart' as models;
import '../guest_session_service.dart';
import '../supabase_auth_service.dart';
import '../reliable_operation_service.dart';
import '../../utils/config.dart';

/// SupabaseDataService handles all database operations with dual ownership support
/// 
/// Supports both guest users (via guest_session_id) and authenticated users (via user_id)
/// while respecting Row Level Security policies and maintaining data integrity.
class SupabaseDataService {
  // Singleton pattern consistent with other services
  static final SupabaseDataService _instance = SupabaseDataService._internal();
  factory SupabaseDataService() => _instance;
  SupabaseDataService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final GuestSessionService _guestSession = GuestSessionService();
  final SupabaseAuthService _auth = SupabaseAuthService();
  final ReliableOperationService _reliableOps = ReliableOperationService();
  
  bool _isInitialized = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _auth.isAuthenticated;
  String? get currentUserId => _auth.currentUser?.id;
  String? get currentGuestSessionId => _guestSession.currentSessionId;
  
  /// Initialize the service
  Future<void> initialize() async {
    await _reliableOps.safely(
      operation: () async {
        // Verify Supabase configuration
        if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
          throw Exception('Supabase configuration not found. Please configure Supabase credentials.');
        }
        
        _isInitialized = true;
        debugPrint('✅ SupabaseDataService: Initialized successfully');
      },
      operationName: 'supabase_data_service_initialization',
    );
  }
  
  // ===== FLASHCARD SETS OPERATIONS =====
  
  /// Get all flashcard sets for current user (guest or authenticated)
  Future<List<FlashcardSet>> getFlashcardSets() async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        final query = _client.from('flashcard_sets').select('''
          id, title, description, is_draft, rating, rating_count,
          user_id, guest_session_id, category_id, is_guest_data,
          last_studied, study_streak, created_at, updated_at,
          flashcards
        ''');
        
        // Add ownership filter based on authentication status
        final List<Map<String, dynamic>> response;
        if (isAuthenticated) {
          // Get authenticated user data
          response = await query
              .eq('user_id', currentUserId!)
              .eq('is_guest_data', false)
              .order('updated_at', ascending: false);
        } else {
          // Get guest session data
          if (currentGuestSessionId == null) {
            debugPrint('⚠️ No guest session ID available');
            return [];
          }
          response = await query
              .eq('guest_session_id', currentGuestSessionId!)
              .eq('is_guest_data', true)
              .order('updated_at', ascending: false);
        }
        
        final sets = response.map((json) => _convertToFlashcardSet(json)).toList();
        debugPrint('✅ Retrieved ${sets.length} flashcard sets from Supabase');
        return sets;
      },
      fallback: () async {
        debugPrint('❌ Failed to retrieve flashcard sets, returning empty list');
        return <FlashcardSet>[];
      },
      operationName: 'get_flashcard_sets',
    );
  }
  
  /// Create a new flashcard set
  Future<FlashcardSet> createFlashcardSet(FlashcardSet set) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        // Prepare data for insertion
        final insertData = _prepareFlashcardSetForInsert(set);
        
        final response = await _client
            .from('flashcard_sets')
            .insert(insertData)
            .select()
            .single();
        
        final createdSet = _convertToFlashcardSet(response);
        debugPrint('✅ Created flashcard set: ${createdSet.title}');
        return createdSet;
      },
      fallback: () async {
        debugPrint('❌ Failed to create flashcard set, returning original');
        return set;
      },
      operationName: 'create_flashcard_set',
    );
  }
  
  /// Update an existing flashcard set
  Future<FlashcardSet> updateFlashcardSet(FlashcardSet set) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        // Prepare data for update
        final updateData = _prepareFlashcardSetForUpdate(set);
        
        final response = await _client
            .from('flashcard_sets')
            .update(updateData)
            .eq('id', set.id)
            .select()
            .single();
        
        final updatedSet = _convertToFlashcardSet(response);
        debugPrint('✅ Updated flashcard set: ${updatedSet.title}');
        return updatedSet;
      },
      fallback: () async {
        debugPrint('❌ Failed to update flashcard set, returning original');
        return set;
      },
      operationName: 'update_flashcard_set',
    );
  }
  
  /// Delete a flashcard set
  Future<void> deleteFlashcardSet(String id) async {
    await _reliableOps.safely(
      operation: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        await _client
            .from('flashcard_sets')
            .delete()
            .eq('id', id);
        
        debugPrint('✅ Deleted flashcard set: $id');
      },
      operationName: 'delete_flashcard_set',
    );
  }
  
  /// Get flashcard sets for a specific guest session (for migration)
  Future<List<FlashcardSet>> getGuestFlashcardSets(String guestSessionId) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        final response = await _client
            .from('flashcard_sets')
            .select('''
              id, title, description, is_draft, rating, rating_count,
              user_id, guest_session_id, category_id, is_guest_data,
              last_studied, study_streak, created_at, updated_at,
              flashcards
            ''')
            .eq('guest_session_id', guestSessionId)
            .eq('is_guest_data', true)
            .order('created_at', ascending: true);
        
        final sets = response.map((json) => _convertToFlashcardSet(json)).toList();
        debugPrint('✅ Retrieved ${sets.length} guest flashcard sets for migration');
        return sets;
      },
      fallback: () async {
        debugPrint('❌ Failed to retrieve guest flashcard sets, returning empty list');
        return <FlashcardSet>[];
      },
      operationName: 'get_guest_flashcard_sets',
    );
  }
  
  // ===== CATEGORIES OPERATIONS =====
  
  /// Get all categories for current user (guest or authenticated)
  Future<List<models.Category>> getCategories() async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        final query = _client.from('categories').select('''
          id, name, description, internal_id, display_order, is_default,
          color_scheme, icon_name, user_id, guest_session_id, is_guest_data,
          created_at, updated_at
        ''');
        
        // Add ownership filter based on authentication status
        final List<Map<String, dynamic>> response;
        if (isAuthenticated) {
          // Get authenticated user data
          response = await query
              .eq('user_id', currentUserId!)
              .eq('is_guest_data', false)
              .order('display_order', ascending: true);
        } else {
          // Get guest session data
          if (currentGuestSessionId == null) {
            debugPrint('⚠️ No guest session ID available');
            return [];
          }
          response = await query
              .eq('guest_session_id', currentGuestSessionId!)
              .eq('is_guest_data', true)
              .order('display_order', ascending: true);
        }
        
        final categories = response.map((json) => _convertToCategory(json)).toList();
        debugPrint('✅ Retrieved ${categories.length} categories from Supabase');
        return categories;
      },
      fallback: () async {
        debugPrint('❌ Failed to retrieve categories, returning empty list');
        return <models.Category>[];
      },
      operationName: 'get_categories',
    );
  }
  
  /// Create a new category
  Future<models.Category> createCategory(models.Category category) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        // Prepare data for insertion
        final insertData = _prepareCategoryForInsert(category);
        
        final response = await _client
            .from('categories')
            .insert(insertData)
            .select()
            .single();
        
        final createdCategory = _convertToCategory(response);
        debugPrint('✅ Created category: ${createdCategory.name}');
        return createdCategory;
      },
      fallback: () async {
        debugPrint('❌ Failed to create category, returning original');
        return category;
      },
      operationName: 'create_category',
    );
  }
  
  /// Update an existing category
  Future<models.Category> updateCategory(models.Category category) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        // Prepare data for update
        final updateData = _prepareCategoryForUpdate(category);
        
        final response = await _client
            .from('categories')
            .update(updateData)
            .eq('id', category.id)
            .select()
            .single();
        
        final updatedCategory = _convertToCategory(response);
        debugPrint('✅ Updated category: ${updatedCategory.name}');
        return updatedCategory;
      },
      fallback: () async {
        debugPrint('❌ Failed to update category, returning original');
        return category;
      },
      operationName: 'update_category',
    );
  }
  
  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await _reliableOps.safely(
      operation: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        await _client
            .from('categories')
            .delete()
            .eq('id', id);
        
        debugPrint('✅ Deleted category: $id');
      },
      operationName: 'delete_category',
    );
  }
  
  // ===== MIGRATION OPERATIONS =====
  
  /// Migrate guest data to authenticated user using database function
  Future<Map<String, dynamic>> migrateGuestDataToUser(String userId, String guestSessionId) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        debugPrint('🔄 Starting guest data migration for session: $guestSessionId → user: $userId');
        
        // Call the database migration function
        final response = await _client
            .rpc('migrate_guest_data_to_user', params: {
          'p_user_id': userId,
          'p_guest_session_id': guestSessionId,
        });
        
        final result = response as Map<String, dynamic>;
        
        if (result['success'] == true) {
          debugPrint('✅ Guest data migration completed successfully');
        } else {
          debugPrint('❌ Guest data migration failed: ${result['error']}');
        }
        
        return result;
      },
      fallback: () async {
        debugPrint('❌ Migration function failed, returning error result');
        return {
          'success': false,
          'error': 'Migration function call failed',
          'sets_migrated': 0,
        };
      },
      operationName: 'migrate_guest_data_to_user',
    );
  }
  
  /// Batch create multiple flashcard sets (useful for migration)
  Future<List<FlashcardSet>> batchCreateFlashcardSets(List<FlashcardSet> sets) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        if (sets.isEmpty) return [];
        
        // Prepare all sets for insertion
        final insertDataList = sets.map((set) => _prepareFlashcardSetForInsert(set)).toList();
        
        final response = await _client
            .from('flashcard_sets')
            .insert(insertDataList)
            .select();
        
        final createdSets = response.map((json) => _convertToFlashcardSet(json)).toList();
        debugPrint('✅ Batch created ${createdSets.length} flashcard sets');
        return createdSets;
      },
      fallback: () async {
        debugPrint('❌ Batch create failed, returning original sets');
        return sets;
      },
      operationName: 'batch_create_flashcard_sets',
    );
  }
  
  /// Batch create multiple categories (useful for migration)
  Future<List<models.Category>> batchCreateCategories(List<models.Category> categories) async {
    return await _reliableOps.withFallback(
      primary: () async {
        if (!_isInitialized) {
          throw Exception('SupabaseDataService not initialized');
        }
        
        if (categories.isEmpty) return [];
        
        // Prepare all categories for insertion
        final insertDataList = categories.map((category) => _prepareCategoryForInsert(category)).toList();
        
        final response = await _client
            .from('categories')
            .insert(insertDataList)
            .select();
        
        final createdCategories = response.map((json) => _convertToCategory(json)).toList();
        debugPrint('✅ Batch created ${createdCategories.length} categories');
        return createdCategories;
      },
      fallback: () async {
        debugPrint('❌ Batch create categories failed, returning original categories');
        return categories;
      },
      operationName: 'batch_create_categories',
    );
  }
  
  // ===== HELPER METHODS FOR DATA CONVERSION =====
  
  /// Convert Supabase JSON to FlashcardSet model
  FlashcardSet _convertToFlashcardSet(Map<String, dynamic> json) {
    try {
      // Handle flashcards array - could be JSON string or already parsed
      List<dynamic> flashcardsData;
      if (json['flashcards'] is String) {
        // If it's a JSON string, parse it
        final flashcardsJson = json['flashcards'] as String;
        flashcardsData = List<dynamic>.from(jsonDecode(flashcardsJson));
      } else if (json['flashcards'] is List) {
        // If it's already a list, use it directly
        flashcardsData = json['flashcards'] as List<dynamic>;
      } else {
        // Fallback to empty list
        flashcardsData = [];
      }
      
      return FlashcardSet(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        isDraft: json['is_draft'] ?? false,
        rating: (json['rating'] ?? 0.0).toDouble(),
        ratingCount: json['rating_count'] ?? 0,
        flashcards: flashcardsData
            .map((cardJson) => Flashcard.fromJson(cardJson))
            .toList(),
        lastUpdated: DateTime.parse(json['updated_at']),
        // Supabase specific fields
        userId: json['user_id'],
        guestSessionId: json['guest_session_id'],
        categoryId: json['category_id'],
        isGuestData: json['is_guest_data'] ?? true,
        lastStudied: json['last_studied'] != null 
            ? DateTime.parse(json['last_studied']) 
            : null,
        studyStreak: json['study_streak'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error converting JSON to FlashcardSet: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Convert Supabase JSON to Category model
  models.Category _convertToCategory(Map<String, dynamic> json) {
    try {
      return models.Category(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        internalId: json['internal_id'] ?? '',
        displayOrder: json['display_order'] ?? 0,
        isDefault: json['is_default'] ?? false,
        colorScheme: json['color_scheme'],
        iconName: json['icon_name'],
        // Supabase specific fields
        userId: json['user_id'],
        guestSessionId: json['guest_session_id'],
        isGuestData: json['is_guest_data'] ?? true,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error converting JSON to Category: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Prepare FlashcardSet for database insertion
  Map<String, dynamic> _prepareFlashcardSetForInsert(FlashcardSet set) {
    final now = DateTime.now();
    
    // Determine ownership based on authentication status
    String? userId;
    String? guestSessionId;
    bool isGuestData;
    
    if (isAuthenticated) {
      userId = currentUserId;
      guestSessionId = null;
      isGuestData = false;
    } else {
      userId = null;
      guestSessionId = currentGuestSessionId;
      isGuestData = true;
    }
    
    return {
      'id': set.id,
      'title': set.title,
      'description': set.description,
      'is_draft': set.isDraft,
      'rating': set.rating,
      'rating_count': set.ratingCount,
      'flashcards': set.flashcards.map((card) => card.toJson()).toList(),
      'user_id': userId,
      'guest_session_id': guestSessionId,
      'category_id': set.categoryId,
      'is_guest_data': isGuestData,
      'last_studied': set.lastStudied?.toIso8601String(),
      'study_streak': set.studyStreak,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }
  
  /// Prepare FlashcardSet for database update
  Map<String, dynamic> _prepareFlashcardSetForUpdate(FlashcardSet set) {
    return {
      'title': set.title,
      'description': set.description,
      'is_draft': set.isDraft,
      'rating': set.rating,
      'rating_count': set.ratingCount,
      'flashcards': set.flashcards.map((card) => card.toJson()).toList(),
      'category_id': set.categoryId,
      'last_studied': set.lastStudied?.toIso8601String(),
      'study_streak': set.studyStreak,
      'updated_at': DateTime.now().toIso8601String(),
      // Note: Don't update ownership fields during regular updates
    };
  }
  
  /// Prepare Category for database insertion
  Map<String, dynamic> _prepareCategoryForInsert(models.Category category) {
    final now = DateTime.now();
    
    // Determine ownership based on authentication status
    String? userId;
    String? guestSessionId;
    bool isGuestData;
    
    if (isAuthenticated) {
      userId = currentUserId;
      guestSessionId = null;
      isGuestData = false;
    } else {
      userId = null;
      guestSessionId = currentGuestSessionId;
      isGuestData = true;
    }
    
    return {
      'id': category.id,
      'name': category.name,
      'description': category.description,
      'internal_id': category.internalId,
      'display_order': category.displayOrder,
      'is_default': category.isDefault,
      'color_scheme': category.colorScheme,
      'icon_name': category.iconName,
      'user_id': userId,
      'guest_session_id': guestSessionId,
      'is_guest_data': isGuestData,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }
  
  /// Prepare Category for database update
  Map<String, dynamic> _prepareCategoryForUpdate(models.Category category) {
    return {
      'name': category.name,
      'description': category.description,
      'internal_id': category.internalId,
      'display_order': category.displayOrder,
      'is_default': category.isDefault,
      'color_scheme': category.colorScheme,
      'icon_name': category.iconName,
      'updated_at': DateTime.now().toIso8601String(),
      // Note: Don't update ownership fields during regular updates
    };
  }
  
  // ===== UTILITY METHODS =====
  
  /// Check if the service is ready for operations
  bool get isReady => _isInitialized && AppConfig.supabaseUrl.isNotEmpty;
  
  /// Get current ownership info for debugging
  Map<String, dynamic> get currentOwnershipInfo => {
    'isAuthenticated': isAuthenticated,
    'userId': currentUserId,
    'guestSessionId': currentGuestSessionId,
    'isReady': isReady,
  };
}
