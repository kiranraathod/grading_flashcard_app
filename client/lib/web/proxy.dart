import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ProxyClient {
  final String baseUrl;

  ProxyClient(this.baseUrl) {
    debugPrint('ProxyClient initialized with baseUrl: $baseUrl');
  }
  
  // Test CORS configuration to help diagnose issues
  Future<Map<String, dynamic>> testCorsConfiguration() async {
    try {
      debugPrint('Testing CORS configuration...');
      final response = await get('/api/cors-test');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('CORS test successful: ${response.statusCode}');
        return data;
      } else {
        debugPrint('CORS test failed with status code: ${response.statusCode}');
        return {
          'error': 'CORS test failed',
          'status_code': response.statusCode,
          'response': response.body,
        };
      }
    } catch (e) {
      debugPrint('CORS test threw exception: $e');
      return {
        'error': 'Exception during CORS test',
        'message': e.toString(),
      };
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    debugPrint('Making POST request to $uri');
    debugPrint('Headers: $mergedHeaders');
    if (body != null) {
      debugPrint('Request body: ${jsonEncode(body)}');
    }
    
    try {
      final response = await http.post(
        uri,
        headers: mergedHeaders,
        body: jsonEncode(body),
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      
      // Check for CORS issues
      if (response.statusCode == 0) {
        debugPrint('WARNING: Status code 0 may indicate a CORS issue');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error during POST request: $e');
      rethrow;
    }
  }
  
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Accept': 'application/json',
    };
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    debugPrint('Making GET request to $uri');
    debugPrint('Headers: $mergedHeaders');
    
    try {
      final response = await http.get(
        uri,
        headers: mergedHeaders,
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      
      // Check for CORS issues
      if (response.statusCode == 0) {
        debugPrint('WARNING: Status code 0 may indicate a CORS issue');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error during GET request: $e');
      rethrow;
    }
  }
  
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    debugPrint('Making PUT request to $uri');
    
    try {
      final response = await http.put(
        uri,
        headers: mergedHeaders,
        body: jsonEncode(body),
      );
      
      // Check for CORS issues
      if (response.statusCode == 0) {
        debugPrint('WARNING: Status code 0 may indicate a CORS issue');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error during PUT request: $e');
      rethrow;
    }
  }
  
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Accept': 'application/json',
    };
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    debugPrint('Making DELETE request to $uri');
    
    try {
      final response = await http.delete(
        uri,
        headers: mergedHeaders,
      );
      
      // Check for CORS issues
      if (response.statusCode == 0) {
        debugPrint('WARNING: Status code 0 may indicate a CORS issue');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error during DELETE request: $e');
      rethrow;
    }
  }
}
