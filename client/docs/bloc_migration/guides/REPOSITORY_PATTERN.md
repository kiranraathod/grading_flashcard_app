# Repository Pattern Implementation Guide

## 🏗️ **Repository Pattern Overview**

The Repository pattern provides a **clean abstraction layer** between BLoCs and data sources, enabling testable business logic and coordinated data operations critical for eliminating the progress bar bug.

---

## 🎯 **Why Repository Pattern**

### **Benefits for FlashMaster Migration**

1. **Single Source of Truth**: Repository owns data caching and coordination
2. **Testable BLoCs**: Business logic isolated from data access details
3. **Coordinated Operations**: Eliminates race conditions between local/cloud storage
4. **Clean Architecture**: Clear separation between business logic and data access

### **Solves Current Issues**

- **Race Conditions**: Repository coordinates local/cloud operations
- **Data Inconsistency**: Single cache managed by repository
- **Testing Complexity**: Easy to mock for unit tests
- **Coupling**: BLoCs don't depend on specific storage implementations

---

## 📊 **Repository Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                          BLoC Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │FlashcardBloc│  │   AuthBloc  │  │  SyncBloc   │  │StudyBloc│ │
│  │             │  │             │  │             │  │         │ │
│  │• Business   │  │• Auth Logic │  │• Sync Logic │  │• Study  │ │
│  │  Logic      │  │• Validation │  │• Conflicts  │  │  Logic  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Repository Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │FlashcardRepo│  │   AuthRepo  │  │  SyncRepo   │  │ApiRepo  │ │
│  │             │  │             │  │             │  │         │ │
│  │• Data Cache │  │• User Cache │  │• Queue Mgmt │  │• HTTP   │ │
│  │• Local/Cloud│  │• Auth State │  │• Conflict   │  │• Retry  │ │
│  │• Streams    │  │• Migration  │  │  Resolution │  │• Cache  │ │
│  │• Validation │  │• Sessions   │  │• Timestamps │  │• Error  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                       Data Sources                             │
│     ┌─────────┐        ┌─────────┐        ┌─────────┐          │
│     │  Hive   │        │Supabase │        │  HTTP   │          │
│     │Database │        │Database │        │  API    │          │
│     └─────────┘        └─────────┘        └─────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔧 **Repository Interface Design**

### **Base Repository Interface**

**File**: `lib/repositories/base_repository.dart`

```dart
/// Base repository interface for all data types
abstract class BaseRepository<T> {
  /// Get all items of type T
  Future<List<T>> getAll();
  
  /// Get specific item by ID
  Future<T?> getById(String id);
  
  /// Save or update an item
  Future<void> save(T item);
  
  /// Delete an item by ID
  Future<void> delete(String id);
  
  /// Clear all items (use with caution)
  Future<void> clear();
  
  /// Watch for real-time updates
  Stream<List<T>> watchAll();
  
  /// Dispose of resources
  void dispose();
}

/// Extended interface for repositories that support cloud sync
abstract class SyncableRepository<T> extends BaseRepository<T> {
  /// Sync local changes to cloud
  Future<void> syncToCloud();
  
  /// Download changes from cloud
  Future<void> syncFromCloud();
  
  /// Resolve sync conflicts
  Future<void> resolveSyncConflicts();
  
  /// Watch sync status
  Stream<SyncStatus> get syncStatus;
  
  /// Queue item for sync
  Future<void> queueForSync(String itemId);
}
```

### **Repository Benefits**

1. **Consistent Interface**: All repositories follow same pattern
2. **Easy Testing**: Simple to mock for unit tests
3. **Stream Support**: Real-time updates for reactive UI
4. **Sync Coordination**: Built-in support for cloud synchronization

---

## 📱 **FlashcardRepository Implementation**

### **Core Implementation**

**File**: `lib/repositories/flashcard_repository.dart`

```dart
class FlashcardRepository implements SyncableRepository<FlashcardSet> {
  // Dependencies
  final StorageService _localStorage;
  final SupabaseService _cloudService;
  final NetworkService _networkService;
  
  // Internal state
  final List<FlashcardSet> _cache = [];
  final List<String> _syncQueue = [];
  bool _isInitialized = false;
  
  // Stream controllers for reactive updates
  final _dataController = StreamController<List<FlashcardSet>>.broadcast();
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  FlashcardRepository({
    required StorageService localStorage,
    required SupabaseService cloudService,
    required NetworkService networkService,
  }) : _localStorage = localStorage,
       _cloudService = cloudService,
       _networkService = networkService;

  @override
  Future<List<FlashcardSet>> getAll() async {
    if (!_isInitialized) {
      await _loadFromLocalStorage();
      _isInitialized = true;
    }
    return List.unmodifiable(_cache);
  }

  @override
  Future<FlashcardSet?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((set) => set.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> save(FlashcardSet item) async {
    try {
      // 1. Update local cache immediately
      _updateCache(item);
      
      // 2. Save to local storage for persistence
      await _saveToLocalStorage();
      
      // 3. Notify UI immediately (critical for progress updates)
      _dataController.add(List.unmodifiable(_cache));
      
      // 4. Queue for cloud sync (non-blocking)
      if (_cloudService.isAuthenticated) {
        await queueForSync(item.id);
      }
      
      debugPrint('✅ Repository saved: ${item.title} - immediate UI update, queued for sync');
      
    } catch (e) {
      debugPrint('❌ Repository save error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<FlashcardSet>> watchAll() {
    // Start loading data if not already loaded
    getAll();
    return _dataController.stream;
  }

  @override
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  @override
  Future<void> queueForSync(String itemId) async {
    if (!_syncQueue.contains(itemId)) {
      _syncQueue.add(itemId);
      debugPrint('📤 Queued for sync: $itemId');
    }
  }

  // Private implementation methods
  
  void _updateCache(FlashcardSet item) {
    final index = _cache.indexWhere((set) => set.id == item.id);
    if (index >= 0) {
      _cache[index] = item;
    } else {
      _cache.add(item);
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final data = await _localStorage.getFlashcardSets();
      _cache.clear();
      _cache.addAll(data);
      debugPrint('📥 Loaded ${_cache.length} sets from local storage');
    } catch (e) {
      debugPrint('⚠️ Error loading from storage: $e');
      // Continue with empty cache rather than failing
    }
  }

  Future<void> _saveToLocalStorage() async {
    try {
      await _localStorage.saveFlashcardSets(
        _cache.map((set) => set.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('❌ Error saving to local storage: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _dataController.close();
    _syncStatusController.close();
  }
}
```

### **Key Features Explained**

#### **1. Immediate UI Updates**
```dart
// Save operation provides immediate feedback
await _saveToLocalStorage();                    // Persist immediately
_dataController.add(List.unmodifiable(_cache)); // Notify UI immediately
await queueForSync(item.id);                    // Queue sync (non-blocking)
```

#### **2. Race Condition Prevention**
```dart
// Local operations are immediate and synchronous
void _updateCache(FlashcardSet item) {
  final index = _cache.indexWhere((set) => set.id == item.id);
  if (index >= 0) {
    _cache[index] = item; // ✅ Immediate local update
  }
}

// Cloud operations are queued and coordinated
Future<void> queueForSync(String itemId) async {
  _syncQueue.add(itemId); // ✅ Queue for later, don't block
}
```

#### **3. Stream-Based Updates**
```dart
// BLoCs subscribe to repository streams
Stream<List<FlashcardSet>> watchAll() {
  return _dataController.stream; // ✅ Real-time updates
}

// Repository emits updates when data changes
_dataController.add(List.unmodifiable(_cache)); // ✅ Trigger UI rebuild
```

---

## 🔄 **AuthRepository Implementation**

### **Authentication Data Management**

**File**: `lib/repositories/auth_repository.dart`

```dart
class AuthRepository {
  final SupabaseService _cloudService;
  final StorageService _localStorage;
  
  User? _currentUser;
  String? _guestId;
  
  AuthRepository({
    required SupabaseService cloudService,
    required StorageService localStorage,
  }) : _cloudService = cloudService,
       _localStorage = localStorage;

  Stream<User?> watchAuthState() {
    return _cloudService.client?.auth.onAuthStateChange
        .map((data) => _mapSupabaseUser(data.session?.user))
        ?? Stream.value(null);
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    final supabaseUser = _cloudService.client?.auth.currentUser;
    _currentUser = _mapSupabaseUser(supabaseUser);
    return _currentUser;
  }

  Future<User> signIn(String email, String password) async {
    try {
      final response = await _cloudService.client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AuthException('Sign in failed');
      }
      
      _currentUser = _mapSupabaseUser(response.user)!;
      
      // Trigger data migration if user had guest data
      await _handleAuthTransition();
      
      return _currentUser!;
    } catch (e) {
      throw AuthException('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _cloudService.client?.auth.signOut();
    _currentUser = null;
  }

  Future<String> createGuestSession() async {
    _guestId = 'guest_${const Uuid().v4()}';
    await _localStorage.storeGuestId(_guestId!);
    return _guestId!;
  }

  Future<void> _handleAuthTransition() async {
    // Handle guest-to-authenticated data migration
    // This coordinates with data migration services
  }

  User? _mapSupabaseUser(SupabaseUser? supabaseUser) {
    if (supabaseUser == null) return null;
    
    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      name: supabaseUser.userMetadata?['name'] ?? 'User',
      isGuest: false,
    );
  }
}
```

---

## 🌐 **SyncRepository Implementation**

### **Coordinated Sync Operations**

**File**: `lib/repositories/sync_repository.dart`

```dart
class SyncRepository {
  final SupabaseService _cloudService;
  final StorageService _localStorage;
  final NetworkService _networkService;
  
  final _statusController = StreamController<SyncStatus>.broadcast();
  final List<String> _syncQueue = [];
  DateTime? _lastSyncTime;

  SyncRepository({
    required SupabaseService cloudService,
    required StorageService localStorage,
    required NetworkService networkService,
  }) : _cloudService = cloudService,
       _localStorage = localStorage,
       _networkService = networkService;

  Stream<SyncStatus> get syncStatus => _statusController.stream;

  Stream<bool> watchNetworkStatus() {
    return _networkService.connectivityStream
        .map((status) => status != ConnectivityResult.none);
  }

  Future<bool> isOnline() async {
    return await _networkService.isConnected();
  }

  Future<int> uploadPendingChanges() async {
    _statusController.add(SyncStatus.syncing);
    int uploadCount = 0;
    
    try {
      // Process sync queue items
      for (final setId in List.from(_syncQueue)) {
        try {
          await syncSpecificSet(setId);
          _syncQueue.remove(setId);
          uploadCount++;
        } catch (e) {
          debugPrint('Failed to upload set $setId: $e');
          // Keep in queue for retry
        }
      }
      
      return uploadCount;
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  Future<List<FlashcardSet>> downloadChanges() async {
    if (!_cloudService.isAuthenticated) return [];
    
    final since = _lastSyncTime ?? DateTime.now().subtract(Duration(days: 30));
    
    try {
      final response = await _cloudService.client!
          .from('flashcard_sets')
          .select('*, flashcards(*)')
          .eq('user_id', _cloudService.currentUserId!)
          .eq('is_deleted', false)
          .gte('updated_at', since.toIso8601String());
      
      final changes = <FlashcardSet>[];
      for (final item in response) {
        changes.add(FlashcardSet.fromJson(item));
      }
      
      debugPrint('📱 Downloaded ${changes.length} changed sets');
      return changes;
      
    } catch (e) {
      debugPrint('❌ Error downloading changes: $e');
      rethrow;
    }
  }

  Future<void> syncSpecificSet(String setId) async {
    try {
      // Get local set data
      final localSets = await _localStorage.getFlashcardSets();
      final localSet = localSets.firstWhere((set) => set.id == setId);
      
      // Upload to cloud with proper conflict resolution
      await _uploadSetToCloud(localSet);
      
      debugPrint('✅ Successfully synced set: ${localSet.title}');
      
    } catch (e) {
      debugPrint('❌ Sync error for set $setId: $e');
      rethrow;
    }
  }

  Future<void> _uploadSetToCloud(FlashcardSet set) async {
    if (!_cloudService.isAuthenticated) {
      throw Exception('Not authenticated for cloud upload');
    }

    try {
      final setUuid = _ensureValidUuid(set.id);
      
      // Use upsert for conflict resolution
      await _cloudService.client!
          .from('flashcard_sets')
          .upsert({
            'id': setUuid,
            'user_id': _cloudService.currentUserId!,
            'title': set.title.trim(),
            'description': set.description,
            'is_draft': set.isDraft,
            'rating': set.rating,
            'rating_count': set.ratingCount,
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Upload flashcards with progress data
      for (final card in set.flashcards) {
        final cardUuid = _ensureValidUuid(card.id);
        
        await _cloudService.client!
            .from('flashcards')
            .upsert({
              'id': cardUuid,
              'flashcard_set_id': setUuid,
              'question': card.question,
              'answer': card.answer,
              'is_completed': card.isCompleted, // 🎯 CRITICAL: Upload progress
              'is_marked_for_review': card.isMarkedForReview,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
      debugPrint('✅ Uploaded set with progress: ${set.title}');
      
    } catch (e) {
      debugPrint('❌ Upload error for ${set.title}: $e');
      rethrow;
    }
  }

  Future<void> markSyncComplete() async {
    _lastSyncTime = DateTime.now();
    _statusController.add(SyncStatus.synced);
  }

  String _ensureValidUuid(String? id) {
    if (id == null || id.isEmpty || !_isValidUuid(id)) {
      return const Uuid().v4();
    }
    return id;
  }

  bool _isValidUuid(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(id);
  }

  void dispose() {
    _statusController.close();
  }
}
```

---

## 🧪 **Repository Testing**

### **Unit Testing Repositories**

**File**: `test/repositories/flashcard_repository_test.dart`

```dart
void main() {
  group('FlashcardRepository', () {
    late FlashcardRepository repository;
    late MockStorageService mockStorage;
    late MockSupabaseService mockCloud;
    late MockNetworkService mockNetwork;

    setUp(() {
      mockStorage = MockStorageService();
      mockCloud = MockSupabaseService();
      mockNetwork = MockNetworkService();
      
      repository = FlashcardRepository(
        localStorage: mockStorage,
        cloudService: mockCloud,
        networkService: mockNetwork,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('save', () {
      test('updates cache and notifies stream immediately', () async {
        // Setup
        final testSet = TestDataBuilder.createTestFlashcardSet();
        final streamUpdates = <List<FlashcardSet>>[];
        
        repository.watchAll().listen(streamUpdates.add);
        
        when(() => mockStorage.saveFlashcardSets(any()))
            .thenAnswer((_) async {});
        
        // Act
        await repository.save(testSet);
        await Future.delayed(Duration.zero); // Allow stream emission
        
        // Assert
        expect(streamUpdates.length, equals(1));
        expect(streamUpdates.first.first.id, equals(testSet.id));
        verify(() => mockStorage.saveFlashcardSets(any())).called(1);
      });

      test('queues for sync when authenticated', () async {
        // Setup
        final testSet = TestDataBuilder.createTestFlashcardSet();
        
        when(() => mockCloud.isAuthenticated).thenReturn(true);
        when(() => mockStorage.saveFlashcardSets(any()))
            .thenAnswer((_) async {});
        
        // Act
        await repository.save(testSet);
        
        // Assert - verify sync queuing (implementation specific)
        // This would verify internal queue state
      });
    });

    group('watchAll', () {
      test('provides real-time updates', () async {
        // Setup
        final updates = <List<FlashcardSet>>[];
        repository.watchAll().listen(updates.add);
        
        when(() => mockStorage.getFlashcardSets())
            .thenAnswer((_) async => []);
        when(() => mockStorage.saveFlashcardSets(any()))
            .thenAnswer((_) async {});
        
        // Act
        final testSet1 = TestDataBuilder.createTestFlashcardSet(id: 'set1');
        final testSet2 = TestDataBuilder.createTestFlashcardSet(id: 'set2');
        
        await repository.save(testSet1);
        await repository.save(testSet2);
        await Future.delayed(Duration.zero);
        
        // Assert
        expect(updates.length, greaterThan(0));
        expect(updates.last.length, equals(2));
      });
    });
  });
}
```

---

## 📊 **Repository Performance Considerations**

### **Optimization Strategies**

#### **1. Caching Strategy**
```dart
// In-memory cache for fast access
final List<FlashcardSet> _cache = [];

// Load from storage only once
if (!_isInitialized) {
  await _loadFromLocalStorage();
  _isInitialized = true;
}
```

#### **2. Batch Operations**
```dart
// Batch multiple saves for efficiency
Future<void> saveAll(List<FlashcardSet> sets) async {
  for (final set in sets) {
    _updateCache(set);
  }
  await _saveToLocalStorage();
  _dataController.add(List.unmodifiable(_cache));
}
```

#### **3. Lazy Loading**
```dart
// Load data only when needed
Future<List<FlashcardSet>> getAll() async {
  if (!_isInitialized) {
    await _loadFromLocalStorage();
    _isInitialized = true;
  }
  return List.unmodifiable(_cache);
}
```

---

## 🎯 **Repository Pattern Success Metrics**

### **Implementation Success Criteria**

1. **✅ Data Abstraction**: BLoCs don't know about Hive/Supabase
2. **✅ Stream Updates**: Real-time UI updates work correctly
3. **✅ Race Condition Prevention**: No conflicts between local/cloud
4. **✅ Testing Simplicity**: Easy to mock for unit tests
5. **✅ Performance**: <100ms for local operations

### **Bug Fix Contribution**

- **Single Cache**: Eliminates competing data sources
- **Immediate Updates**: UI updates don't wait for sync
- **Coordinated Sync**: Cloud operations queued, not immediate
- **Stream Management**: Proper notification of data changes

---

**📅 Created**: 2025-07-02
**🏗️ Pattern**: Repository with Stream-based updates
**🎯 Focus**: Eliminate race conditions, enable testable BLoCs
**📊 Success Metric**: Coordinated data operations, 0% race conditions
