import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/neumorphic_widgets.dart';
import '../providers/auth_provider.dart';
import '../services/debug_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  Map<String, dynamic> _diagnosticResult = {};
  bool _showDiagnostic = false;

  @override
  void initState() {
    super.initState();
    _checkFirestoreSetup();
  }

  Future<void> _checkFirestoreSetup() async {
    try {
      final firestoreStatus = await DebugService.checkFirestoreStatus();
      if (firestoreStatus['needsSetup'] == true && mounted) {
        // Show the setup instructions dialog after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            DebugService.showSetupInstructionsDialog(context);
          }
        });
      }
    } catch (e) {
      print('Error checking Firestore setup: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      // Hide keyboard
      FocusScope.of(context).unfocus();

      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      print('Login attempt with email: ${_emailController.text}');

      // Attempt login
      bool success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        print('Login successful, navigating to home');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('Login failed: ${authProvider.errorMessage}');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _showDiagnostic = true;
    });

    final result = await DebugService.runDiagnostic();

    if (mounted) {
      setState(() {
        _diagnosticResult = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF192734),
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _runDiagnostic,
            tooltip: 'Run diagnostic',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Diagnostic panel
              if (_showDiagnostic) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252836),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Firebase Diagnostic:',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._diagnosticResult.entries.map((entry) {
                        return Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      }),
                      if (_diagnosticResult.isEmpty)
                        const Text(
                          'Running diagnostic...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showDiagnostic = false;
                            });
                          },
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with neumorphic effect
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252836),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(4, 4),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            offset: const Offset(-4, -4),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 80,
                        color: Color(0xFF61DAFB),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome to SriPediaAI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF61DAFB),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    NeumorphicTextField(
                      child: TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              const Icon(Icons.email, color: Color(0xFF61DAFB)),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    NeumorphicTextField(
                      child: TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF61DAFB)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF61DAFB).withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Show reset password dialog
                          _showResetPasswordDialog(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login button with neumorphic style
                    NeumorphicButton(
                      onPressed: authProvider.isLoading ? null : _login,
                      isLoading: authProvider.isLoading,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF61DAFB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF61DAFB),
                      ),
                      child: const Text(
                        'Don\'t have an account? Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252836),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: resetFormKey,
            child: TextFormField(
              controller: resetEmailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Enter your email address',
                hintStyle: TextStyle(color: Colors.white30),
                prefixIcon: Icon(Icons.email, color: Color(0xFF61DAFB)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return TextButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (resetFormKey.currentState!.validate()) {
                            // Request password reset
                            bool success = await authProvider.resetPassword(
                                resetEmailController.text.trim());

                            if (!mounted) return;
                            Navigator.pop(context);

                            // Show success or error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Password reset email sent! Check your inbox.'
                                      : authProvider.errorMessage ??
                                          'Failed to send reset email',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF61DAFB),
                          ),
                        )
                      : const Text('Send Reset Link'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
