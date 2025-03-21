import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SriPediaAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A6F97), // Deep blue color
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E2E), // Dark blue-gray
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        // Additional routes for various features
        '/quiz': (context) => const PlaceholderScreen(title: 'Daily Quiz'),
        '/leaderboard': (context) =>
            const PlaceholderScreen(title: 'Leaderboard'),
        '/classrooms': (context) =>
            const PlaceholderScreen(title: 'Classrooms'),
        '/store': (context) => const PlaceholderScreen(title: 'Store'),
        '/chatbot': (context) => const PlaceholderScreen(title: 'AI Chatbot'),
      },
    );
  }
}
