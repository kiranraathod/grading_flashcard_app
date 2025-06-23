import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simple_auth_state.dart';
import '../providers/working_auth_provider.dart';
import '../services/unified_usage_storage.dart';
import '../utils/config.dart';

/// 🔄 REFACTORED: Unified action tracking provider using consolidated storage
/// 
/// This replaces the fragmented approach with a single, reliable tracking system.
/// Eliminates conflicts between GuestUserManager and legacy storage patterns.
class UnifiedActionTracker extends StateNotifier<UserActionState> {
  final Ref ref;
  String? _currentUserId; // Track current user ID for migration
  
  UnifiedActionTracker(this.ref) : super(UserActionState(
    actionCounts: const {},
    dailyLimits: const {},
    lastReset: DateTime(2000),
  )) {
    _initializeTracking();
    _listenToAuthChanges();
  }

  /// Get current user ID (guest or authenticated)
  String? get currentUserId => _currentUserId;

  /// Listen to authentication state changes and react accordingly
  void _listenToAuthChanges() {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) async {
      debugPrint('🔄 Unified tracker: Auth state changed from ${previous?.runtimeType} to ${next.runtimeType}');
      
      // Handle authentication transition
      if (previous is! AuthStateAuthenticated && next is AuthStateAuthenticated) {
        debugPrint('✨ User authenticated - migrating and refreshing limits');
        await _handleUserAuthenticated(next);
      } 
      // Handle logout transition
      else if (previous is AuthStateAuthenticated && next is! AuthStateAuthenticated) {
        debugPrint('👋 User logged out - switching to guest tracking');
        await _handleUserLoggedOut();
      }
      // Handle user change
      else if (previous != null && _getUserId(previous) != _getUserId(next)) {
        debugPrint('🔄 User changed - reloading data');
        await _reloadUserData();
      }
    });
  }

  /// Initialize tracking system with migration
  Future<void> _initializeTracking() async {
    try {
      debugPrint('🚀 Initializing unified action tracking...');
      
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState) ?? _generateGuestId();
      _currentUserId = userId; // Track current user ID
      
      // Always migrate legacy data first
      await UnifiedUsageStorage.migrateLegacyData(userId);
      
      // Load current usage data
      await _loadUserData(userId);
      
      // Check for daily reset
      await _checkDailyReset();
      
      debugPrint('✅ Unified action tracking initialized for: $userId');
      debugPrint('📊 Current state: ${_getStateDebugString()}');
      
    } catch (e) {
      debugPrint('❌ Unified tracking initialization failed: $e');
      // Fallback to basic guest tracking
      await _initializeFallbackTracking();
    }
  }

  /// Fallback initialization if main init fails
  Future<void> _initializeFallbackTracking() async {
    try {
      final guestLimits = _calculateDailyLimits(false);
      state = state.copyWith(
        actionCounts: {},
        dailyLimits: guestLimits,
        lastReset: DateTime.now(),
        hasReachedLimit: false,
      );
      debugPrint('✅ Fallback guest tracking initialized');
    } catch (e) {
      debugPrint('❌ Even fallback initialization failed: $e');
    }
  }

  /// Handle user authentication with data migration
  Future<void> _handleUserAuthenticated(AuthStateAuthenticated authState) async {
    try {
      final newUserId = _getUserId(authState);
      if (newUserId == null) return;

      debugPrint('🔄 Handling user authentication: $newUserId');
      debugPrint('🔄 Previous user ID: $_currentUserId');
      
      // 🎯 CRITICAL FIX: Migrate current guest data to authenticated user
      if (_currentUserId != null && _currentUserId != newUserId && _currentUserId!.startsWith('guest_')) {
        debugPrint('🔄 Migrating current guest data: $_currentUserId → $newUserId');
        
        // Transfer unified storage data
        await UnifiedUsageStorage.migrateGuestToAuthenticated(_currentUserId!, newUserId);
        
        // Store the current state data to preserve in-memory progress
        final currentData = UnifiedUsageData.empty(newUserId).copyWith(
          actionCounts: state.actionCounts,
          dailyLimits: _calculateDailyLimits(true), // Update to authenticated limits
          lastReset: state.lastReset,
        );
        await UnifiedUsageStorage.storeUsageData(newUserId, currentData);
        
        debugPrint('✅ Guest data migration completed: ${state.actionCounts}');
      } else {
        // Migrate any legacy data for the authenticated user
        await UnifiedUsageStorage.migrateLegacyData(newUserId);
      }
      
      // Update current user ID
      _currentUserId = newUserId;
      
      // Load authenticated user data (includes migrated guest data)
      await _loadUserData(newUserId);
      
      // Apply authenticated limits but preserve action counts
      final authenticatedLimits = _calculateDailyLimits(true);
      final preservedCounts = Map<String, int>.from(state.actionCounts);
      
      // Update state with authenticated limits but keep progress
      state = state.copyWith(
        actionCounts: preservedCounts,
        dailyLimits: authenticatedLimits,
        hasReachedLimit: false, // Reset limit flag for authenticated user
      );
      
      // Save updated state
      final finalData = UnifiedUsageData.empty(newUserId).copyWith(
        actionCounts: preservedCounts,
        dailyLimits: authenticatedLimits,
        lastReset: state.lastReset,
      );
      await UnifiedUsageStorage.storeUsageData(newUserId, finalData);
      
      debugPrint('🎉 Authenticated user limits applied:');
      debugPrint('   📊 Preserved counts: $preservedCounts');
      debugPrint('   📊 New limits: $authenticatedLimits');
      
    } catch (e) {
      debugPrint('❌ Failed to handle user authentication: $e');
    }
  }

  /// Handle user logout
  Future<void> _handleUserLoggedOut() async {
    try {
      debugPrint('🔄 Handling user logout');
      
      // Generate new guest ID
      final guestId = _generateGuestId();
      _currentUserId = guestId; // Update current user ID
      final guestLimits = _calculateDailyLimits(false);
      
      // Create fresh guest data
      final guestData = UnifiedUsageData.empty(guestId).copyWith(
        dailyLimits: guestLimits,
      );
      
      // Store guest data
      await UnifiedUsageStorage.storeUsageData(guestId, guestData);
      
      // Update state
      state = state.copyWith(
        actionCounts: {},
        dailyLimits: guestLimits,
        lastReset: DateTime.now(),
        hasReachedLimit: false,
      );
      
      debugPrint('👋 Reset to guest limits: $guestLimits');
    } catch (e) {
      debugPrint('❌ Failed to handle user logout: $e');
    }
  }

  /// Reload user data when user changes
  Future<void> _reloadUserData() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState) ?? _generateGuestId();
      _currentUserId = userId; // Update current user ID
      
      await _loadUserData(userId);
      await _checkDailyReset();
      
      debugPrint('✅ User data reloaded for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to reload user data: $e');
    }
  }

  /// Load user data from unified storage
  Future<void> _loadUserData(String userId) async {
    try {
      final unifiedData = await UnifiedUsageStorage.getUsageData(userId);
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthStateAuthenticated;
      
      // Calculate current limits (may differ from stored limits due to config changes)
      final currentLimits = _calculateDailyLimits(isAuthenticated);
      
      // Use stored data but update limits if needed
      final finalLimits = unifiedData.dailyLimits.isEmpty ? currentLimits : unifiedData.dailyLimits;
      
      state = state.copyWith(
        actionCounts: unifiedData.actionCounts,
        dailyLimits: finalLimits,
        lastReset: unifiedData.lastReset,
        hasReachedLimit: _checkIfLimitReached(unifiedData.actionCounts, finalLimits),
      );
      
      debugPrint('📖 Loaded unified data for: $userId');
      debugPrint('📊 Data: ${unifiedData.toDebugString()}');
    } catch (e) {
      debugPrint('❌ Failed to load user data: $e');
    }
  }

  /// Check and perform daily reset if needed
  Future<void> _checkDailyReset() async {
    try {
      final now = DateTime.now();
      final lastReset = state.lastReset;
      
      // Handle edge cases: future dates (clock changes), very old dates
      if (lastReset.isAfter(now)) {
        debugPrint('🔄 Future reset date detected (clock change?) - forcing reset');
        await _performDailyReset();
        return;
      }
      
      // Check if more than 24 hours have passed (handles clock changes better)
      final hoursSinceReset = now.difference(lastReset).inHours;
      if (hoursSinceReset >= 24) {
        debugPrint('🔄 Daily reset triggered: ${hoursSinceReset}h since last reset');
        await _performDailyReset();
        return;
      }
      
      // Standard day change check (more reliable than date comparison)
      final nowDate = DateTime(now.year, now.month, now.day);
      final resetDate = DateTime(lastReset.year, lastReset.month, lastReset.day);
      
      if (nowDate.isAfter(resetDate)) {
        debugPrint('🔄 Daily reset triggered: ${resetDate.day}/${resetDate.month} → ${nowDate.day}/${nowDate.month}');
        await _performDailyReset();
      }
    } catch (e) {
      debugPrint('❌ Daily reset check failed: $e');
      // Fallback: if reset logic fails, don't block the user
      // but log the error for debugging
    }
  }

  /// Perform daily reset
  Future<void> _performDailyReset() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState) ?? _generateGuestId();
      
      // Reset usage data
      await UnifiedUsageStorage.resetDailyUsage(userId);
      
      // Update state
      state = state.copyWith(
        actionCounts: {},
        lastReset: DateTime.now(),
        hasReachedLimit: false,
      );
      
      debugPrint('✅ Daily reset completed for: $userId');
    } catch (e) {
      debugPrint('❌ Daily reset failed: $e');
    }
  }

  /// Record an action and update storage
  Future<ActionResult> recordAction(ActionType actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!AuthConfig.enableUsageLimits) {
      debugPrint('💡 Usage limits disabled - allowing action');
      return ActionResult.success();
    }

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState) ?? _generateGuestId();
      
      // Ensure daily reset check
      await _checkDailyReset();
      
      final actionKey = _getActionKey(actionType);
      final currentCount = state.actionCounts[actionKey] ?? 0;
      final limit = state.dailyLimits[actionKey] ?? 0;
      final totalUsage = getTotalUsage();
      final totalLimit = getTotalLimit();
      
      // Check combined quota limit (primary check)
      if (totalUsage >= totalLimit) {
        debugPrint('🚫 Action blocked - combined quota exceeded: $totalUsage/$totalLimit');
        state = state.copyWith(hasReachedLimit: true);
        return ActionResult.limitReached(
          currentUsage: totalUsage,
          limit: totalLimit,
          resetTime: _getTimeUntilReset(),
        );
      }

      // Record the action
      final newCounts = Map<String, int>.from(state.actionCounts);
      newCounts[actionKey] = currentCount + 1;
      final newTotalUsage = newCounts.values.fold(0, (sum, count) => sum + count);
      
      // Update state immediately
      state = state.copyWith(
        actionCounts: newCounts,
        hasReachedLimit: newTotalUsage >= totalLimit,
      );
      
      // Update storage asynchronously
      _updateStorageAsync(userId, newCounts);
      
      debugPrint('📊 Action recorded: $actionKey (${newCounts[actionKey]}/$limit, total: $newTotalUsage/$totalLimit)');
      
      // Return success with usage info
      return ActionResult.success(
        remainingActions: totalLimit - newTotalUsage,
        warningMessage: _getWarningMessage(totalLimit - newTotalUsage, authState is AuthStateAuthenticated),
      );
      
    } catch (e) {
      debugPrint('❌ Failed to record action: $e');
      return ActionResult.error('Failed to record action: $e');
    }
  }

  /// Get warning message when approaching limit
  String? _getWarningMessage(int remaining, bool isAuthenticated) {
    if (remaining <= 0) return null;
    if (remaining == 1) {
      return isAuthenticated 
        ? 'This is your last action today!'
        : 'This is your last guest action! Sign in for more.';
    }
    if (remaining == 2 && !isAuthenticated) {
      return '2 actions left! Sign in to get 5 daily actions.';
    }
    return null;
  }

  /// Update storage asynchronously (non-blocking)
  void _updateStorageAsync(String userId, Map<String, int> newCounts) {
    UnifiedUsageStorage.getUsageData(userId).then((currentData) {
      final updatedData = currentData.copyWith(
        actionCounts: newCounts,
        hasReachedLimit: _checkIfLimitReached(newCounts, currentData.dailyLimits),
      );
      return UnifiedUsageStorage.storeUsageData(userId, updatedData);
    }).catchError((e) {
      debugPrint('⚠️ Failed to update storage asynchronously: $e');
    });
  }

  /// Check if user can perform a specific action
  bool canPerformAction(ActionType actionType) {
    if (!AuthConfig.enableUsageLimits) {
      return true;
    }
    
    final actionKey = _getActionKey(actionType);
    final currentCount = state.actionCounts[actionKey] ?? 0;
    final limit = state.dailyLimits[actionKey] ?? 0;
    
    return currentCount < limit;
  }

  /// Get remaining actions for a specific action type
  int getRemainingActions(ActionType actionType) {
    final actionKey = _getActionKey(actionType);
    final currentCount = state.actionCounts[actionKey] ?? 0;
    final limit = state.dailyLimits[actionKey] ?? 0;
    
    return (limit - currentCount).clamp(0, limit);
  }

  /// Get comprehensive usage status for UI
  UsageStatus getUsageStatus() {
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;
    final totalUsage = getTotalUsage();
    final totalLimit = getTotalLimit();
    final remainingActions = totalLimit - totalUsage;
    final resetTime = _getTimeUntilReset();
    
    return UsageStatus(
      totalUsage: totalUsage,
      totalLimit: totalLimit,
      remainingActions: remainingActions,
      isAuthenticated: isAuthenticated,
      resetTime: resetTime,
      progressPercentage: (totalUsage / totalLimit * 100).clamp(0, 100).round(),
      canPerformActions: remainingActions > 0,
      statusMessage: _getOverallStatusMessage(remainingActions, resetTime, isAuthenticated),
    );
  }

  /// Get total usage across all action types
  int getTotalUsage() {
    return state.actionCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Get overall status message
  String _getOverallStatusMessage(int remaining, String resetTime, bool isAuthenticated) {
    if (remaining <= 0) {
      return isAuthenticated 
        ? 'Daily limit reached. Resets in $resetTime.'
        : 'Guest limit reached. Sign in for 5 daily actions!';
    } else if (remaining == 1) {
      return '1 action remaining (resets in $resetTime)';
    } else if (remaining <= 2 && !isAuthenticated) {
      return '$remaining actions left. Sign in for more!';
    } else {
      return '$remaining actions remaining today';
    }
  }

  /// Get total limit across all action types
  int getTotalLimit() {
    // 🎯 COMBINED QUOTA SYSTEM: Return actual combined limit, not sum of individual limits
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;
    
    // True combined quota: 3 for guests, 5 for authenticated users
    return isAuthenticated ? 5 : 3;
  }

  /// Get usage message for UI display
  String getUsageMessage(ActionType actionType) {
    if (!AuthConfig.enableUsageLimits) return '';
    
    final remaining = getRemainingActions(actionType);
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthStateAuthenticated;
    
    if (remaining <= 0) {
      final resetTime = _getTimeUntilReset();
      return isAuthenticated 
        ? 'Daily limit reached. Resets in $resetTime.'
        : 'Guest limit reached. Sign in for more actions.';
    } else if (remaining == 1) {
      final resetTime = _getTimeUntilReset();
      return '$remaining action remaining (resets in $resetTime)';
    } else {
      return '$remaining actions remaining today';
    }
  }

  /// Get user-friendly time until reset
  String _getTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    
    if (diff.inHours > 1) {
      return '${diff.inHours} hours';
    } else if (diff.inHours == 1) {
      return '1 hour ${diff.inMinutes % 60}min';
    } else if (diff.inMinutes > 1) {
      return '${diff.inMinutes} minutes';
    } else {
      return '1 minute';
    }
  }

  /// Helper: Extract user ID from auth state
  String? _getUserId(AuthState authState) {
    if (authState is AuthStateAuthenticated) {
      final user = authState.user;
      if (user is Map<String, dynamic>) {
        return user['id']?.toString();
      }
      // Handle Supabase User object
      try {
        return (user as dynamic).id;
      } catch (e) {
        return null;
      }
    } else if (authState is AuthStateGuest) {
      return authState.guestId;
    }
    return null;
  }

  /// Helper: Generate guest ID
  String _generateGuestId() {
    return 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Helper: Calculate daily limits based on authentication status
  Map<String, int> _calculateDailyLimits(bool isAuthenticated) {
    // 🎯 COMBINED QUOTA SYSTEM: Set individual limits to combined limit
    // Combined enforcement is handled by getTotalLimit() and enforcer logic
    // Individual limits are set high to avoid conflicts with combined enforcement
    
    final combinedLimit = isAuthenticated ? 5 : 3;
    
    return {
      'flashcard_grading': combinedLimit,      // Set to combined limit
      'interview_practice': combinedLimit,     // to avoid any conflicts
      'content_generation': combinedLimit,     // with combined enforcement
      'ai_assistance': combinedLimit,          // (actual limit enforced by getTotalLimit())
    };
  }

  /// Helper: Convert ActionType to storage key
  String _getActionKey(ActionType actionType) {
    switch (actionType) {
      case ActionType.flashcardGrading:
        return 'flashcard_grading';
      case ActionType.interviewPractice:
        return 'interview_practice';
      case ActionType.contentGeneration:
        return 'content_generation';
      case ActionType.aiAssistance:
        return 'ai_assistance';
    }
  }

  /// Helper: Check if any limit is reached
  bool _checkIfLimitReached(Map<String, int> counts, Map<String, int> limits) {
    for (final entry in counts.entries) {
      final limit = limits[entry.key] ?? 0;
      if (entry.value >= limit) {
        return true;
      }
    }
    return false;
  }

  /// Helper: Get debug state string
  String _getStateDebugString() {
    final totalUsage = getTotalUsage();
    final totalLimit = getTotalLimit();
    return 'Usage: $totalUsage/$totalLimit, Counts: ${state.actionCounts}, Limits: ${state.dailyLimits}';
  }

  /// Debug method: Reset all actions for testing
  Future<void> resetAllActions() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = _getUserId(authState) ?? _generateGuestId();
      
      await UnifiedUsageStorage.resetDailyUsage(userId);
      
      state = state.copyWith(
        actionCounts: {},
        lastReset: DateTime.now(),
        hasReachedLimit: false,
      );
      
      debugPrint('🔄 Debug: All actions reset for $userId');
    } catch (e) {
      debugPrint('❌ Failed to reset actions: $e');
    }
  }

  /// Debug method: Get storage overview
  Future<Map<String, dynamic>> getStorageOverview() async {
    return await UnifiedUsageStorage.getStorageOverview();
  }
}

// ✅ UPDATED PROVIDER DEFINITIONS
final unifiedActionTrackerProvider = StateNotifierProvider<UnifiedActionTracker, UserActionState>((ref) {
  return UnifiedActionTracker(ref);
});

// Enhanced usage status provider
final usageStatusProvider = Provider<UsageStatus>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getUsageStatus();
});

// Convenience providers for specific action types
final canPerformFlashcardGradingProvider = Provider<bool>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.canPerformAction(ActionType.flashcardGrading);
});

final canPerformInterviewPracticeProvider = Provider<bool>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.canPerformAction(ActionType.interviewPractice);
});

final remainingFlashcardActionsProvider = Provider<int>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getRemainingActions(ActionType.flashcardGrading);
});

final remainingInterviewActionsProvider = Provider<int>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getRemainingActions(ActionType.interviewPractice);
});

final flashcardUsageMessageProvider = Provider<String>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getUsageMessage(ActionType.flashcardGrading);
});

final interviewUsageMessageProvider = Provider<String>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getUsageMessage(ActionType.interviewPractice);
});

final totalUsageProvider = Provider<int>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getTotalUsage();
});

final totalLimitProvider = Provider<int>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.getTotalLimit();
});

/// Provider to access current user ID for migration purposes
final currentTrackedUserIdProvider = Provider<String?>((ref) {
  final tracker = ref.watch(unifiedActionTrackerProvider.notifier);
  return tracker.currentUserId;
});
