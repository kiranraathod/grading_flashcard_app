import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _isSuccess = false;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _isSuccess = true;
          _message = 'Password reset email sent! Check your inbox for instructions.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _message = 'Failed to send reset email: ${e.toString()}';
        });
      }
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
        title: const Text('Reset Password'),
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
                // Icon
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Forgot Your Password?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                const Text(
                  'Enter your email address and we will send you instructions to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                
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
                const SizedBox(height: 24),
                
                // Message
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green : Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Send button
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: const Color(0xFF1A5E34),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('SEND RESET LINK', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                
                // Back to login button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
