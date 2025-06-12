# Authentication Patterns and Best Practices

## Overview

This document outlines the specific patterns, architectural decisions, and best practices used in the Flutter Flashcard Application authentication system.

## State Management Patterns

### **Pattern 1: Simple State Classes**

**Use Case**: Basic authentication states (loading, authenticated, error)

**Implementation**:
```dart
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final dynamic user; // Using dynamic to avoid import conflicts
  
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    dynamic user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}
```

**Benefits**:
- No build dependencies
- Easy to understand and debug
- Fast compilation
- Type-safe with manual implementation

**When to Use**:
- ≤ 5 authentication states
- Simple error handling
- Team prefers explicit implementations

---

### **Pattern 2: Sealed Classes (Alternative for Complex States)**

**Use Case**: Multiple authentication states with type safety

**Implementation**:
```dart
sealed class AuthState {
  const AuthState();
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final dynamic user;
  const AuthStateAuthenticated(this.user);
}

class AuthStateGuest extends AuthState {
  final String guestId;
  const AuthStateGuest(this.guestId);
}

class AuthStateError extends AuthState {
  final String message;
  const AuthStateError(this.message);
}
```

**Benefits**:
- Exhaustive pattern matching
- Type safety without code generation
- Clear state transitions
- Good IDE support

**When to Use**:
- > 5 distinct states
- Complex state transitions
- Need exhaustive checking

---

## Provider Patterns

### **Pattern 3: Riverpod StateNotifier Pattern**

**Use Case**: Modern reactive state management

**Implementation**:
```dart
class SimpleAuthNotifier extends StateNotifier<AuthState> {
  late final SupabaseClient _supabase;
  
  SimpleAuthNotifier() : super(const AuthStateInitial()) {
    _supabase = SupabaseService.instance.client;
    _initializeAuth();
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AuthStateLoading();
      
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Email sign-in successful: $email');
    } catch (e) {
      debugPrint('❌ Email sign-in failed: $e');
      state = AuthStateError(_getErrorMessage(e));
    }
  }

  void clearError() {
    if (state is AuthStateError) {
      state = const AuthStateUnauthenticated();
    }
  }
}

// Provider definition
final authNotifierProvider = StateNotifierProvider<SimpleAuthNotifier, AuthState>((ref) {
  return SimpleAuthNotifier();
});
```

**Benefits**:
- Automatic dependency management
- Compile-time safety
- Global accessibility without BuildContext
- Excellent testing support

**Best Practices**:
- Keep business logic in notifier
- Use derived providers for computed state
- Handle async operations properly
- Clear error states appropriately

---

### **Pattern 4: Provider ChangeNotifier Pattern (Legacy Support)**

**Use Case**: Team familiar with Provider, gradual migration

**Implementation**:
```dart
class AuthProvider extends ChangeNotifier {
  AuthState _state = const AuthState();
  AuthState get state => _state;
  
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();
      
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _state = _state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }
}
```

**Benefits**:
- Familiar pattern for existing teams
- Simple implementation
- Good debugging support
- Easy testing

**Limitations**:
- Manual notifyListeners() calls
- No compile-time dependencies
- BuildContext dependency for access

---

## Storage Patterns

### **Pattern 5: Layered Storage Strategy**

**Implementation**:
```dart
class WorkingSecureAuthStorage {
  static const String _guestDataKey = 'guest_user_data';
  static const String _userActionsPrefix = 'user_actions_';
  static const String _migrationCompleteKey = 'migration_complete';

  // Development: SharedPreferences, Production: FlutterSecureStorage
  static Future<String?> _getValue(String key) async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      const storage = FlutterSecureStorage();
      return await storage.read(key: key);
    }
  }

  static Future<void> _setValue(String key, String value) async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      const storage = FlutterSecureStorage();
      await storage.write(key: key, value: value);
    }
  }

  // Guest user management
  static Future<void> storeGuestData(String guestId, Map<String, dynamic> data) async {
    final guestData = {
      'id': guestId,
      'created_at': DateTime.now().toIso8601String(),
      ...data,
    };
    
    await _setValue(_guestDataKey, jsonEncode(guestData));
  }

  static Future<Map<String, dynamic>?> getGuestData() async {
    final dataStr = await _getValue(_guestDataKey);
    if (dataStr != null) {
      return Map<String, dynamic>.from(jsonDecode(dataStr));
    }
    return null;
  }
}
```

**Benefits**:
- Environment-appropriate security
- Clean migration path
- Testable with SharedPreferences
- Secure in production

**When to Use**:
- Need both development convenience and production security
- Guest user data management
- Token storage and session management

---

## UI Patterns

### **Pattern 6: Platform-Specific Authentication Modal**

**Implementation**:
```dart
class WorkingAuthModal extends ConsumerStatefulWidget {
  final String reason;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const WorkingAuthModal({
    super.key,
    required this.reason,
    this.onSuccess,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required String reason,
    VoidCallback? onSuccess,
    VoidCallback? onCancel,
  }) async {
    if (Platform.isIOS) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => WorkingAuthModal(
          reason: reason,
          onSuccess: onSuccess,
          onCancel: onCancel,
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: WorkingAuthModal(
            reason: reason,
            onSuccess: onSuccess,
            onCancel: onCancel,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<WorkingAuthModal> createState() => _WorkingAuthModalState();
}
```

**Benefits**:
- Platform-appropriate UX
- Reusable across features
- Context-aware messaging
- Clean callback handling

**Design Principles**:
- iOS: Bottom sheet presentation
- Android: Dialog presentation
- Consistent branding across platforms
- Accessibility support

---

### **Pattern 7: Usage Limit Integration**

**Implementation**:
```dart
// Pre-action check pattern
Future<bool> _checkUsageLimits(BuildContext context) async {
  if (!AuthConfig.enableUsageLimits) return true;
  
  final actionTracker = ref.read(actionTrackerProvider.notifier);
  
  if (!actionTracker.canPerformAction(ActionType.flashcardGrading)) {
    await WorkingAuthModal.show(
      context,
      reason: 'usage_limit_reached',
      onSuccess: () {
        debugPrint('✅ Authentication successful - can retry action');
      },
    );
    return false;
  }
  
  return true;
}

// Post-action recording pattern
Future<void> _recordAction() async {
  if (AuthConfig.enableUsageLimits) {
    final actionTracker = ref.read(actionTrackerProvider.notifier);
    await actionTracker.recordAction(ActionType.flashcardGrading);
  }
}

// Usage in feature implementation
Future<void> performAction() async {
  if (!await _checkUsageLimits(context)) return;
  
  try {
    final result = await apiService.performAction();
    await _recordAction();
    // Handle success
  } catch (e) {
    // Handle error
  }
}
```

**Benefits**:
- Consistent enforcement across features
- Clear user feedback
- Configurable limits
- Analytics integration ready

---

## Service Patterns

### **Pattern 8: Service Layer with Authentication Integration**

**Implementation**:
```dart
class FlashcardApiService {
  final ProxyClient client;
  final Ref? _ref;

  FlashcardApiService({Ref? ref}) 
      : client = ProxyClient(AppConfig.apiBaseUrl),
        _ref = ref;

  Future<FlashcardAnswer> gradeAnswer(
    FlashcardAnswer answer, {
    BuildContext? context,
  }) async {
    return await SimpleErrorHandler.safe<FlashcardAnswer>(
      () async {
        // Authentication check
        if (_ref != null && AuthConfig.enableUsageLimits) {
          final actionTracker = _ref!.read(actionTrackerProvider.notifier);
          
          if (!actionTracker.canPerformAction(ActionType.flashcardGrading)) {
            if (context != null) {
              await WorkingAuthModal.show(
                context,
                reason: 'flashcard_limit',
                onSuccess: () => debugPrint('Auth successful'),
              );
            }
            return _createAuthRequiredResponse(answer);
          }
        }

        // API call
        final response = await client.post('/api/grade', body: {
          'questionId': answer.questionId,
          'userAnswer': answer.userAnswer,
        });

        // Record action on success
        if (_ref != null && AuthConfig.enableUsageLimits) {
          final actionTracker = _ref!.read(actionTrackerProvider.notifier);
          await actionTracker.recordAction(ActionType.flashcardGrading);
        }

        return FlashcardAnswer.fromJson(jsonDecode(response.body));
      },
      fallback: _createFallbackResponse(answer),
      operationName: 'grade_flashcard_answer',
    );
  }
}
```

**Benefits**:
- Authentication integrated at service layer
- Fallback responses for auth failures
- Consistent error handling
- Optional Riverpod integration

---

## Migration Patterns

### **Pattern 9: Guest-to-Authenticated Data Migration**

**Implementation**:
```dart
Future<void> _migrateGuestDataIfNeeded(String userId) async {
  try {
    final guestData = await WorkingSecureAuthStorage.getGuestData();
    if (guestData != null) {
      debugPrint('🔄 Migrating guest data to authenticated user');
      
      // Migrate action counts
      final guestActions = await WorkingSecureAuthStorage.getUserActions(guestData['id']);
      if (guestActions.isNotEmpty) {
        await WorkingSecureAuthStorage.storeUserActions(userId, guestActions);
      }
      
      // Migrate preferences
      final preferences = await _getGuestPreferences(guestData['id']);
      await _storeUserPreferences(userId, preferences);
      
      // Migrate flashcard progress
      await _migrateFlashcardProgress(guestData['id'], userId);
      
      // Clean up guest data
      await WorkingSecureAuthStorage.clearGuestData();
      debugPrint('✅ Guest data migration completed');
    }
  } catch (e) {
    debugPrint('❌ Guest data migration failed: $e');
    // Log error but don't block authentication
  }
}
```

**Benefits**:
- Seamless user experience
- Data preservation
- Error isolation
- Comprehensive migration

---

### **Pattern 10: Configuration-Based Feature Control**

**Implementation**:
```dart
class AuthConfig {
  // Feature flags
  static bool enableAuthentication = true;
  static bool enableUsageLimits = true;
  static bool enableGuestTracking = true;
  
  // Usage limits
  static int guestMaxGradingActions = 3;
  static int guestMaxInterviewActions = 3;
  static int authenticatedMaxGradingActions = 5;
  static int authenticatedMaxInterviewActions = 5;
  
  // Development flags
  static bool enableDemoMode = true;
  static bool enableAuthDebugLogging = false;
  
  // Environment-specific overrides
  static void configureForEnvironment(Environment env) {
    switch (env) {
      case Environment.dev:
        enableDemoMode = true;
        enableAuthDebugLogging = true;
        break;
      case Environment.prod:
        enableDemoMode = false;
        enableAuthDebugLogging = false;
        break;
    }
  }
}
```

**Benefits**:
- Easy feature toggles
- Environment-specific configuration
- A/B testing support
- Gradual rollout capability

---

## Error Handling Patterns

### **Pattern 11: Graceful Authentication Error Handling**

**Implementation**:
```dart
String _getErrorMessage(dynamic error) {
  final errorString = error.toString().toLowerCase();
  
  if (errorString.contains('invalid_credentials')) {
    return 'Invalid email or password';
  } else if (errorString.contains('email_provider_disabled')) {
    return 'Email authentication is temporarily unavailable';
  } else if (errorString.contains('user_already_exists')) {
    return 'An account with this email already exists';
  } else if (errorString.contains('weak_password')) {
    return 'Password is too weak';
  } else if (errorString.contains('invalid_email')) {
    return 'Please enter a valid email address';
  } else {
    return 'Authentication failed. Please try again.';
  }
}

// Usage in auth methods
Future<void> signInWithEmail(String email, String password) async {
  try {
    state = const AuthStateLoading();
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    debugPrint('✅ Email sign-in successful: $email');
  } catch (e) {
    debugPrint('❌ Email sign-in failed: $e');
    state = AuthStateError(_getErrorMessage(e));
  }
}
```

**Benefits**:
- User-friendly error messages
- Consistent error handling
- Debugging information preserved
- Localization ready

---

## Testing Patterns

### **Pattern 12: Authentication Testing Strategy**

**Implementation**:
```dart
// Mock providers for testing
class MockAuthNotifier extends StateNotifier<AuthState> {
  MockAuthNotifier() : super(const AuthStateInitial());
  
  void mockSignIn(User user) {
    state = AuthStateAuthenticated(user);
  }
  
  void mockSignOut() {
    state = const AuthStateUnauthenticated();
  }
  
  void mockError(String error) {
    state = AuthStateError(error);
  }
}

// Test usage
void main() {
  group('Authentication Tests', () {
    late MockAuthNotifier mockAuth;
    
    setUp(() {
      mockAuth = MockAuthNotifier();
    });
    
    test('should handle successful sign in', () {
      // Arrange
      final user = User(id: 'test-id', email: 'test@example.com');
      
      // Act
      mockAuth.mockSignIn(user);
      
      // Assert
      expect(mockAuth.state, isA<AuthStateAuthenticated>());
      expect((mockAuth.state as AuthStateAuthenticated).user.id, 'test-id');
    });
    
    test('should handle usage limits correctly', () async {
      // Test usage tracking
      final tracker = SimpleActionTracker(mockRef);
      
      expect(tracker.canPerformAction(ActionType.flashcardGrading), true);
      
      await tracker.recordAction(ActionType.flashcardGrading);
      
      // Verify state changes
    });
  });
}
```

**Benefits**:
- Isolated testing
- Predictable state management
- Easy mocking
- Comprehensive coverage

---

## Performance Patterns

### **Pattern 13: Lazy Initialization and Caching**

**Implementation**:
```dart
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  SupabaseClient? _client;
  SupabaseClient get client => _client ??= Supabase.instance.client;
  
  StreamController<AuthState>? _authController;
  Stream<AuthState> get authStateChanges {
    _authController ??= StreamController<AuthState>.broadcast();
    
    // Subscribe to Supabase auth changes only when needed
    client.auth.onAuthStateChange.listen((data) {
      _authController!.add(_mapSupabaseAuthState(data));
    });
    
    return _authController!.stream;
  }
  
  AuthService._();
}
```

**Benefits**:
- Resource efficiency
- Lazy loading
- Memory optimization
- Clean singleton pattern

---

## Best Practices Summary

### **Do's**
- ✅ Choose single state management approach
- ✅ Use simple classes for basic authentication
- ✅ Implement platform-specific UI patterns
- ✅ Plan for guest-to-authenticated migration
- ✅ Use configuration-based feature control
- ✅ Implement graceful error handling
- ✅ Test authentication flows thoroughly

### **Don'ts**
- ❌ Mix Provider and Riverpod in same codebase
- ❌ Over-engineer simple authentication states
- ❌ Ignore platform UX differences
- ❌ Store sensitive data insecurely
- ❌ Block UI during background auth operations
- ❌ Lose user data during authentication transitions

### **Architecture Principles**
1. **Simplicity over perfection**
2. **User experience first**
3. **Gradual complexity introduction**
4. **Clear separation of concerns**
5. **Testable and maintainable code**

This pattern collection provides proven approaches for implementing robust, maintainable authentication systems in Flutter applications.
