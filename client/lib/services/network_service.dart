import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NetworkService extends ChangeNotifier {
  bool _isOnline = false; // Start with offline mode for testing
  bool _isServerReachable = false; // Start with server unreachable for testing
  DateTime _lastCheck = DateTime.now();
  Timer? _periodicCheck;

  bool get isOnline => _isOnline;
  bool get isServerReachable => _isServerReachable;
  DateTime get lastCheck => _lastCheck;

  NetworkService() {
    // Initial check
    checkConnectivity();
    
    // Periodic check every 30 seconds
    _periodicCheck = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkConnectivity();
    });
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
  }

  Future<void> _checkInternetConnection() async {
    try {
      // Try to reach a reliable external service
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      _isOnline = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint('Internet connectivity: $_isOnline');
    } catch (e) {
      debugPrint('Internet connectivity check failed: $e');
      _isOnline = false;
    }
  }

  Future<void> _checkServerConnection() async {
    try {
      // Try to reach the API server health endpoint
      final response = await http.get(
        Uri.parse('${Constants.apiBaseUrl}/'),
      ).timeout(const Duration(seconds: 5));
      
      _isServerReachable = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint('Server connectivity: $_isServerReachable (${response.statusCode})');
    } catch (e) {
      debugPrint('Server connectivity check failed: $e');
      _isServerReachable = false;
    }
  }
  
  // Method to manually force online/offline mode (for testing)
  void setOfflineMode(bool enabled) {
    _isOnline = !enabled;
    _isServerReachable = !enabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicCheck?.cancel();
    super.dispose();
  }
}
