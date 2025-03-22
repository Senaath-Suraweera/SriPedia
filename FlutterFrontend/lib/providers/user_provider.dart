import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserData {
  final String id;
  final String username;
  final String email;
  final Map<String, dynamic>? additionalData;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    this.additionalData,
  });
}

class UserProvider with ChangeNotifier {
  UserData? _user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  bool _isLoading = false;

  UserData? get user => _user;
  bool get isLoading => _isLoading;

  // Constructor to automatically load user data
  UserProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadUserData();
      } else {
        _user = null;
        notifyListeners();
      }
    });

    // Also load immediately if user is already signed in
    if (_auth.currentUser != null) {
      loadUserData();
    }
  }

  Future<void> loadUserData() async {
    if (_auth.currentUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _auth.currentUser!.uid;
      final snapshot = await _database.ref('users/$userId').get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);

        _user = UserData(
          id: userId,
          username: userData['username'] ?? 'User',
          email: _auth.currentUser!.email ?? '',
          additionalData: userData,
        );
      } else {
        // Default data if user record doesn't exist
        _user = UserData(
          id: userId,
          username: _auth.currentUser!.displayName ?? 'User',
          email: _auth.currentUser!.email ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Set default data on error
      if (_auth.currentUser != null) {
        _user = UserData(
          id: _auth.currentUser!.uid,
          username: _auth.currentUser!.displayName ?? 'User',
          email: _auth.currentUser!.email ?? '',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;
      await _database.ref('users/$userId').update(data);
      await loadUserData(); // Reload the user data
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }
}
