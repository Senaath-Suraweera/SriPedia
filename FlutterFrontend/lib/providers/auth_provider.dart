import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DatabaseEvent>? _userStreamSubscription;
  StreamSubscription<User?>? _authStateSubscription;
  bool _initialized = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  // Constructor to initialize listener
  AuthProvider() {
    print('AuthProvider initializing');
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      // Check if there's a current user already
      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        print('Found existing signed in user: ${currentUser.uid}');
        final userData = await _firebaseService.getUserData();
        if (userData != null) {
          _user = UserModel.fromMap(currentUser.uid, userData);
        }
      }

      // Then set up the stream listener
      _initAuthListener();

      _initialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing AuthProvider: $e');
      _initialized = true; // Mark as initialized even on error
      notifyListeners();
    }
  }

  void _initAuthListener() {
    _authStateSubscription =
        _firebaseService.authStateChanges.listen((User? firebaseUser) async {
      print('Auth state changed. User: ${firebaseUser?.uid ?? 'null'}');
      if (firebaseUser != null) {
        try {
          final userData = await _firebaseService.getUserData();
          if (userData != null) {
            print('User data retrieved. Creating UserModel...');
            _user = UserModel.fromMap(firebaseUser.uid, userData);

            // Subscribe to real-time updates for the user
            _subscribeToUserUpdates();
          } else {
            print('No user data found for authenticated user');
            _user = null;
          }
        } catch (e) {
          print('Error loading user data: $e');
          _user = null;
        }
      } else {
        print('No authenticated user');
        _user = null;
        // Cancel subscription when user logs out
        _cancelUserSubscription();
      }
      notifyListeners();
    }, onError: (error) {
      print('Auth state stream error: $error');
      _user = null;
      notifyListeners();
    });
  }

  // Subscribe to real-time user data updates with robust error handling
  void _subscribeToUserUpdates() {
    _cancelUserSubscription();

    try {
      print('Subscribing to real-time user updates');
      _userStreamSubscription =
          _firebaseService.getUserRealtimeStream().listen((event) {
        if (event.snapshot.value == null || _user == null) {
          print('Skipping update: snapshot value is null or user is null');
          return;
        }

        try {
          print('Received real-time update for user: ${_user?.uid}');
          print('Update data type: ${event.snapshot.value.runtimeType}');

          // Safely extract the data based on its type
          Map<String, dynamic> data;

          if (event.snapshot.value is Map) {
            // Handle map data - normal case
            data = Map<String, dynamic>.from(event.snapshot.value as Map);
          } else if (event.snapshot.value is List) {
            // Handle list data - special case in Realtime DB
            print('Warning: Received List data instead of Map');

            // Create a fallback map with basic data
            data = {
              'online': true,
              'lastSeen': DateTime.now().millisecondsSinceEpoch,
            };
          } else {
            // Unable to process this type
            print(
                'Error: Cannot process data of type ${event.snapshot.value.runtimeType}');
            return;
          }

          // Update the user model with a try-catch for additional safety
          try {
            _user = UserModel.fromMap(_user!.uid, {
              ..._user!.toMap(), // Keep existing data as base
              ...data, // Override with real-time data
            });

            notifyListeners();
            print('User model updated successfully');
          } catch (e) {
            print('Error updating user model: $e');
          }
        } catch (e) {
          print('Error processing real-time update: $e');
        }
      }, onError: (error) {
        print('Error in user real-time updates stream: $error');
      }, onDone: () {
        print('User real-time updates stream closed');
      });
    } catch (e) {
      print('Error setting up user updates subscription: $e');
    }
  }

  // Use the new stream that returns UserModel directly

  // Cancel user data subscription
  void _cancelUserSubscription() {
    if (_userStreamSubscription != null) {
      print('Cancelling user real-time subscription');
      _userStreamSubscription?.cancel();
      _userStreamSubscription = null;
    }
  }

  // Cleanup resources
  @override
  void dispose() {
    print('Disposing AuthProvider');
    _cancelUserSubscription();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('AuthProvider: Attempting to sign in');
      await _firebaseService.signInWithEmailAndPassword(email, password);
      print('AuthProvider: Sign in successful');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      print('AuthProvider: Sign in failed - ${e.message}');
      _setError(e.message ?? 'An error occurred during sign in');
      _setLoading(false);
      return false;
    } catch (e) {
      print('AuthProvider: Unexpected error during sign in - $e');
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Register with email and password - add better error handling
  Future<bool> register(
      String email, String password, String username, String role) async {
    _setLoading(true);
    _clearError();

    try {
      print('Attempting registration for: $email');
      await _firebaseService.registerWithEmailAndPassword(
          email, password, username, role);

      print('Registration successful');
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      print(
          'FirebaseAuthException during registration: ${e.code} - ${e.message}');
      _setError(e.message ?? 'An error occurred during registration');
      _setLoading(false);
      return false;
    } catch (e) {
      print('Unexpected error during registration: $e');
      _setError('An unexpected error occurred. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      // Try to sign out from Firebase
      await _firebaseService.signOut();

      // Clear local user data
      _user = null;

      _setLoading(false);
      notifyListeners();

      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
      _setError('Error signing out: $e');
      _setLoading(false);
      notifyListeners();
      // Rethrow the error for handling in UI
      throw e;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.resetPassword(email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'An error occurred while resetting password');
      _setLoading(false);
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_firebaseService.currentUser != null) {
      final userData = await _firebaseService.getUserData();
      if (userData != null) {
        _user = UserModel.fromMap(_firebaseService.currentUser!.uid, userData);
        notifyListeners();
      }
    }
  }

  // Update user points
  Future<void> addPoints(int points) async {
    if (_user == null) return;

    await _firebaseService.updateUserPoints(points);
    // User data will be updated via real-time subscription
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
