import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Short delay to allow Firebase to initialize
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Get Firebase auth directly instead of relying on AuthProvider initially
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print(
          'Firebase current user: ${firebaseUser?.uid ?? 'No user logged in'}');

      // If there's an issue with the provider, use Firebase authentication directly
      if (mounted) {
        if (firebaseUser != null) {
          print('User is authenticated, navigating to home screen');
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          print('User is not authenticated, navigating to login screen');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      print('Error during authentication check: $e');
      // Default to login screen on error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              'SriPediaAI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF61DAFB),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF61DAFB)),
            ),
          ],
        ),
      ),
    );
  }
}
