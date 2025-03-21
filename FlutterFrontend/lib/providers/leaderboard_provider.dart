import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load leaderboard data
  Future<void> loadLeaderboard({int limit = 20}) async {
    _setLoading(true);
    _clearError();

    try {
      _leaderboardData = await _firebaseService.getLeaderboard(limit: limit);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load leaderboard: $e');
      _setLoading(false);
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
