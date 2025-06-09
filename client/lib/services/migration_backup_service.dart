import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'simple_error_handler.dart';

/// Task 1.3: Migration Backup System Implementation
/// 
/// Comprehensive backup and restore system to protect user data during migration
/// and provide rollback capability in case of failures.
class MigrationBackupService {
  static const String _logTag = '[MIGRATION_BACKUP]';
  static const String _backupPrefix = 'migration_backup_';
  static const int _maxBackups = 10;
  static const String _backupDirName = 'migration_backups';
  
  /// Create complete backup of all application data
  Future<BackupResult> createFullBackup({String? label}) async {
    debugPrint('$_logTag Creating comprehensive backup...');
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final backupId = '$_backupPrefix${label ?? 'auto'}_$timestamp';
    
    return await SimpleErrorHandler.safe(
      () async {
        final backup = ApplicationBackup();
        await _gatherAllData(backup);
        
        backup.metadata = BackupMetadata(
          id: backupId,
          timestamp: DateTime.now(),
          label: label ?? 'Automatic backup',
          version: await _getAppVersion(),
          dataTypes: backup.getDataTypes(),
          dataSize: backup.getDataSize(),
        );
        
        final success1 = await _storeBackupToPreferences(backup);
        final success2 = await _storeBackupToFile(backup);
        
        if (!success1 && !success2) {
          throw Exception('Failed to store backup in any location');
        }
        
        await _cleanOldBackups();
        debugPrint('$_logTag ✅ Backup created successfully');
        return BackupResult.success(backup.metadata!);
      },
      fallback: BackupResult.failure('Backup creation failed'),
      operationName: 'create_full_backup',
    );
  }
  
  /// Gather all application data from SharedPreferences
  Future<void> _gatherAllData(ApplicationBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    
    final flashcardSets = prefs.getStringList('flashcard_sets');
    if (flashcardSets != null && flashcardSets.isNotEmpty) {
      backup.flashcardSets = flashcardSets;
    }
    
    final interviewQuestions = prefs.getString('interview_questions');
    if (interviewQuestions != null && interviewQuestions.isNotEmpty) {
      backup.interviewQuestions = interviewQuestions;
    }
    
    backup.userPreferences = await _gatherUserPreferences(prefs);
    backup.cacheData = await _gatherCacheData(prefs);
    backup.progressData = await _gatherProgressData(prefs);
    backup.miscData = await _gatherMiscData(prefs);
    
    final recentViews = prefs.getString('recently_viewed_items');
    if (recentViews != null && recentViews.isNotEmpty) {
      backup.recentViews = recentViews;
    }
  }
  
  /// Gather user preferences
  Future<Map<String, dynamic>> _gatherUserPreferences(SharedPreferences prefs) async {
    final preferences = <String, dynamic>{};
    final allKeys = prefs.getKeys();
    final preferenceKeys = allKeys.where((key) => 
      !key.startsWith('flutter.') && 
      !key.contains('flashcard_sets') &&
      !key.contains('interview_questions') &&
      !key.contains('recently_viewed_items') &&
      !key.startsWith(_backupPrefix) &&
      !key.startsWith('repair_backup_') &&
      !key.startsWith('user_') &&
      !key.startsWith('question_') &&
      !key.startsWith('completion_') &&
      !key.startsWith('activity_')
    );
    
    for (final key in preferenceKeys) {
      final value = prefs.get(key);
      if (value != null) {
        preferences[key] = value;
      }
    }
    return preferences;
  }
  
  /// Gather cache data
  Future<Map<String, dynamic>> _gatherCacheData(SharedPreferences prefs) async {
    final cacheData = <String, dynamic>{};
    final allKeys = prefs.getKeys();
    final cacheKeys = allKeys.where((key) => 
      key.startsWith('question_') ||
      key.startsWith('cache_') ||
      key.startsWith('temp_')
    );
    
    for (final key in cacheKeys) {
      final value = prefs.get(key);
      if (value != null) {
        cacheData[key] = value;
      }
    }
    return cacheData;
  }
  
  /// Gather progress data
  Future<Map<String, dynamic>> _gatherProgressData(SharedPreferences prefs) async {
    final progressData = <String, dynamic>{};
    final allKeys = prefs.getKeys();
    final progressKeys = allKeys.where((key) => 
      key.startsWith('user_') ||
      key.startsWith('completion_') ||
      key.startsWith('activity_')
    );
    
    for (final key in progressKeys) {
      final value = prefs.get(key);
      if (value != null) {
        progressData[key] = value;
      }
    }
    return progressData;
  }
  
  /// Gather miscellaneous data
  Future<Map<String, dynamic>> _gatherMiscData(SharedPreferences prefs) async {
    final miscData = <String, dynamic>{};
    final allKeys = prefs.getKeys();
    final miscKeys = allKeys.where((key) => 
      !key.startsWith('flutter.') &&
      !key.contains('flashcard_sets') &&
      !key.contains('interview_questions') &&
      !key.contains('recently_viewed_items') &&
      !key.startsWith(_backupPrefix) &&
      !key.startsWith('repair_backup_') &&
      !key.startsWith('user_') &&
      !key.startsWith('question_') &&
      !key.startsWith('completion_') &&
      !key.startsWith('activity_') &&
      !key.startsWith('cache_') &&
      !key.startsWith('temp_')
    );
    
    for (final key in miscKeys) {
      final value = prefs.get(key);
      if (value != null) {
        miscData[key] = value;
      }
    }
    return miscData;
  }
  
  Future<bool> _storeBackupToPreferences(ApplicationBackup backup) async {
    return await SimpleErrorHandler.safe(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final backupJson = jsonEncode(backup.toJson());
        await prefs.setString(backup.metadata!.id, backupJson);
        return true;
      },
      fallback: false,
      operationName: 'store_backup_to_preferences',
    );
  }
  
  Future<bool> _storeBackupToFile(ApplicationBackup backup) async {
    return await SimpleErrorHandler.safe(
      () async {
        final directory = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${directory.path}/$_backupDirName');
        
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        
        final backupFile = File('${backupDir.path}/${backup.metadata!.id}.json');
        final backupJson = jsonEncode(backup.toJson());
        await backupFile.writeAsString(backupJson);
        return true;
      },
      fallback: false,
      operationName: 'store_backup_to_file',
    );
  }
  
  Future<String> _getAppVersion() async {
    return await SimpleErrorHandler.safe(
      () async {
        final packageInfo = await PackageInfo.fromPlatform();
        return '${packageInfo.version}+${packageInfo.buildNumber}';
      },
      fallback: 'unknown',
      operationName: 'get_app_version',
    );
  }
  
  Future<void> _cleanOldBackups() async {
    await SimpleErrorHandler.safely(
      () async {
        final backups = await listBackups();
        if (backups.length <= _maxBackups) return;
        
        backups.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final backupsToDelete = backups.take(backups.length - _maxBackups);
        
        for (final backup in backupsToDelete) {
          await deleteBackup(backup.id);
        }
      },
      operationName: 'clean_old_backups',
    );
  }
  
  Future<RestoreResult> restoreFromBackup(String backupId) async {
    return await SimpleErrorHandler.safe(
      () async {
        final backup = await _loadBackup(backupId);
        if (backup == null) {
          return RestoreResult.failure('Backup not found: $backupId');
        }
        
        final safetyResult = await createFullBackup(label: 'pre_restore_safety');
        if (!safetyResult.isSuccess) {
          debugPrint('$_logTag Warning: Could not create safety backup');
        }
        
        final validationResult = await validateBackup(backupId);
        if (!validationResult.isValid) {
          return RestoreResult.failure('Backup validation failed: ${validationResult.error}');
        }
        
        await _restoreData(backup);
        return RestoreResult.success('Successfully restored from $backupId');
      },
      fallback: RestoreResult.failure('Restore operation failed'),
      operationName: 'restore_from_backup',
    );
  }
  
  Future<ApplicationBackup?> _loadBackup(String backupId) async {
    return await SimpleErrorHandler.safe(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final backupJson = prefs.getString(backupId);
        
        if (backupJson != null) {
          return ApplicationBackup.fromJson(jsonDecode(backupJson));
        }
        
        return await _loadBackupFromFile(backupId);
      },
      fallback: null,
      operationName: 'load_backup',
    );
  }
  
  Future<ApplicationBackup?> _loadBackupFromFile(String backupId) async {
    return await SimpleErrorHandler.safe(
      () async {
        final directory = await getApplicationDocumentsDirectory();
        final backupFile = File('${directory.path}/$_backupDirName/$backupId.json');
        
        if (await backupFile.exists()) {
          final backupJson = await backupFile.readAsString();
          return ApplicationBackup.fromJson(jsonDecode(backupJson));
        }
        return null;
      },
      fallback: null,
      operationName: 'load_backup_from_file',
    );
  }
  
  Future<void> _restoreData(ApplicationBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    await _clearApplicationData(prefs);
    
    if (backup.flashcardSets != null && backup.flashcardSets!.isNotEmpty) {
      await prefs.setStringList('flashcard_sets', backup.flashcardSets!);
    }
    
    if (backup.interviewQuestions != null && backup.interviewQuestions!.isNotEmpty) {
      await prefs.setString('interview_questions', backup.interviewQuestions!);
    }
    
    if (backup.userPreferences != null && backup.userPreferences!.isNotEmpty) {
      for (final entry in backup.userPreferences!.entries) {
        await _setPreferenceValue(prefs, entry.key, entry.value);
      }
    }
    
    if (backup.recentViews != null && backup.recentViews!.isNotEmpty) {
      await prefs.setString('recently_viewed_items', backup.recentViews!);
    }
    
    if (backup.progressData != null && backup.progressData!.isNotEmpty) {
      for (final entry in backup.progressData!.entries) {
        await _setPreferenceValue(prefs, entry.key, entry.value);
      }
    }
    
    if (backup.cacheData != null && backup.cacheData!.isNotEmpty) {
      for (final entry in backup.cacheData!.entries) {
        await _setPreferenceValue(prefs, entry.key, entry.value);
      }
    }
    
    if (backup.miscData != null && backup.miscData!.isNotEmpty) {
      for (final entry in backup.miscData!.entries) {
        await _setPreferenceValue(prefs, entry.key, entry.value);
      }
    }
  }
  
  Future<void> _clearApplicationData(SharedPreferences prefs) async {
    final allKeys = prefs.getKeys().toList();
    
    for (final key in allKeys) {
      if (!key.startsWith(_backupPrefix) && 
          !key.startsWith('repair_backup_') &&
          !key.startsWith('flutter.')) {
        await prefs.remove(key);
      }
    }
  }
  
  Future<void> _setPreferenceValue(SharedPreferences prefs, String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      await prefs.setString(key, value.toString());
    }
  }
  
  Future<List<BackupMetadata>> listBackups() async {
    final backups = <BackupMetadata>[];
    await _addBackupsFromPreferences(backups);
    await _addBackupsFromFiles(backups);
    
    final uniqueBackups = <String, BackupMetadata>{};
    for (final backup in backups) {
      uniqueBackups[backup.id] = backup;
    }
    
    final sortedBackups = uniqueBackups.values.toList();
    sortedBackups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedBackups;
  }
  
  Future<void> _addBackupsFromPreferences(List<BackupMetadata> backups) async {
    await SimpleErrorHandler.safely(
      () async {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        final backupKeys = allKeys.where((key) => key.startsWith(_backupPrefix));
        
        for (final key in backupKeys) {
          await SimpleErrorHandler.safely(
            () async {
              final backupJson = prefs.getString(key);
              if (backupJson != null) {
                final backup = ApplicationBackup.fromJson(jsonDecode(backupJson));
                if (backup.metadata != null) {
                  backups.add(backup.metadata!);
                }
              }
            },
            operationName: 'add_backup_from_preferences_$key',
          );
        }
      },
      operationName: 'add_backups_from_preferences',
    );
  }
  
  Future<void> _addBackupsFromFiles(List<BackupMetadata> backups) async {
    await SimpleErrorHandler.safely(
      () async {
        final directory = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${directory.path}/$_backupDirName');
        
        if (await backupDir.exists()) {
          final files = await backupDir.list().toList();
          
          for (final file in files) {
            if (file is File && file.path.endsWith('.json')) {
              await SimpleErrorHandler.safely(
                () async {
                  final backupJson = await file.readAsString();
                  final backup = ApplicationBackup.fromJson(jsonDecode(backupJson));
                  if (backup.metadata != null) {
                    backups.add(backup.metadata!);
                  }
                },
                operationName: 'add_backup_from_file_${file.path}',
              );
            }
          }
        }
      },
      operationName: 'add_backups_from_files',
    );
  }
  
  Future<BackupValidationResult> validateBackup(String backupId) async {
    return await SimpleErrorHandler.safe(
      () async {
        final backup = await _loadBackup(backupId);
        if (backup == null) {
          return BackupValidationResult.invalid('Backup not found: $backupId');
        }
        
        final issues = <String>[];
        
        if (backup.metadata == null) {
          issues.add('Missing backup metadata');
        }
        
        if (backup.flashcardSets != null) {
          for (int i = 0; i < backup.flashcardSets!.length; i++) {
            await SimpleErrorHandler.safely(
              () async {
                final setData = jsonDecode(backup.flashcardSets![i]);
                if (setData is! Map) {
                  issues.add('Invalid flashcard set structure at index $i');
                }
              },
              operationName: 'validate_flashcard_set_$i',
            );
          }
        }
        
        if (backup.interviewQuestions != null) {
          await SimpleErrorHandler.safely(
            () async {
              final questions = jsonDecode(backup.interviewQuestions!);
              if (questions is! List) {
                issues.add('Interview questions is not a valid array');
              }
            },
            operationName: 'validate_interview_questions',
          );
        }
        
        return issues.isEmpty 
          ? BackupValidationResult.valid()
          : BackupValidationResult.invalid('Validation issues: ${issues.join(', ')}');
      },
      fallback: BackupValidationResult.invalid('Validation operation failed'),
      operationName: 'validate_backup',
    );
  }
  
  Future<bool> deleteBackup(String backupId) async {
    return await SimpleErrorHandler.safe(
      () async {
        bool deletedFromPrefs = false;
        bool deletedFromFiles = false;
        
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey(backupId)) {
          await prefs.remove(backupId);
          deletedFromPrefs = true;
        }
        
        final directory = await getApplicationDocumentsDirectory();
        final backupFile = File('${directory.path}/$_backupDirName/$backupId.json');
        if (await backupFile.exists()) {
          await backupFile.delete();
          deletedFromFiles = true;
        }
        
        return deletedFromPrefs || deletedFromFiles;
      },
      fallback: false,
      operationName: 'delete_backup',
    );
  }
}

class ApplicationBackup {
  BackupMetadata? metadata;
  List<String>? flashcardSets;
  String? interviewQuestions;
  Map<String, dynamic>? userPreferences;
  Map<String, dynamic>? cacheData;
  String? recentViews;
  Map<String, dynamic>? progressData;
  Map<String, dynamic>? miscData;
  
  // Default constructor
  ApplicationBackup();
  
  List<String> getDataTypes() {
    final types = <String>[];
    if (flashcardSets != null && flashcardSets!.isNotEmpty) types.add('flashcard_sets');
    if (interviewQuestions != null && interviewQuestions!.isNotEmpty) types.add('interview_questions');
    if (userPreferences != null && userPreferences!.isNotEmpty) types.add('user_preferences');
    if (cacheData != null && cacheData!.isNotEmpty) types.add('cache_data');
    if (recentViews != null && recentViews!.isNotEmpty) types.add('recent_views');
    if (progressData != null && progressData!.isNotEmpty) types.add('progress_data');
    if (miscData != null && miscData!.isNotEmpty) types.add('misc_data');
    return types;
  }
  
  int getDataSize() {
    int size = 0;
    if (flashcardSets != null) size += flashcardSets!.join('').length;
    if (interviewQuestions != null) size += interviewQuestions!.length;
    if (userPreferences != null) size += jsonEncode(userPreferences!).length;
    if (cacheData != null) size += jsonEncode(cacheData!).length;
    if (recentViews != null) size += recentViews!.length;
    if (progressData != null) size += jsonEncode(progressData!).length;
    if (miscData != null) size += jsonEncode(miscData!).length;
    return size;
  }
  
  Map<String, dynamic> toJson() => {
    'metadata': metadata?.toJson(),
    'flashcard_sets': flashcardSets,
    'interview_questions': interviewQuestions,
    'user_preferences': userPreferences,
    'cache_data': cacheData,
    'recent_views': recentViews,
    'progress_data': progressData,
    'misc_data': miscData,
  };
  
  factory ApplicationBackup.fromJson(Map<String, dynamic> json) {
    final backup = ApplicationBackup();
    if (json['metadata'] != null) {
      backup.metadata = BackupMetadata.fromJson(json['metadata']);
    }
    backup.flashcardSets = json['flashcard_sets']?.cast<String>();
    backup.interviewQuestions = json['interview_questions'];
    backup.userPreferences = json['user_preferences']?.cast<String, dynamic>();
    backup.cacheData = json['cache_data']?.cast<String, dynamic>();
    backup.recentViews = json['recent_views'];
    backup.progressData = json['progress_data']?.cast<String, dynamic>();
    backup.miscData = json['misc_data']?.cast<String, dynamic>();
    return backup;
  }
}

class BackupMetadata {
  final String id;
  final DateTime timestamp;
  final String label;
  final String version;
  final List<String> dataTypes;
  final int dataSize;
  
  BackupMetadata({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.version,
    required this.dataTypes,
    required this.dataSize,
  });
  
  String get formattedSize {
    if (dataSize < 1024) return '${dataSize}B';
    if (dataSize < 1024 * 1024) return '${(dataSize / 1024).toStringAsFixed(1)}KB';
    return '${(dataSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  String get formattedTimestamp {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
           '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'label': label,
    'version': version,
    'data_types': dataTypes,
    'data_size': dataSize,
  };
  
  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    label: json['label'],
    version: json['version'],
    dataTypes: json['data_types']?.cast<String>() ?? [],
    dataSize: json['data_size'] ?? 0,
  );
}

class BackupResult {
  final bool isSuccess;
  final String? error;
  final StackTrace? stackTrace;
  final BackupMetadata? metadata;
  
  BackupResult._({
    required this.isSuccess,
    this.error,
    this.stackTrace,
    this.metadata,
  });
  
  factory BackupResult.success(BackupMetadata metadata) => BackupResult._(
    isSuccess: true,
    metadata: metadata,
  );
  
  factory BackupResult.failure(String error, [StackTrace? stackTrace]) => BackupResult._(
    isSuccess: false,
    error: error,
    stackTrace: stackTrace,
  );
}

class RestoreResult {
  final bool isSuccess;
  final String message;
  final String? error;
  final StackTrace? stackTrace;
  
  RestoreResult._({
    required this.isSuccess,
    required this.message,
    this.error,
    this.stackTrace,
  });
  
  factory RestoreResult.success(String message) => RestoreResult._(
    isSuccess: true,
    message: message,
  );
  
  factory RestoreResult.failure(String error, [StackTrace? stackTrace]) => RestoreResult._(
    isSuccess: false,
    message: 'Restore failed',
    error: error,
    stackTrace: stackTrace,
  );
}

class BackupValidationResult {
  final bool isValid;
  final String? error;
  
  BackupValidationResult._({
    required this.isValid,
    this.error,
  });
  
  factory BackupValidationResult.valid() => BackupValidationResult._(isValid: true);
  
  factory BackupValidationResult.invalid(String error) => BackupValidationResult._(
    isValid: false,
    error: error,
  );
}