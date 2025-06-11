import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';
import 'simple_error_handler.dart';
import 'authentication_service.dart';

/// Guest user manager for tracking usage limits
/// 
/// Tracks grading actions for unauthenticated users and enforces limits.
/// Follows existing service patterns with reliable error handling.
class GuestUserManager extends ChangeNotifier {
  static GuestUserManager? _instance;
  static GuestUserManager get instance => _instance ??= GuestUserManager._();
  
  final AuthenticationService _authService = AuthenticationService.instance;
  
  int _guestGradingCount = 0;
  bool _hasReachedLimit = false;
  
  // Storage keys
  static const String _guestGradingCountKey = 'guest_grading_count';
  static const String _lastResetDateKey = 'guest_limit_reset_date';
  
  // Private constructor
  GuestUserManager._();
  
  /// Current grading count for guest user
  int get guestGradingCount => _guestGradingCount;
  
  /// Whether guest user has reached the limit
  bool get hasReachedLimit => _hasReachedLimit;
  
  /// Remaining grading actions for guest user
  int get remainingActions {
    if (_authService.isAuthenticated) {
      return AuthConfig.authenticatedMaxGradingActions - _guestGradingCount;
    }
    return AuthConfig.guestMaxGradingActions - _guestGradingCount;
  }
  
  /// Maximum allowed actions for current user type
  int get maxActions {
    return _authService.isAuthenticated 
        ? AuthConfig.authenticatedMaxGradingActions
        : AuthConfig.guestMaxGradingActions;
  }
  
  /// Whether usage tracking is enabled
  bool get isEnabled => AuthConfig.enableUsageLimits || AuthConfig.enableGuestTracking;
  
  /// Initialize guest user manager
  Future<void> initialize() async {
    if (!isEnabled) {
      debugPrint('Guest user tracking disabled via feature flags');
      return;
    }
    
    await SimpleErrorHandler.safely(
      () async {
        debugPrint('Initializing GuestUserManager...');
        await _loadGradingCount();
        await _checkAndResetDaily();
        _updateLimitStatus();
        
        // 🔧 FIX: Listen for authentication state changes
        _authService.addListener(_onAuthStateChanged);
        
        debugPrint('✅ GuestUserManager initialized - Count: $_guestGradingCount');
      },
      operationName: 'guest_user_manager_initialization',
    );
  }
  
  /// Handle authentication state changes
  void _onAuthStateChanged() {
    debugPrint('🔄 Auth state changed - updating usage limits');
    debugPrint('🔍 Auth Service State: isAuthenticated=${_authService.isAuthenticated}, currentUser=${_authService.currentUser?.id}');
    debugPrint('🔍 Before update: count=$_guestGradingCount, limit=$maxActions, hasReachedLimit=$_hasReachedLimit');
    
    _updateLimitStatus();
    
    debugPrint('🔍 After update: count=$_guestGradingCount, limit=$maxActions, hasReachedLimit=$_hasReachedLimit');
    debugPrint('🔍 canPerformGradingAction() = ${canPerformGradingAction()}');
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    debugPrint('Disposing GuestUserManager');
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
  
  /// Load grading count from storage
  Future<void> _loadGradingCount() async {
    final prefs = await SharedPreferences.getInstance();
    _guestGradingCount = prefs.getInt(_guestGradingCountKey) ?? 0;
  }
  
  /// Check if we need to reset daily limit
  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_lastResetDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    
    if (lastResetDate != today) {
      debugPrint('Resetting daily guest limit - Last reset: $lastResetDate, Today: $today');
      _guestGradingCount = 0;
      await prefs.setInt(_guestGradingCountKey, 0);
      await prefs.setString(_lastResetDateKey, today);
    }
  }
  /// Update limit status based on current count
  void _updateLimitStatus() {
    _hasReachedLimit = _guestGradingCount >= maxActions;
    notifyListeners();
  }
  
  /// Record a grading action
  Future<bool> recordGradingAction() async {
    if (!isEnabled) return true; // Allow if tracking disabled
    
    return await SimpleErrorHandler.safe(
      () async {
        if (_hasReachedLimit) {
          debugPrint('🚫 Grading action blocked - limit already reached');
          return false;
        }
        
        _guestGradingCount++;
        
        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_guestGradingCountKey, _guestGradingCount);
        
        _updateLimitStatus();
        
        // 📊 TESTING LOG: Show current usage state
        debugPrint('📊 Grading action recorded ($_guestGradingCount/$maxActions)');
        
        // 🚨 TESTING LOG: Warn when limit reached
        if (_hasReachedLimit) {
          debugPrint('🚨 Usage limit reached! Next action will trigger auth modal');
        } else if (_guestGradingCount >= maxActions - 1) {
          debugPrint('⚠️ Approaching limit: $remainingActions actions remaining');
        }
        
        return true;
      },
      fallbackOperation: () async {
        debugPrint('❌ Failed to record grading action - allowing action');
        return true; // Fail open to not block user
      },
      operationName: 'record_grading_action',
    );
  }
  
  /// Check if a grading action can be performed
  bool canPerformGradingAction() {
    if (!isEnabled) return true;
    
    final canPerform = !_hasReachedLimit;
    
    // 🔍 TESTING LOG: Show permission check result
    if (!canPerform) {
      debugPrint('🔍 canPerformGradingAction() = false (limit reached)');
    }
    
    return canPerform;
  }
  
  /// Get usage message for UI
  String getUsageMessage() {
    if (!isEnabled) return '';
    
    if (_authService.isAuthenticated) {
      return 'Actions used: $_guestGradingCount/$maxActions';
    }
    
    if (_hasReachedLimit) {
      return 'Daily limit reached. Sign in for more actions!';
    }
    
    final remaining = remainingActions;
    if (remaining <= 1) {
      return '$remaining action remaining. Sign in for more!';
    }
    
    return '$remaining actions remaining today';
  }
  
  /// Reset count (for testing or admin purposes)
  Future<void> resetCount() async {
    await SimpleErrorHandler.safely(
      () async {
        _guestGradingCount = 0;
        _hasReachedLimit = false;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_guestGradingCountKey, 0);
        
        notifyListeners();
        debugPrint('Guest user count reset');
      },
      operationName: 'reset_guest_count',
    );
  }
  
  /// Clear all stored data
  Future<void> clearData() async {
    await SimpleErrorHandler.safely(
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_guestGradingCountKey);
        await prefs.remove(_lastResetDateKey);
        
        _guestGradingCount = 0;
        _hasReachedLimit = false;
        notifyListeners();
        
        debugPrint('Guest user data cleared');
      },
      operationName: 'clear_guest_data',
    );
  }
  
  // Additional methods for debug panel support
  
  /// Get current session identifier (simplified for debug purposes)
  String? get currentSessionId => 'guest_session_${DateTime.now().millisecondsSinceEpoch}';
  
  /// Get current usage count
  int get currentUsageCount => _guestGradingCount;
  
  /// Check if service is initialized
  bool get isInitialized => true; // This service is always considered initialized
  
  /// Reset session (alias for resetCount)
  Future<void> resetSession() async {
    await resetCount();
  }
  
  /// Simulate usage action for testing
  Future<void> simulateUsage() async {
    if (_guestGradingCount < maxActions) {
      await recordGradingAction();
      debugPrint('Simulated grading action - count now: $_guestGradingCount');
    } else {
      debugPrint('Cannot simulate - already at limit');
    }
  }
}
