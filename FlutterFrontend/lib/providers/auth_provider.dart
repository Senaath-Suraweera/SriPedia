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

          // Add debug output to understand the data structure
          print('Update data content: ${event.snapshot.value}');

          // Safely extract the data based on its type with better error handling
          Map<String, dynamic> data = {};

          if (event.snapshot.value is Map) {
            // Handle map data - normal case
            data = Map<String, dynamic>.from(event.snapshot.value as Map);
          } else if (event.snapshot.value is List) {
            // Handle empty list case more explicitly
            print('Warning: Received List data instead of Map');

            // Create a minimal working data structure that won't cause issues
            data = {
              'online': true,
              'lastSeen': DateTime.now().millisecondsSinceEpoch,
              'username': _user?.username ?? 'User',
              'role': _user?.role ?? 'Student',
              'points': _user?.points ?? 0,
              'level': _user?.level ?? 1,
              'xp': _user?.xp ?? 0,
            };
          } else {
            print(
                'Warning: Unexpected value type ${event.snapshot.value.runtimeType}');
            data = {
              'online': true,
              'lastSeen': DateTime.now().millisecondsSinceEpoch,
              'username': _user?.username ?? 'User',
              'role': _user?.role ?? 'Student',
              'points': _user?.points ?? 0,
              'level': _user?.level ?? 1,
              'xp': _user?.xp ?? 0,
            };
          }

          // Update the user model with a try-catch for additional safety
          try {
            // Create a merged map that preserves existing user data
            Map<String, dynamic> mergedData = {
              'uid': _user!.uid,
              'email': _user!.email,
              'username': _user!.username,
              'role': _user!.role,
              'points': _user!.points,
              'level': _user!.level,
              'xp': _user!.xp,
            };

            // Only add properties from data that exist and aren't null
            data.forEach((key, value) {
              if (value != null) {
                mergedData[key] = value;
              }
            });

            // Create new user model from merged data
            final updatedUser = UserModel.fromMap(_user!.uid, mergedData);

            // Only notify listeners if there's an actual change
            if (_user!.username != updatedUser.username ||
                _user!.points != updatedUser.points ||
                _user!.level != updatedUser.level ||
                _user!.xp != updatedUser.xp) {
              _user = updatedUser;
              notifyListeners();
              print('User model updated successfully');
            } else {
              print('No significant changes, skipping update');
            }
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

      // Explicit user data loading with timeout protection
      bool userDataLoaded = false;
      try {
        if (_firebaseService.currentUser != null) {
          final userData = await _firebaseService.getUserData();
          if (userData != null) {
            _user =
                UserModel.fromMap(_firebaseService.currentUser!.uid, userData);
            userDataLoaded = true;
            print("User data explicitly loaded: ${_user!.username}");
          }
        }
      } catch (loadUserError) {
        print('AuthProvider: Error loading user after sign in: $loadUserError');
      }

      // Add critical fallback - if we still don't have user data, create a minimal user
      if (!userDataLoaded && _firebaseService.currentUser != null) {
        print('Creating minimal user model as fallback');
        _user = UserModel(
          uid: _firebaseService.currentUser!.uid,
          email: _firebaseService.currentUser!.email ?? email,
          username: _firebaseService.currentUser!.displayName ?? 'User',
          role: 'Student',
        );
      }

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

  // Register with email and password - simplified to remove role parameter
  Future<bool> register(String email, String password, String username) async {
    _setLoading(true);
    _clearError();

    try {
      print('Attempting registration for: $email');
      await _firebaseService.registerWithEmailAndPassword(
          email, password, username);

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
