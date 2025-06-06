import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/config.dart';
import 'reliable_operation_service.dart';

/// GuestSessionService manages anonymous user sessions and usage tracking
/// 
/// Follows existing service patterns with ChangeNotifier and ReliableOperationService.
/// Implements the guest user authentication strategy with seamless data migration.
class GuestSessionService extends ChangeNotifier {
  // Singleton pattern like RecentViewService
  static final GuestSessionService _instance = GuestSessionService._internal();
  factory GuestSessionService() => _instance;
  GuestSessionService._internal();

  final ReliableOperationService _reliableOps = ReliableOperationService();
  final Uuid _uuid = const Uuid();
  
  String? _currentSessionId;
  int _usageCount = 0;
  DateTime? _lastActivity;
  bool _isInitialized = false;

  // Getters
  String? get currentSessionId => _currentSessionId;
  int get usageCount => _usageCount;
  DateTime? get lastActivity => _lastActivity;
  bool get isInitialized => _isInitialized;
  bool get hasReachedLimit => AppConfig.enableUsageLimits && _usageCount >= AppConfig.guestUsageLimit;
  bool get isNearLimit => AppConfig.enableUsageLimits && _usageCount >= (AppConfig.guestUsageLimit - 1);

  /// Initialize guest session service with existing patterns
  Future<void> initialize() async {
    await _reliableOps.withFallback(
      primary: () async {
        await _loadOrCreateSession();
        _isInitialized = true;
        notifyListeners();
        debugPrint('✅ GuestSessionService: Initialized successfully');
      },
      fallback: () async {
        _createFallbackSession();
        _isInitialized = true;
        notifyListeners();
        debugPrint('⚠️ GuestSessionService: Initialized with fallback session');
      },
      operationName: 'guest_session_initialization',
    );
  }

  /// Load existing session or create new one
  Future<void> _loadOrCreateSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentSessionId = prefs.getString(AppConfig.guestSessionKey);
    
    if (_currentSessionId == null) {
      // Create new session
      _currentSessionId = _uuid.v4();
      await prefs.setString(AppConfig.guestSessionKey, _currentSessionId!);
      debugPrint('🆕 GuestSessionService: Created new session: $_currentSessionId');
    } else {
      debugPrint('📱 GuestSessionService: Loaded existing session: $_currentSessionId');
    }
    
    // Load usage data
    _usageCount = prefs.getInt('${AppConfig.guestSessionKey}_usage') ?? 0;
    final lastActivityMs = prefs.getInt('${AppConfig.guestSessionKey}_last_activity');
    _lastActivity = lastActivityMs != null ? DateTime.fromMillisecondsSinceEpoch(lastActivityMs) : null;
    
    debugPrint('📊 GuestSessionService: Usage count: $_usageCount, Last activity: $_lastActivity');
  }

  /// Create fallback session in case of storage failure
  void _createFallbackSession() {
    _currentSessionId = _uuid.v4();
    _usageCount = 0;
    _lastActivity = null;
    debugPrint('🔄 GuestSessionService: Created fallback session: $_currentSessionId');
  }

  /// Track a usage event (flashcard flip, interview start, etc.)
  Future<bool> trackUsage({required String actionType}) async {
    if (!_isInitialized) {
      debugPrint('⚠️ GuestSessionService: Not initialized, initializing now...');
      await initialize();
    }

    return await _reliableOps.withDefault(
      operation: () async {
        if (!AppConfig.enableUsageLimits) {
          debugPrint('🔓 GuestSessionService: Usage limits disabled, allowing action: $actionType');
          return true;
        }

        if (hasReachedLimit) {
          debugPrint('🚫 GuestSessionService: Usage limit reached ($_usageCount/${AppConfig.guestUsageLimit})');
          return false;
        }

        // Call Supabase database function
        int serverUsageCount = _usageCount + 1; // Fallback value
        
        try {
          if (AppConfig.supabaseUrl.isNotEmpty && _currentSessionId != null) {
            debugPrint('📡 GuestSessionService: Calling Supabase track_guest_usage for session: $_currentSessionId');
            
            final response = await Supabase.instance.client
                .rpc('track_guest_usage', params: {'p_session_id': _currentSessionId});
            
            if (response != null) {
              serverUsageCount = response as int;
              debugPrint('✅ GuestSessionService: Supabase returned usage count: $serverUsageCount');
            }
          } else {
            debugPrint('⚠️ GuestSessionService: Supabase not configured, using local storage only');
          }
        } catch (e) {
          debugPrint('❌ GuestSessionService: Supabase call failed: $e');
          // Continue with local storage as fallback
        }

        // Update local state with server response (or incremented local value as fallback)
        _usageCount = serverUsageCount;
        _lastActivity = DateTime.now();
        
        // Save to local storage as backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('${AppConfig.guestSessionKey}_usage', _usageCount);
        await prefs.setInt('${AppConfig.guestSessionKey}_last_activity', _lastActivity!.millisecondsSinceEpoch);
        
        notifyListeners();
        
        debugPrint('📈 GuestSessionService: Tracked $actionType (Usage: $_usageCount/${AppConfig.guestUsageLimit})');
        
        return true;
      },
      defaultValue: !AppConfig.enforceAuthentication, // Allow if auth not enforced
      operationName: 'track_guest_usage',
    );
  }

  /// Check if action should be allowed
  bool canPerformAction() {
    if (!AppConfig.enableUsageLimits || !AppConfig.enforceAuthentication) {
      return true;
    }
    
    return !hasReachedLimit;
  }

  /// Get remaining actions count
  int getRemainingActions() {
    if (!AppConfig.enableUsageLimits) {
      return -1; // Unlimited
    }
    
    return (AppConfig.guestUsageLimit - _usageCount).clamp(0, AppConfig.guestUsageLimit);
  }

  /// Reset session (for testing or after authentication)
  Future<void> resetSession() async {
    await _reliableOps.safely(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        
        // Clear old session data
        await prefs.remove(AppConfig.guestSessionKey);
        await prefs.remove('${AppConfig.guestSessionKey}_usage');
        await prefs.remove('${AppConfig.guestSessionKey}_last_activity');
        
        // Create new session
        _currentSessionId = _uuid.v4();
        _usageCount = 0;
        _lastActivity = null;
        
        await prefs.setString(AppConfig.guestSessionKey, _currentSessionId!);
        
        notifyListeners();
        debugPrint('🔄 GuestSessionService: Session reset, new ID: $_currentSessionId');
      },
      operationName: 'reset_guest_session',
    );
  }

  /// Clear session data (called after successful authentication)
  Future<void> clearSession() async {
    await _reliableOps.safely(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        
        await prefs.remove(AppConfig.guestSessionKey);
        await prefs.remove('${AppConfig.guestSessionKey}_usage');
        await prefs.remove('${AppConfig.guestSessionKey}_last_activity');
        
        _currentSessionId = null;
        _usageCount = 0;
        _lastActivity = null;
        
        notifyListeners();
        debugPrint('🧹 GuestSessionService: Session cleared after authentication');
      },
      operationName: 'clear_guest_session',
    );
  }

  /// Get session summary for debugging/migration
  Map<String, dynamic> getSessionSummary() {
    return {
      'sessionId': _currentSessionId,
      'usageCount': _usageCount,
      'lastActivity': _lastActivity?.toIso8601String(),
      'hasReachedLimit': hasReachedLimit,
      'remainingActions': getRemainingActions(),
      'limitsEnabled': AppConfig.enableUsageLimits,
      'authRequired': AppConfig.enforceAuthentication,
    };
  }
}
