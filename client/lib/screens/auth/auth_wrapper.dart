import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    
    // Listen to authentication state and return the appropriate screen
    return userService.isAuthenticated 
        ? const HomeScreen() 
        : const LoginScreen();
  }
}
