import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' show Response;
import '../utils/config.dart';
import '../models/app_error.dart';
import 'enhanced_http_client_service.dart';
import 'connectivity_service.dart';
import 'simple_error_handler.dart';

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
    
    await SimpleErrorHandler.safe<void>(
      () async {
        await _enhancedClient.initialize();
        await _connectivity.initialize();
        _isInitialized = true;
        AppConfig.logNetwork('HttpClientService initialized with enhanced features', level: NetworkLogLevel.basic);
      },
      fallbackOperation: () async {
        AppConfig.logNetwork('Failed to initialize enhanced client, falling back to basic', level: NetworkLogLevel.errors);
        _useEnhancedClient = false;
        _isInitialized = true;
      },
      operationName: 'http_client_service_initialization',
    );
  }

  /// Enhanced GET request with automatic fallback
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    await _ensureInitialized();
    
    if (_useEnhancedClient) {
      return await SimpleErrorHandler.safe<http.Response>(
        () async {
          final response = await _enhancedClient.get(endpoint, queryParameters: queryParams);
          return _convertDioResponse(response);
        },
        fallbackOperation: () async {
          AppConfig.logNetwork('Enhanced client failed, falling back', level: NetworkLogLevel.verbose);
          return await _fallbackGet(endpoint, queryParams);
        },
        operationName: 'enhanced_http_get',
      );
    } else {
      return await _fallbackGet(endpoint, queryParams);
    }
  }

  /// Enhanced POST request with automatic fallback
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    await _ensureInitialized();
    
    if (_useEnhancedClient) {
      return await SimpleErrorHandler.safe<http.Response>(
        () async {
          final response = await _enhancedClient.post(endpoint, data: body);
          return _convertDioResponse(response);
        },
        fallbackOperation: () async {
          AppConfig.logNetwork('Enhanced client failed, falling back', level: NetworkLogLevel.verbose);
          return await _fallbackPost(endpoint, body);
        },
        operationName: 'enhanced_http_post',
      );
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
  http.Response _convertDioResponse(Response response) {
    // Convert headers from Map<String, List<String>> to Map<String, String>
    // by taking the first value from each header list
    final Map<String, String> convertedHeaders = {};
    response.headers.map.forEach((key, values) {
      if (values.isNotEmpty) {
        convertedHeaders[key] = values.first;
      }
    });
    
    return http.Response(
      response.data is String ? response.data : json.encode(response.data),
      response.statusCode ?? 200,
      headers: convertedHeaders,
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
      return await SimpleErrorHandler.safe<bool>(
        () async {
          final response = await get('/api/ping');
          return response.statusCode == 200;
        },
        fallback: false,
        operationName: 'http_connectivity_check',
      );
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
