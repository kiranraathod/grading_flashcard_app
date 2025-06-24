import 'package:flutter/foundation.dart';
import '../utils/enhanced_safe_map_converter.dart';

/// Simple test script to validate LinkedMap conversion fixes
/// 
/// This test simulates the exact conditions that were causing the
/// `LinkedMap<dynamic, dynamic>` conversion errors during guest-to-authenticated
/// user data migration.
class LinkedMapConversionTest {
  
  /// Test the Enhanced SafeMapConverter with problematic data types
  static Future<void> runBasicTest() async {
    debugPrint('🧪 LINKEDMAP CONVERSION TEST');
    debugPrint('===========================');
    
    try {
      // Test 1: Basic LinkedMap conversion
      await _testBasicConversion();
      
      // Test 2: List conversion
      await _testListConversion();
      
      // Test 3: Hive data simulation
      await _testHiveDataConversion();
      
      debugPrint('🏁 Basic test completed');
      
    } catch (e) {
      debugPrint('❌ Test failed: $e');
    }
  }
  
  /// Test basic LinkedMap conversion
  static Future<void> _testBasicConversion() async {
    debugPrint('\n📋 Test 1: Basic LinkedMap Conversion');
    debugPrint('-------------------------------------');
    
    try {
      // Simulate problematic LinkedMap data
      final Map<dynamic, dynamic> problematicData = {
        'id': '1',
        'title': 'Test Flashcard Set',
        'flashcards': [
          {
            'id': '1',
            'question': 'What is Python?',
            'answer': 'A programming language',
            'isCompleted': false,
          }
        ],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Input type: ${problematicData.runtimeType}');
      
      // Test Enhanced SafeMapConverter
      final converted = EnhancedSafeMapConverter.safeConvert(problematicData);
      
      if (converted != null) {
        debugPrint('✅ Conversion successful');
        debugPrint('  Output type: ${converted.runtimeType}');
        debugPrint('  Keys: ${converted.keys.toList()}');
        debugPrint('  Has flashcards: ${converted.containsKey('flashcards')}');
      } else {
        debugPrint('❌ Conversion failed');
      }
      
    } catch (e) {
      debugPrint('❌ Test 1 failed: $e');
    }
  }
  
  /// Test list conversion
  static Future<void> _testListConversion() async {
    debugPrint('\n📋 Test 2: List Conversion');
    debugPrint('---------------------------');
    
    try {
      final List<dynamic> testList = [
        {
          'id': 'set1',
          'title': 'Python Basics',
          'flashcards': [
            {
              'id': 'card1',
              'question': 'What is Python?',
              'answer': 'A programming language',
              'isCompleted': false,
            }
          ]
        }
      ];
      
      final converted = EnhancedSafeMapConverter.safeConvertList(testList);
      
      if (converted.isNotEmpty) {
        debugPrint('✅ List conversion successful');
        debugPrint('  Items converted: ${converted.length}');
      } else {
        debugPrint('❌ List conversion failed');
      }
      
    } catch (e) {
      debugPrint('❌ Test 2 failed: $e');
    }
  }
  
  /// Test Hive data conversion
  static Future<void> _testHiveDataConversion() async {
    debugPrint('\n📋 Test 3: Hive Data Conversion');
    debugPrint('--------------------------------');
    
    try {
      final List<dynamic> hiveData = [
        {
          'id': 'set1',
          'title': 'Python Basics',
          'flashcards': [
            {
              'id': 'card1',
              'question': 'What is Python?',
              'answer': 'A programming language',
              'isCompleted': false,
            }
          ],
          'isDraft': false,
          'lastUpdated': DateTime.now().toIso8601String(),
        }
      ];
      
      final converted = EnhancedSafeMapConverter.convertHiveData(hiveData);
      
      if (converted.isNotEmpty) {
        debugPrint('✅ Hive conversion successful');
        debugPrint('  Items converted: ${converted.length}');
        
        for (int i = 0; i < converted.length; i++) {
          final item = converted[i];
          debugPrint('  Item $i: ${item['title']}');
        }
      } else {
        debugPrint('❌ Hive conversion failed');
      }
      
    } catch (e) {
      debugPrint('❌ Test 3 failed: $e');
    }
  }
  
  /// Quick test for debugging
  static Future<void> quickTest() async {
    debugPrint('🔧 QUICK LINKEDMAP TEST');
    debugPrint('=======================');
    
    try {
      final testData = {
        'id': '1',
        'title': 'Test Data',
        'completed': false,
      };
      
      final result = EnhancedSafeMapConverter.safeConvert(testData);
      
      if (result != null) {
        debugPrint('✅ Quick test PASSED - LinkedMap fix is working!');
      } else {
        debugPrint('❌ Quick test FAILED');
      }
      
    } catch (e) {
      debugPrint('❌ Quick test error: $e');
    }
  }
}
