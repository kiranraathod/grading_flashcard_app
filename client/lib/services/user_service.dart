import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/config.dart';
import 'simple_error_handler.dart';

/// UserService using Hive for consistent storage across the application
/// 
/// Migrated from SharedPreferences to align with StorageService pattern.
/// Includes automatic migration logic for existing users.
class UserService extends ChangeNotifier {
  // Hive storage
  static late Box _userBox;
  static const String _boxName = 'user_data';
  
  // Data properties
  List<bool> _weeklyStreak = List.filled(7, false);
  
  // Getters
  List<bool> get weeklyStreak => List.unmodifiable(_weeklyStreak);
  
  // Placeholder for current day (in real app, would be calculated)
  int get currentDay => DateTime.now().weekday % 7; // 0 = Sunday, 1 = Monday, etc.
  
  /// Initialize Hive box for UserService (call this during app startup)
  static Future<void> initialize() async {
    await SimpleErrorHandler.safely(
      () async {
        _userBox = await Hive.openBox(_boxName);
        debugPrint('✅ UserService: Hive box initialized successfully');
      },
      operationName: 'user_service_hive_initialization',
    );
  }
  
  UserService() {
    _loadUserData();
  }  
  /// Load user data with automatic migration from SharedPreferences
  Future<void> _loadUserData() async {
    await SimpleErrorHandler.safe<void>(
      () async {
        // Try loading from Hive first
        final hiveStreakData = _userBox.get(AppConfig.userStreakKey);
        if (hiveStreakData != null) {
          _weeklyStreak = List<bool>.from(hiveStreakData);
          debugPrint('✅ UserService: Loaded streak data from Hive');
          notifyListeners();
          return;
        }
        
        // Migration: Check SharedPreferences for existing data
        final prefs = await SharedPreferences.getInstance();
        final streakJson = prefs.getString(AppConfig.userStreakKey);
        
        if (streakJson != null) {
          // Migrate existing data
          final streakList = json.decode(streakJson) as List;
          _weeklyStreak = streakList.map((item) => item as bool).toList();
          
          // Save to Hive and cleanup SharedPreferences
          await _userBox.put(AppConfig.userStreakKey, _weeklyStreak);
          await prefs.remove(AppConfig.userStreakKey);
          
          debugPrint('✅ UserService: Migrated streak data from SharedPreferences to Hive');
        } else {
          // No existing data - initialize with default values
          _weeklyStreak = List.generate(7, (index) => index < 3);
          await _userBox.put(AppConfig.userStreakKey, _weeklyStreak);
          debugPrint('✅ UserService: Initialized default streak data');
        }
        
        notifyListeners();
      },
      fallbackOperation: () async {
        debugPrint('❌ UserService: Error loading user data, using fallback');
        // Fallback to default values
        _weeklyStreak = List.filled(7, false);
        notifyListeners();
      },
      operationName: 'load_user_data',
    );
  }  
  /// Mark a specific day as complete in the weekly streak
  Future<void> markDayComplete(int day) async {
    if (day >= 0 && day < 7) {
      _weeklyStreak[day] = true;
      await _saveUserData();
      notifyListeners();
      debugPrint('✅ UserService: Marked day $day as complete');
    } else {
      debugPrint('⚠️ UserService: Invalid day index: $day (must be 0-6)');
    }
  }
  
  /// Save user data to Hive storage
  Future<void> _saveUserData() async {
    await SimpleErrorHandler.safely(
      () async {
        await _userBox.put(AppConfig.userStreakKey, _weeklyStreak);
        debugPrint('✅ UserService: Saved streak data to Hive');
      },
      operationName: 'save_user_data',
    );
  }
  
  /// Reset the weekly streak (for testing purposes)
  Future<void> resetStreak() async {
    await SimpleErrorHandler.safely(
      () async {
        _weeklyStreak = List.filled(7, false);
        await _saveUserData();
        notifyListeners();
        debugPrint('✅ UserService: Reset weekly streak');
      },
      operationName: 'reset_streak',
    );
  }
  
  /// Reset all user data (for testing purposes)
  Future<void> resetUser() async {
    await SimpleErrorHandler.safely(
      () async {
        _weeklyStreak = List.filled(7, false);
        await _saveUserData();
        notifyListeners();
        debugPrint('✅ UserService: Reset user data');
      },
      operationName: 'reset_user',
    );
  }
}