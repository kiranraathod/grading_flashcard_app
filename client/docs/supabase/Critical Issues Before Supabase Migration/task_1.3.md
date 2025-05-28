# Task 1.3: Migration Backup System Implementation

## Priority Level
🚨 **CRITICAL BLOCKER** - Must be completed before any data modification

## Overview
Implement comprehensive backup and restore system to protect user data during migration process and provide rollback capability in case of failures.

## Background
Current application has NO backup mechanism. SharedPreferences is single point of failure. Migration process requires multiple data transformations that could corrupt or lose user data permanently.

**Risk Without Backup:**
- Permanent data loss if migration fails  
- No recovery mechanism for corrupted repairs
- No way to test migration safely
- Cannot rollback failed migration attempts

## Implementation Steps

### Step 1: Create Backup Service
Create `lib/services/migration_backup_service.dart`:

```dart
class MigrationBackupService {
  static const String _backupPrefix = 'migration_backup_';
  static const int _maxBackups = 5; // Keep last 5 backups
  
  /// Create complete backup of all application data
  Future<BackupResult> createFullBackup({String? label}) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupId = '${_backupPrefix}${label ?? 'auto'}_$timestamp';
    
    try {
      final backup = await _gatherAllData();
      backup.metadata = BackupMetadata(
        id: backupId,
        timestamp: DateTime.now(),
        label: label ?? 'Automatic backup',
        version: await _getAppVersion(),
        dataTypes: backup.getDataTypes(),
      );
      
      // Store backup in multiple locations for safety
      await _storeBackup(backup);
      await _storeBackupToFile(backup); // Additional file backup
      
      // Clean old backups
      await _cleanOldBackups();
      
      return BackupResult.success(backup.metadata!);
      
    } catch (e, stackTrace) {
      return BackupResult.failure('Backup creation failed: $e', stackTrace);
    }
  }
  
  Future<ApplicationBackup> _gatherAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = ApplicationBackup();
    
    // Backup flashcard sets
    final flashcardSets = prefs.getStringList('flashcard_sets');
    if (flashcardSets != null) {
      backup.flashcardSets = flashcardSets;
    }
    
    // Backup interview questions
    final interviewQuestions = prefs.getString('interview_questions');
    if (interviewQuestions != null) {
      backup.interviewQuestions = interviewQuestions;
    }
    
    // Backup user preferences
    backup.userPreferences = await _gatherUserPreferences(prefs);
    
    // Backup cache data
    backup.cacheData = await _gatherCacheData(prefs);
    
    // Backup recent view data
    final recentViews = prefs.getString('recent_views');
    if (recentViews != null) {
      backup.recentViews = recentViews;
    }
    
    // Backup any other application-specific data
    backup.miscData = await _gatherMiscData(prefs);
    
    return backup;
  }
  
  Future<Map<String, dynamic>> _gatherUserPreferences(SharedPreferences prefs) async {
    final preferences = <String, dynamic>{};
    
    // Gather all preference keys that aren't data storage
    final allKeys = prefs.getKeys();
    final preferenceKeys = allKeys.where((key) => 
      !key.startsWith('flutter.') && 
      !key.contains('flashcard_sets') &&
      !key.contains('interview_questions') &&
      !key.contains('recent_views') &&
      !key.startsWith(_backupPrefix)
    );
    
    for (final key in preferenceKeys) {
      final value = prefs.get(key);
      if (value != null) {
        preferences[key] = value;
      }
    }
    
    return preferences;
  }
  
  Future<void> _storeBackup(ApplicationBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    final backupJson = jsonEncode(backup.toJson());
    
    await prefs.setString(backup.metadata!.id, backupJson);
  }
  
  Future<void> _storeBackupToFile(ApplicationBackup backup) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/migration_backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      final backupFile = File('${backupDir.path}/${backup.metadata!.id}.json');
      final backupJson = jsonEncode(backup.toJson());
      
      await backupFile.writeAsString(backupJson);
      
    } catch (e) {
      // File backup is secondary - don't fail if this doesn't work
      print('Warning: Could not create file backup: $e');
    }
  }
  
  /// Restore data from backup
  Future<RestoreResult> restoreFromBackup(String backupId) async {
    try {
      final backup = await _loadBackup(backupId);
      if (backup == null) {
        return RestoreResult.failure('Backup not found: $backupId');
      }
      
      // Create safety backup before restore
      await createFullBackup(label: 'pre_restore_safety');
      
      // Restore data
      await _restoreData(backup);
      
      return RestoreResult.success('Successfully restored from $backupId');
      
    } catch (e, stackTrace) {
      return RestoreResult.failure('Restore failed: $e', stackTrace);
    }
  }
  
  Future<ApplicationBackup?> _loadBackup(String backupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString(backupId);
      
      if (backupJson != null) {
        return ApplicationBackup.fromJson(jsonDecode(backupJson));
      }
      
      // Try loading from file backup
      return await _loadBackupFromFile(backupId);
      
    } catch (e) {
      print('Error loading backup $backupId: $e');
      return null;
    }
  }
  
  Future<void> _restoreData(ApplicationBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear existing data first
    await _clearApplicationData(prefs);
    
    // Restore flashcard sets
    if (backup.flashcardSets != null) {
      await prefs.setStringList('flashcard_sets', backup.flashcardSets!);
    }
    
    // Restore interview questions
    if (backup.interviewQuestions != null) {
      await prefs.setString('interview_questions', backup.interviewQuestions!);
    }
    
    // Restore user preferences
    if (backup.userPreferences != null) {
      for (final entry in backup.userPreferences!.entries) {
        await _setPreferenceValue(prefs, entry.key, entry.value);
      }
    }
    
    // Restore recent views
    if (backup.recentViews != null) {
      await prefs.setString('recent_views', backup.recentViews!);
    }
    
    // Restore misc data
    if (backup.miscData != null) {
      for (final entry in backup.miscData!.entries) {
        await _setPreferenceValue(prefs, entry.key, entry.value);
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
    }
  }
  
  /// List all available backups
  Future<List<BackupMetadata>> listBackups() async {
    final prefs = await SharedPreferences.getInstance();
    final backups = <BackupMetadata>[];
    
    final allKeys = prefs.getKeys();
    final backupKeys = allKeys.where((key) => key.startsWith(_backupPrefix));
    
    for (final key in backupKeys) {
      try {
        final backupJson = prefs.getString(key);
        if (backupJson != null) {
          final backup = ApplicationBackup.fromJson(jsonDecode(backupJson));
          if (backup.metadata != null) {
            backups.add(backup.metadata!);
          }
        }
      } catch (e) {
        // Skip corrupted backup
        continue;
      }
    }
    
    // Sort by timestamp (newest first)
    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return backups;
  }
  
  /// Validate backup integrity
  Future<BackupValidationResult> validateBackup(String backupId) async {
    try {
      final backup = await _loadBackup(backupId);
      if (backup == null) {
        return BackupValidationResult.invalid('Backup not found');
      }
      
      final issues = <String>[];
      
      // Validate flashcard sets
      if (backup.flashcardSets != null) {
        for (int i = 0; i < backup.flashcardSets!.length; i++) {
          try {
            jsonDecode(backup.flashcardSets![i]);
          } catch (e) {
            issues.add('Invalid JSON in flashcard set $i');
          }
        }
      }
      
      // Validate interview questions
      if (backup.interviewQuestions != null) {
        try {
          final questions = jsonDecode(backup.interviewQuestions!);
          if (questions is! List) {
            issues.add('Interview questions is not a valid array');
          }
        } catch (e) {
          issues.add('Invalid JSON in interview questions');
        }
      }
      
      return issues.isEmpty 
        ? BackupValidationResult.valid()
        : BackupValidationResult.invalid('Validation issues: ${issues.join(', ')}');
        
    } catch (e) {
      return BackupValidationResult.invalid('Validation failed: $e');
    }
  }
}

class ApplicationBackup {
  BackupMetadata? metadata;
  List<String>? flashcardSets;
  String? interviewQuestions;
  Map<String, dynamic>? userPreferences;
  Map<String, dynamic>? cacheData;
  String? recentViews;
  Map<String, dynamic>? miscData;
  
  List<String> getDataTypes() {
    final types = <String>[];
    if (flashcardSets != null) types.add('flashcard_sets');
    if (interviewQuestions != null) types.add('interview_questions');
    if (userPreferences != null) types.add('user_preferences');
    if (cacheData != null) types.add('cache_data');
    if (recentViews != null) types.add('recent_views');
    if (miscData != null) types.add('misc_data');
    return types;
  }
  
  Map<String, dynamic> toJson() => {
    'metadata': metadata?.toJson(),
    'flashcard_sets': flashcardSets,
    'interview_questions': interviewQuestions,
    'user_preferences': userPreferences,
    'cache_data': cacheData,
    'recent_views': recentViews,
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
  
  BackupMetadata({
    required this.id,
    required this.timestamp,
    required this.label,
    required this.version,
    required this.dataTypes,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'label': label,
    'version': version,
    'data_types': dataTypes,
  };
  
  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    label: json['label'],
    version: json['version'],
    dataTypes: json['data_types']?.cast<String>() ?? [],
  );
}
```

### Step 2: Add Backup UI to Data Validation Screen
Update `DataValidationScreen` to include backup/restore functionality:

```dart
// Add backup buttons to app bar
AppBar(
  title: Text('Data Validation & Backup'),
  actions: [
    IconButton(
      icon: Icon(Icons.backup),
      onPressed: _createBackup,
      tooltip: 'Create Backup',
    ),
    IconButton(
      icon: Icon(Icons.restore),
      onPressed: _showRestoreDialog,
      tooltip: 'Restore from Backup',
    ),
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: _runValidation,
    ),
  ],
),

// Add backup methods
Future<void> _createBackup() async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _BackupLabelDialog(),
  );
  
  if (result != null) {
    try {
      final backupService = MigrationBackupService();
      final backupResult = await backupService.createFullBackup(label: result);
      
      if (backupResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${backupResult.error}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup error: $e')),
      );
    }
  }
}
```

## Acceptance Criteria

- [ ] Complete backup of all SharedPreferences data
- [ ] Multiple backup storage locations (SharedPreferences + file system)
- [ ] Backup validation and integrity checking
- [ ] Restore functionality with safety backups
- [ ] Automatic cleanup of old backups
- [ ] Backup listing and management UI
- [ ] Error handling and rollback capabilities
- [ ] Backup metadata tracking (timestamp, version, data types)

## Testing Instructions

1. **Create backup:**
   ```dart
   final backupService = MigrationBackupService();
   final result = await backupService.createFullBackup(label: 'test');
   ```

2. **Test restore:**
   - Create backup
   - Modify some data
   - Restore from backup
   - Verify data is restored correctly

3. **Test backup validation:**
   - Create backup
   - Corrupt backup data
   - Run validation
   - Verify corruption is detected

## Next Steps
After completing this task:
- All data modification tasks can proceed safely
- Begin Task 1.2 (Data Repair) with backup protection
- Implement migration process with rollback capability

## Dependencies
- `path_provider` package for file system access
- `shared_preferences` package
- JSON encoding/decoding capabilities