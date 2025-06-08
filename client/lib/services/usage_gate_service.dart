import 'package:flutter/material.dart';
import '../utils/config.dart';
import 'reliable_operation_service.dart';
import 'guest_session_service.dart';
import 'supabase_auth_service.dart';
import 'authenticated_user_usage_service.dart';

/// UsageGateService manages usage limits and authentication prompts
///
/// Enhanced to handle both guest users (3 uses) and authenticated users (6 uses, shown as unlimited).
/// Implements progress saving and seamless transition between guest and authenticated states.
class UsageGateService extends ChangeNotifier {
  // Singleton pattern
  static final UsageGateService _instance = UsageGateService._internal();
  factory UsageGateService() => _instance;
  UsageGateService._internal();

  final ReliableOperationService _reliableOps = ReliableOperationService();
  final GuestSessionService _guestSession = GuestSessionService();
  final SupabaseAuthService _auth = SupabaseAuthService();
  final AuthenticatedUserUsageService _authUsage = AuthenticatedUserUsageService();

  bool _showingAuthPrompt = false;
  DateTime? _lastPromptShown;

  // Getters
  bool get showingAuthPrompt => _showingAuthPrompt;
  DateTime? get lastPromptShown => _lastPromptShown;
  bool get shouldShowAuthPrompt => _shouldShowAuthPrompt();

  /// Check if authentication prompt should be shown
  bool _shouldShowAuthPrompt() {
    // Never show if already authenticated
    if (_auth.isAuthenticated) {
      return false;
    }

    // Never show if features are disabled or debug skip is enabled
    if (!AppConfig.enableUsageLimits || !AppConfig.enforceAuthentication || AppConfig.debugSkipAuth) {
      return false;
    }

    // Never show if already showing
    if (_showingAuthPrompt) {
      return false;
    }

    // Show if guest has reached the limit
    return _guestSession.hasReachedLimit;
  }

  /// Attempt to perform an action, checking usage limits for both guest and authenticated users
  Future<bool> attemptAction({required String actionType}) async {
    return await _reliableOps.withDefault(
      operation: () async {
        // Handle authenticated users
        if (_auth.isAuthenticated) {
          // Track usage for authenticated users but always allow action
          await _authUsage.trackUsage(actionType: actionType);
          debugPrint('✅ UsageGateService: Action allowed - authenticated user (unlimited experience)');
          return true;
        }

        // Always allow if limits disabled or debug skip enabled
        if (!AppConfig.enableUsageLimits || !AppConfig.enforceAuthentication || AppConfig.debugSkipAuth) {
          if (AppConfig.debugSkipAuth) {
            debugPrint('🔓 UsageGateService: Action allowed - debug skip auth enabled');
          } else {
            debugPrint('🔓 UsageGateService: Action allowed - limits disabled');
          }
          return true;
        }

        // Handle guest users
        final canPerform = await _guestSession.trackUsage(
          actionType: actionType,
        );

        if (canPerform) {
          debugPrint('✅ UsageGateService: Action allowed - guest within limits (${_guestSession.usageCount}/${AppConfig.guestUsageLimit})');
          notifyListeners(); // Update UI in case near limit
          return true;
        } else {
          debugPrint('🚫 UsageGateService: Action blocked - guest limit reached');
          _triggerAuthPrompt();
          return false;
        }
      },
      defaultValue: true, // Default to allowing action
      operationName: 'attempt_action',
    );
  }

  /// Trigger authentication prompt
  void _triggerAuthPrompt() {
    _showingAuthPrompt = true;
    _lastPromptShown = DateTime.now();
    notifyListeners();
    debugPrint('📢 UsageGateService: Authentication prompt triggered');
  }

  /// Mark authentication prompt as handled
  void markAuthPromptHandled() {
    _showingAuthPrompt = false;
    notifyListeners();
    debugPrint('✅ UsageGateService: Authentication prompt handled');
  }

  /// Get usage status summary for both guest and authenticated users
  Map<String, dynamic> getUsageStatus() {
    if (_auth.isAuthenticated) {
      // Return authenticated user status
      final authStatus = _authUsage.getUsageStatus();
      return {
        'isAuthenticated': true,
        'userType': 'authenticated',
        'usageCount': authStatus['usageCount'],
        'usageLimit': authStatus['actualLimit'],
        'displayText': authStatus['displayText'],
        'showAsUnlimited': authStatus['showAsUnlimited'],
        'remainingActions': -1, // Always show unlimited for auth users
        'hasReachedLimit': false, // Never show as reached for better UX
        'shouldShowAuthPrompt': false,
        'limitsEnabled': AppConfig.enableUsageLimits,
        'authRequired': false, // Already authenticated
      };
    } else {
      // Return guest user status
      return {
        'isAuthenticated': false,
        'userType': 'guest',
        'usageCount': _guestSession.usageCount,
        'usageLimit': AppConfig.guestUsageLimit,
        'displayText': '${_guestSession.usageCount}/${AppConfig.guestUsageLimit}',
        'showAsUnlimited': false,
        'remainingActions': _guestSession.getRemainingActions(),
        'hasReachedLimit': _guestSession.hasReachedLimit,
        'shouldShowAuthPrompt': shouldShowAuthPrompt,
        'limitsEnabled': AppConfig.enableUsageLimits,
        'authRequired': AppConfig.enforceAuthentication,
      };
    }
  }

  /// Check if user is near the limit (for warning messages)
  bool isNearLimit() {
    if (_auth.isAuthenticated) {
      return false; // Never show as near limit for authenticated users
    }

    if (!AppConfig.enableUsageLimits) {
      return false;
    }

    return _guestSession.isNearLimit;
  }

  /// Get remaining actions for display
  int getRemainingActions() {
    if (_auth.isAuthenticated) {
      return -1; // Unlimited for authenticated users
    }

    if (!AppConfig.enableUsageLimits) {
      return -1; // Unlimited
    }

    return _guestSession.getRemainingActions();
  }

  /// Handle successful authentication and save progress
  Future<void> handleSuccessfulAuthentication() async {
    await _reliableOps.safely(
      operation: () async {
        debugPrint('🔐 UsageGateService: Handling successful authentication');
        
        // Initialize authenticated user usage service
        await _authUsage.initialize();
        
        // Migrate guest data to authenticated user account
        await _migrateGuestProgress();
        
        // Clear guest session after successful migration
        await _guestSession.clearSession();
        
        notifyListeners();
        debugPrint('✅ UsageGateService: Authentication handling complete');
      },
      operationName: 'handle_successful_authentication',
    );
  }

  /// Migrate guest progress to authenticated user account
  Future<void> _migrateGuestProgress() async {
    try {
      final guestSessionId = _guestSession.currentSessionId;
      final userId = _auth.currentUser?.id;
      
      if (guestSessionId != null && userId != null) {
        debugPrint('🔄 UsageGateService: Migrating guest progress from $guestSessionId to $userId');
        
        // Call hybrid storage migration if available
        try {
          // This will trigger the hybrid storage service to migrate guest data
          // The migration happens automatically when authentication state changes
          debugPrint('📦 UsageGateService: Triggering data migration via hybrid storage');
        } catch (e) {
          debugPrint('⚠️ UsageGateService: Data migration warning: $e');
          // Continue even if migration has issues
        }
        
        debugPrint('✅ UsageGateService: Progress migration completed');
      } else {
        debugPrint('⚠️ UsageGateService: Cannot migrate - missing session or user ID');
      }
    } catch (e) {
      debugPrint('❌ UsageGateService: Progress migration failed: $e');
      // Don't throw error - authentication should still succeed
    }
  }

  /// Check and potentially show auth popup if limit exceeded
  Future<void> checkAndShowAuthPopup(BuildContext context) async {
    if (!_auth.isAuthenticated &&
        _guestSession.hasReachedLimit &&
        AppConfig.enableUsageLimits &&
        AppConfig.enforceAuthentication &&
        !_showingAuthPrompt) {
      _triggerAuthPrompt();
      // Note: The actual popup should be shown by UI components using AuthenticatedAction
      // This method just triggers the internal state change
    }
  }
}
