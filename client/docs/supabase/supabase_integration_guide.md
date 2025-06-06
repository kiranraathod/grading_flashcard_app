# Supabase Integration Guide - Updated for Guest Authentication (2025-06-06)

This comprehensive guide has been **updated** to include the guest user authentication strategy, providing a complete implementation roadmap for the FlashMaster application's migration to Supabase with seamless user onboarding.

## Table of Contents - Updated

1. [Authentication Strategy Implementation](#authentication-strategy) 🆕
2. [Database Setup & Guest Support](#database-setup) 
3. [Flutter Services with Feature Flags](#flutter-services) 🆕
4. [Usage Tracking & Migration](#usage-tracking) 🆕
5. [Testing Strategy](#testing-strategy)
6. [Deployment with Zero Disruption](#deployment) 🆕

## 1. Authentication Strategy Implementation 🆕

### 1.1 Core Principles

**Guest-First Experience**:
- Users can immediately access all core features
- 3-action limit encourages sign-up without being restrictive
- Seamless data migration preserves user investment

**Testing-Friendly Development**:
- Feature flags allow complete testing without restrictions
- Database functions tested independently of UI
- Gradual rollout minimizes risk

### 1.2 Implementation Phases

**Phase 0: Database Foundation** (Week 1-2)
```sql
-- Create Supabase project
-- Deploy schema v2 with guest support
-- Test track_guest_usage() function
-- Test migrate_guest_data_to_user() function
-- Verify all database constraints
```

**Phase 1: Flutter Services** (Week 3-4)
```dart
// Implement services with feature flags
AuthConfig.ENABLE_USAGE_LIMITS = false;  // Testing mode
AuthConfig.ENFORCE_AUTHENTICATION = false;  // Testing mode

// Test authentication flow without restrictions
// Verify data migration works correctly
```

## 2. Database Setup & Guest Support

### 2.1 Essential Schema Updates

**Guest Session Tracking**:
```sql
CREATE TABLE public.guest_sessions (
  session_id TEXT UNIQUE NOT NULL,
  usage_count INTEGER DEFAULT 0,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Dual Ownership Pattern**:
All data tables support both `user_id` and `guest_session_id`:
```sql
CONSTRAINT check_owner CHECK (
  (user_id IS NOT NULL AND guest_session_id IS NULL) OR
  (user_id IS NULL AND guest_session_id IS NOT NULL)
);
```

## 3. Flutter Services with Feature Flags 🆕

### 3.1 Configuration Service

```dart
// lib/config/auth_config.dart
class AuthConfig {
  // Feature flags for safe testing
  static const bool ENABLE_USAGE_LIMITS = false; // ⚠️ Start disabled
  static const bool ENFORCE_AUTHENTICATION = false; // ⚠️ Start disabled
  static const int GUEST_USAGE_LIMIT = 3;
  
  // Easy testing controls
  static bool get isTestingMode => !ENABLE_USAGE_LIMITS;
  static bool get allowUnlimitedGuest => !ENFORCE_AUTHENTICATION;
}
```

### 3.2 Guest Session Service

```dart
// lib/services/guest_session_service.dart
class GuestSessionService {
  Future<int> trackUsageEvent() async {
    // Skip tracking in testing mode
    if (AuthConfig.isTestingMode) {
      return 0; // Always allow in testing
    }
    
    final sessionId = await getOrCreateSessionId();
    return await _supabase.rpc('track_guest_usage', 
      params: {'p_session_id': sessionId}
    );
  }
  
  Future<bool> isUsageLimitReached() async {
    if (AuthConfig.allowUnlimitedGuest) {
      return false; // Never limit in testing
    }
    // Check actual usage count
  }
}
```

### 3.3 Authentication Service

```dart
// lib/services/supabase_auth_service.dart
class SupabaseAuthService extends ChangeNotifier {
  Future<bool> signInWithGoogle() async {
    // Google OAuth implementation
    final response = await _supabase.auth.signInWithOAuth(Provider.google);
    
    // Trigger data migration after successful login
    if (response && _currentUser != null) {
      await _handlePostLoginMigration();
    }
    
    return response;
  }
  
  Future<void> _handlePostLoginMigration() async {
    // Migrate guest data to user account
    final sessionId = await _guestService.getOrCreateSessionId();
    final result = await _supabase.rpc('migrate_guest_data_to_user', 
      params: {
        'p_user_id': _currentUser!.id,
        'p_guest_session_id': sessionId,
      }
    );
    
    if (result['success'] == true) {
      await _guestService.clearSession();
    }
  }
}
```

## 4. Testing Strategy

### 4.1 Database Testing First

```sql
-- Test usage tracking
SELECT track_guest_usage('test-session-123');
SELECT * FROM guest_sessions WHERE session_id = 'test-session-123';

-- Test data migration
SELECT migrate_guest_data_to_user('test-user-id', 'test-session-123');
```

### 4.2 Flutter Testing with Feature Flags

```dart
// Start with restrictions disabled
// Test all authentication flows
// Verify data migration works
// Only then enable restrictions for team testing
```

## 5. Deployment Strategy

**Week 1-2**: Database setup and testing  
**Week 3-4**: Flutter implementation (restrictions off)  
**Week 5-6**: Team testing with restrictions  
**Week 7-8**: Limited user rollout  
**Week 9-10**: Full production deployment

**Zero User Disruption**: Users continue normal usage throughout development
