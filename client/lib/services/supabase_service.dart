import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  
  factory SupabaseService() {
    return _instance;
  }
  
  SupabaseService._internal();
  
  Future<void> initialize() async {
    await Supabase.initialize(
      url: Constants.supabaseUrl,
      anonKey: Constants.supabaseAnonKey,
      debug: kDebugMode,
    );
    debugPrint('Supabase initialized with URL: ${Constants.supabaseUrl}');
  }
  
  // Get the Supabase client
  SupabaseClient get client => Supabase.instance.client;
  
  // Auth methods
  Future<AuthResponse> signUp({
    required String email, 
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  Future<AuthResponse> signIn({
    required String email, 
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
  
  // Get current user
  User? get currentUser => client.auth.currentUser;
  
  // Check if user is signed in
  bool get isAuthenticated => currentUser != null;
  
  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
