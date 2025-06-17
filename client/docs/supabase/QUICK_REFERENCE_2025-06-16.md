# FlashMaster Unified System - Quick Reference

**Date**: June 16, 2025  
**Version**: 3.0  
**Status**: Production Ready  

---

## 🚀 **Quick Start**

### **Current Provider Names** (Use These!)
```dart
// ✅ MAIN PROVIDERS
unifiedActionTrackerProvider           // State management
unifiedUsageLimitEnforcerProvider      // Quota enforcement  
unifiedActionMiddlewareProvider        // Action wrapping

// ✅ CONVENIENCE PROVIDERS
canPerformAnyActionProvider           // bool: can perform any action
totalRemainingActionsProvider         // int: total remaining actions
usageStatusMessageProvider            // String: user-friendly status
```

### **Quick Usage Pattern**
```dart
// In any ConsumerWidget:
final middleware = ref.read(unifiedActionMiddlewareProvider);

// Execute action with automatic quota enforcement:
final result = await middleware.executeWithQuota(
  ActionType.flashcardGrading,
  () async => performYourAction(),
  context: context,        // Required for auth modal
  source: 'your_screen',   // For debugging
);
```

---

## 📊 **Current Quota System**

| User Type | Total Actions | Auth Trigger |
|-----------|---------------|--------------|
| **Guest** | 3 per day | Modal shows when limit reached |
| **Authenticated** | 5 per day | No modal, limit enforced |

### **Action Types**
- `ActionType.flashcardGrading` - Flashcard study sessions
- `ActionType.interviewPractice` - Interview question practice  
- `ActionType.contentGeneration` - AI content generation
- `ActionType.aiAssistance` - AI-powered assistance

---

## 🔧 **Core Files** 

| Component | File | Purpose |
|-----------|------|---------|
| **Storage** | `unified_usage_storage.dart` | Single source of truth |
| **Tracking** | `unified_action_tracking_provider.dart` | State management |
| **Enforcement** | `unified_usage_limit_enforcer.dart` | Quota management |
| **Middleware** | `unified_action_middleware.dart` | Action wrapping |
| **Migration** | `storage_migration_utility.dart` | Legacy data migration |

## ✅ **What Works**

- ✅ **Automatic migration** from legacy systems
- ✅ **Guest user tracking** (3 actions/day)
- ✅ **Authentication rewards** (5 actions/day)
- ✅ **Daily reset** (passive, on app interaction)
- ✅ **Supabase compatibility** (UUID user IDs)
- ✅ **Error recovery** (comprehensive fallbacks)
- ✅ **Combined quota system** (total across all action types)

## 🗑️ **Removed Legacy Files**

- ❌ `guest_user_manager.dart` - Replaced by unified tracking
- ❌ `working_action_tracking_provider.dart` - Replaced by unified version
- ❌ `usage_limit_enforcer.dart` - Replaced by unified version  
- ❌ `action_middleware.dart` - Replaced by unified version

---

## 🔍 **Debug Commands**

```dart
// Get usage summary
final enforcer = ref.read(unifiedUsageLimitEnforcerProvider);
print(enforcer.getUsageSummary());

// Get storage overview  
final overview = await UnifiedUsageStorage.getStorageOverview();
print(overview);

// Reset for testing
final tracker = ref.read(unifiedActionTrackerProvider.notifier);
await tracker.resetAllActions();
```

---

## 🚨 **Common Issues**

| Problem | Solution |
|---------|----------|
| **Usage not tracking** | Check imports: use `unifiedActionTrackerProvider` |
| **Auth modal not showing** | Ensure `context` parameter in `executeWithQuota()` |
| **Quota not resetting** | Daily reset is passive (requires app interaction) |
| **Data lost** | Check migration with `StorageMigrationUtility.verifyMigration()` |

---

## 🔐 **Supabase Integration**

### **Ready to Deploy** ✅
The unified system handles Supabase User objects automatically:

```dart
// Works with both formats:
user['id']?.toString()     // Map format
(user as dynamic).id       // Supabase User object
```

### **Database Schema**
- Use: `2025-06-10_supabase_schema_v2.sql`
- Compatible with unified storage keys
- UUID user IDs fully supported

---

## 📱 **Example Implementation**

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPerform = ref.watch(canPerformAnyActionProvider);
    final statusMessage = ref.watch(usageStatusMessageProvider);
    final middleware = ref.read(unifiedActionMiddlewareProvider);
    
    return Column(
      children: [
        Text(statusMessage),
        ElevatedButton(
          onPressed: canPerform ? () async {
            final result = await middleware.executeWithQuota(
              ActionType.flashcardGrading,
              () => performStudyAction(),
              context: context,
              source: 'my_screen',
            );
            
            if (result != null) {
              // Success - handle result
            }
            // Failure - quota exceeded, modal was shown
          } : null,
          child: Text('Study Flashcards'),
        ),
      ],
    );
  }
}
```

---

**Quick Reference Version**: 3.0  
**For Complete Guide**: See `unified_system_supabase_integration_2025-06-16.md`