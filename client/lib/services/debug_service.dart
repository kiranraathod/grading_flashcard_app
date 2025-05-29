import 'package:flutter/foundation.dart';
import 'data_validation_service.dart';
import 'data_repair_service.dart';
import 'migration_backup_service.dart';

class DebugService {
  static const String _logTag = '[DEBUG_SERVICE]';
  
  /// Run comprehensive data validation and output results to console
  static Future<void> runDataValidation() async {
    debugPrint('$_logTag ===== STARTING DATA VALIDATION =====');
    debugPrint('$_logTag Timestamp: ${DateTime.now().toIso8601String()}');
    
    try {
      final validationService = DataValidationService();
      final report = await validationService.validateAllStoredData();
      
      // Print comprehensive report to console
      report.printReport();
      
      // Additional debug output
      debugPrint('$_logTag ===== VALIDATION COMPLETE =====');
      
      if (report.hasBlockingIssues) {
        debugPrint('$_logTag 🚨 MIGRATION BLOCKED - Critical issues found');
        debugPrint('$_logTag Next steps: Implement Task 1.2 (Data Repair) and Task 1.3 (Backup System)');
      } else {
        debugPrint('$_logTag ✅ VALIDATION PASSED - Ready for migration');
        debugPrint('$_logTag Next steps: Proceed with Supabase migration');
      }
      
      return;
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ VALIDATION FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
      debugPrint('$_logTag This indicates a critical system issue that must be resolved');
    }
  }
  
  /// Quick validation check - returns true if ready for migration
  static Future<bool> isReadyForMigration() async {
    try {
      final validationService = DataValidationService();
      final report = await validationService.validateAllStoredData();
      
      final isReady = !report.hasBlockingIssues;
      debugPrint('$_logTag Migration readiness check: ${isReady ? 'READY' : 'BLOCKED'}');
      
      return isReady;
    } catch (e) {
      debugPrint('$_logTag Migration readiness check failed: $e');
      return false;
    }
  }
  
  /// Get validation summary for quick status check
  static Future<String> getValidationSummary() async {
    try {
      final validationService = DataValidationService();
      final report = await validationService.validateAllStoredData();
      
      return 'Status: ${report.migrationStatus}, '
             'Issues: ${report.totalIssues} '
             '(${report.criticalErrors.length} critical, '
             '${report.errors.length} errors, '
             '${report.warnings.length} warnings)';
    } catch (e) {
      return 'Validation failed: $e';
    }
  }
  
  /// Run validation with detailed console output (for debugging)
  static Future<void> runDetailedValidation() async {
    debugPrint('$_logTag ===== DETAILED VALIDATION ANALYSIS =====');
    
    try {
      final validationService = DataValidationService();
      final report = await validationService.validateAllStoredData();
      
      // Print JSON report for technical analysis
      debugPrint('$_logTag JSON Report:');
      debugPrint(report.toJson().toString());
      
      // Print issue breakdown
      debugPrint('$_logTag Issue Breakdown:');
      
      if (report.criticalErrors.isNotEmpty) {
        debugPrint('$_logTag Critical Errors:');
        for (final issue in report.criticalErrors) {
          debugPrint('$_logTag   - ${issue.location}: ${issue.message}');
        }
      }
      
      if (report.errors.isNotEmpty) {
        debugPrint('$_logTag Errors:');
        for (final issue in report.errors) {
          debugPrint('$_logTag   - ${issue.location}: ${issue.message}');
        }
      }
      
      if (report.warnings.isNotEmpty) {
        debugPrint('$_logTag Warnings:');
        for (final issue in report.warnings) {
          debugPrint('$_logTag   - ${issue.location}: ${issue.message}');
        }
      }
      
      if (report.suggestions.isNotEmpty) {
        debugPrint('$_logTag Suggestions:');
        for (final issue in report.suggestions) {
          debugPrint('$_logTag   - ${issue.location}: ${issue.message}');
        }
      }
      
      debugPrint('$_logTag ===== END DETAILED VALIDATION =====');
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag Detailed validation failed: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
  
  /// Task 1.2: Run automated data repair
  static Future<void> runDataRepair() async {
    debugPrint('$_logTag ===== STARTING DATA REPAIR =====');
    debugPrint('$_logTag Timestamp: ${DateTime.now().toIso8601String()}');
    
    try {
      final repairService = DataRepairService();
      final result = await repairService.repairAllData();
      
      // Print comprehensive report to console
      result.printSummary();
      
      debugPrint('$_logTag ===== REPAIR COMPLETE =====');
      
      if (result.wasSuccessful) {
        debugPrint('$_logTag ✅ Data repair completed successfully');
        debugPrint('$_logTag 🚀 Ready to proceed with Supabase migration'); 
        debugPrint('$_logTag Total repairs applied: ${result.totalChanges}');
      } else {
        debugPrint('$_logTag ❌ Data repair encountered issues');
        debugPrint('$_logTag ⛔ Review errors before proceeding');
        debugPrint('$_logTag Errors encountered: ${result.errors.length}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ REPAIR FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
      debugPrint('$_logTag This indicates a critical system issue that must be resolved');
    }
  }
  
  /// Check if repairs are needed
  static Future<bool> repairNeeded() async {
    try {
      final repairService = DataRepairService();
      final needed = await repairService.repairNeeded();
      
      debugPrint('$_logTag Repair needed check: ${needed ? 'YES' : 'NO'}');
      return needed;
    } catch (e) {
      debugPrint('$_logTag Repair check failed: $e');
      return false;
    }
  }
  
  /// Complete validation and repair workflow
  static Future<void> runValidationAndRepair() async {
    debugPrint('$_logTag ===== COMPLETE VALIDATION & REPAIR WORKFLOW =====');
    
    try {
      // Step 1: Run validation
      debugPrint('$_logTag Step 1: Running initial validation...');
      await runDataValidation();
      
      // Step 2: Check if repairs are needed
      debugPrint('$_logTag Step 2: Checking if repairs are needed...');
      final needed = await repairNeeded();
      
      if (!needed) {
        debugPrint('$_logTag ✅ No repairs needed - data is migration-ready');
        return;
      }
      
      // Step 3: Run repairs
      debugPrint('$_logTag Step 3: Running automated repairs...');
      await runDataRepair();
      
      // Step 4: Final validation
      debugPrint('$_logTag Step 4: Running final validation...');
      await runDataValidation();
      
      debugPrint('$_logTag ===== WORKFLOW COMPLETE =====');
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ WORKFLOW FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
  
  /// Task 1.3: Create comprehensive backup
  static Future<void> createBackup({String? label}) async {
    debugPrint('$_logTag ===== CREATING BACKUP =====');
    debugPrint('$_logTag Timestamp: ${DateTime.now().toIso8601String()}');
    
    try {
      final backupService = MigrationBackupService();
      final result = await backupService.createFullBackup(label: label ?? 'console_backup');
      
      if (result.isSuccess) {
        debugPrint('$_logTag ✅ Backup created successfully');
        debugPrint('$_logTag Backup ID: ${result.metadata!.id}');
        debugPrint('$_logTag Data types: ${result.metadata!.dataTypes.join(', ')}');
        debugPrint('$_logTag Size: ${result.metadata!.formattedSize}');
        debugPrint('$_logTag Label: ${result.metadata!.label}');
      } else {
        debugPrint('$_logTag ❌ Backup creation failed: ${result.error}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ BACKUP FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
  
  /// Task 1.3: List all available backups
  static Future<void> listBackups() async {
    debugPrint('$_logTag ===== LISTING BACKUPS =====');
    
    try {
      final backupService = MigrationBackupService();
      final backups = await backupService.listBackups();
      
      if (backups.isEmpty) {
        debugPrint('$_logTag No backups found');
        return;
      }
      
      debugPrint('$_logTag Found ${backups.length} backup(s):');
      for (int i = 0; i < backups.length; i++) {
        final backup = backups[i];
        debugPrint('$_logTag [$i] ${backup.label} (${backup.formattedTimestamp})');
        debugPrint('$_logTag     ID: ${backup.id}');
        debugPrint('$_logTag     Size: ${backup.formattedSize}');
        debugPrint('$_logTag     Types: ${backup.dataTypes.join(', ')}');
        debugPrint('$_logTag     Version: ${backup.version}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ LIST BACKUPS FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
  
  /// Task 1.3: Validate backup integrity
  static Future<void> validateBackup(String backupId) async {
    debugPrint('$_logTag ===== VALIDATING BACKUP =====');
    debugPrint('$_logTag Backup ID: $backupId');
    
    try {
      final backupService = MigrationBackupService();
      final result = await backupService.validateBackup(backupId);
      
      if (result.isValid) {
        debugPrint('$_logTag ✅ Backup validation passed');
        debugPrint('$_logTag Backup is valid and ready for restore');
      } else {
        debugPrint('$_logTag ❌ Backup validation failed: ${result.error}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ BACKUP VALIDATION FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
  
  /// Task 1.3: Restore from backup
  static Future<void> restoreFromBackup(String backupId) async {
    debugPrint('$_logTag ===== RESTORING FROM BACKUP =====');
    debugPrint('$_logTag Backup ID: $backupId');
    debugPrint('$_logTag ⚠️  This will replace all current data!');
    
    try {
      final backupService = MigrationBackupService();
      final result = await backupService.restoreFromBackup(backupId);
      
      if (result.isSuccess) {
        debugPrint('$_logTag ✅ Restore completed successfully');
        debugPrint('$_logTag ${result.message}');
        debugPrint('$_logTag Recommendation: Run validation to verify data integrity');
      } else {
        debugPrint('$_logTag ❌ Restore failed: ${result.error}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ RESTORE FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
  
  /// Task 1.3: Complete backup workflow
  static Future<void> runBackupWorkflow() async {
    debugPrint('$_logTag ===== COMPLETE BACKUP WORKFLOW =====');
    
    try {
      // Step 1: Create backup
      debugPrint('$_logTag Step 1: Creating backup...');
      await createBackup(label: 'workflow_backup');
      
      // Step 2: List backups
      debugPrint('$_logTag Step 2: Listing available backups...');
      await listBackups();
      
      debugPrint('$_logTag ===== BACKUP WORKFLOW COMPLETE =====');
      
    } catch (e, stackTrace) {
      debugPrint('$_logTag ❌ BACKUP WORKFLOW FAILED: $e');
      debugPrint('$_logTag Stack trace: $stackTrace');
    }
  }
}
