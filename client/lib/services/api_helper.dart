import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A helper class for making API requests with improved timeout handling
class ApiHelper {
  final String baseUrl;
  final Duration timeout;
  
  ApiHelper({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });
  
  /// Makes a POST request with proper timeout and error handling
  Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> data
  ) async {
    final url = '$baseUrl$endpoint';
    
    print('Making API request to $url');
    print('Sending data: ${jsonEncode(data)}');
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(
        timeout,
        onTimeout: () {
          print('API request timed out after ${timeout.inSeconds} seconds');
          throw TimeoutException('Server took too long to respond');
        },
      );
      
      print('Received response with status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during API call: $e');
      rethrow;
    }
  }
  
  /// Makes a GET request with proper timeout and error handling
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );
    
    print('Making API GET request to $uri');
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        timeout,
        onTimeout: () {
          print('API request timed out after ${timeout.inSeconds} seconds');
          throw TimeoutException('Server took too long to respond');
        },
      );
      
      print('Received response with status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during API call: $e');
      rethrow;
    }
  }
  
  /// Example usage for grading a flashcard answer
  Future<Map<String, dynamic>> gradeAnswer(
    String flashcardId,
    String question,
    String userAnswer
  ) async {
    return await post('/api/grade', {
      'flashcardId': flashcardId,
      'question': question,
      'userAnswer': userAnswer,
    });
  }
  
  /// Example usage for getting suggestions
  Future<Map<String, dynamic>> getSuggestions(String flashcardId) async {
    return await get('/api/suggestions', queryParams: {
      'flashcardId': flashcardId,
    });
  }
  
  /// Example usage for submitting feedback
  Future<Map<String, dynamic>> submitFeedback(
    String flashcardId,
    String userFeedback
  ) async {
    return await post('/api/feedback', {
      'flashcardId': flashcardId,
      'userFeedback': userFeedback,
    });
  }
}
