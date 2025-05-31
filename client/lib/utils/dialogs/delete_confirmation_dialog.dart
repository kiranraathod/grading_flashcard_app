import 'package:flutter/material.dart';

/// Simple confirmation dialog for delete operations
/// Follows existing app dialog patterns for consistency
class DeleteConfirmationDialog {
  /// Shows a confirmation dialog for delete operations
  /// Returns true if user confirms, false if cancelled
  static Future<bool> show(
    BuildContext context, {
    required String itemName,
    required String itemType,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemType'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false; // Return false if dialog is dismissed
  }
}
