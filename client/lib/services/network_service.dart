import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'simple_error_handler.dart';

class NetworkService extends ChangeNotifier {
  bool _isOnline = false;
  bool _isServerReachable = false;
  DateTime _lastCheck = DateTime.now();
  Timer? _periodicCheck;

  bool get isOnline => _isOnline;
  bool get isServerReachable => _isServerReachable;
  DateTime get lastCheck => _lastCheck;

  NetworkService() {
    // Initial check
    checkConnectivity();
    
    // Periodic check with configurable interval
    _periodicCheck = Timer.periodic(AppConfig.networkCheckInterval, (timer) {
      checkConnectivity();
    });
    
    AppConfig.logNetwork(
      'NetworkService initialized with check interval: ${AppConfig.networkCheckInterval.inSeconds}s',
      level: NetworkLogLevel.basic
    );
  }

  Future<void> checkConnectivity() async {
    await _checkInternetConnection();
    if (_isOnline) {
      await _checkServerConnection();
    } else {
      _isServerReachable = false;
    }
    
    _lastCheck = DateTime.now();
    notifyListeners();
    
    AppConfig.logNetwork(
      'Connectivity check: Online=$_isOnline, ServerReachable=$_isServerReachable',
      level: NetworkLogLevel.basic
    );
  }

  Future<void> _checkInternetConnection() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        // Use our own backend for connectivity check
        final pingEndpoint = AppConfig.endpoints['ping'] ?? '/api/ping';
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}$pingEndpoint'),
        ).timeout(AppConfig.connectivityTimeout);
        
        _isOnline = response.statusCode >= 200 && response.statusCode < 300;
        
        AppConfig.logNetwork(
          'Internet connectivity check: $_isOnline (${response.statusCode})',
          level: NetworkLogLevel.verbose
        );
      },
      fallbackOperation: () async {
        AppConfig.logNetwork(
          'Internet connectivity check failed',
          level: NetworkLogLevel.errors
        );
        _isOnline = false;
      },
      operationName: 'check_internet_connection',
    );
  }

  Future<void> _checkServerConnection() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        // Check if API server is reachable and responsive
        final response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/'),
        ).timeout(AppConfig.connectivityTimeout);
        
        _isServerReachable = response.statusCode >= 200 && response.statusCode < 300;
        
        AppConfig.logNetwork(
          'Server connectivity check: $_isServerReachable (${response.statusCode})',
          level: NetworkLogLevel.verbose
        );
      },
      fallbackOperation: () async {
        AppConfig.logNetwork(
          'Server connectivity check failed',
          level: NetworkLogLevel.errors
        );
        _isServerReachable = false;
      },
      operationName: 'check_server_connection',
    );
  }
  
  // Method to manually force online/offline mode (for testing)
  void setOfflineMode(bool enabled) {
    _isOnline = !enabled;
    _isServerReachable = !enabled;
    notifyListeners();
    
    AppConfig.logNetwork(
      'Manual connectivity override: Online=$_isOnline, ServerReachable=$_isServerReachable',
      level: NetworkLogLevel.basic
    );
  }

  @override
  void dispose() {
    _periodicCheck?.cancel();
    super.dispose();
  }
}