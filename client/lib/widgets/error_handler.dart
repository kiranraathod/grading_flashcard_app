import 'package:flutter/material.dart';
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';

class ErrorHandler extends StatelessWidget {
  final Widget child;
  
  const ErrorHandler({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppError>(
      stream: ErrorService().errorStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final error = snapshot.data!;
          
          // Display different UI based on error severity
          switch (error.severity) {
            case ErrorSeverity.critical:
              // For critical errors, show a full-screen error
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, error);
              });
              break;
            case ErrorSeverity.error:
            case ErrorSeverity.warning:
              // For errors and warnings, show a snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorSnackBar(context, error);
              });
              break;
            case ErrorSeverity.info:
              // For info, just show a simple message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showInfoSnackBar(context, error);
              });
              break;
          }
        }
        
        return child;
      },
    );
  }
  
  void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      barrierDismissible: error.severity != ErrorSeverity.critical,
      builder: (context) => AlertDialog(
        title: Text('Error', style: DS.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userFriendlyMessage, style: DS.bodyMedium),
            SizedBox(height: DS.spacingM),
            Text(
              error.actionableAdvice,
              style: DS.bodyMedium.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
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
  
  void _showErrorSnackBar(BuildContext context, AppError error) {
    final Color textColor = Colors.white;
    final Color fadedTextColor = Color.fromRGBO(
      255, 255, 255, 0.7,  // Using fromRGBO instead of withOpacity
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.userFriendlyMessage,
              style: DS.bodyMedium.copyWith(color: textColor),
            ),
            Text(
              error.actionableAdvice,
              style: DS.bodySmall.copyWith(
                color: fadedTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        backgroundColor: error.severity == ErrorSeverity.error 
            ? AppColors.error 
            : AppColors.warning,
        duration: Duration(seconds: error.severity == ErrorSeverity.error ? 5 : 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: textColor,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  void _showInfoSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.message,
          style: DS.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}