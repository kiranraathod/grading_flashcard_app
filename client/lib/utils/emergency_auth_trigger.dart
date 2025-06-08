import 'package:flutter/material.dart';
import '../services/guest_session_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/config.dart';
import '../widgets/authentication_popup.dart';

/// Emergency authentication trigger for forcing authentication popups
/// 
/// Provides utilities to check authentication status and force popups when needed
class EmergencyAuthTrigger {
  
  /// Check authentication status and force popup if needed
  static void checkAndTrigger(BuildContext context) {
    final guestSession = GuestSessionService();
    final authService = SupabaseAuthService();
    
    debugPrint('🚨 Emergency Auth Check:');
    debugPrint('  Usage: ${guestSession.usageCount}/${AppConfig.guestUsageLimit}');
    debugPrint('  Reached limit: ${guestSession.hasReachedLimit}');
    debugPrint('  Authenticated: ${authService.isAuthenticated}');
    debugPrint('  Limits enabled: ${AppConfig.enableUsageLimits}');
    debugPrint('  Auth enforced: ${AppConfig.enforceAuthentication}');
    
    if (guestSession.hasReachedLimit && 
        !authService.isAuthenticated &&
        AppConfig.enableUsageLimits && 
        AppConfig.enforceAuthentication) {
      
      debugPrint('🚨 EMERGENCY: Triggering auth popup NOW');
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AuthenticationPopup(),
          );
        }
      });
    }
  }
  
  /// Force trigger authentication popup regardless of conditions
  static void forceTrigger(BuildContext context) {
    debugPrint('🚨 FORCE: Triggering auth popup');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AuthenticationPopup(),
        );
      }
    });
  }
}
