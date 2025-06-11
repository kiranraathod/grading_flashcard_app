# Enhanced v2 Schema Testing Guide

## Testing Flow for v2 Implementation

### Phase 1: Guest User Experience
1. **Start with authentication disabled**
   ```dart
   // In config.dart
   static bool enableAuthentication = false;
   ```

2. **Run app and verify**
   - App should work exactly as before
   - Profile menu shows existing options
   - No authentication features visible
   - This confirms zero disruption

### Phase 2: Enable Authentication
1. **Enable authentication features**
   ```dart
   // In config.dart
   static bool enableAuthentication = true;
   static bool enableUsageLimits = true;
   static bool enableGuestTracking = true;
   ```

2. **Restart app and test guest experience**
   - Profile icon should show same appearance
   - Click profile icon → should now show "Sign In" option
   - Perform grading actions (flashcard grading, interview practice)
   - After 3 actions → should see usage limit message
   - Profile menu should show: "2 actions remaining today"

### Phase 3: Authentication Flow
1. **Test sign-up process**
   - Click profile icon → "Sign In"
   - Opens Material Design 3 modal
   - Switch to "Create Account" tab
   - Enter email and password
   - Should create account and auto-sign in
   - Profile icon should show green indicator

2. **Verify automatic setup**
   - Check Supabase dashboard → Authentication → Users
   - Should see new user created
   - Check Table Editor → categories
   - Should see 7 default categories created automatically
   - Check user_preferences table
   - Should see default preferences created

3. **Test authenticated experience**
   - Perform grading actions
   - Should now have 5 total actions instead of 3
   - Profile menu should show: "X actions used: 2/5"
   - Green profile icon indicates authenticated state

### Phase 4: Data Persistence
1. **Create test data**
   - Create a flashcard set
   - Add some flashcards
   - Practice some interview questions
   - Mark some flashcards as completed

2. **Verify data in Supabase**
   - Check flashcard_sets table → should see your set
   - Check flashcards table → should see your cards
   - Check user_progress table → should see completion status
   - Check user_activity table → should see recent views
   - Check weekly_activity table → should see usage tracking

3. **Test sign out/sign in**
   - Sign out from profile menu
   - App should return to guest mode (3 actions)
   - Sign back in
   - All data should be preserved
   - Usage should return to 5 actions

### Phase 5: Advanced Features
1. **Test user preferences**
   ```dart
   // Should automatically have default preferences
   final prefs = await Supabase.instance.client
     .from('user_preferences')
     .select()
     .eq('user_id', currentUserId)
     .single();
   ```

2. **Test guest session tracking**
   ```dart
   // Check guest_sessions table for anonymous tracking
   final sessions = await Supabase.instance.client
     .from('guest_sessions')
     .select()
     .gt('expires_at', DateTime.now().toIso8601String());
   ```

3. **Test analytics data**
   ```dart
   // Check weekly_activity for usage analytics
   final activity = await Supabase.instance.client
     .from('weekly_activity')
     .select()
     .eq('user_id', currentUserId);
   ```

## Expected Results After Testing

### Database Tables Should Contain:
- **categories**: 7 default categories per user
- **user_preferences**: Default settings per user
- **flashcard_sets**: Any sets created during testing
- **flashcards**: Individual cards in sets
- **user_progress**: Completion status for practiced cards
- **user_activity**: Recent view history
- **weekly_activity**: Usage tracking per week
- **guest_sessions**: Anonymous session tracking
- **interview_questions**: Any practice questions

### User Experience Should Show:
- ✅ **Guest Mode**: 3 grading actions, "Sign In" prompt at limit
- ✅ **Authenticated Mode**: 5 grading actions, green profile indicator
- ✅ **Data Persistence**: All data saved and restored on sign-in
- ✅ **Zero Disruption**: Existing features work identically
- ✅ **Progressive Enhancement**: Authentication features layer on seamlessly

## Troubleshooting v2

### Common Issues and Solutions:

1. **Schema deployment fails**
   - Check for syntax errors in SQL
   - Run sections separately if needed
   - Verify UUID extension is enabled

2. **RLS policies deny access**
   - Check user is authenticated: `auth.uid()`
   - Verify policies are created correctly
   - Test with simple SELECT first

3. **Default categories not created**
   - Check if trigger fired: look for new user in auth.users
   - Manually call: `SELECT create_default_categories('user-uuid');`
   - Verify function exists in Database → Functions

4. **Guest sessions not working**
   - Check guest_sessions table exists
   - Verify session token generation
   - Check expiry cleanup is working

5. **Usage limits not enforcing**
   - Verify GuestUserManager is initialized
   - Check SharedPreferences storage
   - Verify daily reset logic

### Debug Queries:

```sql
-- Check user's data
SELECT * FROM categories WHERE user_id = auth.uid();
SELECT * FROM user_preferences WHERE user_id = auth.uid();
SELECT * FROM weekly_activity WHERE user_id = auth.uid();

-- Check guest sessions
SELECT * FROM guest_sessions WHERE expires_at > NOW();

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies WHERE tablename IN ('categories', 'flashcard_sets');

-- Check triggers and functions
SELECT * FROM information_schema.triggers WHERE event_object_table = 'users';
SELECT * FROM information_schema.routines WHERE routine_name LIKE '%default_categories%';
```

## Performance Verification

### v2 Performance Features to Test:

1. **Index Usage**
   ```sql
   -- Verify indexes are used in query plans
   EXPLAIN (ANALYZE, BUFFERS) 
   SELECT * FROM flashcards WHERE set_id = 'some-uuid';
   ```

2. **Denormalized Counts**
   ```sql
   -- Verify flashcard_count is maintained
   SELECT title, flashcard_count, 
          (SELECT COUNT(*) FROM flashcards WHERE set_id = fs.id) as actual_count
   FROM flashcard_sets fs WHERE user_id = auth.uid();
   ```

3. **Automated Cleanup**
   ```sql
   -- Test guest session cleanup
   SELECT cleanup_expired_guest_sessions();
   ```

## Security Verification

### Test RLS Policies:

1. **User Isolation**
   - Create two test users
   - Verify each can only see their own data
   - Test all tables with both users

2. **Guest Session Security**
   - Verify guests can't access user tables
   - Test session token security
   - Check no personal data in guest_sessions

3. **Public Sharing (if enabled)**
   - Create public flashcard set
   - Test visibility from different users
   - Verify private sets stay private

### Expected Security Behavior:
- ✅ Users can only access their own data
- ✅ Public flashcard sets visible to all
- ✅ Guest sessions contain no personal data
- ✅ All policies enforce proper isolation
- ✅ No SQL injection vulnerabilities
