import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DebugService {
  // Check Firebase connection status
  static Future<bool> checkFirebaseConnection() async {
    try {
      // Try to get a small amount of data from Firestore
      await FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test')
          .set({'timestamp': FieldValue.serverTimestamp()});

      print('Firebase Firestore connection successful');
      return true;
    } catch (e) {
      print('Firebase Firestore connection failed: $e');
      return false;
    }
  }

  // Check Authentication status
  static Future<Map<String, dynamic>> checkAuthStatus() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;
      result['isAuthenticated'] = user != null;
      result['userId'] = user?.uid;
      result['email'] = user?.email;
      result['emailVerified'] = user?.emailVerified;
      result['displayName'] = user?.displayName;

      print('Auth status: ${user != null ? 'Logged in' : 'Not logged in'}');
      return result;
    } catch (e) {
      print('Error checking auth status: $e');
      result['error'] = e.toString();
      return result;
    }
  }

  // Check if user exists in Firestore
  static Future<bool> checkUserInFirestore(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      final exists = doc.exists;
      print('User in Firestore: ${exists ? 'exists' : 'does not exist'}');
      return exists;
    } catch (e) {
      print('Error checking user in Firestore: $e');
      return false;
    }
  }

  // Check if user exists in Realtime Database
  static Future<bool> checkUserInRealtimeDB(String uid) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await ref.get();

      final exists = snapshot.exists;
      print('User in Realtime DB: ${exists ? 'exists' : 'does not exist'}');
      return exists;
    } catch (e) {
      print('Error checking user in Realtime Database: $e');
      return false;
    }
  }

  // Run a full diagnostic
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final result = <String, dynamic>{};

    // Check connection
    result['connectionOk'] = await checkFirebaseConnection();

    // Check auth status
    final authStatus = await checkAuthStatus();
    result['authStatus'] = authStatus;

    // If authenticated, check user data
    if (authStatus['isAuthenticated'] == true && authStatus['userId'] != null) {
      final uid = authStatus['userId'] as String;
      result['userInFirestore'] = await checkUserInFirestore(uid);
      result['userInRealtimeDB'] = await checkUserInRealtimeDB(uid);
    }

    return result;
  }

  // Examine the structure of a Realtime Database node
  static Future<String> inspectRealtimeDBNode(String path) async {
    try {
      final ref = FirebaseDatabase.instance.ref(path);
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return "Node doesn't exist";
      }

      final value = snapshot.value;
      final valueType = value.runtimeType.toString();
      String details = "Value type: $valueType\n";

      if (value is Map) {
        details += "Keys: ${(value as Map).keys.join(", ")}\n";
      } else if (value is List) {
        details += "Length: ${(value as List).length}\n";
      }

      return details;
    } catch (e) {
      return "Error inspecting node: $e";
    }
  }

  // Test write to Realtime DB
  static Future<bool> testRealtimeDBWrite() async {
    try {
      final ref = FirebaseDatabase.instance.ref("_debug_test");
      await ref.set(
          {"timestamp": ServerValue.timestamp, "test": "Debug write test"});
      return true;
    } catch (e) {
      print("Error writing to Realtime DB: $e");
      return false;
    }
  }

  // Check Firestore Database Status (expanded to check if it exists)
  static Future<Map<String, dynamic>> checkFirestoreStatus() async {
    final result = <String, dynamic>{};

    try {
      // Try to access Firestore
      await FirebaseFirestore.instance
          .collection('_connection_test')
          .doc('test')
          .get();

      result['exists'] = true;
      result['status'] = 'Firestore database exists and is accessible';

      print('Firestore database exists and is accessible');
    } catch (e) {
      final errorMsg = e.toString();
      result['exists'] = false;
      result['status'] = 'Firestore database not set up';
      result['error'] = errorMsg;

      if (errorMsg.contains('NOT_FOUND') &&
          errorMsg.contains('does not exist')) {
        result['needsSetup'] = true;
        result['setupUrl'] =
            'https://console.cloud.google.com/firestore/databases';
        print('Firestore database needs to be created in Firebase Console');
      } else {
        result['needsSetup'] = false;
        print('Firestore error: $errorMsg');
      }
    }

    return result;
  }

  // Enhanced diagnostic
  static Future<Map<String, dynamic>> enhancedDiagnostic() async {
    final result = await runDiagnostic();

    // Add Firestore database check
    result['firestoreStatus'] = await checkFirestoreStatus();

    // Add Realtime DB test
    result['realtimeDBWriteTest'] = await testRealtimeDBWrite();

    // If authenticated, check user node structure
    if (result['authStatus']?['isAuthenticated'] == true &&
        result['authStatus']?['userId'] != null) {
      final uid = result['authStatus']['userId'] as String;
      result['userNodeStructure'] = await inspectRealtimeDBNode('users/$uid');
    }

    return result;
  }

  // Show setup instructions dialog
  static void showSetupInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Setup Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Firebase project is missing the Firestore database.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'To complete setup:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Go to Firebase Console'),
            Text('2. Select your project (sripedia-2a129)'),
            Text('3. Click on "Firestore Database" in the left menu'),
            Text('4. Click "Create database"'),
            Text('5. Choose "Start in test mode" for development'),
            Text('6. Select a database location closest to your users'),
            Text('7. Click "Enable"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
