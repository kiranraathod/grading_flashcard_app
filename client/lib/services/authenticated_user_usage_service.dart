import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/config.dart';
import 'reliable_operation_service.dart';
import 'supabase_auth_service.dart';

/// AuthenticatedUserUsageService manages usage tracking for authenticated users
/// 
/// Tracks usage for authenticated users with actual limits but shows "unlimited" in UI
/// to enhance user experience while maintaining reasonable usage limits.
class AuthenticatedUserUsageService extends ChangeNotifier {
  // Singleton pattern
  static final AuthenticatedUserUsageService _instance = AuthenticatedUserUsageService._internal();
  factory AuthenticatedUserUsageService() => _instance;
  AuthenticatedUserUsageService._internal();

  final ReliableOperationService _reliableOps = ReliableOperationService();
  final SupabaseAuthService _auth = SupabaseAuthService();
  
  int _usageCount = 0;
  DateTime? _lastActivity;
  String? _currentUserId;
  bool _isInitialized = false;

  // Getters
  int get usageCount => _usageCount;
  DateTime? get lastActivity => _lastActivity;
  String? get currentUserId => _currentUserId;
  bool get isInitialized => _isInitialized;
  
  // Actual limit check (internal use)
  bool get hasReachedActualLimit => _usageCount >= AppConfig.authenticatedUserLimit;
  
  // UI display (always shows as unlimited for better UX)
  bool get hasReachedDisplayLimit => false; // Always false for "unlimited" experience
  String get displayUsageText => AppConfig.showUnlimitedForAuth ? "Unlimited access" : "$_usageCount/${AppConfig.authenticatedUserLimit}";
  
  /// Initialize authenticated user usage tracking
  Future<void> initialize() async {
    await _reliableOps.withFallback(
      primary: () async {
        _currentUserId = _auth.currentUser?.id;
        if (_currentUserId != null) {
          await _loadUsageData();
        }
        _isInitialized = true;
        notifyListeners();
        debugPrint('✅ AuthenticatedUserUsageService: Initialized for user $_currentUserId');
      },
      fallback: () async {
        _isInitialized = true;
        notifyListeners();
        debugPrint('⚠️ AuthenticatedUserUsageService: Initialized with fallback');
      },
      operationName: 'auth_user_usage_initialization',
    );
  }

  /// Load usage data for current user
  Future<void> _loadUsageData() async {
    if (_currentUserId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userUsageKey = '${AppConfig.authUserUsageKey}_$_currentUserId';
    
    _usageCount = prefs.getInt(userUsageKey) ?? 0;
    final lastActivityMs = prefs.getInt('${userUsageKey}_last_activity');
    _lastActivity = lastActivityMs != null ? DateTime.fromMillisecondsSinceEpoch(lastActivityMs) : null;
    
    debugPrint('📊 AuthenticatedUserUsageService: Loaded usage count: $_usageCount for user $_currentUserId');
  }

  /// Track usage for authenticated user
  Future<bool> trackUsage({required String actionType}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_currentUserId == null) {
      debugPrint('⚠️ AuthenticatedUserUsageService: No authenticated user');
      return false;
    }

    return await _reliableOps.withDefault(
      operation: () async {
        // Check actual limit (internal)
        if (hasReachedActualLimit) {
          debugPrint('🚫 AuthenticatedUserUsageService: Actual limit reached ($_usageCount/${AppConfig.authenticatedUserLimit})');
          // Still return true to maintain "unlimited" experience
          // but we track it internally for analytics/monitoring
          _logLimitExceeded(actionType);
          return true; // Allow action but log it
        }

        // Increment usage
        _usageCount++;
        _lastActivity = DateTime.now();
        
        // Save to local storage
        await _saveUsageData();
        
        // Track in Supabase for analytics (optional)
        _trackInSupabase(actionType);
        
        notifyListeners();
        
        debugPrint('📈 AuthenticatedUserUsageService: Tracked $actionType (Usage: $_usageCount/${AppConfig.authenticatedUserLimit})');
        
        return true;
      },
      defaultValue: true, // Always allow for authenticated users
      operationName: 'track_authenticated_user_usage',
    );
  }

  /// Save usage data to local storage
  Future<void> _saveUsageData() async {
    if (_currentUserId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userUsageKey = '${AppConfig.authUserUsageKey}_$_currentUserId';
    
    await prefs.setInt(userUsageKey, _usageCount);
    if (_lastActivity != null) {
      await prefs.setInt('${userUsageKey}_last_activity', _lastActivity!.millisecondsSinceEpoch);
    }
  }

  /// Track usage in Supabase for analytics
  void _trackInSupabase(String actionType) async {
    try {
      if (AppConfig.supabaseUrl.isNotEmpty && _currentUserId != null) {
        await Supabase.instance.client
            .from('user_analytics')
            .upsert({
          'user_id': _currentUserId,
          'action_type': actionType,
          'usage_count': _usageCount,
          'timestamp': DateTime.now().toIso8601String(),
        });
        debugPrint('📊 AuthenticatedUserUsageService: Tracked in Supabase');
      }
    } catch (e) {
      debugPrint('⚠️ AuthenticatedUserUsageService: Supabase tracking failed: $e');
      // Don't throw error - this is just for analytics
    }
  }

  /// Log when actual limit is exceeded (for monitoring)
  void _logLimitExceeded(String actionType) {
    debugPrint('⚠️ AuthenticatedUserUsageService: User $_currentUserId exceeded limit with action: $actionType');
    // Could send analytics event here for monitoring heavy users
  }

  /// Reset usage count (for testing or new billing cycle)
  Future<void> resetUsage() async {
    await _reliableOps.safely(
      operation: () async {
        _usageCount = 0;
        _lastActivity = null;
        await _saveUsageData();
        notifyListeners();
        debugPrint('🔄 AuthenticatedUserUsageService: Usage reset for user $_currentUserId');
      },
      operationName: 'reset_authenticated_user_usage',
    );
  }

  /// Handle user authentication change
  Future<void> onUserChanged(String? newUserId) async {
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      if (newUserId != null) {
        await _loadUsageData();
      } else {
        _usageCount = 0;
        _lastActivity = null;
      }
      notifyListeners();
      debugPrint('👤 AuthenticatedUserUsageService: User changed to $_currentUserId');
    }
  }

  /// Get usage status for display
  Map<String, dynamic> getUsageStatus() {
    return {
      'userId': _currentUserId,
      'usageCount': _usageCount,
      'actualLimit': AppConfig.authenticatedUserLimit,
      'displayText': displayUsageText,
      'showAsUnlimited': AppConfig.showUnlimitedForAuth,
      'hasReachedActualLimit': hasReachedActualLimit,
      'hasReachedDisplayLimit': hasReachedDisplayLimit,
      'lastActivity': _lastActivity?.toIso8601String(),
    };
  }

  /// Check if user can perform action (always true for better UX)
  bool canPerformAction() {
    return true; // Always allow for authenticated users to maintain "unlimited" experience
  }

  /// Get remaining actions (-1 indicates unlimited for display)
  int getRemainingActions() {
    if (AppConfig.showUnlimitedForAuth) {
      return -1; // Unlimited display
    } else {
      return (AppConfig.authenticatedUserLimit - _usageCount).clamp(0, AppConfig.authenticatedUserLimit);
    }
  }
}
