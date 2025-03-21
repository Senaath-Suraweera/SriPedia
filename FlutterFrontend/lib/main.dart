import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/classroom_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/quiz_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/quiz/daily_quiz_screen.dart';

void main() async {
  // Catch all Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    FlutterError.presentError(details);
  };

  // Catch all Dart errors
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Wait briefly to ensure Firebase is fully ready
    await Future.delayed(const Duration(milliseconds: 500));
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use lazy: false to ensure AuthProvider initializes immediately
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ClassroomProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'SriPediaAI',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2A6F97),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1E2E),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
          '/quiz': (context) => const DailyQuizScreen(),
          '/leaderboard': (context) =>
              const PlaceholderScreen(title: 'Leaderboard'),
          '/classrooms': (context) =>
              const PlaceholderScreen(title: 'Classrooms'),
          '/store': (context) => const PlaceholderScreen(title: 'Store'),
          '/chatbot': (context) => const PlaceholderScreen(title: 'AI Chatbot'),
        },
      ),
    );
  }
}
