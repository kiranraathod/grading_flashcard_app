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
    
    final String message = !networkService.isOnline
        ? 'No internet connection. Using offline grading.'
        : 'Cannot reach grading server. Using offline grading.';
    
    return Container(
      width: double.infinity,
      color: Colors.amber.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => networkService.checkConnectivity(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
