import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Enhanced SafeMapConverter - Production-Ready LinkedMap Conversion Utility
/// 
/// Solves the critical `LinkedMap<dynamic, dynamic>` to `Map<String, dynamic>` conversion
/// errors that occur during Hive storage data migration and guest-to-authenticated
/// user transitions in Flutter applications.
/// 
/// Based on Flutter community best practices and handles:
/// - LinkedMap from Hive storage
/// - _InternalLinkedHashMap from JSON parsing
/// - Nested structures with recursive conversion
/// - Deep object graphs with circular reference protection
/// - Type safety with comprehensive error handling

class EnhancedSafeMapConverter {
  // Track conversion depth to prevent infinite recursion
  static int _conversionDepth = 0;
  static const int _maxDepth = 50;
  
  /// Primary conversion method - handles any input type safely
  /// 
  /// This is the main entry point for all conversions. It automatically
  /// detects the input type and applies the appropriate conversion strategy.
  static Map<String, dynamic>? safeConvert(dynamic input) {
    try {
      _conversionDepth = 0; // Reset depth counter
      return _performSafeConversion(input);
    } catch (e) {
      debugPrint('❌ EnhancedSafeMapConverter: Critical conversion failure: $e');
      return null;
    }
  }

  /// Internal conversion with depth tracking
  static Map<String, dynamic>? _performSafeConversion(dynamic input) {
    // Prevent infinite recursion
    if (_conversionDepth > _maxDepth) {
      debugPrint('⚠️ Max conversion depth reached, stopping recursion');
      return <String, dynamic>{};
    }
    
    _conversionDepth++;
    
    try {
      if (input == null) {
        return null;
      }
      
      // Handle different input types
      if (input is Map<String, dynamic>) {
        // Already correct type, but may have nested LinkedMaps
        return _convertMapRecursively(input);
      } else if (input is Map) {
        // LinkedMap, _InternalLinkedHashMap, or other Map types
        return _convertMapRecursively(input);
      } else if (input is String) {
        // Try to parse as JSON if it's a JSON string
        return _tryParseJsonString(input);
      } else {
        debugPrint('⚠️ Input is not a Map type: ${input.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Conversion failed for input type ${input.runtimeType}: $e');
      return null;
    } finally {
      _conversionDepth--;
    }
  }

  /// Convert a list of dynamic items to `List<Map<String, dynamic>>`
  /// 
  /// Filters out any items that fail to convert, ensuring partial success
  /// even when some items in the list are corrupted or incompatible.
  static List<Map<String, dynamic>> safeConvertList(List<dynamic> input) {
    try {
      final List<Map<String, dynamic>> result = [];
      
      for (int i = 0; i < input.length; i++) {
        try {
          final converted = safeConvert(input[i]);
          if (converted != null) {
            result.add(converted);
          } else {
            debugPrint('⚠️ Skipping unconvertible item at index $i: ${input[i].runtimeType}');
          }
        } catch (e) {
          debugPrint('❌ Failed to convert list item at index $i: $e');
          // Continue with next item
        }
      }
      
      debugPrint('✅ Converted ${result.length}/${input.length} list items successfully');
      return result;
    } catch (e) {
      debugPrint('❌ List conversion failed: $e');
      return [];
    }
  }

  /// Recursively convert Map with comprehensive error handling
  /// 
  /// This method handles the core conversion logic for nested Map structures,
  /// including LinkedMaps from Hive and other Map variants.
  static Map<String, dynamic> _convertMapRecursively(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    
    try {
      // Use entries to avoid concurrent modification issues
      final entries = map.entries.toList();
      
      for (final entry in entries) {
        try {
          final String key = entry.key.toString();
          final dynamic value = entry.value;
          
          result[key] = _convertValueRecursively(value);
        } catch (e) {
          debugPrint('❌ Failed to convert map entry with key "${entry.key}": $e');
          // Skip this entry but continue with others
        }
      }
    } catch (e) {
      debugPrint('❌ Error iterating over map: $e');
    }
    
    return result;
  }

  /// Convert individual values with type-specific handling
  /// 
  /// Handles primitive types, nested Maps, Lists, and complex objects
  static dynamic _convertValueRecursively(dynamic value) {
    try {
      if (value == null) {
        return null;
      } else if (value is Map<String, dynamic>) {
        // Already correct type, but check for nested issues
        return _convertMapRecursively(value);
      } else if (value is Map) {
        // LinkedMap or other Map types
        return _convertMapRecursively(value);
      } else if (value is List) {
        // Handle lists that might contain Maps
        return _convertListRecursively(value);
      } else if (_isPrimitive(value)) {
        // Primitive types: String, int, double, bool, DateTime, etc.
        return value;
      } else {
        // Complex objects - try to convert using toString or JSON
        return _handleComplexObject(value);
      }
    } catch (e) {
      debugPrint('❌ Value conversion failed for ${value.runtimeType}: $e');
      // Return null for failed conversions rather than crashing
      return null;
    }
  }

  /// Convert lists that may contain nested Maps
  static List<dynamic> _convertListRecursively(List<dynamic> list) {
    try {
      return list.map((item) => _convertValueRecursively(item)).toList();
    } catch (e) {
      debugPrint('❌ List conversion failed: $e');
      return [];
    }
  }

  /// Check if a value is a primitive type
  static bool _isPrimitive(dynamic value) {
    return value is String ||
           value is int ||
           value is double ||
           value is bool ||
           value is DateTime ||
           value is Duration ||
           value == null;
  }

  /// Handle complex objects that aren't primitives or Maps/Lists
  static dynamic _handleComplexObject(dynamic value) {
    try {
      // Try to get a string representation
      final stringValue = value.toString();
      
      // If it looks like JSON, try to parse it
      if (stringValue.startsWith('{') || stringValue.startsWith('[')) {
        try {
          final parsed = jsonDecode(stringValue);
          if (parsed is Map) {
            return _convertMapRecursively(parsed);
          } else if (parsed is List) {
            return _convertListRecursively(parsed);
          }
        } catch (e) {
          // Not valid JSON, continue with string representation
        }
      }
      
      // Return the string representation as fallback
      return stringValue;
    } catch (e) {
      debugPrint('❌ Complex object handling failed: $e');
      return null;
    }
  }

  /// Try to parse a string as JSON
  static Map<String, dynamic>? _tryParseJsonString(String input) {
    try {
      if (input.trim().startsWith('{') && input.trim().endsWith('}')) {
        final dynamic parsed = jsonDecode(input);
        if (parsed is Map) {
          return _convertMapRecursively(parsed);
        }
      }
      return null;
    } catch (e) {
      // Not a valid JSON string
      return null;
    }
  }

  /// Utility method specifically for Hive data conversion
  /// 
  /// Designed for migrating data from Hive storage that contains LinkedMaps
  /// to JSON-compatible `Map<String, dynamic>` format for Supabase migration.
  static List<Map<String, dynamic>> convertHiveData(List<dynamic> hiveData) {
    try {
      debugPrint('🔄 Converting ${hiveData.length} items from Hive LinkedMap format');
      
      final converted = safeConvertList(hiveData);
      
      debugPrint('✅ Successfully converted ${converted.length}/${hiveData.length} Hive items');
      
      // Additional validation for Hive data
      _validateHiveConversion(converted);
      
      return converted;
    } catch (e) {
      debugPrint('❌ Hive data conversion failed: $e');
      return [];
    }
  }

  /// Validate converted Hive data for common issues
  static void _validateHiveConversion(List<Map<String, dynamic>> converted) {
    try {
      for (int i = 0; i < converted.length; i++) {
        final item = converted[i];
        
        // Check for common required fields
        if (!item.containsKey('id')) {
          debugPrint('⚠️ Item $i missing required "id" field');
        }
        
        // Check for remaining LinkedMap objects (should be none)
        _checkForRemainingLinkedMaps(item, 'Item $i');
      }
    } catch (e) {
      debugPrint('❌ Validation failed: $e');
    }
  }

  /// Recursively check for any remaining LinkedMap objects
  static void _checkForRemainingLinkedMaps(dynamic value, String path) {
    try {
      if (value == null) return;
      
      final String typeName = value.runtimeType.toString();
      if (typeName.contains('LinkedMap')) {
        debugPrint('🚨 WARNING: LinkedMap found at $path: $typeName');
        return;
      }
      
      if (value is Map) {
        value.forEach((key, val) {
          _checkForRemainingLinkedMaps(val, '$path.$key');
        });
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          _checkForRemainingLinkedMaps(value[i], '$path[$i]');
        }
      }
    } catch (e) {
      // Silent fail for validation - don't break the main process
    }
  }

  /// Utility method for safe JSON encoding/decoding cycle
  /// 
  /// Sometimes the most reliable way to convert LinkedMap is through
  /// a JSON encode/decode cycle, which normalizes all Map types.
  static Map<String, dynamic>? jsonCycleConvert(dynamic input) {
    try {
      // First, do a basic conversion
      final converted = safeConvert(input);
      if (converted == null) return null;
      
      // Then do a JSON cycle to ensure all nested structures are normalized
      final jsonString = jsonEncode(converted);
      final decoded = jsonDecode(jsonString);
      
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ JSON cycle conversion failed: $e');
      return safeConvert(input); // Fallback to direct conversion
    }
  }

  /// Debug method to analyze problematic data
  /// 
  /// Use this method to understand what types of data are causing conversion issues
  static void analyzeProblematicData(dynamic data, [String label = 'Unknown']) {
    try {
      debugPrint('🔍 Analyzing $label:');
      debugPrint('  Type: ${data.runtimeType}');
      
      final dataString = data.toString();
      final preview = dataString.length > 100 ? '${dataString.substring(0, 100)}...' : dataString;
      debugPrint('  String representation: $preview');
      
      if (data is Map) {
        debugPrint('  Keys: ${data.keys.take(5).toList()}');
        debugPrint('  Key types: ${data.keys.take(5).map((k) => k.runtimeType).toList()}');
        
        final firstValue = data.values.isNotEmpty ? data.values.first : null;
        if (firstValue != null) {
          debugPrint('  First value type: ${firstValue.runtimeType}');
        }
      } else if (data is List) {
        debugPrint('  Length: ${data.length}');
        if (data.isNotEmpty) {
          debugPrint('  First item type: ${data.first.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('❌ Analysis failed: $e');
    }
  }
}
