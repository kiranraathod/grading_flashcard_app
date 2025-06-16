# 🔄 IMPORT UPDATE GUIDE: Transition to Unified Storage System

## Overview

This guide helps transition from the fragmented storage system to the unified storage system.

## Import Updates Required

### 1. Provider Imports (Update these files)

**OLD IMPORTS:**
```dart
import '../providers/working_action_tracking_provider.dart';
import '../services/usage_limit_enforcer.dart';
```

**NEW IMPORTS:**
```dart
import '../providers/unified_action_tracking_provider.dart';
import '../services/unified_usage_limit_enforcer.dart';
```

### 2. Provider Name Changes

**OLD PROVIDER NAMES → NEW PROVIDER NAMES:**
```dart
// Action Tracking Provider
actionTrackerProvider → unifiedActionTrackerProvider

// Usage Limit Enforcer
usageLimitEnforcerProvider → unifiedUsageLimitEnforcerProvider

// Convenience Providers (compatible names maintained)
canPerformFlashcardGradingProvider → (same name)
canPerformInterviewPracticeProvider → (same name)
remainingFlashcardActionsProvider → (same name)
remainingInterviewActionsProvider → (same name)
flashcardUsageMessageProvider → (same name)
interviewUsageMessageProvider → (same name)

// New Unified Providers (additional functionality)
canPerformAnyActionProvider → (new)
totalRemainingActionsProvider → (new)
usageStatusMessageProvider → (new)
usageSummaryProvider → (new, for debug panels)
```

### 3. Service Method Changes

**OLD METHODS → NEW METHODS:**
```dart
// Usage Limit Enforcer
enforcer.enforceLimit() → (same signature)
enforcer.executeAction() → (same signature)
enforcer.getRemainingActions() → enforcer.getTotalRemainingActions()
enforcer.canPerformAnyAction() → (same)
enforcer.getUsageSummary() → (same, enhanced data)

// Action Tracker
tracker.recordAction() → (same signature)
tracker.canPerformAction() → (same signature)
tracker.getRemainingActions() → (same signature)
tracker.resetActions() → tracker.resetAllActions()
```

## Files That Need Updates

### High Priority (Core Usage Logic)
1. ✅ `services/action_middleware.dart` - Core middleware
2. ✅ `services/interview_api_service.dart` - API service
3. ✅ `blocs/study/study_bloc.dart` - Study logic
4. ✅ `widgets/auth_debug_panel.dart` - Debug panel
5. ✅ `widgets/app_header.dart` - Header usage display

### Medium Priority (UI Components)
6. ✅ `widgets/auth/authentication_modal.dart` - Auth modal
7. ✅ Other UI components using usage tracking

### Low Priority (Remove Completely)
8. ❌ `services/guest_user_manager.dart` - **DEPRECATED** (remove)
9. ❌ `providers/working_action_tracking_provider.dart` - **DEPRECATED** (keep for reference)
10. ❌ `services/usage_limit_enforcer.dart` - **DEPRECATED** (keep for reference)

## Step-by-Step Migration Process

### Phase 1: Update Core Services
1. Update `action_middleware.dart`
2. Update `interview_api_service.dart`
3. Update `study_bloc.dart`

### Phase 2: Update UI Components
1. Update `auth_debug_panel.dart`
2. Update `app_header.dart`
3. Update `authentication_modal.dart`

### Phase 3: Remove Legacy References
1. Comment out `GuestUserManager` initialization
2. Remove legacy provider registrations
3. Update any remaining import references

## Testing Checklist

After each file update, verify:
- [ ] App compiles without errors
- [ ] Usage limits still enforce correctly
- [ ] Authentication modal triggers at correct limits
- [ ] Debug panel shows unified data
- [ ] No duplicate tracking (check logs)

## Rollback Plan

If issues occur:
1. Revert specific file changes
2. Keep both old and new systems running temporarily
3. Use feature flags to switch between systems
4. Debug specific issues before continuing

## Key Benefits After Migration

1. **Single Source of Truth**: No more conflicting usage counts
2. **Reliable Daily Reset**: Consistent reset mechanism
3. **Better Performance**: Reduced storage operations
4. **Easier Debugging**: Unified logging and state
5. **Cleaner Architecture**: Eliminated code duplication

## Common Issues and Solutions

### Issue: "Provider not found" errors
**Solution:** Ensure new provider imports are added to all consuming widgets

### Issue: Usage counts reset unexpectedly
**Solution:** Check migration completed successfully, verify no legacy storage conflicts

### Issue: Debug panel shows empty data
**Solution:** Verify unified providers are being watched, not legacy providers

### Issue: Authentication modal not triggering
**Solution:** Ensure `unifiedUsageLimitEnforcerProvider` is being used in action middleware
