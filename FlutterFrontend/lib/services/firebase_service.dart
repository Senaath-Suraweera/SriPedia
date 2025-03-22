import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import 'realtime_database_service.dart';
import 'dart:math'; // For min() function

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RealtimeDatabaseService _realtimeDB = RealtimeDatabaseService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Sign in successful for user: ${userCredential.user?.uid}');

      // Update online status in Realtime Database
      if (userCredential.user != null) {
        try {
          await _realtimeDB.updateUserOnlineStatus(
              userCredential.user!.uid, true);
          print('Online status updated successfully');
        } catch (e) {
          print('Error updating online status: $e');
          // Don't throw here - we still want to complete the login process
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during sign in: ${e.code} - ${e.message}');
      throw FirebaseAuthException(
        code: e.code,
        message: getAuthErrorMessage(e.code),
      );
    } catch (e) {
      print('Unexpected error during sign in: $e');
      // Added more descriptive error information to help debugging
      if (e is TypeError) {
        print('Type error details: ${e.toString()}');
      }
      throw Exception('Authentication error: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      print('Attempting to register with email: $email');
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Registration successful for user: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        // Create UserModel - always set role to "Student" by default
        final userModel = UserModel(
          uid: uid,
          email: email,
          username: username,
          role: "Student", // Default role is always "Student"
        );

        try {
          // Add user to Firestore database first
          await _createUserInFirestore(userModel);
          print('User added to Firestore');

          // Update display name
          await userCredential.user!.updateDisplayName(username);
          print('Display name updated');

          // Add user to Realtime Database - do this last to avoid the initial sign-in issue
          try {
            await _realtimeDB.saveUserToRealtimeDB(userModel);
            print('User added to Realtime Database');
          } catch (rtdbError) {
            // Just log the error but don't fail the registration
            print('Error adding user to Realtime Database: $rtdbError');
            print('Realtime DB setup will be retried on next sign-in');
          }
        } catch (e) {
          print('Error setting up user data: $e');
          // Consider additional cleanup here if needed
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception during registration: ${e.code} - ${e.message}');
      throw FirebaseAuthException(
        code: e.code,
        message: getAuthErrorMessage(e.code),
      );
    } catch (e) {
      print('Unexpected error during registration: $e');
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserInFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'username': user.username,
      'role': user.role,
      'points': user.points,
      'level': user.level,
      'xp': user.xp,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting sign out process');

      // Update online status before signing out (if user exists)
      if (currentUser != null) {
        try {
          await _realtimeDB.updateUserOnlineStatus(currentUser!.uid, false);
          print('Updated online status to offline');
        } catch (e) {
          // Just log the error but continue with sign out
          print('Error updating online status during sign out: $e');
        }
      }

      // Sign out from Firebase Auth
      await _auth.signOut();
      print('Signed out from Firebase Auth');
    } catch (e) {
      print('Error during Firebase sign out: $e');
      // Rethrow for handling in the provider
      throw e;
    }
  }

  // Get user data (combining Firestore and Realtime Database)
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) {
        print('No current user found when fetching user data');
        return null;
      }

      final String uid = currentUser!.uid;
      print('Fetching user data for UID: $uid');

      // Try RTDB first since Firestore isn't initialized yet
      try {
        print('Attempting to get data from Realtime Database');
        final rtdbSnapshot = await _realtimeDB.userRef(uid).get();

        // Debug the value type we're getting
        if (rtdbSnapshot.exists && rtdbSnapshot.value != null) {
          print('RTDB data found for user');
          print('RTDB data type: ${rtdbSnapshot.value.runtimeType}');
          print('RTDB data value: ${rtdbSnapshot.value}');

          // Handle different possible types from RTDB
          if (rtdbSnapshot.value is Map) {
            print('RTDB data is a Map, using it directly');
            final data = Map<String, dynamic>.from(rtdbSnapshot.value as Map);

            // Make sure critical fields exist
            if (!data.containsKey('username')) {
              data['username'] = currentUser!.displayName ?? 'User';
            }
            if (!data.containsKey('role')) {
              data['role'] = 'Student';
            }
            if (!data.containsKey('points')) {
              data['points'] = 0;
            }
            if (!data.containsKey('level')) {
              data['level'] = 1;
            }
            if (!data.containsKey('xp')) {
              data['xp'] = 0;
            }

            return data;
          } else if (rtdbSnapshot.value is List) {
            print('RTDB data is a List, converting to Map');

            // Return basic user data
            return {
              'email': currentUser!.email ?? '',
              'username': currentUser!.displayName ??
                  uid.substring(0, min(uid.length, 6)),
              'role': 'Student',
              'points': 0,
              'level': 1,
              'xp': 0,
              'online': true,
              'lastSeen': DateTime.now().millisecondsSinceEpoch,
            };
          } else {
            print('RTDB data is not a usable type: ${rtdbSnapshot.value}');
            // Return minimal placeholder data
            return {
              'email': currentUser!.email ?? '',
              'username': currentUser!.displayName ?? 'User',
              'role': 'Student',
              'points': 0,
              'level': 1,
              'xp': 0,
            };
          }
        } else {
          print('No RTDB data found, creating new user data');

          // No data exists - create and save basic user data
          final userData = {
            'email': currentUser!.email ?? '',
            'username': currentUser!.displayName ?? 'User',
            'role': 'Student',
            'points': 0,
            'level': 1,
            'xp': 0,
            'online': true,
            'lastSeen': ServerValue.timestamp,
          };

          // Save this data to RTDB
          try {
            await _realtimeDB.userRef(uid).set(userData);
            print('Created new user data in RTDB');
          } catch (e) {
            print('Failed to create user data in RTDB: $e');
          }

          return userData;
        }
      } catch (e) {
        print('Error fetching from RTDB: $e');
      }

      // Display warning about Firestore not being set up
      print(
          'WARNING: Firestore database has not been created for this project yet!');
      print(
          'Please visit https://console.cloud.google.com/datastore/setup?project=sripedia-2a129');
      print('Creating fallback user data since database does not exist...');

      // Return minimal placeholder data
      return {
        'email': currentUser!.email ?? '',
        'username': currentUser!.displayName ?? 'User',
        'role': 'Student',
        'points': 0,
        'level': 1,
        'xp': 0,
      };
    } catch (e) {
      print('Error in getUserData: $e');
      return null;
    }
  }

  // Get user data stream from Realtime Database - with better error handling
  Stream<UserModel?> getUserModelStream() {
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _realtimeDB.getUserStream(currentUser!.uid).map((event) {
      if (event.snapshot.value == null) return null;

      try {
        if (event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return UserModel.fromMap(currentUser!.uid, data);
        } else {
          print(
              'Stream data is not a Map: ${event.snapshot.value.runtimeType}');
          return null;
        }
      } catch (e) {
        print('Error parsing stream data: $e');
        return null;
      }
    });
  }

  // Get user data stream from Realtime Database
  Stream<DatabaseEvent> getUserRealtimeStream() {
    if (currentUser == null) {
      throw Exception("No authenticated user");
    }

    return _realtimeDB.getUserStream(currentUser!.uid);
  }

  // Get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) {
    return _realtimeDB.getLeaderboard(limit: limit);
  }

  // Update user data (both in Firestore and Realtime Database)
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    final String uid = currentUser!.uid;

    // Update in Firestore
    await _firestore.collection('users').doc(uid).update(data);

    // Update same data in Realtime Database
    await _realtimeDB.userRef(uid).update(data);
  }

  // Update user points
  Future<void> updateUserPoints(int points) async {
    if (currentUser == null) return;

    await _realtimeDB.updateUserPoints(currentUser!.uid, points);

    // Also update Firestore for consistency
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();

    if (doc.exists) {
      int currentPoints = (doc.data() as Map<String, dynamic>)['points'] ?? 0;
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'points': currentPoints + points});
    }
  }

  // Get user classrooms
  Future<List<Map<String, dynamic>>> getUserClassrooms() async {
    if (currentUser == null) return [];

    return _realtimeDB.getUserClassrooms(currentUser!.uid);
  }

  // Join a classroom
  Future<void> joinClassroom(String classroomId) async {
    if (currentUser == null) return;

    await _realtimeDB.joinClassroom(currentUser!.uid, classroomId);
  }

  // Leave a classroom
  Future<void> leaveClassroom(String classroomId) async {
    if (currentUser == null) return;

    await _realtimeDB.leaveClassroom(currentUser!.uid, classroomId);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: getAuthErrorMessage(e.code),
      );
    }
  }

  // Get user-friendly error messages
  String getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
