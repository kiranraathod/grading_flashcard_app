# Task 3.1: Authentication Foundation Implementation

## Priority Level
🚨 **CRITICAL BLOCKER** - Required for Supabase Migration

## Overview
Implement basic authentication system as foundation for Supabase migration. Current application has NO authentication but Supabase requires user-scoped data access.

## Background
**Current State:**
- Zero authentication system
- All data stored locally without user context
- No user management or session handling

**Migration Requirement:**
```dart
// Current: No user context
await localStorage.save('questions', data);

// Required for Supabase: User-scoped data
await supabase.from('questions').insert({
  ...data,
  'user_id': supabase.auth.currentUser!.id, // REQUIRED but doesn't exist
});
```

**Migration Challenge:**
- How to associate existing local data with new user accounts
- Strategy for users who don't want to create accounts
- Seamless migration without losing existing data

## Implementation Steps

### Step 1: Basic Authentication Service
Create `lib/services/auth_service.dart`:

```dart
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  User? _currentUser;
  bool _isInitialized = false;
  
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  
  /// Initialize authentication system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check for existing session
      await _checkExistingSession();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Create anonymous user for migration compatibility
  Future<AuthResult> createAnonymousUser() async {
    try {
      final userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      final user = User(
        id: userId,
        email: null,
        displayName: 'Anonymous User',
        isAnonymous: true,
        createdAt: DateTime.now(),
      );
      
      await _saveUserSession(user);
      _currentUser = user;
      notifyListeners();
      
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Failed to create anonymous user: $e');
    }
  }
  
  /// Register with email and password (for future Supabase integration)
  Future<AuthResult> register(String email, String password, String displayName) async {
    try {
      // For now, create local user - will be replaced with Supabase auth
      final userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final user = User(
        id: userId,
        email: email,
        displayName: displayName,
        isAnonymous: false,
        createdAt: DateTime.now(),
      );
      
      // Store credentials securely (simplified for demo)
      await _storeCredentials(email, password);
      await _saveUserSession(user);
      
      _currentUser = user;
      notifyListeners();
      
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Registration failed: $e');
    }
  }
  
  /// Sign in with email and password
  Future<AuthResult> signIn(String email, String password) async {
    try {
      // Verify credentials (simplified for demo)
      final isValid = await _verifyCredentials(email, password);
      if (!isValid) {
        return AuthResult.failure('Invalid credentials');
      }
      
      final user = await _getUserByEmail(email);
      if (user == null) {
        return AuthResult.failure('User not found');
      }
      
      await _saveUserSession(user);
      _currentUser = user;
      notifyListeners();
      
      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Sign in failed: $e');
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _clearUserSession();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
  
  /// Associate existing local data with authenticated user
  Future<DataMigrationResult> associateLocalDataWithUser(User user) async {
    try {
      final migrationService = LocalDataMigrationService();
      return await migrationService.migrateLocalDataToUser(user);
    } catch (e) {
      return DataMigrationResult.failure('Data association failed: $e');
    }
  }
  
  Future<void> _checkExistingSession() async {
    final storage = ReliableStorageService();
    final sessionData = await storage.get<String>('user_session');
    
    if (sessionData != null) {
      try {
        final userData = jsonDecode(sessionData);
        _currentUser = User.fromJson(userData);
      } catch (e) {
        debugPrint('Invalid session data: $e');
        await _clearUserSession();
      }
    }
  }
  
  Future<void> _saveUserSession(User user) async {
    final storage = ReliableStorageService();
    await storage.set('user_session', jsonEncode(user.toJson()));
  }
  
  Future<void> _clearUserSession() async {
    final storage = ReliableStorageService();
    await storage.set('user_session', null);
  }
  
  Future<void> _storeCredentials(String email, String password) async {
    // In production, use proper secure storage
    final storage = ReliableStorageService();
    final hashedPassword = _hashPassword(password);
    await storage.set('auth_$email', hashedPassword);
  }
  
  Future<bool> _verifyCredentials(String email, String password) async {
    final storage = ReliableStorageService();
    final storedHash = await storage.get<String>('auth_$email');
    if (storedHash == null) return false;
    
    return storedHash == _hashPassword(password);
  }
  
  Future<User?> _getUserByEmail(String email) async {
    final storage = ReliableStorageService();
    final userData = await storage.get<String>('user_$email');
    if (userData == null) return null;
    
    try {
      return User.fromJson(jsonDecode(userData));
    } catch (e) {
      return null;
    }
  }
  
  String _hashPassword(String password) {
    // Simplified hashing - use proper crypto in production
    return password.hashCode.toString();
  }
}

class User {
  final String id;
  final String? email;
  final String displayName;
  final bool isAnonymous;
  final DateTime createdAt;
  
  User({
    required this.id,
    this.email,
    required this.displayName,
    required this.isAnonymous,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'is_anonymous': isAnonymous,
    'created_at': createdAt.toIso8601String(),
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    displayName: json['display_name'],
    isAnonymous: json['is_anonymous'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
}

class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  
  AuthResult.success(this.user) : isSuccess = true, error = null;
  AuthResult.failure(this.error) : isSuccess = false, user = null;
}
```

### Step 2: Local Data Migration Service
Create `lib/services/local_data_migration_service.dart`:

```dart
class LocalDataMigrationService {
  /// Migrate all local data to be associated with a user
  Future<DataMigrationResult> migrateLocalDataToUser(User user) async {
    final result = DataMigrationResult();
    
    try {
      // Migrate flashcard sets
      await _migrateFlashcardSets(user, result);
      
      // Migrate interview questions
      await _migrateInterviewQuestions(user, result);
      
      // Migrate user progress
      await _migrateUserProgress(user, result);
      
      // Migrate recent views
      await _migrateRecentViews(user, result);
      
      result.success = true;
      result.message = 'Successfully migrated ${result.itemsMigrated} items to user ${user.displayName}';
      
    } catch (e, stackTrace) {
      result.success = false;
      result.message = 'Migration failed: $e';
      result.error = e;
      result.stackTrace = stackTrace;
    }
    
    return result;
  }
  
  Future<void> _migrateFlashcardSets(User user, DataMigrationResult result) async {
    final storage = ReliableStorageService();
    final setsData = await storage.get<List<String>>('flashcard_sets');
    
    if (setsData != null && setsData.isNotEmpty) {
      final userSetsKey = 'user_${user.id}_flashcard_sets';
      await storage.set(userSetsKey, setsData);
      result.itemsMigrated += setsData.length;
      result.addDetail('Migrated ${setsData.length} flashcard sets');
    }
  }
  
  Future<void> _migrateInterviewQuestions(User user, DataMigrationResult result) async {
    final storage = ReliableStorageService();
    final questionsData = await storage.get<String>('interview_questions');
    
    if (questionsData != null && questionsData.isNotEmpty) {
      try {
        final questions = jsonDecode(questionsData) as List;
        
        // Add user_id to each question
        final userQuestions = questions.map((q) {
          final question = Map<String, dynamic>.from(q);
          question['user_id'] = user.id;
          return question;
        }).toList();
        
        final userQuestionsKey = 'user_${user.id}_interview_questions';
        await storage.set(userQuestionsKey, jsonEncode(userQuestions));
        
        result.itemsMigrated += questions.length;
        result.addDetail('Migrated ${questions.length} interview questions');
      } catch (e) {
        result.addDetail('Failed to migrate interview questions: $e');
      }
    }
  }
  
  Future<void> _migrateUserProgress(User user, DataMigrationResult result) async {
    final storage = ReliableStorageService();
    
    // Look for any progress-related keys
    final allKeys = await _getAllStorageKeys();
    final progressKeys = allKeys.where((key) => 
      key.contains('progress') || 
      key.contains('completion') || 
      key.contains('recent')
    );
    
    int migratedCount = 0;
    for (final key in progressKeys) {
      final data = await storage.get(key);
      if (data != null) {
        final userKey = 'user_${user.id}_$key';
        await storage.set(userKey, data);
        migratedCount++;
      }
    }
    
    if (migratedCount > 0) {
      result.itemsMigrated += migratedCount;
      result.addDetail('Migrated $migratedCount progress items');
    }
  }
  
  Future<List<String>> _getAllStorageKeys() async {
    // This would need to be implemented based on storage system
    // For now, return known keys
    return [
      'recent_views',
      'user_preferences',
      'weekly_activity',
      'daily_progress',
    ];
  }
}

class DataMigrationResult {
  bool success = false;
  String message = '';
  int itemsMigrated = 0;
  List<String> details = [];
  dynamic error;
  StackTrace? stackTrace;
  
  void addDetail(String detail) {
    details.add(detail);
  }
  
  static DataMigrationResult failure(String message) {
    final result = DataMigrationResult();
    result.success = false;
    result.message = message;
    return result;
  }
}
```

### Step 3: Authentication UI Components
Create `lib/screens/auth_screen.dart`:

```dart
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Sign In'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            SizedBox(height: 32),
            _buildForm(),
            SizedBox(height: 24),
            _buildActionButton(),
            SizedBox(height: 16),
            _buildToggleButton(),
            SizedBox(height: 32),
            _buildAnonymousOption(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return Column(
      children: [
        Icon(Icons.school, size: 64, color: Theme.of(context).primaryColor),
        SizedBox(height: 16),
        Text(
          'FlashMaster',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _isSignUp ? 'Create your account to sync data' : 'Sign in to your account',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildForm() {
    return Column(
      children: [
        if (_isSignUp) ...[
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 16),
        ],
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        child: _isLoading
          ? CircularProgressIndicator()
          : Text(_isSignUp ? 'Create Account' : 'Sign In'),
      ),
    );
  }
  
  Widget _buildAnonymousOption() {
    return Column(
      children: [
        Divider(),
        SizedBox(height: 16),
        Text('Don\'t want to create an account?'),
        SizedBox(height: 8),
        TextButton(
          onPressed: _handleAnonymousAuth,
          child: Text('Continue as Guest'),
        ),
      ],
    );
  }
  
  Future<void> _handleAuth() async {
    if (_isLoading) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    
    if (_isSignUp && _nameController.text.trim().isEmpty) {
      _showError('Please enter your display name');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      AuthResult result;
      
      if (_isSignUp) {
        result = await authService.register(email, password, _nameController.text.trim());
      } else {
        result = await authService.signIn(email, password);
      }
      
      if (result.isSuccess) {
        // Migrate local data to user
        if (result.user != null) {
          await authService.associateLocalDataWithUser(result.user!);
        }
        
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        _showError(result.error ?? 'Authentication failed');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _handleAnonymousAuth() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      final result = await authService.createAnonymousUser();
      
      if (result.isSuccess) {
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        _showError(result.error ?? 'Failed to create anonymous session');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
```

## Integration with Main App

### Step 4: Update Main App
Update `lib/main.dart`:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add AuthService to providers
        ChangeNotifierProvider(create: (_) => AuthService()),
        // ... existing providers
      ],
      child: MaterialApp(
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            if (!auth.isInitialized) {
              return SplashScreen();
            }
            
            if (!auth.isAuthenticated) {
              return AuthScreen();
            }
            
            return HomeScreen();
          },
        ),
        routes: {
          '/auth': (context) => AuthScreen(),
          '/home': (context) => HomeScreen(),
          // ... existing routes
        },
      ),
    );
  }
}
```

## Acceptance Criteria

- [ ] Basic authentication service with local storage
- [ ] User registration and sign-in functionality
- [ ] Anonymous user support for migration compatibility
- [ ] Local data migration to user-scoped storage
- [ ] Authentication UI with email/password and guest options
- [ ] Session persistence across app restarts
- [ ] Graceful handling of authentication errors
- [ ] Data association with authenticated users
- [ ] Foundation ready for Supabase auth integration

## Testing Instructions

1. **Test user registration:**
   - Create new account with email/password
   - Verify user session persists across app restarts
   - Confirm local data is migrated to user scope

2. **Test anonymous users:**
   - Create anonymous session
   - Verify functionality works without email
   - Test data persistence

3. **Test data migration:**
   - Create local data before authentication
   - Sign in with new account
   - Verify all data is properly associated with user

## Migration Strategy

**Phase 1:** Local Authentication (Current Task)
- Implement local auth system
- Migrate existing data to user-scoped storage
- Test thoroughly with current data

**Phase 2:** Supabase Integration (Future)
- Replace local auth with Supabase auth
- Migrate user-scoped local data to Supabase
- Maintain same UI and user experience

## Next Steps
After completing this task:
- All data becomes user-scoped and migration-ready
- Proceed to Task 4.1: Migration Preparation & Validation
- Begin Supabase integration with authentication foundation

## Dependencies
- ReliableStorageService (from Task 2.1)
- Existing data services for migration
- Secure storage for credentials (consider flutter_secure_storage)