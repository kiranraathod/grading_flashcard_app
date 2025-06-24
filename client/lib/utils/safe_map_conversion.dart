/// Safe Map conversion utilities to handle LinkedMap and other Map type issues
/// 
/// This utility prevents the common LinkedMap<dynamic, dynamic> to Map<String, dynamic>
/// conversion errors that occur during data migration and storage operations.
library;

import 'package:flutter/foundation.dart';

class SafeMapConverter {
  /// Safely convert any Map type (including LinkedMap) to Map<String, dynamic>
  /// 
  /// This method handles:
  /// - LinkedMap<dynamic, dynamic> from Hive storage
  /// - _InternalLinkedHashMap from JSON parsing  
  /// - Nested structures with recursive conversion
  /// - Type safety with comprehensive error handling
  static Map<String, dynamic>? safeConvert(dynamic input) {
    try {
      if (input == null) return null;
      
      if (input is Map<String, dynamic>) {
        // Already the right type, but may have nested LinkedMaps
        return _convertMapRecursively(input);
      } else if (input is Map) {
        // LinkedMap, _InternalLinkedHashMap, or other Map types
        return _convertMapRecursively(input);
      } else {
        debugPrint('⚠️ SafeMapConverter: Input is not a Map type: ${input.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ SafeMapConverter: Failed to convert map: $e');
      return null;
    }
  }

  /// Convert a list of maps safely, filtering out any failed conversions
  static List<Map<String, dynamic>> safeConvertList(List<dynamic> input) {
    try {
      return input
          .map((item) => safeConvert(item))
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('❌ SafeMapConverter: Failed to convert list: $e');
      return [];
    }
  }

  /// Recursively convert Map to handle nested LinkedMaps with comprehensive error handling
  static Map<String, dynamic> _convertMapRecursively(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    
    try {
      map.forEach((key, value) {
        try {
          final stringKey = key.toString();
          result[stringKey] = _safeValueConversion(value);
        } catch (e) {
          debugPrint('❌ SafeMapConverter: Error converting map entry with key "$key": $e');
          // Skip this entry but continue with others
        }
      });
    } catch (e) {
      debugPrint('❌ SafeMapConverter: Error iterating over map: $e');
    }
    
    return result;
  }

  /// Safely convert any value type with recursive handling
  static dynamic _safeValueConversion(dynamic value) {
    try {
      if (value == null) {
        return null;
      } else if (value is Map<String, dynamic>) {
        return _convertMapRecursively(value);
      } else if (value is Map) {
        return _convertMapRecursively(value);
      } else if (value is List) {
        return value.map((item) => _safeValueConversion(item)).toList();
      } else {
        // Primitive types (String, int, double, bool, etc.)
        return value;
      }
    } catch (e) {
      debugPrint('❌ SafeMapConverter: Error converting value: $e');
      return null;
    }
  }

  /// Utility method for safe JSON parsing with LinkedMap handling
  /// 
  /// Use this when you need to parse JSON that might contain nested structures
  /// and want to ensure all Maps are properly converted to Map<String, dynamic>
  static Map<String, dynamic>? safeJsonDecode(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      return safeConvert(decoded);
    } catch (e) {
      debugPrint('❌ SafeMapConverter: Failed to decode JSON: $e');
      return null;
    }
  }

  /// Convert Hive data to JSON-serializable format
  /// 
  /// Specifically designed for migrating data from Hive storage that may contain
  /// LinkedMap objects to JSON-compatible Map<String, dynamic> format
  static List<Map<String, dynamic>> convertHiveData(List<dynamic> hiveData) {
    try {
      debugPrint('🔄 SafeMapConverter: Converting ${hiveData.length} items from Hive format');
      
      final converted = safeConvertList(hiveData);
      
      debugPrint('✅ SafeMapConverter: Successfully converted ${converted.length} items');
      return converted;
    } catch (e) {
      debugPrint('❌ SafeMapConverter: Error converting Hive data: $e');
      return [];
    }
  }
}

// Import for JSON functionality
import 'dart:convert';
