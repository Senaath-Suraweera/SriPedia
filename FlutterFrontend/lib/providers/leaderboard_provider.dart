import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/realtime_database_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final RealtimeDatabaseService _realtimeDBService = RealtimeDatabaseService();
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedDate;
  List<String> _availableDates = [];
  String _currentCategory = 'daily_quizzes';

  // Getters
  List<Map<String, dynamic>> get leaderboardData => _leaderboardData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedDate =>
      _selectedDate ??
      (_availableDates.isNotEmpty ? _availableDates.first : '');
  List<String> get availableDates => _availableDates;
  String get currentCategory => _currentCategory;

  // Load leaderboard data
  Future<void> loadLeaderboard({String? category, int limit = 50}) async {
    // Don't notify listeners until the end of this method
    _isLoading = true;
    _errorMessage = null;

    try {
      _currentCategory = category ?? 'daily_quizzes';

      // First, get available dates for this category without notifying
      try {
        _availableDates = await _realtimeDBService
            .getLeaderboardDatesForCategory(_currentCategory);
      } catch (e) {
        print('Error loading dates: $e');
        _availableDates = [];
      }

      // If no dates or no selected date, use the first available date
      if (_availableDates.isEmpty) {
        _leaderboardData = [];
        _isLoading = false;
        notifyListeners(); // Single notification at the end
        return;
      }

      // Only auto-select when no date is selected or current selection is invalid
      if (_selectedDate == null || !_availableDates.contains(_selectedDate)) {
        _selectedDate = _availableDates.first;
      }

      // Get leaderboard data for the selected date
      final data = await _realtimeDBService.getLeaderboardByDateAndCategory(
          category: _currentCategory, date: _selectedDate!);

      // Sort by points in descending order
      data.sort((a, b) {
        // Check if both entries have score field
        if (a.containsKey('score') && b.containsKey('score')) {
          return (b['score'] as int? ?? 0).compareTo(a['score'] as int? ?? 0);
        }
        return 0; // No sort if score field isn't available
      });

      // Add position field to each entry
      for (int i = 0; i < data.length; i++) {
        data[i]['position'] = i + 1;
      }

      _leaderboardData = data;
      _isLoading = false;

      // Only notify once at the end of all processing
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load leaderboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set selected date without triggering any notifications
  void setSelectedDate(String date) {
    _selectedDate = date;
    // No notifyListeners() call - caller must handle state update
  }

  // Check if user is the current logged in user
  bool isCurrentUser(String userId) {
    final currentUser = _firebaseService.currentUser;
    return currentUser != null && currentUser.uid == userId;
  }

  // IMPORTANT: Remove these helper methods that have notifyListeners()
  // as they're causing the issue by being called during the build phase
  /*
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
  */
}
