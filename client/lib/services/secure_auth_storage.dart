import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage for authentication data using platform-specific secure storage
/// 
/// Replaces SharedPreferences for sensitive authentication information.
/// Uses iOS Keychain and Android Keystore for encrypted storage.
class SecureAuthStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const String _sessionKey = 'supabase_session';
  static const String _guestIdKey = 'guest_id';
  static const String _guestDataKey = 'guest_data';
  static const String _migrationStatusKey = 'migration_completed';
  static const String _userActionsKey = 'user_actions';

  /// Store Supabase session data
  static Future<void> storeSession(String sessionData) async {
    try {
      await _storage.write(key: _sessionKey, value: sessionData);
      debugPrint('✅ Session stored securely');
    } catch (e) {
      debugPrint('❌ Failed to store session: $e');
    }
  }

  /// Retrieve Supabase session data
  static Future<String?> getSession() async {
    try {
      return await _storage.read(key: _sessionKey);
    } catch (e) {
      debugPrint('❌ Failed to retrieve session: $e');
      return null;
    }
  }

  /// Clear session data
  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _sessionKey);
      debugPrint('✅ Session cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear session: $e');
    }
  }

  /// Store guest user data
  static Future<void> storeGuestData(String guestId, Map<String, dynamic> data) async {
    try {
      await _storage.write(key: _guestIdKey, value: guestId);
      await _storage.write(key: _guestDataKey, value: jsonEncode(data));
      debugPrint('✅ Guest data stored: $guestId');
    } catch (e) {
      debugPrint('❌ Failed to store guest data: $e');
    }
  }

  /// Retrieve guest user data
  static Future<GuestUserData?> getGuestData() async {
    try {
      final guestId = await _storage.read(key: _guestIdKey);
      final guestDataStr = await _storage.read(key: _guestDataKey);
      
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
      await _storage.delete(key: _guestIdKey);
      await _storage.delete(key: _guestDataKey);
      debugPrint('✅ Guest data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear guest data: $e');
    }
  }

  /// Store user actions for unified tracking
  static Future<void> storeUserActions(String userId, Map<String, int> actions) async {
    try {
      final key = '${_userActionsKey}_$userId';
      await _storage.write(key: key, value: jsonEncode(actions));
      debugPrint('✅ User actions stored for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to store user actions: $e');
    }
  }

  /// Retrieve user actions
  static Future<Map<String, int>> getUserActions(String userId) async {
    try {
      final key = '${_userActionsKey}_$userId';
      final actionsStr = await _storage.read(key: key);
      
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
      final key = '${_userActionsKey}_$userId';
      await _storage.delete(key: key);
      debugPrint('✅ User actions cleared for: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear user actions: $e');
    }
  }

  /// Mark migration as completed
  static Future<void> markMigrationComplete() async {
    try {
      await _storage.write(key: _migrationStatusKey, value: 'true');
      debugPrint('✅ Migration marked as complete');
    } catch (e) {
      debugPrint('❌ Failed to mark migration complete: $e');
    }
  }

  /// Check if migration is completed
  static Future<bool> isMigrationComplete() async {
    try {
      final status = await _storage.read(key: _migrationStatusKey);
      return status == 'true';
    } catch (e) {
      debugPrint('❌ Failed to check migration status: $e');
      return false;
    }
  }

  /// Clear all authentication data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ All secure storage cleared');
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
