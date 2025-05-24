import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';
import '../utils/theme_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final networkService = Provider.of<NetworkService>(context);
    
    // If everything is working, don't show the banner
    if (networkService.isOnline && networkService.isServerReachable) {
      return const SizedBox.shrink();
    }
    
    // Determine message and color based on connectivity state
    final String message;
    final Color backgroundColor;
    
    if (!networkService.isOnline) {
      message = AppLocalizations.of(context).offlineMessage;
      backgroundColor = context.errorColor;
    } else if (!networkService.isServerReachable) {
      message = AppLocalizations.of(context).serverConnectionError;
      backgroundColor = context.warningColor;
    } else {
      // Should never reach here due to the first condition
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Text(
        message,
        style: context.bodyMedium?.copyWith(
          color: context.onPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}