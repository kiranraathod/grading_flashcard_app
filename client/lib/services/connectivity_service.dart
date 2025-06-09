import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';
import '../utils/config.dart';
import 'simple_error_handler.dart';

enum NetworkStatus {
  unknown,
  connected,
  disconnected,
  connecting,
  poor,
  good,
  excellent
}

enum NetworkType {
  none,
  mobile,
  wifi,
  ethernet,
  vpn,
  other
}

class NetworkQuality {
  final double latency; // in milliseconds
  final double bandwidth; // estimated Mbps
  final NetworkStatus status;
  final DateTime timestamp;

  const NetworkQuality({
    required this.latency,
    required this.bandwidth,
    required this.status,
    required this.timestamp,
  });

  bool get isGood => status == NetworkStatus.good || status == NetworkStatus.excellent;
  bool get isPoor => status == NetworkStatus.poor;
  bool get isConnected => status != NetworkStatus.disconnected && status != NetworkStatus.unknown;
}

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Core connectivity checking
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker.instance;
  
  // State management
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _connectionSubscription;
  Timer? _networkQualityTimer;
  Timer? _healthCheckTimer;
  
  // Current status
  NetworkStatus _currentStatus = NetworkStatus.unknown;
  NetworkType _currentType = NetworkType.none;
  NetworkQuality? _currentQuality;
  bool _isOnline = false;
  final List<NetworkQuality> _qualityHistory = [];
  
  // Configuration - OPTIMIZED FOR POOR NETWORKS
  static const int maxQualityHistorySize = 10;               // Reduced memory usage
  static const Duration qualityCheckInterval = Duration(minutes: 5);   // Much less frequent
  static const Duration healthCheckInterval = Duration(minutes: 10);   // Reduced overhead
  
  // Getters
  NetworkStatus get currentStatus => _currentStatus;
  NetworkType get currentType => _currentType;
  NetworkQuality? get currentQuality => _currentQuality;
  bool get isOnline => _isOnline;
  List<NetworkQuality> get qualityHistory => List.unmodifiable(_qualityHistory);
  
  bool get hasInternetConnection => _isOnline && _currentStatus != NetworkStatus.disconnected;
  bool get hasGoodConnection => _currentQuality?.isGood ?? false;
  bool get hasPoorConnection => _currentQuality?.isPoor ?? false;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    await SimpleErrorHandler.safely(
      () async {
        AppConfig.logNetwork('Initializing ConnectivityService', level: NetworkLogLevel.basic);
        
        // Configure connection checker
        _connectionChecker.checkInterval = AppConfig.networkCheckInterval;
        
        // Check initial connectivity
        await _checkInitialConnectivity();
        
        // Start monitoring
        _startConnectivityMonitoring();
        _startInternetMonitoring();
        _startNetworkQualityMonitoring();
        _startPeriodicHealthCheck();
        
        AppConfig.logNetwork('ConnectivityService initialized successfully', level: NetworkLogLevel.basic);
      },
      operationName: 'connectivity_service_initialization',
    );
  }

  /// Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        final connectivityResults = await _connectivity.checkConnectivity();
        final hasInternet = await _connectionChecker.hasConnection;
        
        _updateConnectivityType(connectivityResults);
        _isOnline = hasInternet;
        _updateNetworkStatus();
        
        AppConfig.logNetwork(
          'Initial connectivity: Type=${_currentType.name}, Online=$_isOnline, Status=${_currentStatus.name}',
          level: NetworkLogLevel.basic
        );
      },
      fallbackOperation: () async {
        AppConfig.logNetwork('Error checking initial connectivity, using defaults', level: NetworkLogLevel.errors);
        _currentStatus = NetworkStatus.unknown;
        _isOnline = false;
      },
      operationName: 'check_initial_connectivity',
    );
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectivityType(results);
        _updateNetworkStatus();
        _scheduleQualityCheck();
        notifyListeners();
      },
      onError: (error) {
        AppConfig.logNetwork('Connectivity monitoring error: $error', level: NetworkLogLevel.errors);
      },
    );
  }

  /// Start monitoring actual internet connection
  void _startInternetMonitoring() {
    _connectionSubscription = _connectionChecker.onStatusChange.listen(
      (InternetConnectionStatus status) {
        final wasOnline = _isOnline;
        _isOnline = status == InternetConnectionStatus.connected;
        
        if (wasOnline != _isOnline) {
          AppConfig.logNetwork(
            'Internet status changed: ${_isOnline ? "Connected" : "Disconnected"}',
            level: NetworkLogLevel.basic
          );
          
          _updateNetworkStatus();
          _scheduleQualityCheck();
          notifyListeners();
        }
      },
      onError: (error) {
        AppConfig.logNetwork('Internet monitoring error: $error', level: NetworkLogLevel.errors);
      },
    );
  }

  /// Start periodic network quality monitoring
  void _startNetworkQualityMonitoring() {
    _networkQualityTimer = Timer.periodic(qualityCheckInterval, (_) {
      _performQualityCheck();
    });
  }

  /// Start periodic health checks
  void _startPeriodicHealthCheck() {
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  /// Update connectivity type based on connectivity results
  void _updateConnectivityType(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _currentType = NetworkType.none;
    } else if (results.contains(ConnectivityResult.wifi)) {
      _currentType = NetworkType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _currentType = NetworkType.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _currentType = NetworkType.ethernet;
    } else if (results.contains(ConnectivityResult.vpn)) {
      _currentType = NetworkType.vpn;
    } else {
      _currentType = NetworkType.other;
    }
  }

  /// Update network status based on current conditions
  void _updateNetworkStatus() {
    if (!_isOnline || _currentType == NetworkType.none) {
      _currentStatus = NetworkStatus.disconnected;
    } else if (_currentQuality != null) {
      _currentStatus = _currentQuality!.status;
    } else {
      _currentStatus = NetworkStatus.connected;
    }
  }

  /// Schedule a quality check (debounced)
  void _scheduleQualityCheck() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_isOnline) {
        _performQualityCheck();
      }
    });
  }

  /// Perform network quality assessment
  Future<void> _performQualityCheck() async {
    if (!_isOnline) return;

    await SimpleErrorHandler.safe<void>(
      () async {
        AppConfig.logNetwork('Performing network quality check', level: NetworkLogLevel.verbose);
        
        final stopwatch = Stopwatch()..start();
        
        // Use a web-safe approach for quality check
        final hasConnection = await _connectionChecker.hasConnection;
        
        stopwatch.stop();
        
        if (hasConnection) {
          final latency = stopwatch.elapsedMilliseconds.toDouble();
          final bandwidth = _estimateBandwidth(latency);
          final status = _assessNetworkStatus(latency, bandwidth);
          
          final quality = NetworkQuality(
            latency: latency,
            bandwidth: bandwidth,
            status: status,
            timestamp: DateTime.now(),
          );
          
          _updateQuality(quality);
          
          AppConfig.logNetwork(
            'Network quality: Latency=${latency.toStringAsFixed(1)}ms, Status=${status.name}',
            level: NetworkLogLevel.verbose
          );
        }
      },
      fallbackOperation: () async {
        AppConfig.logNetwork('Quality check failed, using poor quality fallback', level: NetworkLogLevel.verbose);
        
        // Update with poor quality on failure
        _updateQuality(NetworkQuality(
          latency: 999999,
          bandwidth: 0,
          status: NetworkStatus.poor,
          timestamp: DateTime.now(),
        ));
      },
      operationName: 'network_quality_check',
    );
  }

  /// Update quality and maintain history
  void _updateQuality(NetworkQuality quality) {
    _currentQuality = quality;
    _qualityHistory.add(quality);
    
    // Maintain history size
    if (_qualityHistory.length > maxQualityHistorySize) {
      _qualityHistory.removeAt(0);
    }
    
    _updateNetworkStatus();
    notifyListeners();
  }

  /// Estimate bandwidth based on latency (simplified)
  double _estimateBandwidth(double latency) {
    // This is a simplified estimation - in production you might want more sophisticated measurement
    if (latency < 50) return 50.0; // Excellent
    if (latency < 100) return 25.0; // Good
    if (latency < 200) return 10.0; // Fair
    if (latency < 500) return 5.0; // Poor
    return 1.0; // Very poor
  }

  /// Assess network status based on measurements
  NetworkStatus _assessNetworkStatus(double latency, double bandwidth) {
    if (latency < 50 && bandwidth > 25) return NetworkStatus.excellent;
    if (latency < 100 && bandwidth > 10) return NetworkStatus.good;
    if (latency < 300 && bandwidth > 2) return NetworkStatus.connected;
    return NetworkStatus.poor;
  }

  /// Perform comprehensive health check
  Future<bool> _performHealthCheck() async {
    return await SimpleErrorHandler.safe<bool>(
      () async {
        AppConfig.logNetwork('Performing connectivity health check', level: NetworkLogLevel.verbose);
        
        // Check multiple connectivity indicators
        final connectivityResult = await _connectivity.checkConnectivity();
        final hasInternet = await _connectionChecker.hasConnection;
        
        // Update state
        _updateConnectivityType(connectivityResult);
        _isOnline = hasInternet;
        _updateNetworkStatus();
        
        notifyListeners();
        return _isOnline;
      },
      fallback: false,
      operationName: 'connectivity_health_check',
    );
  }

  /// Get average quality metrics
  Map<String, double> getAverageQualityMetrics() {
    if (_qualityHistory.isEmpty) {
      return {'latency': 0, 'bandwidth': 0};
    }

    final totalLatency = _qualityHistory.fold<double>(0, (sum, q) => sum + q.latency);
    final totalBandwidth = _qualityHistory.fold<double>(0, (sum, q) => sum + q.bandwidth);

    return {
      'latency': totalLatency / _qualityHistory.length,
      'bandwidth': totalBandwidth / _qualityHistory.length,
    };
  }

  /// Wait for connection to be available
  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isOnline) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription = _connectionChecker.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        subscription.cancel();
      }
    });

    // Set timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      subscription.cancel();
    });

    return completer.future;
  }

  /// Force refresh connectivity status
  Future<void> forceRefresh() async {
    AppConfig.logNetwork('Force refreshing connectivity status', level: NetworkLogLevel.basic);
    await _checkInitialConnectivity();
    await _performQualityCheck();
    notifyListeners();
  }

  /// Dispose of resources
  @override
  void dispose() {
    AppConfig.logNetwork('Disposing ConnectivityService', level: NetworkLogLevel.basic);
    
    _connectivitySubscription?.cancel();
    _connectionSubscription?.cancel();
    _networkQualityTimer?.cancel();
    _healthCheckTimer?.cancel();
    
    super.dispose();
  }
}
