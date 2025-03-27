import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

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
  bool get isAuthenticated => _supabaseService.isAuthenticated;
  User? get currentUser => _supabaseService.currentUser;

  // Placeholder for current day (in real app, would be calculated)
  int get currentDay =>
      DateTime.now().weekday % 7; // 0 = Sunday, 1 = Monday, etc.

  UserService() {
    _loadUserData();

    // Listen for auth state changes
    _supabaseService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _loadUserData();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _resetUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      if (_supabaseService.isAuthenticated) {
        // Load from Supabase
        final userId = _supabaseService.currentUser!.id;

        // Fetch profile data from Supabase
        final response =
            await _supabaseService.client
                .from('profiles')
                .select()
                .eq('id', userId)
                .maybeSingle();

        if (response != null) {
          _level = response['level'] ?? 0;
          _xp = response['xp'] ?? 0;
          _maxXp = response['max_xp'] ?? 50;
          _displayName = response['display_name'];
          _avatarUrl = response['avatar_url'];

          // Fetch streak data (simplified approach)
          final DateTime now = DateTime.now();
          final DateTime weekAgo = now.subtract(const Duration(days: 7));

          final sessionResponse = await _supabaseService.client
              .from('study_sessions')
              .select('start_time')
              .eq('user_id', userId)
              .gte('start_time', weekAgo.toIso8601String())
              .order('start_time');

          if (sessionResponse != null) {
            _weeklyStreak = List.filled(7, false);

            for (var session in sessionResponse) {
              final sessionDay =
                  DateTime.parse(session['start_time']).weekday % 7;
              _weeklyStreak[sessionDay] = true;
            }
          }
        }
      } else {
        // Fallback to SharedPreferences for non-authenticated users
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
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Fallback to local data if there's an error
      _loadLocalData();
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

      if (_supabaseService.isAuthenticated) {
        // Create a study session record
        await _supabaseService.client.from('study_sessions').insert({
          'user_id': _supabaseService.currentUser!.id,
          'cards_studied': 1, // Minimal entry
          'start_time': DateTime.now().toIso8601String(),
          'end_time': DateTime.now().toIso8601String(),
        });
      }

      await _saveUserData();
      notifyListeners();
    }
  }

  Future<void> _saveUserData() async {
    try {
      if (_supabaseService.isAuthenticated) {
        // Save to Supabase
        final userId = _supabaseService.currentUser!.id;

        // Update profile in Supabase
        await _supabaseService.client
            .from('profiles')
            .update({
              'level': _level,
              'xp': _xp,
              'max_xp': _maxXp,
              'last_updated': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      } else {
        // Save locally for non-authenticated users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('level', _level);
        await prefs.setInt('xp', _xp);
        await prefs.setInt('maxXp', _maxXp);
        await prefs.setString('weeklyStreak', json.encode(_weeklyStreak));
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
      // Fallback to local storage if there's an error
      _saveLocalData();
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
    return await _supabaseService.signIn(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabaseService.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabaseService.resetPassword(email);
  }

  // Profile methods
  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    if (!_supabaseService.isAuthenticated) return;

    try {
      final userId = _supabaseService.currentUser!.id;

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
        await _supabaseService.client
            .from('profiles')
            .update(updates)
            .eq('id', userId);

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
