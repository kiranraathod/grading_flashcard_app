import 'package:http/http.dart' as http;
import 'dart:convert';

class ProxyClient {
  final String baseUrl;

  ProxyClient(this.baseUrl);

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    return response;
  }
}
