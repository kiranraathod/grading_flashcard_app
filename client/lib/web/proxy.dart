import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/local_auth_service.dart';

class ProxyClient {
  final String baseUrl;
  final LocalAuthService _authService = LocalAuthService();

  ProxyClient(this.baseUrl);

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
    
    // No longer requiring authentication tokens for any endpoints
    debugPrint('Making request to $endpoint without requiring authentication');
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    final response = await http.post(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    return response;
  }
  
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Accept': 'application/json',
    };
    
    // No longer requiring authentication tokens for any endpoints
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    final response = await http.get(
      uri,
      headers: mergedHeaders,
    );
    return response;
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
    
    // No longer requiring authentication tokens for any endpoints
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    final response = await http.put(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    return response;
  }
  
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Accept': 'application/json',
    };
    
    // Add authentication token if available
    if (_authService.isAuthenticated && _authService.token != null) {
      defaultHeaders['Authorization'] = 'Bearer ${_authService.token}';
    }
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    final response = await http.delete(
      uri,
      headers: mergedHeaders,
    );
    return response;
  }
}
