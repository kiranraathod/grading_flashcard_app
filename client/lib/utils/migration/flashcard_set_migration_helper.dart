import 'package:flutter/foundation.dart';
import '../../models/flashcard_set.dart';
import '../../models/flashcard.dart';

/// FlashcardSetMigrationHelper provides utilities for converting between 
/// legacy local storage format and Supabase-compatible format.
/// 
/// This helper ensures seamless migration while maintaining backward compatibility
/// with existing local storage data.
class FlashcardSetMigrationHelper {
  
  // ===== LEGACY TO SUPABASE MIGRATION =====
  
  /// Convert legacy local FlashcardSet to Supabase-compatible format for guest users
  static FlashcardSet migrateToSupabaseForGuest(
    FlashcardSet legacy, {
    required String guestSessionId,
    String? categoryId,
  }) {
    try {
      debugPrint('🔄 Migrating legacy set "${legacy.title}" to guest Supabase format');
      
      return FlashcardSet(
        // Preserve all existing data
        id: legacy.id,
        title: legacy.title,
        description: legacy.description,
        isDraft: legacy.isDraft,
        rating: legacy.rating,
        ratingCount: legacy.ratingCount,
        flashcards: List<Flashcard>.from(legacy.flashcards), // Deep copy
        lastUpdated: legacy.lastUpdated,
        // Add Supabase fields for guest user
        userId: null,
        guestSessionId: guestSessionId,
        categoryId: categoryId,
        isGuestData: true,
        lastStudied: null, // Will be set when first studied
        studyStreak: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error migrating legacy set to guest format: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Convert legacy local FlashcardSet to Supabase-compatible format for authenticated users
  static FlashcardSet migrateToSupabaseForUser(
    FlashcardSet legacy, {
    required String userId,
    String? categoryId,
  }) {
    try {
      debugPrint('🔄 Migrating legacy set "${legacy.title}" to authenticated user Supabase format');
      
      return FlashcardSet(
        // Preserve all existing data
        id: legacy.id,
        title: legacy.title,
        description: legacy.description,
        isDraft: legacy.isDraft,
        rating: legacy.rating,
        ratingCount: legacy.ratingCount,
        flashcards: List<Flashcard>.from(legacy.flashcards), // Deep copy
        lastUpdated: legacy.lastUpdated,
        // Add Supabase fields for authenticated user
        userId: userId,
        guestSessionId: null,
        categoryId: categoryId,
        isGuestData: false,
        lastStudied: null, // Will be set when first studied
        studyStreak: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error migrating legacy set to user format: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Batch migrate multiple legacy sets to guest format
  static List<FlashcardSet> batchMigrateToGuest(
    List<FlashcardSet> legacySets, {
    required String guestSessionId,
    String? defaultCategoryId,
  }) {
    final migratedSets = <FlashcardSet>[];
    
    for (int i = 0; i < legacySets.length; i++) {
      try {
        final migrated = migrateToSupabaseForGuest(
          legacySets[i],
          guestSessionId: guestSessionId,
          categoryId: defaultCategoryId,
        );
        migratedSets.add(migrated);
      } catch (e) {
        debugPrint('⚠️ Failed to migrate set ${i + 1}/${legacySets.length}: $e');
        // Continue with other sets even if one fails
      }
    }
    
    debugPrint('✅ Successfully migrated ${migratedSets.length}/${legacySets.length} sets to guest format');
    return migratedSets;
  }
  
  /// Batch migrate multiple legacy sets to authenticated user format
  static List<FlashcardSet> batchMigrateToUser(
    List<FlashcardSet> legacySets, {
    required String userId,
    String? defaultCategoryId,
  }) {
    final migratedSets = <FlashcardSet>[];
    
    for (int i = 0; i < legacySets.length; i++) {
      try {
        final migrated = migrateToSupabaseForUser(
          legacySets[i],
          userId: userId,
          categoryId: defaultCategoryId,
        );
        migratedSets.add(migrated);
      } catch (e) {
        debugPrint('⚠️ Failed to migrate set ${i + 1}/${legacySets.length}: $e');
        // Continue with other sets even if one fails
      }
    }
    
    debugPrint('✅ Successfully migrated ${migratedSets.length}/${legacySets.length} sets to user format');
    return migratedSets;
  }
  
  // ===== SUPABASE TO LEGACY CONVERSION =====
  
  /// Convert Supabase FlashcardSet back to legacy format for backward compatibility
  /// This is useful when interfacing with existing UI components that expect legacy format
  static FlashcardSet convertToLegacyFormat(FlashcardSet supabaseSet) {
    try {
      debugPrint('🔄 Converting Supabase set "${supabaseSet.title}" to legacy format');
      
      return FlashcardSet(
        // Core legacy fields
        id: supabaseSet.id,
        title: supabaseSet.title,
        description: supabaseSet.description,
        isDraft: supabaseSet.isDraft,
        rating: supabaseSet.rating,
        ratingCount: supabaseSet.ratingCount,
        flashcards: List<Flashcard>.from(supabaseSet.flashcards), // Deep copy
        lastUpdated: supabaseSet.lastUpdated,
        // Note: Supabase-specific fields are intentionally omitted
        // for backward compatibility with legacy components
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error converting Supabase set to legacy format: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Batch convert Supabase sets to legacy format
  static List<FlashcardSet> batchConvertToLegacy(List<FlashcardSet> supabaseSets) {
    final legacySets = <FlashcardSet>[];
    
    for (int i = 0; i < supabaseSets.length; i++) {
      try {
        final legacy = convertToLegacyFormat(supabaseSets[i]);
        legacySets.add(legacy);
      } catch (e) {
        debugPrint('⚠️ Failed to convert set ${i + 1}/${supabaseSets.length} to legacy: $e');
        // Continue with other sets even if one fails
      }
    }
    
    debugPrint('✅ Successfully converted ${legacySets.length}/${supabaseSets.length} sets to legacy format');
    return legacySets;
  }
  
  // ===== OWNERSHIP TRANSFER UTILITIES =====
  
  /// Transfer guest data to authenticated user format (for post-authentication migration)
  static FlashcardSet transferGuestDataToUser(
    FlashcardSet guestSet, {
    required String userId,
    String? categoryId,
  }) {
    if (!guestSet.isGuestData) {
      throw ArgumentError('Cannot transfer non-guest data. Set must have isGuestData = true');
    }
    
    try {
      debugPrint('🔄 Transferring guest set "${guestSet.title}" to user $userId');
      
      return guestSet.copyWith(
        userId: userId,
        guestSessionId: null,
        isGuestData: false,
        categoryId: categoryId ?? guestSet.categoryId,
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error transferring guest data to user: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Batch transfer multiple guest sets to authenticated user
  static List<FlashcardSet> batchTransferGuestDataToUser(
    List<FlashcardSet> guestSets, {
    required String userId,
    String? defaultCategoryId,
  }) {
    final transferredSets = <FlashcardSet>[];
    
    for (int i = 0; i < guestSets.length; i++) {
      try {
        if (guestSets[i].isGuestData) {
          final transferred = transferGuestDataToUser(
            guestSets[i],
            userId: userId,
            categoryId: defaultCategoryId,
          );
          transferredSets.add(transferred);
        } else {
          debugPrint('⚠️ Skipping non-guest set: ${guestSets[i].title}');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to transfer set ${i + 1}/${guestSets.length}: $e');
        // Continue with other sets even if one fails
      }
    }
    
    debugPrint('✅ Successfully transferred ${transferredSets.length} guest sets to user $userId');
    return transferredSets;
  }
  
  // ===== VALIDATION UTILITIES =====
  
  /// Validate that a FlashcardSet has valid ownership data
  static bool isValidOwnership(FlashcardSet set) {
    // Must have either userId OR guestSessionId, not both
    final hasUserId = set.userId != null;
    final hasGuestSessionId = set.guestSessionId != null;
    
    if (hasUserId && hasGuestSessionId) {
      debugPrint('❌ Invalid ownership: Set has both userId and guestSessionId');
      return false;
    }
    
    if (!hasUserId && !hasGuestSessionId) {
      debugPrint('❌ Invalid ownership: Set has neither userId nor guestSessionId');
      return false;
    }
    
    // Validate isGuestData flag matches ownership
    if (set.isGuestData && hasUserId) {
      debugPrint('❌ Invalid ownership: Set marked as guest data but has userId');
      return false;
    }
    
    if (!set.isGuestData && hasGuestSessionId) {
      debugPrint('❌ Invalid ownership: Set marked as user data but has guestSessionId');
      return false;
    }
    
    return true;
  }
  
  /// Get ownership summary for debugging
  static Map<String, dynamic> getOwnershipSummary(FlashcardSet set) {
    return {
      'id': set.id,
      'title': set.title,
      'userId': set.userId,
      'guestSessionId': set.guestSessionId,
      'isGuestData': set.isGuestData,
      'isValidOwnership': isValidOwnership(set),
      'ownerType': set.isGuestData ? 'guest' : 'authenticated',
      'ownerId': set.ownerId,
    };
  }
  
  /// Check if a set needs migration (legacy format without Supabase fields)
  static bool needsMigration(Map<String, dynamic> jsonData) {
    // Check if any Supabase-specific fields are missing
    final hasSupabaseFields = jsonData.containsKey('isGuestData') ||
                             jsonData.containsKey('userId') ||
                             jsonData.containsKey('guestSessionId') ||
                             jsonData.containsKey('createdAt');
    
    return !hasSupabaseFields;
  }
}
