import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// BACKUP of original UserService implementation using SharedPreferences
/// Created during migration to Hive - DO NOT USE IN PRODUCTION
class UserServiceBackup extends ChangeNotifier {
  // Removed level and XP related properties
  List<bool> _weeklyStreak = List.filled(7, false);
  
  // Removed level and XP related getters
  List<bool> get weeklyStreak => List.unmodifiable(_weeklyStreak);
  
  // Placeholder for current day (in real app, would be calculated)
  int get currentDay => DateTime.now().weekday % 7; // 0 = Sunday, 1 = Monday, etc.
  
  UserServiceBackup() {
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
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
  
  // Removed addXp method
  
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
      // Removed level and XP related saving
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
  
  // Reset user (for testing) - simplified to only reset streak
  Future<void> resetUser() async {
    _weeklyStreak = List.filled(7, false);
    await _saveUserData();
    notifyListeners();
  }
}