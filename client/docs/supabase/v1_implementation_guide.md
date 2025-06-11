# Integration Instructions for v1 Schema Implementation

## Step 1: Add Basic Authentication to main.dart

Add this to your `client/lib/main.dart` imports:
```dart
import 'services/basic_auth_service_v1.dart';
```

Add this to your initialization function (in `_initializeSystemStabilization()`):
```dart
// Initialize basic authentication (v1)
await SimpleErrorHandler.safely(
  () async {
    await BasicAuthService.instance.initialize();
    debugPrint('✅ Basic auth service initialized');
  },
  operationName: 'basic_auth_initialization',
);
```

Add this to your Provider tree in main.dart:
```dart
// In MultiProvider providers list:
ChangeNotifierProvider.value(value: BasicAuthService.instance),
```

## Step 2: Modify App Header for Basic Auth

Add these imports to your `client/lib/widgets/app_header.dart`:
```dart
import '../services/basic_auth_service_v1.dart';
import '../widgets/simple_auth_dialog_v1.dart';
```

Replace the profile PopupMenuButton with:
```dart
Consumer<BasicAuthService>(
  builder: (context, authService, child) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 45),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: authService.isAuthenticated 
            ? Colors.green 
            : context.primaryColor,
          child: Icon(
            Icons.person,
            color: context.onPrimaryColor,
            size: 18,
          ),
        ),
      ),
      itemBuilder: (_) => [
        if (authService.isAuthenticated) ...[
          PopupMenuItem(
            enabled: false,
            child: Text(
              authService.currentUser?.email ?? 'User',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const PopupMenuDivider(),
        ],
        
        PopupMenuItem(
          value: authService.isAuthenticated ? 'sign_out' : 'sign_in',
          child: Row(
            children: [
              Icon(authService.isAuthenticated 
                ? Icons.logout 
                : Icons.login
              ),
              const SizedBox(width: 8),
              Text(authService.isAuthenticated 
                ? 'Sign Out' 
                : 'Sign In'
              ),
            ],
          ),
        ),
        
        const PopupMenuDivider(),
        
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).settings),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'sign_in':
            SimpleAuthDialog.show(context);
            break;
          case 'sign_out':
            await authService.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            }
            break;
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            break;
        }
      },
    );
  },
)
```

## Step 3: Test v1 Implementation

### 3.1 Enable Authentication
In your config file, set:
```dart
static bool enableAuthentication = true;
static bool enableBasicAuth = true;
```

### 3.2 Test Flow
1. **Run the app** - should compile without errors
2. **Click profile icon** - should show "Sign In" option
3. **Test sign up** - create a new account
4. **Verify categories** - check Supabase dashboard for default categories
5. **Test sign in** - sign in with existing account
6. **Check profile icon** - should show green and email
7. **Test sign out** - should return to "Sign In" option

### 3.3 Verify Database
In Supabase dashboard:
- Check **Authentication > Users** - should see new users
- Check **Table Editor > categories** - should see default categories
- Check **Table Editor > flashcard_sets** - should be empty initially

## Step 4: Basic Usage Examples

### Create a Flashcard Set
```dart
// Get auth service
final authService = Provider.of<BasicAuthService>(context, listen: false);

if (authService.isAuthenticated) {
  // Create flashcard set
  final response = await Supabase.instance.client
    .from('flashcard_sets')
    .insert({
      'user_id': authService.currentUser!.id,
      'title': 'My First Set',
      'description': 'Practice questions for data analysis',
    });
}
```

### Get User Data
```dart
// Get user's categories
final categories = await authService.getCategories();

// Get user's flashcard sets
final sets = await authService.getFlashcardSets();
```

## Step 5: Manual Setup Required (v1 Limitations)

Since v1 is basic, you'll need to manually:

1. **Add more RLS policies** as you build features
2. **Create indexes** for performance:
   ```sql
   CREATE INDEX idx_flashcards_set_id ON flashcards(set_id);
   CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
   ```
3. **Handle guest users** if needed (no built-in support)
4. **Add data migration** from local storage
5. **Implement usage limits** manually

## Step 6: Limitations and Future Upgrades

### v1 Limitations:
- ❌ No guest user support
- ❌ No usage limits
- ❌ Basic security only
- ❌ No automated data management
- ❌ Manual category creation
- ❌ No performance optimization
- ❌ No advanced features

### When to Upgrade to v2:
- Need guest user tracking
- Want usage limits
- Require advanced security
- Need performance optimization
- Want sharing features
- Need automated maintenance

## Troubleshooting v1

### Common Issues:
1. **Users table not found** - Supabase creates this automatically
2. **RLS denies access** - Check your policies match user IDs
3. **Categories not created** - Manually insert for existing users
4. **Performance slow** - Add indexes as needed

### Debug Commands:
```sql
-- Check if user exists
SELECT * FROM auth.users WHERE email = 'user@example.com';

-- Check user's data
SELECT * FROM categories WHERE user_id = 'user-uuid-here';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'categories';
```
