import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_service.dart';

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
      message = 'You are currently offline. Some features may be limited.';
      backgroundColor = Colors.red.shade700;
    } else if (!networkService.isServerReachable) {
      message = 'Cannot connect to server. Using offline mode.';
      backgroundColor = Colors.orange.shade700;
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}