# Pure BLoC Migration Troubleshooting Guide

## 🚨 **Common Issues & Solutions**

This guide provides solutions for common issues encountered during the Pure BLoC migration, organized by phase and problem type.

---

## 🎯 **Quick Issue Diagnosis**

### **Issue Categories**

| Category | Symptoms | Common Causes |
|----------|----------|---------------|
| **Compilation** | Build errors, import issues | Missing dependencies, incorrect paths |
| **State Management** | UI not updating, wrong state | BLoC event/state issues, provider setup |
| **Data Persistence** | Data loss, sync issues | Repository problems, storage failures |
| **Performance** | Slow UI, memory leaks | Excessive rebuilds, unclosed streams |
| **Testing** | Test failures, mock issues | Incorrect setup, missing dependencies |

---

## 🔧 **Phase-Specific Issues**

## **Phase 1: Foundation Setup Issues**

### **Issue 1.1: Compilation Errors**

#### **Problem: Missing BLoC Dependencies**
```
Error: 'flutter_bloc' is not a recognized package
Error: Could not find package 'equatable'
```

**Solution**:
```yaml
# pubspec.yaml - ensure correct versions
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  get_it: ^7.6.4

# Run after adding
flutter pub get
flutter clean
flutter pub get
```

#### **Problem: Service Locator Registration Errors**
```
Error: Could not find dependency FlashcardRepository
Error: GetIt: Object/factory with type FlashcardBloc is not registered
```

**Solution**:
```dart
// lib/core/service_locator.dart - check registration order
Future<void> setupServiceLocator() async {
  // 1. Register dependencies first
  sl.registerLazySingleton<StorageService>(() => StorageService());
  
  // 2. Register repositories second
  sl.registerLazySingleton<FlashcardRepository>(
    () => FlashcardRepository(localStorage: sl<StorageService>()),
  );
  
  // 3. Register BLoCs last
  sl.registerFactory<FlashcardBloc>(
    () => FlashcardBloc(repository: sl<FlashcardRepository>()),
  );
}
```

### **Issue 1.2: Repository Integration Problems**

#### **Problem: Repository Not Loading Data**
```
FlashcardBloc shows empty state despite data in storage
```

**Solution**:
```dart
// Check repository initialization
@override
Future<List<FlashcardSet>> getAll() async {
  if (!_isInitialized) {
    await _loadFromLocalStorage(); // ← Ensure this is called
    _isInitialized = true;
  }
  return List.unmodifiable(_cache);
}

// Verify storage service
Future<void> _loadFromLocalStorage() async {
  try {
    final data = await _localStorage.getFlashcardSets();
    _cache.clear();
    _cache.addAll(data);
    debugPrint('📥 Loaded ${_cache.length} sets'); // ← Add logging
  } catch (e) {
    debugPrint('❌ Load error: $e'); // ← Check for errors
  }
}
```

---

## **Phase 2: Authentication Migration Issues**

### **Issue 2.1: AuthBloc State Problems**

#### **Problem: AuthBloc Not Emitting States**
```
AuthBloc stuck in AuthInitial state
UI not updating on authentication changes
```

**Solution**:
```dart
// Check AuthBloc constructor
AuthBloc({required AuthRepository repository})
    : _repository = repository,
      super(AuthInitial()) {
  
  on<AuthInitialized>(_onInitialized);
  // ← Ensure all events are registered
  
  // ← Ensure stream subscription
  _userSubscription = _repository.watchAuthState().listen((user) {
    add(AuthUserChanged(user));
  });
}

// Verify repository stream
Stream<User?> watchAuthState() {
  return _cloudService.client?.auth.onAuthStateChange
      .map((data) => _mapSupabaseUser(data.session?.user))
      ?? Stream.value(null); // ← Provide fallback
}
```

#### **Problem: Cross-System Dependencies Still Present**
```
Error: 'WidgetRef' is not defined
Error: Provider.of called without ancestor
```

**Solution**:
```dart
// Remove all Riverpod/Provider references from StudyBloc
class StudyBloc extends Bloc<StudyEvent, StudyState> {
  // ❌ Remove: final WidgetRef _ref;
  // ❌ Remove: final middleware = _ref.read(provider);
  
  // ✅ Add: Direct BLoC dependencies
  final FlashcardBloc _flashcardBloc;
  
  StudyBloc({
    required FlashcardBloc flashcardBloc, // ✅ Pure BLoC injection
  }) : _flashcardBloc = flashcardBloc;
}
```

---

## **Phase 3: Study Flow Migration Issues (CRITICAL)**

### **Issue 3.1: Progress Bar Still Disappearing**

#### **Problem: Race Condition Not Fixed**
```
Progress shows briefly then disappears
Same bug as before migration
```

**Diagnosis Steps**:
```dart
// 1. Check StudyBloc coordination
Future<void> _onFlashcardAnswered(FlashcardAnswered event, Emitter<StudyState> emit) async {
  // ✅ Must call FlashcardBloc
  _flashcardBloc.add(FlashcardProgressUpdated(
    setId: state.flashcardSet!.id,
    cardId: event.flashcard.id,
    isCompleted: true,
  ));
  
  // ✅ Must emit updated local state
  emit(state.copyWith(flashcardSet: updatedSet));
}

// 2. Check FlashcardBloc handling
Future<void> _onProgressUpdated(FlashcardProgressUpdated event, Emitter<FlashcardState> emit) async {
  // ✅ Must save through repository
  await _repository.save(updatedSet);
  // ✅ Repository must notify stream immediately
}

// 3. Check Repository stream emission
Future<void> save(FlashcardSet item) async {
  _updateCache(item);
  await _saveToLocalStorage();
  _dataController.add(List.unmodifiable(_cache)); // ✅ Critical line
}
```

**Solution - Add Extensive Logging**:
```dart
// Add debug logging to track data flow
debugPrint('🎯 StudyBloc: Triggering progress update for ${event.cardId}');
_flashcardBloc.add(FlashcardProgressUpdated(...));

debugPrint('🎯 FlashcardBloc: Received progress update');
await _repository.save(updatedSet);

debugPrint('🎯 Repository: Saved and notifying stream');
_dataController.add(List.unmodifiable(_cache));
```

#### **Problem: StudyBloc and FlashcardBloc Out of Sync**
```
StudyBloc shows different data than FlashcardBloc
UI inconsistency
```

**Solution**:
```dart
// Add StudySetUpdated event handling
class StudyScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ✅ Listen to FlashcardBloc changes
        BlocListener<FlashcardBloc, FlashcardState>(
          listener: (context, state) {
            if (state is FlashcardLoaded) {
              final studyBloc = context.read<StudyBloc>();
              final currentSet = studyBloc.state.flashcardSet;
              
              if (currentSet != null) {
                final updatedSet = state.flashcardSets
                    .firstWhere((set) => set.id == currentSet.id);
                
                // ✅ Sync StudyBloc with latest data
                studyBloc.add(StudySetUpdated(updatedSet));
              }
            }
          },
        ),
      ],
      // ...
    );
  }
}
```

### **Issue 3.2: Performance Degradation**

#### **Problem: Too Many UI Rebuilds**
```
UI becomes slow during study session
Excessive widget rebuilds
```

**Diagnosis**:
```dart
// Add rebuild counter for debugging
class _HomeScreenState extends State<HomeScreen> {
  int _rebuildCount = 0;
  
  @override
  Widget build(BuildContext context) {
    _rebuildCount++;
    debugPrint('🏠 HomeScreen rebuild #$_rebuildCount');
    
    return BlocBuilder<FlashcardBloc, FlashcardState>(
      builder: (context, state) {
        // Check if state is properly equatable
      },
    );
  }
}
```

**Solution**:
```dart
// Ensure proper Equatable implementation
class FlashcardLoaded extends FlashcardState {
  final List<FlashcardSet> flashcardSets;
  
  const FlashcardLoaded(this.flashcardSets);
  
  @override
  List<Object?> get props => [flashcardSets]; // ✅ Proper props
}

// Check FlashcardSet equality
class FlashcardSet extends Equatable {
  @override
  List<Object?> get props => [
    id, title, description, flashcards, lastUpdated // ✅ All fields
  ];
}
```

---

## **Phase 4: Sync & Network Migration Issues**

### **Issue 4.1: Sync Operations Failing**

#### **Problem: Upload Errors**
```
Error uploading to Supabase
Network timeouts
Authentication failures
```

**Solution**:
```dart
// Add retry logic and better error handling
Future<void> _uploadSetToCloud(FlashcardSet set) async {
  int retryCount = 0;
  const maxRetries = 3;
  
  while (retryCount < maxRetries) {
    try {
      // Check authentication first
      if (!_cloudService.isAuthenticated) {
        throw Exception('Not authenticated');
      }
      
      // Validate data before upload
      final setUuid = _ensureValidUuid(set.id);
      if (setUuid.isEmpty) {
        throw Exception('Invalid set ID');
      }
      
      // Upload with timeout
      await _cloudService.client!
          .from('flashcard_sets')
          .upsert({...})
          .timeout(Duration(seconds: 30));
          
      break; // Success
      
    } catch (e) {
      retryCount++;
      debugPrint('❌ Upload attempt $retryCount failed: $e');
      
      if (retryCount >= maxRetries) {
        rethrow;
      }
      
      // Wait before retry
      await Future.delayed(Duration(seconds: retryCount * 2));
    }
  }
}
```

#### **Problem: Sync Conflicts**
```
Data conflicts between local and cloud
Overwrites occurring
```

**Solution**:
```dart
// Implement proper conflict resolution
Future<void> resolveSyncConflicts() async {
  final localSets = await _localStorage.getFlashcardSets();
  final cloudSets = await _downloadChanges();
  
  for (final cloudSet in cloudSets) {
    final localSet = localSets.firstWhere(
      (set) => set.id == cloudSet.id,
      orElse: () => null,
    );
    
    if (localSet != null) {
      // Conflict resolution: latest timestamp wins
      final resolvedSet = localSet.lastUpdated.isAfter(cloudSet.lastUpdated)
          ? localSet
          : cloudSet;
          
      await _repository.save(resolvedSet);
    }
  }
}
```

---

## **Phase 5: UI & Services Migration Issues**

### **Issue 5.1: Provider References Still Present**

#### **Problem: Mixed State Management**
```
Error: Provider.of called without ancestor
BlocProvider and Provider conflicts
```

**Solution**:
```dart
// Find and replace all Provider usage
// ❌ Remove:
final flashcardService = Provider.of<FlashcardService>(context);

// ✅ Replace with:
BlocBuilder<FlashcardBloc, FlashcardState>(
  builder: (context, state) {
    if (state is FlashcardLoaded) {
      return _buildContent(state.flashcardSets);
    }
    return CircularProgressIndicator();
  },
)
```

### **Issue 5.2: Debug Panel Not Working**

#### **Problem: Debug Panel Shows No Data**
```
Debug panel empty
State not updating
```

**Solution**:
```dart
// Ensure proper BLoC listening
class AuthDebugPanel extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocBuilder(
      blocs: [
        context.watch<AuthBloc>(),
        context.watch<SyncBloc>(),
        context.watch<FlashcardBloc>(),
      ],
      builder: (context, states) {
        final authState = states[0] as AuthState;
        final syncState = states[1] as SyncState;
        final flashcardState = states[2] as FlashcardState;
        
        return _buildDebugContent(authState, syncState, flashcardState);
      },
    );
  }
}
```

---

## **Phase 6: Cleanup & Testing Issues**

### **Issue 6.1: Test Failures**

#### **Problem: BLoC Tests Not Working**
```
blocTest fails with state mismatch
Mock setup issues
```

**Solution**:
```dart
// Proper test setup
void main() {
  group('FlashcardBloc', () {
    late FlashcardBloc flashcardBloc;
    late MockFlashcardRepository mockRepository;

    setUp(() {
      mockRepository = MockFlashcardRepository();
      
      // ✅ Register fallback values
      registerFallbackValue(TestDataBuilder.createTestFlashcardSet());
      
      flashcardBloc = FlashcardBloc(repository: mockRepository);
    });

    tearDown(() {
      flashcardBloc.close(); // ✅ Always close BLoCs
    });

    blocTest<FlashcardBloc, FlashcardState>(
      'emits correct state when data loads',
      build: () {
        // ✅ Setup mocks before building BLoC
        when(() => mockRepository.getAll())
            .thenAnswer((_) async => [TestDataBuilder.createTestFlashcardSet()]);
        return flashcardBloc;
      },
      act: (bloc) => bloc.add(FlashcardLoadRequested()),
      expect: () => [
        FlashcardLoading(),
        isA<FlashcardLoaded>(), // ✅ Use isA for complex states
      ],
    );
  });
}
```

#### **Problem: Integration Tests Failing**
```
Widget tests can't find BLoC providers
Context issues
```

**Solution**:
```dart
testWidgets('Widget test with proper BLoC setup', (tester) async {
  // ✅ Provide all necessary BLoCs
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<FlashcardBloc>.value(value: mockFlashcardBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: HomeScreen(),
      ),
    ),
  );
  
  // ✅ Wait for initial state
  await tester.pump();
  
  // Now test widget behavior
});
```

---

## 🔍 **Debugging Techniques**

### **Logging Strategy**

#### **Add Comprehensive Logging**
```dart
// In BLoCs
@override
void onChange(Change<StudyState> change) {
  super.onChange(change);
  debugPrint('🎓 StudyBloc: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}');
}

// In Repositories
Future<void> save(FlashcardSet item) async {
  debugPrint('📦 Repository: Saving ${item.title}');
  _updateCache(item);
  debugPrint('📦 Repository: Cache updated');
  await _saveToLocalStorage();
  debugPrint('📦 Repository: Local storage updated');
  _dataController.add(List.unmodifiable(_cache));
  debugPrint('📦 Repository: Stream notified');
}
```

#### **State Inspection**
```dart
// Add BLoC observer for debugging
class DebugBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType}: ${change.currentState} → ${change.nextState}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print('ERROR in ${bloc.runtimeType}: $error');
  }
}

// In main.dart
void main() {
  if (kDebugMode) {
    Bloc.observer = DebugBlocObserver();
  }
  runApp(MyApp());
}
```

### **Performance Monitoring**

#### **Rebuild Counter**
```dart
class RebuildCounter extends StatefulWidget {
  final Widget child;
  final String name;
  
  const RebuildCounter({required this.child, required this.name});

  @override
  _RebuildCounterState createState() => _RebuildCounterState();
}

class _RebuildCounterState extends State<RebuildCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    _count++;
    debugPrint('🔄 ${widget.name} rebuild #$_count');
    return widget.child;
  }
}

// Usage
RebuildCounter(
  name: 'HomeScreen',
  child: BlocBuilder<FlashcardBloc, FlashcardState>(
    builder: (context, state) => _buildContent(state),
  ),
)
```

---

## 📋 **Prevention Checklist**

### **Before Each Phase**
- [ ] Review phase documentation thoroughly
- [ ] Set up proper development environment
- [ ] Create backup of current working state
- [ ] Plan rollback strategy

### **During Implementation**
- [ ] Follow test-driven development
- [ ] Add extensive logging for debugging
- [ ] Test each component in isolation
- [ ] Validate integration points

### **Before Phase Completion**
- [ ] Run comprehensive test suite
- [ ] Validate performance metrics
- [ ] Check for memory leaks
- [ ] Review code for anti-patterns

---

## 🚨 **Emergency Procedures**

### **If Migration Breaks App**

#### **Immediate Rollback**
```bash
# 1. Revert to last working commit
git checkout [last-working-commit]

# 2. Restore dependencies
flutter pub get

# 3. Verify app works
flutter run
```

#### **Partial Rollback Strategy**
```dart
// 1. Comment out new BLoC providers in main.dart
// return MultiBlocProvider(
//   providers: [
//     // BlocProvider<FlashcardBloc>(...),  ← Comment out
//   ],
//   child: ProviderScope(  // ← Keep existing
//     child: MultiProvider( // ← Keep existing
```

### **If Data Corruption Occurs**

#### **Data Recovery**
```dart
// 1. Check for backup data
final backupData = await _localStorage.getBackupData();

// 2. Restore from backup
if (backupData.isNotEmpty) {
  await _localStorage.restoreFromBackup(backupData);
}

// 3. Verify data integrity
final restoredSets = await _localStorage.getFlashcardSets();
for (final set in restoredSets) {
  if (!_isValidFlashcardSet(set)) {
    debugPrint('⚠️ Invalid set detected: ${set.id}');
  }
}
```

---

## 📞 **Getting Help**

### **Internal Resources**
- [Migration Master Plan](../MIGRATION_MASTER_PLAN.md)
- [Architecture Documentation](../architecture/)
- [Testing Guides](../testing/)
- [Implementation Guides](../phases/)

### **External Resources**
- [BLoC Documentation](https://bloclibrary.dev/)
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Equatable Package](https://pub.dev/packages/equatable)

### **Community Support**
- [BLoC Discord](https://discord.gg/Hc5KD3g)
- [Flutter Community](https://discord.gg/N7Yshp4)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter-bloc)

---

**📅 Created**: 2025-07-02
**🔄 Last Updated**: 2025-07-02
**👤 Maintained By**: Development Team
**📋 Review Schedule**: Updated as issues are encountered and resolved
