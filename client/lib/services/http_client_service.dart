import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import '../models/app_error.dart';
import 'enhanced_http_client_service.dart';
import 'connectivity_service.dart';

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  final http.Client _client = http.Client();
  final EnhancedHttpClientService _enhancedClient = EnhancedHttpClientService();
  final ConnectivityService _connectivity = ConnectivityService();
  
  bool _useEnhancedClient = true;
  bool _isInitialized = false;

  /// Initialize the HTTP client service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _enhancedClient.initialize();
      await _connectivity.initialize();
      _isInitialized = true;
      AppConfig.logNetwork('HttpClientService initialized with enhanced features', level: NetworkLogLevel.basic);
    } catch (e) {
      AppConfig.logNetwork('Failed to initialize enhanced client, falling back to basic: $e', level: NetworkLogLevel.errors);
      _useEnhancedClient = false;
      _isInitialized = true;
    }
  }

  /// Enhanced GET request with automatic fallback
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    await _ensureInitialized();
    
    if (_useEnhancedClient) {
      try {
        final response = await _enhancedClient.get(endpoint, queryParameters: queryParams);
        return _convertDioResponse(response);
      } catch (e) {
        AppConfig.logNetwork('Enhanced client failed, falling back: $e', level: NetworkLogLevel.verbose);
        return await _fallbackGet(endpoint, queryParams);
      }
    } else {
      return await _fallbackGet(endpoint, queryParams);
    }
  }

  /// Enhanced POST request with automatic fallback
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    await _ensureInitialized();
    
    if (_useEnhancedClient) {
      try {
        final response = await _enhancedClient.post(endpoint, data: body);
        return _convertDioResponse(response);
      } catch (e) {
        AppConfig.logNetwork('Enhanced client failed, falling back: $e', level: NetworkLogLevel.verbose);
        return await _fallbackPost(endpoint, body);
      }
    } else {
      return await _fallbackPost(endpoint, body);
    }
  }

  /// Fallback GET using basic HTTP client
  Future<http.Response> _fallbackGet(String endpoint, Map<String, String>? queryParams) async {
    final uri = _buildUri(endpoint, queryParams);
    final response = await _client.get(uri, headers: AppConfig.defaultHeaders)
        .timeout(AppConfig.apiTimeout);
    _validateResponse(response);
    return response;
  }

  /// Fallback POST using basic HTTP client
  Future<http.Response> _fallbackPost(String endpoint, Map<String, dynamic>? body) async {
    final uri = _buildUri(endpoint, null);
    final response = await _client.post(uri, headers: AppConfig.defaultHeaders,
      body: body != null ? json.encode(body) : null).timeout(AppConfig.apiTimeout);
    _validateResponse(response);
    return response;
  }

  /// Convert Dio response to http.Response for backward compatibility
  http.Response _convertDioResponse(response) {
    return http.Response(
      response.data is String ? response.data : json.encode(response.data),
      response.statusCode ?? 200,
      headers: Map<String, String>.from(response.headers.map),
    );
  }

  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final baseUri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    return queryParams != null ? baseUri.replace(queryParameters: queryParams) : baseUri;
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw AppError.api('HTTP ${response.statusCode}', code: 'http_${response.statusCode}');
  }

  /// Enhanced connectivity check
  Future<bool> checkConnectivity() async {
    await _ensureInitialized();
    
    if (_useEnhancedClient) {
      return await _enhancedClient.healthCheck();
    } else {
      try {
        final response = await get('/api/ping');
        return response.statusCode == 200;
      } catch (e) {
        return false;
      }
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_useEnhancedClient) {
      return _enhancedClient.getPerformanceStats();
    }
    return {'message': 'Enhanced features not available'};
  }

  /// Reset circuit breaker
  void resetCircuitBreaker() {
    if (_useEnhancedClient) {
      _enhancedClient.resetCircuitBreaker();
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void dispose() {
    _client.close();
    if (_useEnhancedClient) {
      _enhancedClient.dispose();
    }
  }
}
