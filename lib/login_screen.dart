import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'No account found with this email address.';
              break;
            case 'wrong-password':
              _errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'invalid-email':
              _errorMessage = 'Please enter a valid email address.';
              break;
            case 'user-disabled':
              _errorMessage = 'This account has been disabled.';
              break;
            default:
              _errorMessage = 'Login failed. Please check your credentials.';
          }
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

  Future<void> _forgotPassword() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _usernameController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${_usernameController.text.trim()}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Failed to send password reset email.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and Branding
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Shelf-It',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1565C0),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inventory Management System',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),

                        // Login Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Input
                              Semantics(
                                label: 'Email address input field',
                                hint: 'Enter your email address to log in',
                                child: TextFormField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              Semantics(
                                label: 'Password input field',
                                hint: 'Enter your password to log in',
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      tooltip: _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error Message
                              if (_errorMessage.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Login Button
                              SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Forgot Password Link
                              Center(
                                child: TextButton(
                                  onPressed: _forgotPassword,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Sign Up Link
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/signup');
                                      },
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
