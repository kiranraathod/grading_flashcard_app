import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import '../models/app_error.dart';

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  final http.Client _client = http.Client();
  
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    final response = await _client.get(uri, headers: AppConfig.defaultHeaders)
        .timeout(AppConfig.apiTimeout);
    _validateResponse(response);
    return response;
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint, null);
    final response = await _client.post(uri, headers: AppConfig.defaultHeaders,
      body: body != null ? json.encode(body) : null).timeout(AppConfig.apiTimeout);
    _validateResponse(response);
    return response;
  }

  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final baseUri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint');
    return queryParams != null ? baseUri.replace(queryParameters: queryParams) : baseUri;
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw AppError.api('HTTP ${response.statusCode}', code: 'http_${response.statusCode}');
  }

  Future<bool> checkConnectivity() async {
    try {
      final response = await get('/api/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() => _client.close();
}
