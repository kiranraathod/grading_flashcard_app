import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthResponse {
  final Map<String, dynamic> user;
  final String token;

  AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'],
      token: json['token'],
    );
  }
}

class AuthState {
  final AuthChangeEvent event;
  final dynamic session;
  
  AuthState({
    required this.event,
    this.session,
  });
}

enum AuthChangeEvent {
  signedIn,
  signedOut,
  signedUp,
  passwordRecovery,
  userUpdated,
  tokenRefreshed,
}

class LocalAuthService {
  static final LocalAuthService _instance = LocalAuthService._internal();
  
  factory LocalAuthService() {
    return _instance;
  }
  
  LocalAuthService._internal();
  
  String? _token;
  Map<String, dynamic>? _user;
  
  // Auth state change stream
  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateChanges => _authStateController.stream;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = json.decode(userJson);
    }
    
    debugPrint('LocalAuthService initialized');
  }
  
  // Getters
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get userId => _user?['id'];
  bool get isAuthenticated => _token != null && _user != null;
  
  // Auth methods
  Future<AuthResponse> signUp({
    required String email, 
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'userData': data,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Registration failed: ${response.body}');
      }
      
      final responseData = json.decode(response.body);
      
      // Save token and user data
      await _saveAuthData(responseData['token'], responseData['user']);
      
      // Notify listeners
      _authStateController.add(AuthState(
        event: AuthChangeEvent.signedUp,
        session: null,  // Not needed
      ));
      
      return AuthResponse.fromJson(responseData);
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }
  
  Future<AuthResponse> signIn({
    required String email, 
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Login failed: ${response.body}');
      }
      
      final responseData = json.decode(response.body);
      
      // Save token and user data
      await _saveAuthData(responseData['token'], responseData['user']);
      
      // Notify listeners
      _authStateController.add(AuthState(
        event: AuthChangeEvent.signedIn,
        session: null,  // Not needed
      ));
      
      return AuthResponse.fromJson(responseData);
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    // Clear saved token and user data
    await _clearAuthData();
    
    // Notify listeners
    _authStateController.add(AuthState(
      event: AuthChangeEvent.signedOut,
      session: null,  // Not needed
    ));
  }
  
  Future<void> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Password reset failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
  
  // Helper methods
  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    _token = token;
    _user = userData;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user', json.encode(userData));
  }
  
  Future<void> _clearAuthData() async {
    _token = null;
    _user = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user');
  }
}
