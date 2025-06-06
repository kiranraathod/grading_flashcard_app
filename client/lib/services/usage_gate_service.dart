import 'package:flutter/foundation.dart';
import '../utils/config.dart';
import 'reliable_operation_service.dart';
import 'guest_session_service.dart';
import 'supabase_auth_service.dart';

/// UsageGateService manages usage limits and authentication prompts
/// 
/// Follows existing service patterns with ChangeNotifier and ReliableOperationService.
/// Controls when users are prompted to authenticate based on usage limits.
class UsageGateService extends ChangeNotifier {
  // Singleton pattern
  static final UsageGateService _instance = UsageGateService._internal();
  factory UsageGateService() => _instance;
  UsageGateService._internal();

  final ReliableOperationService _reliableOps = ReliableOperationService();
  final GuestSessionService _guestSession = GuestSessionService();
  final SupabaseAuthService _auth = SupabaseAuthService();
  
  bool _showingAuthPrompt = false;
  DateTime? _lastPromptShown;

  // Getters
  bool get showingAuthPrompt => _showingAuthPrompt;
  DateTime? get lastPromptShown => _lastPromptShown;
  bool get shouldShowAuthPrompt => _shouldShowAuthPrompt();

  /// Check if authentication prompt should be shown
  bool _shouldShowAuthPrompt() {
    // Never show if not authenticated user
    if (_auth.isAuthenticated) {
      return false;
    }

    // Never show if features are disabled
    if (!AppConfig.enableUsageLimits || !AppConfig.enforceAuthentication) {
      return false;
    }

    // Never show if already showing
    if (_showingAuthPrompt) {
      return false;
    }

    // Show if guest has reached the limit
    return _guestSession.hasReachedLimit;
  }

  /// Attempt to perform an action, checking usage limits
  Future<bool> attemptAction({required String actionType}) async {
    return await _reliableOps.withDefault(
      operation: () async {
        // Always allow if authenticated
        if (_auth.isAuthenticated) {
          debugPrint('✅ UsageGateService: Action allowed - authenticated user');
          return true;
        }

        // Always allow if limits disabled
        if (!AppConfig.enableUsageLimits || !AppConfig.enforceAuthentication) {
          debugPrint('🔓 UsageGateService: Action allowed - limits disabled');
          return true;
        }

        // Check guest usage
        final canPerform = await _guestSession.trackUsage(actionType: actionType);
        
        if (canPerform) {
          debugPrint('✅ UsageGateService: Action allowed - within limits');
          notifyListeners(); // Update UI in case near limit
          return true;
        } else {
          debugPrint('🚫 UsageGateService: Action blocked - limit reached');
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

  /// Get usage status summary
  Map<String, dynamic> getUsageStatus() {
    return {
      'isAuthenticated': _auth.isAuthenticated,
      'usageCount': _guestSession.usageCount,
      'usageLimit': AppConfig.guestUsageLimit,
      'remainingActions': _guestSession.getRemainingActions(),
      'hasReachedLimit': _guestSession.hasReachedLimit,
      'shouldShowAuthPrompt': shouldShowAuthPrompt,
      'limitsEnabled': AppConfig.enableUsageLimits,
      'authRequired': AppConfig.enforceAuthentication,
    };
  }

  /// Check if user is near the limit (for warning messages)
  bool isNearLimit() {
    if (_auth.isAuthenticated || !AppConfig.enableUsageLimits) {
      return false;
    }
    
    return _guestSession.isNearLimit;
  }

  /// Get remaining actions for display
  int getRemainingActions() {
    if (_auth.isAuthenticated || !AppConfig.enableUsageLimits) {
      return -1; // Unlimited
    }
    
    return _guestSession.getRemainingActions();
  }
}
