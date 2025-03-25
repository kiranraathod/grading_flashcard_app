import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserService extends ChangeNotifier {
  int _level = 0;
  int _xp = 0;
  int _maxXp = 50;
  List<bool> _weeklyStreak = List.filled(7, false);
  
  int get level => _level;
  int get xp => _xp;
  int get maxXp => _maxXp;
  List<bool> get weeklyStreak => List.unmodifiable(_weeklyStreak);
  
  // Placeholder for current day (in real app, would be calculated)
  int get currentDay => DateTime.now().weekday % 7; // 0 = Sunday, 1 = Monday, etc.
  
  UserService() {
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
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
      debugPrint('Error loading user data: $e');
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
      await _saveUserData();
      notifyListeners();
    }
  }
  
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('level', _level);
      await prefs.setInt('xp', _xp);
      await prefs.setInt('maxXp', _maxXp);
      await prefs.setString('weeklyStreak', json.encode(_weeklyStreak));
    } catch (e) {
      debugPrint('Error saving user data: $e');
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
