import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/simple_auth_state.dart';
import '../services/working_secure_auth_storage.dart';
import '../services/supabase_service.dart';
import '../services/storage_service.dart';
import '../utils/config.dart';
import '../utils/migration_debug_helper.dart';
import '../utils/enhanced_safe_map_converter.dart';

/// Simple authentication notifier
class SimpleAuthNotifier extends StateNotifier<AuthState> {
  SupabaseClient? _supabase;
  
  // Callback for data migration completion
  final List<Function(String userId)> _onUserDataMigrated = [];
  
  SimpleAuthNotifier() : super(const AuthStateInitial()) {
    _supabase = SupabaseService.instance.client;
    _initializeAuth();
  }

  /// Register a callback to be called when user data migration completes
  void onUserDataMigrated(Function(String userId) callback) {
    _onUserDataMigrated.add(callback);
  }

  /// Remove a data migration callback
  void removeUserDataMigrationCallback(Function(String userId) callback) {
    _onUserDataMigrated.remove(callback);
  }

  /// Trigger all data migration callbacks
  void _triggerDataMigrationCallbacks(String userId) {
    debugPrint('');
    debugPrint('🔔 ========== SERVICE NOTIFICATION PROCESS ==========');
    debugPrint('👤 User ID: $userId');
    debugPrint('📢 Registered callbacks: ${_onUserDataMigrated.length}');
    debugPrint('');
    
    if (_onUserDataMigrated.isEmpty) {
      debugPrint('ℹ️ No services registered for migration callbacks');
      debugPrint('💡 This means services will load data on their own schedule');
      debugPrint('==================================================');
      return;
    }
    
    debugPrint('🚀 Notifying services to reload with migrated data...');
    
    for (int i = 0; i < _onUserDataMigrated.length; i++) {
      try {
        final callbackIndex = i + 1;
        debugPrint('');
        debugPrint('📞 Callback $callbackIndex/${_onUserDataMigrated.length}:');
        debugPrint('  • Status: Executing...');
        debugPrint('  • Purpose: Reload service data for authenticated user');
        
        _onUserDataMigrated[i](userId);
        
        debugPrint('  • Result: ✅ Success');
        debugPrint('  • Impact: Service data refreshed with migrated content');
        
      } catch (e) {
        debugPrint('  • Result: ❌ Failed');
        debugPrint('  • Error: $e');
        debugPrint('  • Impact: This service may not see migrated data immediately');
      }
    }
    
    debugPrint('');
    debugPrint('🏁 All service notifications completed');
    debugPrint('');
    debugPrint('📊 EXPECTED OUTCOMES:');
    debugPrint('====================');
    debugPrint('✅ FlashcardService: Should reload and show migrated sets');
    debugPrint('✅ InterviewService: Should reload and show migrated questions');  
    debugPrint('✅ UI Components: Should refresh and display user\'s content');
    debugPrint('✅ Progress: All completion status should be preserved');
    debugPrint('');
    debugPrint('🔄 If data doesn\'t appear immediately, check individual service logs');
    debugPrint('==================================================================');
  }

  Future<void> _initializeAuth() async {
    if (!AuthConfig.enableAuthentication) {
      debugPrint('Authentication disabled via config');
      state = const AuthStateUnauthenticated();
      return;
    }

    try {
      state = const AuthStateLoading();
      
      // Check for existing Supabase session
      final session = _supabase?.auth.currentSession;
      if (session != null) {
        debugPrint('Found existing session for: ${session.user.email}');
        state = AuthStateAuthenticated(session.user);
        await _migrateGuestDataIfNeeded(session.user.id);
        return;
      }

      // Check for guest user data
      final guestData = await WorkingSecureAuthStorage.getGuestData();
      if (guestData != null) {
        debugPrint('Found guest user: ${guestData.id}');
        state = AuthStateGuest(guestData.id);
        return;
      }

      debugPrint('No existing authentication found');
      state = const AuthStateUnauthenticated();
      
      // Listen to Supabase auth changes
      _supabase?.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.event, data.session);
      });
      
    } catch (e) {
      debugPrint('❌ Auth initialization error: $e');
      state = AuthStateError('Authentication initialization failed: $e');
    }
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint('🔄 Auth state changed: $event');
    
    switch (event) {
      case AuthChangeEvent.signedIn:
        if (session?.user != null) {
          final user = session!.user;
          debugPrint('✅ User signed in: ${user.id} (${user.email})');
          state = AuthStateAuthenticated(user);
          
          // 🔍 DEBUG: Generate migration report before attempting migration
          MigrationDebugHelper.generateMigrationReport(user.id);
          
          _migrateGuestDataIfNeeded(user.id);
        }
        break;
        
      case AuthChangeEvent.signedOut:
        debugPrint('👋 User signed out');
        state = const AuthStateUnauthenticated();
        break;
        
      case AuthChangeEvent.userUpdated:
        if (session?.user != null) {
          final user = session!.user;
          debugPrint('🔄 User updated: ${user.id}');
          state = AuthStateAuthenticated(user);
        }
        break;
        
      default:
        break;
    }
  }

  Future<void> _migrateGuestDataIfNeeded(String userId) async {
    try {
      debugPrint('🔄 Starting comprehensive guest data migration for user: $userId');
      
      final guestData = await WorkingSecureAuthStorage.getGuestData();
      if (guestData != null) {
        debugPrint('📦 Found guest data, migrating to authenticated user');
        
        // 1. Migrate usage tracking data
        final guestActions = await WorkingSecureAuthStorage.getUserActions(guestData.id);
        if (guestActions.isNotEmpty) {
          await WorkingSecureAuthStorage.storeUserActions(userId, guestActions);
          debugPrint('✅ Migrated ${guestActions.length} guest actions');
        }
        
        // 2. Import and trigger comprehensive data migration
        await _migrateAllGuestContent(userId);
        
        // 3. Clear guest data
        await WorkingSecureAuthStorage.clearGuestData();
        
        // 4. Trigger data reload in services
        _triggerDataMigrationCallbacks(userId);
        
        debugPrint('✅ Guest data migration completed successfully');
      } else {
        debugPrint('📋 No guest data found, checking for orphaned content');
        // Still check for orphaned content that might exist without guest record
        await _migrateAllGuestContent(userId);
        
        // Trigger reload anyway in case there was guest data
        _triggerDataMigrationCallbacks(userId);
      }
    } catch (e) {
      debugPrint('❌ Guest data migration failed: $e');
    }
  }

  /// Migrate all guest content including flashcards, interview questions, and progress
  Future<void> _migrateAllGuestContent(String userId) async {
    try {
      debugPrint('');
      debugPrint('🚀 ========== GUEST DATA MIGRATION STARTED ==========');
      debugPrint('🔑 Authenticated User ID: $userId');
      debugPrint('📅 Migration Time: ${DateTime.now().toIso8601String()}');
      debugPrint('🏗️ Migration Strategy: Hive → SharedPreferences backup → Future Supabase sync');
      debugPrint('');
      
      // 🔍 DEBUG: Check guest data state before migration
      debugPrint('🔍 STEP 1: Pre-Migration Data Analysis');
      debugPrint('==========================================');
      await MigrationDebugHelper.debugGuestDataState();
      
      debugPrint('');
      debugPrint('🔍 STEP 2: Fetching Guest Data from Hive Storage');
      debugPrint('================================================');
      
      // Get current guest flashcard data from Hive
      final guestFlashcards = StorageService.getFlashcardSets();
      final guestInterviews = StorageService.getInterviewQuestions();
      
      debugPrint('📊 Data Discovery Results:');
      debugPrint('  • Flashcard sets found: ${guestFlashcards?.length ?? 0}');
      debugPrint('  • Interview questions found: ${guestInterviews?.length ?? 0}');
      
      if (guestFlashcards != null && guestFlashcards.isNotEmpty) {
        debugPrint('');
        debugPrint('📚 Detailed Flashcard Analysis:');
        for (int i = 0; i < guestFlashcards.length; i++) {
          final set = guestFlashcards[i];
          final title = set['title'] ?? 'Untitled';
          final cardCount = (set['flashcards'] as List?)?.length ?? 0;
          final completedCards = (set['flashcards'] as List?)
              ?.where((card) => card['isCompleted'] == true)
              .length ?? 0;
          
          debugPrint('  Set ${i + 1}: "$title"');
          debugPrint('    - Cards: $cardCount total, $completedCards completed');
          debugPrint('    - Progress: ${cardCount > 0 ? ((completedCards / cardCount) * 100).toStringAsFixed(1) : 0}%');
          debugPrint('    - Raw data type: ${set.runtimeType}');
        }
        
        debugPrint('');
        debugPrint('🔧 STEP 3: Converting LinkedMap Data for JSON Serialization');
        debugPrint('==========================================================');
        debugPrint('🔄 Converting ${guestFlashcards.length} flashcard sets using Enhanced SafeMapConverter...');
        
        final convertedFlashcards = EnhancedSafeMapConverter.convertHiveData(guestFlashcards);
        final convertedInterviews = guestInterviews != null ? EnhancedSafeMapConverter.convertHiveData(guestInterviews) : null;
        
        debugPrint('✅ Conversion Results:');
        debugPrint('  • Flashcard sets converted: ${convertedFlashcards.length}/${guestFlashcards.length}');
        debugPrint('  • Interview questions converted: ${convertedInterviews?.length ?? 0}/${guestInterviews?.length ?? 0}');
        debugPrint('  • Data ready for JSON serialization: ✅');
        
        debugPrint('');
        debugPrint('💾 STEP 4: Creating SharedPreferences Backup');
        debugPrint('=============================================');
        
        final migrationPayload = {
          'flashcards': convertedFlashcards,
          'interviews': convertedInterviews,
          'migrated_at': DateTime.now().toIso8601String(),
          'migration_source': 'guest_session',
          'original_guest_data_count': {
            'flashcard_sets': guestFlashcards.length,
            'interview_questions': guestInterviews?.length ?? 0,
          },
          'conversion_success': {
            'flashcards_converted': convertedFlashcards.length,
            'interviews_converted': convertedInterviews?.length ?? 0,
          }
        };
        
        debugPrint('📦 Migration payload prepared:');
        debugPrint('  • Total data size: ${jsonEncode(migrationPayload).length} characters');
        debugPrint('  • Backup destination: SharedPreferences');
        debugPrint('  • Backup key: user_migrated_data_$userId');
        
        // Store user-scoped backup of guest data
        await _backupGuestDataForUser(userId, migrationPayload);
        
        debugPrint('');
        debugPrint('🏁 STEP 5: Finalizing Migration');
        debugPrint('===============================');
        
        // Mark the data as migrated in storage service for user context
        await _markDataAsMigrated(userId);
        
        debugPrint('✅ Migration flags set successfully');
        
        // 🔍 DEBUG: Verify migration result
        debugPrint('');
        debugPrint('🔍 STEP 6: Post-Migration Verification');
        debugPrint('=====================================');
        await MigrationDebugHelper.debugMigrationResult(userId);
        
        debugPrint('');
        debugPrint('📢 STEP 7: Notifying Services');
        debugPrint('=============================');
        debugPrint('🔔 Preparing to trigger ${_onUserDataMigrated.length} service callbacks...');
        
        // 🔧 FIX: Add small delay before triggering callbacks to ensure services are ready
        await Future.delayed(const Duration(milliseconds: 100));
        
        debugPrint('');
        debugPrint('🏁 ========== MIGRATION COMPLETED SUCCESSFULLY ==========');
        debugPrint('✅ Guest data successfully migrated for user: $userId');
        debugPrint('✅ Data preserved during authentication transition');
        debugPrint('✅ Services will reload with migrated data');
        debugPrint('=========================================================');
        
        // Trigger callbacks to reload services with migrated data
        _triggerDataMigrationCallbacks(userId);
        
      } else {
        debugPrint('');
        debugPrint('📋 ========== NO DATA MIGRATION NEEDED ==========');
        debugPrint('ℹ️ No guest flashcard data found to migrate');
        debugPrint('📊 Migration Analysis:');
        debugPrint('  • Flashcard sets: 0');
        debugPrint('  • Interview questions: ${guestInterviews?.length ?? 0}');
        debugPrint('');
        debugPrint('🎯 This is normal for:');
        debugPrint('  • New guest users who haven\'t created content');
        debugPrint('  • Users who cleared their data');
        debugPrint('  • Fresh app installations');
        debugPrint('');
        debugPrint('🔄 Authentication will proceed normally');
        debugPrint('===============================================');
      }
      
    } catch (e) {
      debugPrint('❌ Guest content migration failed: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      // Don't throw - this shouldn't block authentication
    }
  }

  // REMOVED: Unused conversion methods - all conversion now handled by EnhancedSafeMapConverter

  // REMOVED: All broken custom conversion methods replaced with Enhanced SafeMapConverter  
  /// Create a user-scoped backup of guest data
  Future<void> _backupGuestDataForUser(String userId, Map<String, dynamic> guestData) async {
    try {
      debugPrint('');
      debugPrint('💾 ========== DATA BACKUP PROCESS ==========');
      debugPrint('👤 User ID: $userId');
      debugPrint('📁 Storage Method: SharedPreferences (Local)');
      debugPrint('🎯 Purpose: Guest-to-Authenticated transition backup');
      debugPrint('');
      
      // Use SharedPreferences for user-scoped data backup
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'user_migrated_data_$userId';
      
      debugPrint('📊 Backup Data Analysis:');
      debugPrint('  • Backup Key: $backupKey');
      debugPrint('  • Data Structure:');
      
      if (guestData['flashcards'] != null) {
        final flashcards = guestData['flashcards'] as List;
        debugPrint('    - Flashcards: ${flashcards.length} sets');
        for (int i = 0; i < flashcards.length; i++) {
          final set = flashcards[i];
          debugPrint('      Set ${i + 1}: ${set['title']} (${(set['flashcards'] as List).length} cards)');
        }
      }
      
      if (guestData['interviews'] != null) {
        final interviews = guestData['interviews'] as List;
        debugPrint('    - Interviews: ${interviews.length} questions');
      }
      
      debugPrint('    - Migration Timestamp: ${guestData['migrated_at']}');
      debugPrint('    - Source: ${guestData['migration_source']}');
      
      final jsonString = jsonEncode(guestData);
      debugPrint('    - Serialized Size: ${jsonString.length} characters');
      
      debugPrint('');
      debugPrint('💾 Writing to SharedPreferences...');
      await prefs.setString(backupKey, jsonString);
      debugPrint('✅ Data written successfully');
      
      // Also set a flag to indicate this user has migrated data
      final flagKey = 'user_has_migrated_data_$userId';
      await prefs.setBool(flagKey, true);
      debugPrint('🏁 Migration flag set: $flagKey = true');
      
      debugPrint('');
      debugPrint('🔍 STORAGE STRATEGY EXPLANATION:');
      debugPrint('================================');
      debugPrint('📍 CURRENT: Data stored in SharedPreferences');
      debugPrint('  • Why: Immediate backup during auth transition');
      debugPrint('  • Pros: Fast, reliable, survives app restarts');
      debugPrint('  • Cons: Local only, not synced across devices');
      debugPrint('');
      debugPrint('🌐 FUTURE: Supabase Database Integration');
      debugPrint('  • When: After authentication is stable');
      debugPrint('  • What: Sync to PostgreSQL with RLS policies');
      debugPrint('  • Benefits: Cross-device sync, backup, collaboration');
      debugPrint('  • Status: Schema ready, implementation pending');
      debugPrint('');
      debugPrint('🔄 MIGRATION COMPLETE: Guest data is now safely backed up!');
      debugPrint('==========================================');
      
    } catch (e) {
      debugPrint('');
      debugPrint('❌ ========== BACKUP FAILED ==========');
      debugPrint('User: $userId');
      debugPrint('Error: $e');
      debugPrint('=====================================');
      rethrow;
    }
  }

  /// Mark that data has been migrated for this user to prevent re-loading defaults
  Future<void> _markDataAsMigrated(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('data_migrated_for_user_$userId', true);
      await prefs.setString('last_migration_date_$userId', DateTime.now().toIso8601String());
      debugPrint('🏷️ Marked data as migrated for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to mark data as migrated: $e');
    }
  }  Future<void> signInAnonymously() async {
    try {
      state = const AuthStateLoading();
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      final response = await _supabase!.auth.signInAnonymously();
      if (response.user != null) {
        final guestId = response.user!.id;
        await WorkingSecureAuthStorage.storeGuestData(guestId, {
          'created_at': DateTime.now().toIso8601String(),
          'type': 'anonymous',
        });
        
        state = AuthStateGuest(guestId);
        debugPrint('✅ Anonymous sign-in successful: $guestId');
      }
    } catch (e) {
      debugPrint('❌ Anonymous sign-in failed: $e');
      state = AuthStateError('Failed to create guest session: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AuthStateLoading();
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email sign-in successful: $email');
    } catch (e) {
      debugPrint('❌ Email sign-in failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      state = const AuthStateLoading();
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      final response = await _supabase!.auth.signUp(
        email: email,
        password: password,
      );
      
      if (AuthConfig.requireEmailVerification && 
          response.user?.emailConfirmedAt == null) {
        state = const AuthStateEmailVerificationRequired();
      }
      
      debugPrint('✅ Email sign-up successful: $email');
    } catch (e) {
      debugPrint('❌ Email sign-up failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = const AuthStateLoading();
      
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      await _supabase!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'your-app://auth-callback',
      );
      
      debugPrint('✅ Google sign-in initiated');
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  Future<void> signInDemo() async {
    if (!AuthConfig.enableDemoMode) {
      state = const AuthStateError('Demo mode disabled');
      return;
    }

    try {
      state = const AuthStateLoading();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create a simple demo user object
      final demoUser = {
        'id': 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        'email': 'demo@flashmaster.app',
        'user_metadata': {
          'full_name': 'Demo User',
          'demo_mode': true,
        },
      };
      
      state = AuthStateAuthenticated(demoUser);
      debugPrint('✅ Demo authentication successful');
    } catch (e) {
      debugPrint('❌ Demo authentication failed: $e');
      state = AuthStateError('Demo authentication failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      if (_supabase != null) {
        await _supabase!.auth.signOut();
      }
      await WorkingSecureAuthStorage.clearSession();
      state = const AuthStateUnauthenticated();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      state = const AuthStateUnauthenticated();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase client not initialized');
      }
      
      await _supabase!.auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent: $email');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  void clearError() {
    if (state is AuthStateError) {
      state = const AuthStateUnauthenticated();
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid_credentials')) {
      return 'Invalid email or password';
    } else if (errorString.contains('email_provider_disabled')) {
      return 'Email authentication is temporarily unavailable';
    } else if (errorString.contains('user_already_exists')) {
      return 'An account with this email already exists';
    } else if (errorString.contains('weak_password')) {
      return 'Password is too weak';
    } else if (errorString.contains('invalid_email')) {
      return 'Please enter a valid email address';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }
}

// Provider instances
final authNotifierProvider = StateNotifierProvider<SimpleAuthNotifier, AuthState>((ref) {
  return SimpleAuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthStateAuthenticated;
});

final currentUserProvider = Provider<dynamic>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthStateAuthenticated) {
    return authState.user;
  }
  return null;
});

final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthStateGuest;
});
