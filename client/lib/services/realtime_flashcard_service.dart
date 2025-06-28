import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../services/enhanced_supabase_service.dart';
import '../services/supabase_realtime_manager.dart';
import '../services/authentication_service.dart';

/// Dedicated real-time flashcard service for cross-device synchronization
///
/// Features:
/// - Real-time flashcard set synchronization
/// - Optimistic updates with conflict resolution
/// - Cross-device study progress sync
/// - Real-time collaboration capabilities
/// - Enhanced error handling and recovery
class RealtimeFlashcardService extends ChangeNotifier {
  static RealtimeFlashcardService? _instance;
  static RealtimeFlashcardService get instance =>
      _instance ??= RealtimeFlashcardService._();

  final EnhancedSupabaseService _supabaseService =
      EnhancedSupabaseService.instance;
  final SupabaseRealtimeManager _realtimeManager =
      SupabaseRealtimeManager.instance;
  final AuthenticationService _authService = AuthenticationService.instance;

  // Stream controllers for real-time updates
  final StreamController<FlashcardSet> _flashcardSetUpdatesController =
      StreamController<FlashcardSet>.broadcast();
  final StreamController<String> _flashcardSetDeletionsController =
      StreamController<String>.broadcast();
  final StreamController<RealtimeEvent> _realtimeEventsController =
      StreamController<RealtimeEvent>.broadcast();

  // Subscription management
  RealtimeSubscription? _flashcardSetsSubscription;
  RealtimeSubscription? _flashcardsSubscription;
  bool _isInitialized = false;

  // Optimistic update tracking
  final Set<String> _pendingOptimisticUpdates = {};

  RealtimeFlashcardService._();

  /// Stream of real-time flashcard set updates
  Stream<FlashcardSet> get flashcardSetUpdates =>
      _flashcardSetUpdatesController.stream;

  /// Stream of real-time flashcard set deletions
  Stream<String> get flashcardSetDeletions =>
      _flashcardSetDeletionsController.stream;

  /// Stream of real-time events (for debugging/monitoring)
  Stream<RealtimeEvent> get realtimeEvents => _realtimeEventsController.stream;

  /// Check if real-time service is active
  bool get isActive => _isInitialized && _realtimeManager.isConnected;

  /// Initialize real-time flashcard synchronization
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('RealtimeFlashcardService already initialized');
      return;
    }

    try {
      debugPrint('🚀 Initializing Real-time Flashcard Service...');

      // Ensure dependencies are ready
      await _ensureDependenciesReady();

      // Set up authentication listener
      _setupAuthenticationListener();

      // Initialize real-time subscriptions if user is authenticated
      final user = _authService.currentUser;
      if (user != null) {
        await _setupRealtimeSubscriptions(user.id);
      }

      _isInitialized = true;
      debugPrint('✅ Real-time Flashcard Service initialized');
      debugPrint('   📡 Real-time subscriptions ready');
      debugPrint('   🔄 Cross-device sync enabled');
    } catch (e) {
      debugPrint('❌ Real-time service initialization failed: $e');
      rethrow;
    }
  }

  /// Ensure all dependencies are ready
  Future<void> _ensureDependenciesReady() async {
    if (!_supabaseService.isInitialized) {
      await _supabaseService.initialize();
    }

    if (!_realtimeManager.isConnected) {
      await _realtimeManager.initialize();
    }
  }

  /// Set up authentication state listener
  void _setupAuthenticationListener() {
    _authService.addListener(_onAuthStateChanged);
  }

  /// Handle authentication state changes
  Future<void> _onAuthStateChanged() async {
    final user = _authService.currentUser;

    if (user != null) {
      debugPrint('👤 User authenticated, setting up real-time subscriptions');
      await _setupRealtimeSubscriptions(user.id);
    } else {
      debugPrint('🚪 User signed out, cleaning up real-time subscriptions');
      await _cleanupSubscriptions();
    }
  }

  /// Set up real-time subscriptions for flashcard data
  Future<void> _setupRealtimeSubscriptions(String userId) async {
    try {
      // Clean up existing subscriptions first
      await _cleanupSubscriptions();

      // Subscribe to flashcard_sets table
      await _setupFlashcardSetsSubscription(userId);

      // Subscribe to flashcards table for individual card updates
      await _setupFlashcardsSubscription(userId);

      debugPrint('✅ Real-time subscriptions established for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to setup real-time subscriptions: $e');
      _emitRealtimeEvent(
        RealtimeEventType.error,
        'Subscription setup failed: $e',
      );
    }
  }

  /// Set up flashcard sets subscription
  Future<void> _setupFlashcardSetsSubscription(String userId) async {
    final channel = _supabaseService.createRealtimeSubscription(
      channelName: 'flashcard_sets_realtime',
      table: 'flashcard_sets',
      userIdColumn: 'user_id',
      userId: userId,
      onInsert: _handleFlashcardSetInsert,
      onUpdate: _handleFlashcardSetUpdate,
      onDelete: _handleFlashcardSetDelete,
      onSubscribed: () {
        debugPrint('📡 Flashcard sets real-time subscription active');
        _emitRealtimeEvent(
          RealtimeEventType.subscribed,
          'Flashcard sets subscription active',
        );
      },
      onError: (error) {
        debugPrint('❌ Flashcard sets subscription error: $error');
        _emitRealtimeEvent(
          RealtimeEventType.error,
          'Flashcard sets error: $error',
        );
      },
    );

    _flashcardSetsSubscription = RealtimeSubscription(
      id: 'flashcard_sets_realtime',
      channel: channel,
      onResubscribed: () {
        debugPrint('🔄 Flashcard sets subscription restored');
        _emitRealtimeEvent(
          RealtimeEventType.reconnected,
          'Flashcard sets subscription restored',
        );
      },
    );

    _realtimeManager.registerSubscription(_flashcardSetsSubscription!);
  }

  /// Set up individual flashcards subscription
  Future<void> _setupFlashcardsSubscription(String userId) async {
    final channel = _supabaseService.createRealtimeSubscription(
      channelName: 'flashcards_realtime',
      table: 'flashcards',
      userIdColumn: 'user_id',
      userId: userId,
      onInsert: _handleFlashcardInsert,
      onUpdate: _handleFlashcardUpdate,
      onDelete: _handleFlashcardDelete,
      onSubscribed: () {
        debugPrint('📡 Individual flashcards real-time subscription active');
        _emitRealtimeEvent(
          RealtimeEventType.subscribed,
          'Flashcards subscription active',
        );
      },
      onError: (error) {
        debugPrint('❌ Flashcards subscription error: $error');
        _emitRealtimeEvent(RealtimeEventType.error, 'Flashcards error: $error');
      },
    );

    _flashcardsSubscription = RealtimeSubscription(
      id: 'flashcards_realtime',
      channel: channel,
      onResubscribed: () {
        debugPrint('🔄 Flashcards subscription restored');
        _emitRealtimeEvent(
          RealtimeEventType.reconnected,
          'Flashcards subscription restored',
        );
      },
    );

    _realtimeManager.registerSubscription(_flashcardsSubscription!);
  }

  /// Handle flashcard set insert events
  void _handleFlashcardSetInsert(PostgresChangePayload payload) {
    _handleFlashcardSetChange(payload.newRecord, RealtimeEventType.insert);
  }

  /// Handle flashcard set update events
  void _handleFlashcardSetUpdate(PostgresChangePayload payload) {
    _handleFlashcardSetChange(payload.newRecord, RealtimeEventType.update);
  }

  /// Handle flashcard set delete events
  void _handleFlashcardSetDelete(PostgresChangePayload payload) {
    final record = payload.oldRecord;
    final setId = record['id'] as String;

    debugPrint('🗑️ Real-time flashcard set deletion: $setId');
    _flashcardSetDeletionsController.add(setId);
    _emitRealtimeEvent(
      RealtimeEventType.delete,
      'Flashcard set deleted: $setId',
    );
  }

  /// Handle flashcard set changes (insert/update)
  void _handleFlashcardSetChange(
    Map<String, dynamic> record,
    RealtimeEventType eventType,
  ) {
    try {
      final flashcardSet = FlashcardSet.fromJson(record);
      final setId = flashcardSet.id;

      // Skip if this is an optimistic update we initiated
      if (_pendingOptimisticUpdates.contains(setId)) {
        debugPrint(
          '⏭️ Skipping optimistic update for set: ${flashcardSet.title}',
        );
        _pendingOptimisticUpdates.remove(setId);
        return;
      }

      debugPrint(
        '📡 Real-time flashcard set $eventType: ${flashcardSet.title}',
      );
      _flashcardSetUpdatesController.add(flashcardSet);
      _emitRealtimeEvent(
        eventType,
        'Flashcard set ${eventType.name}: ${flashcardSet.title}',
      );
    } catch (e) {
      debugPrint('❌ Error handling flashcard set change: $e');
      _emitRealtimeEvent(RealtimeEventType.error, 'Set change error: $e');
    }
  }

  /// Handle individual flashcard insert events
  void _handleFlashcardInsert(PostgresChangePayload payload) {
    _handleFlashcardChange(payload.newRecord, RealtimeEventType.insert);
  }

  /// Handle individual flashcard update events
  void _handleFlashcardUpdate(PostgresChangePayload payload) {
    _handleFlashcardChange(payload.newRecord, RealtimeEventType.update);
  }

  /// Handle individual flashcard delete events
  void _handleFlashcardDelete(PostgresChangePayload payload) {
    final record = payload.oldRecord;
    final cardId = record['id'] as String;

    debugPrint('🗑️ Real-time flashcard deletion: $cardId');
    _emitRealtimeEvent(RealtimeEventType.delete, 'Flashcard deleted: $cardId');
  }

  /// Handle individual flashcard changes
  void _handleFlashcardChange(
    Map<String, dynamic> record,
    RealtimeEventType eventType,
  ) {
    try {
      final flashcard = Flashcard.fromJson(record);
      debugPrint('📡 Real-time flashcard $eventType: ${flashcard.question}');
      _emitRealtimeEvent(
        eventType,
        'Flashcard ${eventType.name}: ${flashcard.question}',
      );

      // Note: Individual flashcard updates typically trigger a full set refresh
      // This is handled by the repository layer
    } catch (e) {
      debugPrint('❌ Error handling flashcard change: $e');
      _emitRealtimeEvent(RealtimeEventType.error, 'Card change error: $e');
    }
  }

  /// Mark update as optimistic to avoid duplicate processing
  void markOptimisticUpdate(String setId) {
    _pendingOptimisticUpdates.add(setId);

    // Remove after a timeout to prevent memory leaks
    Timer(const Duration(seconds: 10), () {
      _pendingOptimisticUpdates.remove(setId);
    });
  }

  /// Emit real-time event for monitoring/debugging
  void _emitRealtimeEvent(RealtimeEventType type, String message) {
    _realtimeEventsController.add(
      RealtimeEvent(type: type, message: message, timestamp: DateTime.now()),
    );
  }

  /// Clean up all subscriptions
  Future<void> _cleanupSubscriptions() async {
    if (_flashcardSetsSubscription != null) {
      _realtimeManager.unregisterSubscription(_flashcardSetsSubscription!.id);
      _flashcardSetsSubscription = null;
    }

    if (_flashcardsSubscription != null) {
      _realtimeManager.unregisterSubscription(_flashcardsSubscription!.id);
      _flashcardsSubscription = null;
    }

    debugPrint('🧹 Real-time subscriptions cleaned up');
  }

  /// Force reconnection of real-time subscriptions
  Future<void> forceReconnect() async {
    debugPrint('🔄 Forcing real-time reconnection...');
    await _realtimeManager.forceReconnect();

    final user = _authService.currentUser;
    if (user != null) {
      await _setupRealtimeSubscriptions(user.id);
    }
  }

  /// Get real-time service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isActive': isActive,
      'pendingOptimisticUpdates': _pendingOptimisticUpdates.length,
      'flashcardSetsSubscriptionActive': _flashcardSetsSubscription != null,
      'flashcardsSubscriptionActive': _flashcardsSubscription != null,
      'realtimeManagerStatus': _realtimeManager.getConnectionInfo(),
    };
  }

  /// Dispose resources
  @override
  void dispose() {
    _cleanupSubscriptions();
    _flashcardSetUpdatesController.close();
    _flashcardSetDeletionsController.close();
    _realtimeEventsController.close();
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}

/// Real-time event types for monitoring and debugging
enum RealtimeEventType {
  insert,
  update,
  delete,
  subscribed,
  error,
  reconnected,
}

/// Real-time event data structure
class RealtimeEvent {
  final RealtimeEventType type;
  final String message;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RealtimeEvent(${type.name}: $message at ${timestamp.toIso8601String()})';
  }
}
