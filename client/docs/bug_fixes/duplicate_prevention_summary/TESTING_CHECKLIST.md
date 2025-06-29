# Testing Checklist for Duplicate Prevention

## ✅ **Pre-Testing Verification**

### **Database Constraints Status:**
- [ ] Run this SQL query to verify constraints exist:
```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE indexname IN ('unique_active_user_title', 'unique_question_per_set');
```
**Expected**: 2 rows showing both indexes

### **Code Changes Status:**
- [ ] FlashcardService has `import 'package:supabase_flutter/supabase_flutter.dart'`
- [ ] FlashcardService has `_migrationCompleteKey` constant
- [ ] InterviewService has `import 'package:supabase_flutter/supabase_flutter.dart'`

## 🧪 **Functional Testing**

### **Test 1: Database Constraint Works**
- [ ] Try creating duplicate flashcard sets via SQL
- [ ] Should get error 23505 (duplicate key violation)

### **Test 2: Migration Flag Works**
- [ ] Start app with existing user
- [ ] Check logs for "Migration already completed, skipping"
- [ ] Call `resetMigrationFlag()` if needed to test migration

### **Test 3: App Duplicate Prevention**
- [ ] Try to create flashcard set with existing name
- [ ] Should handle gracefully without showing error to user
- [ ] Check logs for "already exists in cloud, skipping upload"

### **Test 4: Normal Operations Still Work**
- [ ] Create new flashcard set with unique name
- [ ] Edit existing flashcard set
- [ ] Delete flashcard set
- [ ] Sync between devices (if multiple devices available)

## 🔍 **Debug Commands**

### **Reset Migration for Testing:**
```dart
// In your app debug panel or console
await FlashcardService.instance.resetMigrationFlag();
```

### **Check Migration Status:**
```dart
// Check if migration flag is set
SharedPreferences prefs = await SharedPreferences.getInstance();
bool migrationComplete = prefs.getBool('migration_complete_v2') ?? false;
print('Migration complete: $migrationComplete');
```

### **Force Duplicate Test:**
```sql
-- This should fail in Supabase SQL Editor
INSERT INTO flashcard_sets (user_id, title, is_deleted) VALUES 
  ('YOUR_USER_ID_HERE', 'Test Duplicate', false),
  ('YOUR_USER_ID_HERE', 'Test Duplicate', false);
```

## 📱 **User Experience Testing**

### **Scenario 1: First Time User**
- [ ] New user registration/login
- [ ] Creates flashcard sets
- [ ] No duplicates appear
- [ ] Migration runs once (if applicable)

### **Scenario 2: Existing User**
- [ ] Existing user login
- [ ] Migration skipped (check logs)
- [ ] Existing data intact
- [ ] No new duplicates created

### **Scenario 3: Offline/Online Sync**
- [ ] Create data while offline
- [ ] Go online and sync
- [ ] No duplicates created during sync
- [ ] All data synced correctly

## 🚨 **Issue Indicators**

### **Red Flags (Need Investigation):**
- Multiple sets with same name appear
- Migration data loads repeatedly
- PostgrestException errors shown to user
- Sync operations fail unexpectedly

### **Green Flags (Working Correctly):**
- Console shows "already exists in cloud, skipping upload"
- Console shows "Migration already completed, skipping"
- Only one set per unique name exists
- Sync operations complete without user-facing errors

## 🎯 **Success Criteria**

✅ **Primary Goal**: No duplicate flashcard sets can be created  
✅ **Secondary Goal**: Migration data loads only once  
✅ **Tertiary Goal**: User experience remains smooth  

If all tests pass, the duplicate prevention implementation is successful! 🎉
