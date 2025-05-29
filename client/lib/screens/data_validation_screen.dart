import 'package:flutter/material.dart';
import '../services/data_validation_service.dart';
import '../services/data_repair_service.dart';
import '../services/migration_backup_service.dart';

class DataValidationScreen extends StatefulWidget {
  const DataValidationScreen({super.key});

  @override
  State<DataValidationScreen> createState() => _DataValidationScreenState();
}

class _DataValidationScreenState extends State<DataValidationScreen> {
  DataValidationReport? _report;
  bool _isValidating = false;
  bool _isRepairing = false;
  
  @override
  void initState() {
    super.initState();
    // Auto-run validation on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runValidation();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Validation & Backup'),
        actions: [
          // Task 1.3: Backup buttons
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _createBackup,
            tooltip: 'Create Backup',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.restore),
            tooltip: 'Backup Management',
            onSelected: _handleBackupMenuAction,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'list',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('List Backups'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore_page),
                    SizedBox(width: 8),
                    Text('Restore from Backup'),
                  ],
                ),
              ),
            ],
          ),
          // Task 1.2: Repair button  
          if (_report != null && _report!.hasBlockingIssues && !_isRepairing)
            IconButton(
              icon: const Icon(Icons.build),
              onPressed: _runRepair,
              tooltip: 'Repair Data',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runValidation,
            tooltip: 'Refresh Validation',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isValidating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Validating stored data...'),
            SizedBox(height: 8),
            Text('This may take a few moments', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    if (_isRepairing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Repairing data corruption...'),
            SizedBox(height: 8),
            Text('Creating backup and applying fixes', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    if (_report == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Data validation will start automatically'),
          ],
        ),
      );
    }
    
    return _buildReport();
  }
  
  Widget _buildReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          if (_report!.criticalErrors.isNotEmpty) 
            _buildIssueSection('Critical Errors', _report!.criticalErrors, Colors.red, Icons.error),
          if (_report!.errors.isNotEmpty) 
            _buildIssueSection('Errors', _report!.errors, Colors.orange, Icons.warning),
          if (_report!.warnings.isNotEmpty) 
            _buildIssueSection('Warnings', _report!.warnings, Colors.amber, Icons.info),
          if (_report!.suggestions.isNotEmpty) 
            _buildIssueSection('Suggestions', _report!.suggestions, Colors.blue, Icons.lightbulb),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final isBlocked = _report!.hasBlockingIssues;
    final color = isBlocked ? Colors.red : Colors.green;
    
    return Card(
      color: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBlocked ? Icons.block : Icons.check_circle,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Migration Status: ${_report!.migrationStatus}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (isBlocked)
                        Text(
                          'Estimated fix time: ${((_report!.criticalErrors.length * 2) + _report!.errors.length + (_report!.warnings.length / 5).ceil()).clamp(1, 14)} days',
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCountChip('Critical', _report!.criticalErrors.length, Colors.red)),
                Expanded(child: _buildCountChip('Errors', _report!.errors.length, Colors.orange)),
                Expanded(child: _buildCountChip('Warnings', _report!.warnings.length, Colors.amber)),
                Expanded(child: _buildCountChip('Suggestions', _report!.suggestions.length, Colors.blue)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIssueSection(String title, List<ValidationIssue> issues, Color color, IconData icon) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          '$title (${issues.length})',
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: issues.map((issue) => ListTile(
          leading: Icon(Icons.arrow_right, color: color, size: 20),
          title: Text(
            issue.location,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(issue.message),
          trailing: Text(
            issue.timestamp.toLocal().toString().substring(11, 16),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        )).toList(),
      ),
    );
  }
  
  Future<void> _runValidation() async {
    setState(() {
      _isValidating = true;
      _report = null;
    });
    
    try {
      debugPrint('🔍 Starting data validation from UI...');
      final validationService = DataValidationService();
      final report = await validationService.validateAllStoredData();
      
      setState(() {
        _report = report;
        _isValidating = false;
      });
      
      // Print to console for debugging
      report.printReport();
      
      // Show snackbar with result
      if (mounted) {
        final message = report.hasBlockingIssues 
            ? '⚠️ Found ${report.totalIssues} issues blocking migration'
            : '✅ Validation passed - Ready for migration';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: report.hasBlockingIssues ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Validation failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      setState(() {
        _isValidating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  /// Task 1.2: Run data repair operations
  Future<void> _runRepair() async {
    // Confirm repair operation
    final shouldRepair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair Data'),
        content: const Text(
          'This will automatically repair data corruption issues identified by the validation system. '
          'A backup will be created before making any changes.\n\n'
          'Do you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );
    
    if (shouldRepair != true) return;
    
    setState(() {
      _isRepairing = true;
    });
    
    try {
      debugPrint('🔧 Starting data repair from UI...');
      final repairService = DataRepairService();
      final result = await repairService.repairAllData();
      
      // Show repair results
      if (mounted) {
        _showRepairResults(result);
      }
      
      // Re-run validation to show updated status
      await _runValidation();
      
    } catch (e, stackTrace) {
      debugPrint('❌ Repair failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repair failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRepairing = false;
        });
      }
    }
  }
  
  /// Show repair results in a dialog
  void _showRepairResults(DataRepairResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.wasSuccessful ? Icons.check_circle : Icons.error,
              color: result.wasSuccessful ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(result.wasSuccessful ? 'Repair Successful' : 'Repair Issues'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary
              Card(
                color: result.wasSuccessful ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: result.wasSuccessful ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Repairs Applied: ${result.repairs.length}'),
                      Text('Errors: ${result.errors.length}'),
                      if (result.postRepairValidation != null)
                        Text('Migration Status: ${result.postRepairValidation!.migrationStatus}'),
                    ],
                  ),
                ),
              ),
              
              // Repairs applied
              if (result.repairs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Repairs Applied:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                const SizedBox(height: 8),
                ...result.repairs.take(8).map((repair) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repair,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
                if (result.repairs.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('... and ${result.repairs.length - 8} more repairs'),
                  ),
              ],
              
              // Errors
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                const SizedBox(height: 8),
                ...result.errors.map((error) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Task 1.3: Create backup
  Future<void> _createBackup() async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => _BackupLabelDialog(),
    );
    
    if (label != null) {
      try {
        final backupService = MigrationBackupService();
        final result = await backupService.createFullBackup(label: label);
        
        if (mounted) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backup created successfully: ${result.metadata!.label}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backup failed: ${result.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  /// Task 1.3: Handle backup menu actions
  Future<void> _handleBackupMenuAction(String action) async {
    switch (action) {
      case 'list':
        await _showBackupList();
        break;
      case 'restore':
        await _showRestoreDialog();
        break;
    }
  }
  
  /// Task 1.3: Show backup list
  Future<void> _showBackupList() async {
    try {
      final backupService = MigrationBackupService();
      final backups = await backupService.listBackups();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Available Backups'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: backups.isEmpty
                  ? const Center(child: Text('No backups found'))
                  : ListView.builder(
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        return Card(
                          child: ListTile(
                            title: Text(backup.label),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Created: ${backup.formattedTimestamp}'),
                                Text('Size: ${backup.formattedSize}'),
                                Text('Types: ${backup.dataTypes.join(', ')}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) => _handleBackupAction(action, backup.id),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'validate',
                                  child: Text('Validate'),
                                ),
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Restore'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading backups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Task 1.3: Handle individual backup actions
  Future<void> _handleBackupAction(String action, String backupId) async {
    final backupService = MigrationBackupService();
    
    switch (action) {
      case 'validate':
        try {
          final result = await backupService.validateBackup(backupId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.isValid ? 'Backup is valid' : 'Backup validation failed: ${result.error}'),
                backgroundColor: result.isValid ? Colors.green : Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Validation error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
        
      case 'restore':
        await _restoreFromBackup(backupId);
        break;
        
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Backup'),
            content: const Text('Are you sure you want to delete this backup? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          try {
            final success = await backupService.deleteBackup(backupId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Backup deleted successfully' : 'Failed to delete backup'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delete error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }
  
  /// Task 1.3: Show restore dialog
  Future<void> _showRestoreDialog() async {
    try {
      final backupService = MigrationBackupService();
      final backups = await backupService.listBackups();
      
      if (backups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backups available for restore')),
          );
        }
        return;
      }
      
      if (mounted) {
        final selectedBackup = await showDialog<BackupMetadata>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Backup to Restore'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  return ListTile(
                    title: Text(backup.label),
                    subtitle: Text('${backup.formattedTimestamp} (${backup.formattedSize})'),
                    onTap: () => Navigator.of(context).pop(backup),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        
        if (selectedBackup != null) {
          await _restoreFromBackup(selectedBackup.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading backups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Task 1.3: Restore from backup
  Future<void> _restoreFromBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace ALL current data with the backup data. '
          'A safety backup will be created before restoration.\n\n'
          'Are you sure you want to proceed?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final backupService = MigrationBackupService();
        final result = await backupService.restoreFromBackup(backupId);
        
        if (mounted) {
          if (result.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restore completed successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Re-run validation after restore
            await _runValidation();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restore failed: ${result.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Task 1.3: Backup label input dialog
class _BackupLabelDialog extends StatefulWidget {
  @override
  _BackupLabelDialogState createState() => _BackupLabelDialogState();
}

class _BackupLabelDialogState extends State<_BackupLabelDialog> {
  final _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Set default label with timestamp
    _controller.text = 'Manual backup ${DateTime.now().toIso8601String().substring(0, 16)}';
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter a label for this backup:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Backup Label',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _controller.text.trim();
            if (label.isNotEmpty) {
              Navigator.of(context).pop(label);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
