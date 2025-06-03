// Test script to verify UserService Hive migration
// This is a basic validation script - run: dart test test/userservice_migration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_flashcard_app/services/user_service.dart';

void main() {
  group('UserService Hive Migration Tests', () {
    setUp(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      await UserService.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      await Hive.deleteFromDisk();
    });

    test('UserService should initialize correctly', () async {
      expect(() => UserService(), returnsNormally);
    });

    test('UserService should store and retrieve weekly streak', () async {
      final userService = UserService();
      
      // Mark some days as complete
      await userService.markDayComplete(0);
      await userService.markDayComplete(2);
      await userService.markDayComplete(4);

      // Verify the streak is updated
      expect(userService.weeklyStreak[0], isTrue);
      expect(userService.weeklyStreak[1], isFalse);
      expect(userService.weeklyStreak[2], isTrue);
      expect(userService.weeklyStreak[3], isFalse);
      expect(userService.weeklyStreak[4], isTrue);
    });

    test('UserService should reset streak correctly', () async {
      final userService = UserService();
      
      // Mark some days as complete
      await userService.markDayComplete(0);
      await userService.markDayComplete(1);
      
      // Reset streak
      await userService.resetStreak();
      
      // Verify all days are false
      for (int i = 0; i < 7; i++) {
        expect(userService.weeklyStreak[i], isFalse);
      }
    });

    test('UserService should persist data across instances', () async {
      // Create first instance and set data
      final userService1 = UserService();
      await userService1.markDayComplete(1);
      await userService1.markDayComplete(3);
      
      // Create second instance and verify data persists
      final userService2 = UserService();
      
      // Wait for data to load
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(userService2.weeklyStreak[1], isTrue);
      expect(userService2.weeklyStreak[3], isTrue);
      expect(userService2.weeklyStreak[0], isFalse);
    });

    test('UserService should handle invalid day indices gracefully', () async {
      final userService = UserService();
      
      // Test invalid indices - should not throw
      expect(() => userService.markDayComplete(-1), returnsNormally);
      expect(() => userService.markDayComplete(7), returnsNormally);
      expect(() => userService.markDayComplete(100), returnsNormally);
    });
  });
}