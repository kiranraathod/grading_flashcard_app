import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted && context.mounted) {
        // Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please check your email for verification.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to login screen
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign up: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo or icon
                Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                
                // App name or title
                Text(
                  'Join LLM Flashcards',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 36),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    helperText: 'Must be at least 6 characters long',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Signup button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: const Color(0xFF1A5E34),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),
                
                // Login option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
