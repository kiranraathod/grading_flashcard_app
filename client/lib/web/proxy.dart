import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../utils/config.dart';
import '../models/app_error.dart';

class ProxyClient {
  final String baseUrl;

  ProxyClient(this.baseUrl);
  
  // Helper function to determine if we should retry based on exception type
  bool _shouldRetry(Exception exception) {
    // Check if it's our custom AppError type
    if (exception is AppError) {
      // Cast to AppError to access its properties safely
      final appError = exception as AppError;
      // Only retry network errors and timeouts
      return appError.code == 'network_error' || 
             appError.code == 'api_timeout';
    } 
    
    // For generic exceptions, check the error message
    final message = exception.toString().toLowerCase();
    return message.contains('timeout') || 
           message.contains('socket') || 
           message.contains('connection');
  }

  // POST request with error handling, timeouts, retries, and logging
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    Map<String, String>? additionalHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      ...AppConfig.defaultHeaders,
      ...?additionalHeaders,
    };
    
    // Log request based on log level
    AppConfig.logNetwork(
      'POST $endpoint - Request: ${jsonEncode(body)}', 
      level: NetworkLogLevel.verbose
    );
    
    return AppConfig.withRetry<http.Response>(
      operation: () async {
        return AppConfig.withTimeout<http.Response>(
          operation: () async {
            final response = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(body),
            );
            
            // Log response based on log level
            if (response.statusCode >= 200 && response.statusCode < 300) {
              AppConfig.logNetwork(
                'POST $endpoint - Success: ${response.statusCode}',
                level: NetworkLogLevel.basic
              );
            } else {
              AppConfig.logNetwork(
                'POST $endpoint - Error: ${response.statusCode} - ${response.body}',
                level: NetworkLogLevel.errors
              );
            }
            
            return response;
          },
          timeout: timeout ?? AppConfig.apiTimeout,
          context: 'POST $endpoint',
          onTimeout: () {
            throw AppError.api(
              'The server took too long to respond',
              code: 'api_timeout',
              severity: ErrorSeverity.warning,
              context: {
                'endpoint': endpoint,
                'timeout': (timeout ?? AppConfig.apiTimeout).inSeconds,
              },
            );
          },
        );
      },
      maxAttempts: maxRetries ?? AppConfig.maxRetryAttempts,
      delay: retryDelay ?? AppConfig.retryDelay,
      context: 'POST $endpoint',
      retryIf: _shouldRetry,
    );
  }  // GET request with the same error handling, timeouts, and retries
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    Map<String, String>? additionalHeaders,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    final headers = {
      ...AppConfig.defaultHeaders,
      ...?additionalHeaders,
    };
    
    AppConfig.logNetwork(
      'GET $endpoint${queryParams != null ? ' - Params: $queryParams' : ''}', 
      level: NetworkLogLevel.verbose
    );
    
    return AppConfig.withRetry<http.Response>(
      operation: () async {
        return AppConfig.withTimeout<http.Response>(
          operation: () async {
            final response = await http.get(
              uri,
              headers: headers,
            );
            
            if (response.statusCode >= 200 && response.statusCode < 300) {
              AppConfig.logNetwork(
                'GET $endpoint - Success: ${response.statusCode}',
                level: NetworkLogLevel.basic
              );
            } else {
              AppConfig.logNetwork(
                'GET $endpoint - Error: ${response.statusCode} - ${response.body}',
                level: NetworkLogLevel.errors
              );
            }
            
            return response;
          },
          timeout: timeout ?? AppConfig.apiTimeout,
          context: 'GET $endpoint',
          onTimeout: () {
            throw AppError.api(
              'The server took too long to respond',
              code: 'api_timeout',
              severity: ErrorSeverity.warning,
              context: {
                'endpoint': endpoint,
                'timeout': (timeout ?? AppConfig.apiTimeout).inSeconds,
              },
            );
          },
        );
      },
      maxAttempts: maxRetries ?? AppConfig.maxRetryAttempts,
      delay: retryDelay ?? AppConfig.retryDelay,
      context: 'GET $endpoint',
      retryIf: _shouldRetry,
    );
  }
}