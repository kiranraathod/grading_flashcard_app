/// Network States for unified network state management
///
/// Phase 4 Migration: Provides unified network state to coordinate
/// with SyncBloc for network-aware sync operations.
library;

import 'package:equatable/equatable.dart';
import '../../services/connectivity_service.dart';

/// Base network state
abstract class NetworkState extends Equatable {
  const NetworkState();

  @override
  List<Object?> get props => [];
}

/// Initial state - network not yet initialized
class NetworkInitial extends NetworkState {
  const NetworkInitial();
}

/// Network monitoring active
class NetworkMonitoring extends NetworkState {
  final NetworkStatus status;
  final NetworkType type;
  final bool isOnline;
  final NetworkQuality? quality;
  final DateTime lastChecked;
  final Map<String, double>? averageMetrics;

  const NetworkMonitoring({
    required this.status,
    required this.type,
    required this.isOnline,
    this.quality,
    required this.lastChecked,
    this.averageMetrics,
  });

  @override
  List<Object?> get props => [
    status,
    type,
    isOnline,
    quality,
    lastChecked,
    averageMetrics,
  ];

  /// Check if network is suitable for sync operations
  bool get isSuitableForSync {
    if (!isOnline) return false;
    
    switch (status) {
      case NetworkStatus.excellent:
      case NetworkStatus.good:
        return true;
      case NetworkStatus.connected:
        return quality?.bandwidth != null && quality!.bandwidth > 1.0;
      case NetworkStatus.poor:
        return false;
      default:
        return false;
    }
  }

  /// Check if network is suitable for background operations
  bool get isSuitableForBackground {
    return isOnline && status != NetworkStatus.poor;
  }

  /// Get network status description
  String get statusDescription {
    if (!isOnline) return 'Offline';
    
    switch (status) {
      case NetworkStatus.excellent:
        return 'Excellent Connection';
      case NetworkStatus.good:
        return 'Good Connection';
      case NetworkStatus.connected:
        return 'Connected';
      case NetworkStatus.poor:
        return 'Poor Connection';
      case NetworkStatus.connecting:
        return 'Connecting...';
      default:
        return 'Unknown';
    }
  }

  /// Get network type description
  String get typeDescription {
    switch (type) {
      case NetworkType.wifi:
        return 'Wi-Fi';
      case NetworkType.mobile:
        return 'Mobile Data';
      case NetworkType.ethernet:
        return 'Ethernet';
      case NetworkType.vpn:
        return 'VPN';
      case NetworkType.other:
        return 'Other';
      case NetworkType.none:
        return 'No Connection';
    }
  }

  NetworkMonitoring copyWith({
    NetworkStatus? status,
    NetworkType? type,
    bool? isOnline,
    NetworkQuality? quality,
    DateTime? lastChecked,
    Map<String, double>? averageMetrics,
  }) {
    return NetworkMonitoring(
      status: status ?? this.status,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      quality: quality ?? this.quality,
      lastChecked: lastChecked ?? this.lastChecked,
      averageMetrics: averageMetrics ?? this.averageMetrics,
    );
  }
}

/// Network connection test in progress
class NetworkTesting extends NetworkState {
  final DateTime startTime;

  const NetworkTesting({required this.startTime});

  @override
  List<Object?> get props => [startTime];

  Duration get elapsedTime => DateTime.now().difference(startTime);
}

/// Network error state
class NetworkError extends NetworkState {
  final String error;
  final DateTime errorTime;
  final NetworkStatus? lastKnownStatus;

  const NetworkError({
    required this.error,
    required this.errorTime,
    this.lastKnownStatus,
  });

  @override
  List<Object?> get props => [error, errorTime, lastKnownStatus];
}
