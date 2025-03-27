import 'package:http/http.dart' as http;
import 'dart:convert';

class ProxyClient {
  final String baseUrl;

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
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    final response = await http.delete(
      uri,
      headers: mergedHeaders,
    );
    return response;
  }
}
