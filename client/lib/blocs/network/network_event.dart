/// Network Events for unified network state management
///
/// Phase 4 Migration: Convert ConnectivityService to BLoC pattern
/// for unified network state management with SyncBloc coordination.
library;

import 'package:equatable/equatable.dart';
import '../../services/connectivity_service.dart';

/// Base network event
abstract class NetworkEvent extends Equatable {
  const NetworkEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize network monitoring
class NetworkInitialized extends NetworkEvent {
  const NetworkInitialized();
}

/// Connectivity status changed
class NetworkConnectivityChanged extends NetworkEvent {
  final NetworkStatus status;
  final NetworkType type;
  final bool isOnline;

  const NetworkConnectivityChanged({
    required this.status,
    required this.type,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [status, type, isOnline];
}

/// Network quality changed
class NetworkQualityChanged extends NetworkEvent {
  final NetworkQuality quality;

  const NetworkQualityChanged({required this.quality});

  @override
  List<Object?> get props => [quality];
}

/// Force refresh network status
class NetworkRefreshRequested extends NetworkEvent {
  const NetworkRefreshRequested();
}

/// Test network connection
class NetworkConnectionTestRequested extends NetworkEvent {
  const NetworkConnectionTestRequested();
}

/// Network went offline
class NetworkWentOffline extends NetworkEvent {
  const NetworkWentOffline();
}

/// Network came online
class NetworkCameOnline extends NetworkEvent {
  const NetworkCameOnline();
}

/// Network quality degraded
class NetworkQualityDegraded extends NetworkEvent {
  final NetworkQuality previousQuality;
  final NetworkQuality currentQuality;

  const NetworkQualityDegraded({
    required this.previousQuality,
    required this.currentQuality,
  });

  @override
  List<Object?> get props => [previousQuality, currentQuality];
}

/// Network quality improved
class NetworkQualityImproved extends NetworkEvent {
  final NetworkQuality previousQuality;
  final NetworkQuality currentQuality;

  const NetworkQualityImproved({
    required this.previousQuality,
    required this.currentQuality,
  });

  @override
  List<Object?> get props => [previousQuality, currentQuality];
}
