import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_auth_service.dart';
import 'local_api_service.dart';

class UserService extends ChangeNotifier {
  final LocalAuthService _authService = LocalAuthService();
  final LocalApiService _apiService = LocalApiService();

  int _level = 0;
  int _xp = 0;
  int _maxXp = 50;
  List<bool> _weeklyStreak = List.filled(7, false);
  String? _displayName;
  String? _avatarUrl;

  int get level => _level;
  int get xp => _xp;
  int get maxXp => _maxXp;
  List<bool> get weeklyStreak => List.unmodifiable(_weeklyStreak);
  String? get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;

  // Authentication getters
  bool get isAuthenticated => _authService.isAuthenticated;
  Map<String, dynamic>? get currentUser => _authService.user;
  String? get userId => _authService.userId;

  // Placeholder for current day (in real app, would be calculated)
  int get currentDay =>
      DateTime.now().weekday % 7; // 0 = Sunday, 1 = Monday, etc.

  UserService() {
    _loadUserData();

    // Listen for auth state changes
    _authService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedIn || 
          event.event == AuthChangeEvent.signedUp) {
        _loadUserData();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _resetUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      if (_authService.isAuthenticated) {
        // Load from API
        try {
          final profileData = await _apiService.getUserProfile();
          
          _level = profileData['level'] ?? 0;
          _xp = profileData['xp'] ?? 0;
          _maxXp = profileData['max_xp'] ?? 50;
          _displayName = profileData['display_name'];
          _avatarUrl = profileData['avatar_url'];

          // Get streak data
          final streakData = await _apiService.getLearningStats();
          
          // Initialize streak array
          _weeklyStreak = List.filled(7, false);
          
          // Set streak days based on session data
          // This is simplified - your actual implementation may differ
          final int streakDays = streakData['streakDays'] ?? 0;
          final DateTime now = DateTime.now();
          
          for (int i = 0; i < streakDays && i < 7; i++) {
            final int day = (now.subtract(Duration(days: i)).weekday) % 7;
            _weeklyStreak[day] = true;
          }
        } catch (e) {
          debugPrint('Error loading data from API: $e');
          // Fall back to local data if API fails
          await _loadLocalData();
        }
      } else {
        // Fallback to SharedPreferences for non-authenticated users
        await _loadLocalData();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Fallback to local data if there's an error
      await _loadLocalData();
    }
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _level = prefs.getInt('level') ?? 0;
      _xp = prefs.getInt('xp') ?? 0;
      _maxXp = prefs.getInt('maxXp') ?? 50;

      final streakJson = prefs.getString('weeklyStreak');
      if (streakJson != null) {
        final streakList = json.decode(streakJson) as List;
        _weeklyStreak = streakList.map((item) => item as bool).toList();
      } else {
        // In a real app, this would track actual user activity
        // For now, just simulate some streak data
        _weeklyStreak = List.generate(7, (index) => index < 3);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local user data: $e');
    }
  }

  Future<void> addXp(int amount) async {
    _xp += amount;

    // Level up if XP threshold reached
    if (_xp >= _maxXp) {
      _level++;
      _xp = _xp - _maxXp;
      _maxXp = (_maxXp * 1.2).round(); // Increase XP needed for next level
    }

    await _saveUserData();
    notifyListeners();
  }

  Future<void> markDayComplete(int day) async {
    if (day >= 0 && day < 7) {
      _weeklyStreak[day] = true;

      if (_authService.isAuthenticated) {
        // We don't need to call the API - your backend will handle the streak
        // when you submit progress through study sessions
      }

      await _saveUserData();
      notifyListeners();
    }
  }

  Future<void> _saveUserData() async {
    try {
      if (_authService.isAuthenticated) {
        // Update progress on the server
        try {
          await _apiService.updateUserProgress(_xp);
          
          // Update profile if needed
          if (_displayName != null || _avatarUrl != null) {
            await _apiService.updateUserProfile({
              'display_name': _displayName,
              'avatar_url': _avatarUrl,
            });
          }
        } catch (e) {
          debugPrint('Error saving data to API: $e');
          // Fall back to local storage if API fails
          await _saveLocalData();
        }
      } else {
        // Save locally for non-authenticated users
        await _saveLocalData();
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
      // Fallback to local storage if there's an error
      await _saveLocalData();
    }
  }

  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('level', _level);
      await prefs.setInt('xp', _xp);
      await prefs.setInt('maxXp', _maxXp);
      await prefs.setString('weeklyStreak', json.encode(_weeklyStreak));
    } catch (e) {
      debugPrint('Error saving local user data: $e');
    }
  }

  void _resetUserData() {
    _level = 0;
    _xp = 0;
    _maxXp = 50;
    _weeklyStreak = List.filled(7, false);
    _displayName = null;
    _avatarUrl = null;
    notifyListeners();
  }

  // Authentication methods
  Future<AuthResponse> signIn(String email, String password) async {
    return await _authService.signIn(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _authService.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  // Profile methods
  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    if (!_authService.isAuthenticated) return;

    try {
      Map<String, dynamic> updates = {};
      if (displayName != null) {
        updates['display_name'] = displayName;
        _displayName = displayName;
      }

      if (avatarUrl != null) {
        updates['avatar_url'] = avatarUrl;
        _avatarUrl = avatarUrl;
      }

      if (updates.isNotEmpty) {
        await _apiService.updateUserProfile(updates);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  // Reset streak (for testing)
  Future<void> resetStreak() async {
    _weeklyStreak = List.filled(7, false);
    await _saveUserData();
    notifyListeners();
  }

  // Reset user (for testing)
  Future<void> resetUser() async {
    _level = 0;
    _xp = 0;
    _maxXp = 50;
    _weeklyStreak = List.filled(7, false);
    await _saveUserData();
    notifyListeners();
  }
}
