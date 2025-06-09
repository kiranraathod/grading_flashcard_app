import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';
import 'connectivity_service.dart';
import 'enhanced_cache_manager.dart';
import 'enhanced_http_client_service.dart';
import 'simple_error_handler.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  partial,
  offline,
}

enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

class SyncItem {
  final String id;
  final String endpoint;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttempt;
  final String? error;

  const SyncItem({
    required this.id,
    required this.endpoint,
    required this.data,
    this.priority = SyncPriority.normal,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttempt,
    this.error,
  });

  SyncItem copyWith({
    int? retryCount,
    DateTime? lastAttempt,
    String? error,
  }) {
    return SyncItem(
      id: id,
      endpoint: endpoint,
      data: data,
      priority: priority,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      error: error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'data': data,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastAttempt': lastAttempt?.toIso8601String(),
      'error': error,
    };
  }

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'],
      endpoint: json['endpoint'],
      data: Map<String, dynamic>.from(json['data']),
      priority: SyncPriority.values[json['priority']],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
      lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt']) : null,
      error: json['error'],
    );
  }
}

class SyncStatusTracker extends ChangeNotifier {
  static final SyncStatusTracker _instance = SyncStatusTracker._internal();
  factory SyncStatusTracker() => _instance;
  SyncStatusTracker._internal();

  final ConnectivityService _connectivity = ConnectivityService();
  final EnhancedCacheManager _cache = EnhancedCacheManager();
  final EnhancedHttpClientService _httpClient = EnhancedHttpClientService();

  // State management
  SyncStatus _currentStatus = SyncStatus.idle;
  final List<SyncItem> _syncQueue = [];
  final List<SyncItem> _completedSyncs = [];
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  // Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetries = 3;
  static const int maxQueueSize = 100;

  // Getters
  SyncStatus get currentStatus => _currentStatus;
  List<SyncItem> get syncQueue => List.unmodifiable(_syncQueue);
  List<SyncItem> get completedSyncs => List.unmodifiable(_completedSyncs);
  int get pendingCount => _syncQueue.length;
  bool get isSyncing => _isSyncing;

  /// Initialize the sync status tracker
  Future<void> initialize() async {
    await _loadSyncQueue();
    _startPeriodicSync();
    _setupConnectivityListener();
    
    AppConfig.logNetwork('SyncStatusTracker initialized', level: NetworkLogLevel.basic);
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue(
    String endpoint,
    Map<String, dynamic> data, {
    SyncPriority priority = SyncPriority.normal,
  }) async {
    final item = SyncItem(
      id: _generateSyncId(),
      endpoint: endpoint,
      data: data,
      priority: priority,
      createdAt: DateTime.now(),
    );

    _syncQueue.add(item);
    _sortSyncQueue();
    
    // Maintain queue size
    if (_syncQueue.length > maxQueueSize) {
      _syncQueue.removeRange(maxQueueSize, _syncQueue.length);
    }

    await _saveSyncQueue();
    notifyListeners();

    AppConfig.logNetwork('Added to sync queue: ${item.id}', level: NetworkLogLevel.verbose);

    // Trigger immediate sync for critical items
    if (priority == SyncPriority.critical && _connectivity.hasInternetConnection) {
      _performSync();
    }
  }

  /// Perform sync operation
  Future<void> _performSync() async {
    if (_isSyncing || !_connectivity.hasInternetConnection) return;

    _isSyncing = true;
    _currentStatus = SyncStatus.syncing;
    notifyListeners();

    int successCount = 0;
    int failureCount = 0;

    await SimpleErrorHandler.safe<void>(
      () async {
        AppConfig.logNetwork('Starting sync operation', level: NetworkLogLevel.basic);
        
        final itemsToSync = List<SyncItem>.from(_syncQueue);
        
        for (final item in itemsToSync) {
          await SimpleErrorHandler.safe<void>(
            () async {
              await _syncSingleItem(item);
              _syncQueue.remove(item);
              _completedSyncs.add(item);
              successCount++;
              
              AppConfig.logNetwork('Synced item: ${item.id}', level: NetworkLogLevel.verbose);
            },
            fallbackOperation: () async {
              final updatedItem = item.copyWith(
                retryCount: item.retryCount + 1,
                lastAttempt: DateTime.now(),
                error: 'sync_failed',
              );
              
              final index = _syncQueue.indexOf(item);
              if (index != -1) {
                _syncQueue[index] = updatedItem;
              }
              
              if (updatedItem.retryCount >= maxRetries) {
                _syncQueue.remove(updatedItem);
                AppConfig.logNetwork('Max retries exceeded for: ${item.id}', level: NetworkLogLevel.errors);
              }
              
              failureCount++;
              AppConfig.logNetwork('Failed to sync item: ${item.id}', level: NetworkLogLevel.errors);
            },
            operationName: 'sync_individual_item_${item.id}',
          );
        }

        // Update status based on results
        if (failureCount == 0) {
          _currentStatus = SyncStatus.success;
        } else if (successCount > 0) {
          _currentStatus = SyncStatus.partial;
        } else {
          _currentStatus = SyncStatus.failed;
        }

        await _saveSyncQueue();
        
        AppConfig.logNetwork(
          'Sync completed: $successCount success, $failureCount failed',
          level: NetworkLogLevel.basic
        );
      },
      fallbackOperation: () async {
        _currentStatus = SyncStatus.failed;
        AppConfig.logNetwork('Sync operation failed', level: NetworkLogLevel.errors);
      },
      operationName: 'perform_sync_operation',
    );

    // Finally block equivalent
    _isSyncing = false;
    notifyListeners();
  }

  /// Sync a single item
  Future<void> _syncSingleItem(SyncItem item) async {
    final response = await _httpClient.post(
      item.endpoint,
      data: item.data,
      enableRetry: false, // We handle retries ourselves
    );
    
    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  /// Generate unique sync ID
  String _generateSyncId() {
    return 'sync_${DateTime.now().millisecondsSinceEpoch}_${_syncQueue.length}';
  }

  /// Sort sync queue by priority
  void _sortSyncQueue() {
    _syncQueue.sort((a, b) {
      // Sort by priority first (higher priority first)
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      
      // Then by creation time (older first)
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(syncInterval, (_) {
      if (_connectivity.hasInternetConnection && _syncQueue.isNotEmpty) {
        _performSync();
      }
    });
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivity.addListener(() {
      if (_connectivity.hasInternetConnection && _syncQueue.isNotEmpty) {
        // Connection restored, trigger sync
        Future.delayed(const Duration(seconds: 2), () => _performSync());
      } else if (!_connectivity.hasInternetConnection) {
        _currentStatus = SyncStatus.offline;
        notifyListeners();
      }
    });
  }

  /// Save sync queue to persistent storage
  Future<void> _saveSyncQueue() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        final data = {
          'syncQueue': _syncQueue.map((item) => item.toJson()).toList(),
          'completedSyncs': _completedSyncs.map((item) => item.toJson()).toList(),
        };
        await _cache.cacheData('sync_queue', data);
      },
      fallbackOperation: () async {
        AppConfig.logNetwork('Failed to save sync queue', level: NetworkLogLevel.errors);
      },
      operationName: 'save_sync_queue',
    );
  }

  /// Load sync queue from persistent storage
  Future<void> _loadSyncQueue() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        final data = await _cache.getCachedData('sync_queue');
        if (data != null) {
          if (data['syncQueue'] != null) {
            _syncQueue.addAll(
              (data['syncQueue'] as List).map((item) => SyncItem.fromJson(item))
            );
          }
          if (data['completedSyncs'] != null) {
            _completedSyncs.addAll(
              (data['completedSyncs'] as List).map((item) => SyncItem.fromJson(item))
            );
          }
        }
      },
      fallbackOperation: () async {
        AppConfig.logNetwork('Failed to load sync queue', level: NetworkLogLevel.errors);
      },
      operationName: 'load_sync_queue',
    );
  }

  /// Manually trigger sync
  Future<void> triggerSync() async {
    if (_connectivity.hasInternetConnection) {
      await _performSync();
    }
  }

  /// Clear completed syncs
  void clearCompletedSyncs() {
    _completedSyncs.clear();
    _saveSyncQueue();
    notifyListeners();
  }

  /// Get sync statistics
  Map<String, dynamic> getStatistics() {
    return {
      'pendingCount': _syncQueue.length,
      'completedCount': _completedSyncs.length,
      'currentStatus': _currentStatus.name,
      'isSyncing': _isSyncing,
    };
  }

  /// Dispose resources
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
