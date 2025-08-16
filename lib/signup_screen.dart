import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

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
  final _companyNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isOrganization = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if email is already in use
        bool emailTaken = await _checkEmailExists(_emailController.text);
        if (emailTaken) {
          _showErrorMessage(
            'The email address is already in use by another account.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Create user with Firebase Auth
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'isOrganization': _isOrganization,
          'companyName': _isOrganization ? _companyNameController.text.trim() : null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'weak-password':
            message = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            message = 'The account already exists for that email.';
            break;
          case 'invalid-email':
            message = 'The email address is not valid.';
            break;
          default:
            message = 'An error occurred. Please try again.';
        }
        _showErrorMessage(message);
      } catch (e) {
        _showErrorMessage('An unexpected error occurred. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      // Create a temporary user to check if email exists
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'TemporaryPassword123!',
      );

      // If no error is thrown, delete the temporary user
      await FirebaseAuth.instance.currentUser?.delete();

      return false; // Email is not taken
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true; // Email is already in use
      }
      // Handle other exceptions if necessary
      rethrow;
    } catch (e) {
      // Log or handle unexpected errors
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 60,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Welcome Text
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Shelf It to manage your inventory efficiently',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Signup Form Card
                Card(
                  elevation: 8,
                  shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Account Type Selection
                          Text(
                            'Account Type',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Personal'),
                                  value: false,
                                  groupValue: _isOrganization,
                                  onChanged: (value) {
                                    setState(() {
                                      _isOrganization = value!;
                                    });
                                  },
                                  activeColor: theme.colorScheme.primary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text('Company'),
                                  value: true,
                                  groupValue: _isOrganization,
                                  onChanged: (value) {
                                    setState(() {
                                      _isOrganization = value!;
                                    });
                                  },
                                  activeColor: theme.colorScheme.primary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email address';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Company Name Field (if organization)
                          if (_isOrganization) ...[
                            TextFormField(
                              controller: _companyNameController,
                              decoration: InputDecoration(
                                labelText: 'Company Name',
                                prefixIcon: const Icon(Icons.business_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (_isOrganization && (value == null || value.isEmpty)) {
                                  return 'Please enter your company name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$')
                                  .hasMatch(value)) {
                                return 'Password must include both letters and numbers';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                          const SizedBox(height: 32),
                          
                          // Sign Up Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
