import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ClassroomProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get classrooms => _classrooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load user's classrooms
  Future<void> loadUserClassrooms() async {
    _setLoading(true);
    _clearError();

    try {
      _classrooms = await _firebaseService.getUserClassrooms();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load classrooms: $e');
      _setLoading(false);
    }
  }

  // Join a classroom
  Future<bool> joinClassroom(String classroomId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.joinClassroom(classroomId);
      await loadUserClassrooms(); // Refresh classrooms list
      return true;
    } catch (e) {
      _setError('Failed to join classroom: $e');
      _setLoading(false);
      return false;
    }
  }

  // Leave a classroom
  Future<bool> leaveClassroom(String classroomId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.leaveClassroom(classroomId);
      await loadUserClassrooms(); // Refresh classrooms list
      return true;
    } catch (e) {
      _setError('Failed to leave classroom: $e');
      _setLoading(false);
      return false;
    }
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
