/// NetworkBloc: Unified network state management
///
/// Phase 4 Migration: Converts ConnectivityService to BLoC pattern
/// for coordination with SyncBloc and unified state management.
///
/// Key Features:
/// - Wraps ConnectivityService with BLoC pattern
/// - Provides reactive network status updates
/// - Coordinates with SyncBloc for network-aware operations
/// - Maintains network quality metrics
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../services/connectivity_service.dart';
import 'network_event.dart';
import 'network_state.dart';

/// NetworkBloc - BLoC wrapper for ConnectivityService
///
/// Provides unified network state management and coordinates with SyncBloc
/// to enable network-aware sync operations.
class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final ConnectivityService _connectivityService;
  
  // Stream subscriptions for cleanup
  StreamSubscription? _connectivitySubscription;
  Timer? _qualityMonitorTimer;
  
  // Previous state for change detection
  NetworkStatus? _previousStatus;
  NetworkQuality? _previousQuality;

  NetworkBloc({required ConnectivityService connectivityService})
    : _connectivityService = connectivityService,
      super(const NetworkInitial()) {
    
    // Register event handlers
    on<NetworkInitialized>(_onInitialized);
    on<NetworkConnectivityChanged>(_onConnectivityChanged);
    on<NetworkQualityChanged>(_onQualityChanged);
    on<NetworkRefreshRequested>(_onRefreshRequested);
    on<NetworkConnectionTestRequested>(_onConnectionTestRequested);
    on<NetworkWentOffline>(_onWentOffline);
    on<NetworkCameOnline>(_onCameOnline);
    on<NetworkQualityDegraded>(_onQualityDegraded);
    on<NetworkQualityImproved>(_onQualityImproved);
  }

  /// Initialize network monitoring
  Future<void> _onInitialized(
    NetworkInitialized event,
    Emitter<NetworkState> emit,
  ) async {
    debugPrint('🌐 NetworkBloc: Initializing network monitoring...');
    
    try {
      // Initialize connectivity service
      await _connectivityService.initialize();
      
      // Get initial network state
      final currentStatus = _connectivityService.currentStatus;
      final currentType = _connectivityService.currentType;
      final isOnline = _connectivityService.isOnline;
      final quality = _connectivityService.currentQuality;
      
      debugPrint('🌐 NetworkBloc: Initial state - Status: $currentStatus, Type: $currentType, Online: $isOnline');
      
      // Emit initial monitoring state
      emit(
        NetworkMonitoring(
          status: currentStatus,
          type: currentType,
          isOnline: isOnline,
          quality: quality,
          lastChecked: DateTime.now(),
          averageMetrics: _connectivityService.getAverageQualityMetrics(),
        ),
      );
      
      // Start listening to connectivity changes
      _startConnectivityMonitoring();
      
      // Start periodic quality monitoring
      _startQualityMonitoring();
      
      debugPrint('✅ NetworkBloc: Network monitoring initialized successfully');
      
    } catch (error) {
      debugPrint('❌ NetworkBloc: Failed to initialize network monitoring: $error');
      emit(
        NetworkError(
          error: 'Failed to initialize network monitoring: $error',
          errorTime: DateTime.now(),
        ),
      );
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    // Listen to connectivity service changes
    _connectivitySubscription = _connectivityService.addListener(() {
      final currentStatus = _connectivityService.currentStatus;
      final currentType = _connectivityService.currentType;
      final isOnline = _connectivityService.isOnline;
      
      // Detect online/offline transitions
      if (_previousStatus != null) {
        final wasOnline = _previousStatus != NetworkStatus.disconnected;
        
        if (!wasOnline && isOnline) {
          add(const NetworkCameOnline());
        } else if (wasOnline && !isOnline) {
          add(const NetworkWentOffline());
        }
      }
      
      // Emit connectivity change
      add(
        NetworkConnectivityChanged(
          status: currentStatus,
          type: currentType,
          isOnline: isOnline,
        ),
      );
      
      _previousStatus = currentStatus;
    }) as StreamSubscription?;
  }

  /// Start periodic quality monitoring
  void _startQualityMonitoring() {
    _qualityMonitorTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) {
        final quality = _connectivityService.currentQuality;
        if (quality != null) {
          // Check for quality changes
          if (_previousQuality != null && _previousQuality != quality) {
            if (quality.status.index < _previousQuality!.status.index) {
              add(
                NetworkQualityImproved(
                  previousQuality: _previousQuality!,
                  currentQuality: quality,
                ),
              );
            } else if (quality.status.index > _previousQuality!.status.index) {
              add(
                NetworkQualityDegraded(
                  previousQuality: _previousQuality!,
                  currentQuality: quality,
                ),
              );
            }
          }
          
          add(NetworkQualityChanged(quality: quality));
          _previousQuality = quality;
        }
      },
    );
  }

  /// Handle connectivity status changes
  void _onConnectivityChanged(
    NetworkConnectivityChanged event,
    Emitter<NetworkState> emit,
  ) {
    debugPrint(
      '🌐 NetworkBloc: Connectivity changed - ${event.status} (${event.type}) - Online: ${event.isOnline}',
    );
    
    if (state is NetworkMonitoring) {
      final currentState = state as NetworkMonitoring;
      emit(
        currentState.copyWith(
          status: event.status,
          type: event.type,
          isOnline: event.isOnline,
          lastChecked: DateTime.now(),
          averageMetrics: _connectivityService.getAverageQualityMetrics(),
        ),
      );
    } else {
      emit(
        NetworkMonitoring(
          status: event.status,
          type: event.type,
          isOnline: event.isOnline,
          quality: _connectivityService.currentQuality,
          lastChecked: DateTime.now(),
          averageMetrics: _connectivityService.getAverageQualityMetrics(),
        ),
      );
    }
  }

  /// Handle network quality changes
  void _onQualityChanged(
    NetworkQualityChanged event,
    Emitter<NetworkState> emit,
  ) {
    debugPrint(
      '🌐 NetworkBloc: Quality changed - ${event.quality.status} (${event.quality.latency}ms)',
    );
    
    if (state is NetworkMonitoring) {
      final currentState = state as NetworkMonitoring;
      emit(
        currentState.copyWith(
          quality: event.quality,
          lastChecked: DateTime.now(),
          averageMetrics: _connectivityService.getAverageQualityMetrics(),
        ),
      );
    }
  }

  /// Handle refresh requests
  Future<void> _onRefreshRequested(
    NetworkRefreshRequested event,
    Emitter<NetworkState> emit,
  ) async {
    debugPrint('🔄 NetworkBloc: Refresh requested');
    
    try {
      await _connectivityService.forceRefresh();
      
      // Get updated state
      final currentStatus = _connectivityService.currentStatus;
      final currentType = _connectivityService.currentType;
      final isOnline = _connectivityService.isOnline;
      final quality = _connectivityService.currentQuality;
      
      if (state is NetworkMonitoring) {
        final currentState = state as NetworkMonitoring;
        emit(
          currentState.copyWith(
            status: currentStatus,
            type: currentType,
            isOnline: isOnline,
            quality: quality,
            lastChecked: DateTime.now(),
            averageMetrics: _connectivityService.getAverageQualityMetrics(),
          ),
        );
      }
      
      debugPrint('✅ NetworkBloc: Refresh completed');
      
    } catch (error) {
      debugPrint('❌ NetworkBloc: Refresh failed: $error');
      emit(
        NetworkError(
          error: 'Failed to refresh network status: $error',
          errorTime: DateTime.now(),
          lastKnownStatus: state is NetworkMonitoring 
              ? (state as NetworkMonitoring).status 
              : null,
        ),
      );
    }
  }

  /// Handle connection test requests
  Future<void> _onConnectionTestRequested(
    NetworkConnectionTestRequested event,
    Emitter<NetworkState> emit,
  ) async {
    debugPrint('🧪 NetworkBloc: Connection test requested');
    
    emit(NetworkTesting(startTime: DateTime.now()));
    
    try {
      // Wait for connection with timeout
      final connected = await _connectivityService.waitForConnection(
        timeout: const Duration(seconds: 10),
      );
      
      if (connected) {
        // Get current state after successful test
        final currentStatus = _connectivityService.currentStatus;
        final currentType = _connectivityService.currentType;
        final isOnline = _connectivityService.isOnline;
        final quality = _connectivityService.currentQuality;
        
        emit(
          NetworkMonitoring(
            status: currentStatus,
            type: currentType,
            isOnline: isOnline,
            quality: quality,
            lastChecked: DateTime.now(),
            averageMetrics: _connectivityService.getAverageQualityMetrics(),
          ),
        );
        
        debugPrint('✅ NetworkBloc: Connection test successful');
      } else {
        debugPrint('❌ NetworkBloc: Connection test failed - timeout');
        emit(
          NetworkError(
            error: 'Connection test timed out',
            errorTime: DateTime.now(),
          ),
        );
      }
      
    } catch (error) {
      debugPrint('❌ NetworkBloc: Connection test failed: $error');
      emit(
        NetworkError(
          error: 'Connection test failed: $error',
          errorTime: DateTime.now(),
        ),
      );
    }
  }

  /// Handle network going offline
  void _onWentOffline(
    NetworkWentOffline event,
    Emitter<NetworkState> emit,
  ) {
    debugPrint('📱 NetworkBloc: Network went offline');
    
    if (state is NetworkMonitoring) {
      final currentState = state as NetworkMonitoring;
      emit(
        currentState.copyWith(
          status: NetworkStatus.disconnected,
          isOnline: false,
          lastChecked: DateTime.now(),
        ),
      );
    }
  }

  /// Handle network coming online
  void _onCameOnline(
    NetworkCameOnline event,
    Emitter<NetworkState> emit,
  ) {
    debugPrint('🌐 NetworkBloc: Network came online');
    
    // Force refresh to get current status
    add(const NetworkRefreshRequested());
  }

  /// Handle network quality degradation
  void _onQualityDegraded(
    NetworkQualityDegraded event,
    Emitter<NetworkState> emit,
  ) {
    debugPrint(
      '📉 NetworkBloc: Quality degraded from ${event.previousQuality.status} to ${event.currentQuality.status}',
    );
    
    // Update state with new quality
    if (state is NetworkMonitoring) {
      final currentState = state as NetworkMonitoring;
      emit(
        currentState.copyWith(
          quality: event.currentQuality,
          status: event.currentQuality.status,
          lastChecked: DateTime.now(),
        ),
      );
    }
  }

  /// Handle network quality improvement
  void _onQualityImproved(
    NetworkQualityImproved event,
    Emitter<NetworkState> emit,
  ) {
    debugPrint(
      '📈 NetworkBloc: Quality improved from ${event.previousQuality.status} to ${event.currentQuality.status}',
    );
    
    // Update state with new quality
    if (state is NetworkMonitoring) {
      final currentState = state as NetworkMonitoring;
      emit(
        currentState.copyWith(
          quality: event.currentQuality,
          status: event.currentQuality.status,
          lastChecked: DateTime.now(),
        ),
      );
    }
  }

  // Public helper methods for external access

  /// Get current network status
  NetworkStatus get currentStatus => _connectivityService.currentStatus;

  /// Get current network type
  NetworkType get currentType => _connectivityService.currentType;

  /// Check if currently online
  bool get isOnline => _connectivityService.isOnline;

  /// Check if has good connection
  bool get hasGoodConnection => _connectivityService.hasGoodConnection;

  /// Get current quality
  NetworkQuality? get currentQuality => _connectivityService.currentQuality;

  /// Check if suitable for sync operations
  bool get isSuitableForSync {
    if (state is NetworkMonitoring) {
      return (state as NetworkMonitoring).isSuitableForSync;
    }
    return false;
  }

  /// Check if suitable for background operations
  bool get isSuitableForBackground {
    if (state is NetworkMonitoring) {
      return (state as NetworkMonitoring).isSuitableForBackground;
    }
    return false;
  }

  /// Force refresh network status
  void forceRefresh() {
    add(const NetworkRefreshRequested());
  }

  /// Test network connection
  void testConnection() {
    add(const NetworkConnectionTestRequested());
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    final metrics = _connectivityService.getAverageQualityMetrics();
    
    return {
      'current_status': currentStatus.name,
      'current_type': currentType.name,
      'is_online': isOnline,
      'has_good_connection': hasGoodConnection,
      'average_latency': metrics['latency'],
      'average_bandwidth': metrics['bandwidth'],
      'last_checked': state is NetworkMonitoring 
          ? (state as NetworkMonitoring).lastChecked.toIso8601String()
          : null,
    };
  }

  // Dispose and cleanup

  @override
  Future<void> close() async {
    debugPrint('🔄 NetworkBloc: Disposing...');

    // Cancel subscriptions
    await _connectivitySubscription?.cancel();
    _qualityMonitorTimer?.cancel();

    // Dispose connectivity service
    _connectivityService.dispose();

    debugPrint('✅ NetworkBloc: Disposed successfully');

    return super.close();
  }
}
