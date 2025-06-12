import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Simple secure storage using SharedPreferences for development
/// In production, this would use flutter_secure_storage
class WorkingSecureAuthStorage {
  // Storage keys with prefixes for security
  static const String _sessionKey = 'auth_session_v2';
  static const String _guestIdKey = 'auth_guest_id_v2';
  static const String _guestDataKey = 'auth_guest_data_v2';
  static const String _migrationStatusKey = 'auth_migration_completed_v2';
  static const String _userActionsKey = 'auth_user_actions_v2';

  /// Store session data
  static Future<void> storeSession(String sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, sessionData);
      debugPrint('✅ Session stored');
    } catch (e) {
      debugPrint('❌ Failed to store session: $e');
    }
  }

  /// Retrieve session data
  static Future<String?> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionKey);
    } catch (e) {
      debugPrint('❌ Failed to retrieve session: $e');
      return null;
    }
  }

  /// Clear session data
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      debugPrint('✅ Session cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear session: $e');
    }
  }

  /// Store guest user data
  static Future<void> storeGuestData(String guestId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_guestIdKey, guestId);
      await prefs.setString(_guestDataKey, jsonEncode(data));
      debugPrint('✅ Guest data stored: $guestId');
    } catch (e) {
      debugPrint('❌ Failed to store guest data: $e');
    }
  }

  /// Retrieve guest user data
  static Future<GuestUserData?> getGuestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guestId = prefs.getString(_guestIdKey);
      final guestDataStr = prefs.getString(_guestDataKey);
      
      if (guestId != null && guestDataStr != null) {
        return GuestUserData(
          id: guestId,
          data: jsonDecode(guestDataStr),
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to retrieve guest data: $e');
      return null;
    }
  }

  /// Clear guest user data
  static Future<void> clearGuestData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestIdKey);
      await prefs.remove(_guestDataKey);
      debugPrint('✅ Guest data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear guest data: $e');
    }
  }

  /// Store user actions for unified tracking
  static Future<void> storeUserActions(String userId, Map<String, int> actions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userActionsKey}_$userId';
      await prefs.setString(key, jsonEncode(actions));
      debugPrint('✅ User actions stored for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to store user actions: $e');
    }
  }

  /// Retrieve user actions
  static Future<Map<String, int>> getUserActions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userActionsKey}_$userId';
      final actionsStr = prefs.getString(key);
      
      if (actionsStr != null) {
        final decoded = jsonDecode(actionsStr) as Map<String, dynamic>;
        return Map<String, int>.from(decoded);
      }
      return {};
    } catch (e) {
      debugPrint('❌ Failed to retrieve user actions: $e');
      return {};
    }
  }

  /// Clear user actions
  static Future<void> clearUserActions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_userActionsKey}_$userId';
      await prefs.remove(key);
      debugPrint('✅ User actions cleared for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear user actions: $e');
    }
  }

  /// Mark migration as completed
  static Future<void> markMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationStatusKey, true);
      debugPrint('✅ Migration marked as complete');
    } catch (e) {
      debugPrint('❌ Failed to mark migration complete: $e');
    }
  }

  /// Check if migration is completed
  static Future<bool> isMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationStatusKey) ?? false;
    } catch (e) {
      debugPrint('❌ Failed to check migration status: $e');
      return false;
    }
  }

  /// Clear all authentication data
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith('auth_')) {
          await prefs.remove(key);
        }
      }
      
      debugPrint('✅ All auth storage cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear all storage: $e');
    }
  }
}

/// Data class for guest user information
class GuestUserData {
  final String id;
  final Map<String, dynamic> data;

  const GuestUserData({
    required this.id,
    required this.data,
  });

  @override
  String toString() => 'GuestUserData(id: $id, data: $data)';
}
