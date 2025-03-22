import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class RealtimeDatabaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Reference to the database root
  DatabaseReference get _databaseRef => _database.ref();

  // User reference
  DatabaseReference userRef(String uid) =>
      _databaseRef.child('users').child(uid);

  // Questions reference
  DatabaseReference get questionsRef => _databaseRef.child('questions');

  // Leaderboard reference
  DatabaseReference get leaderboardRef => _databaseRef.child('leaderboard');

  // Classrooms reference
  DatabaseReference get classroomsRef => _databaseRef.child('classrooms');

  // Get daily quizzes reference
  DatabaseReference get dailyQuizzesRef => _databaseRef.child('daily_quizzes');

  // Update user online status with better error handling
  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      final ref = userRef(uid);

      // First check if user exists in RTDB
      final snapshot = await ref.get();

      if (snapshot.exists) {
        // Check if the value is a Map
        if (snapshot.value is Map) {
          // User exists, just update the online status
          await ref.update({
            'online': isOnline,
            'lastSeen': ServerValue.timestamp,
          });
        } else {
          // User exists but data is not in expected format (could be a list or other type)
          // Set it as new data to ensure it's a Map
          await ref.set({
            'online': isOnline,
            'lastSeen': ServerValue.timestamp,
            'username': 'User', // Set a default username
            'points': 0,
            'level': 1,
            'xp': 0,
            'role': 'Student',
          });
        }
      } else {
        // User doesn't exist yet (first sign in after registration)
        // Create a record with all needed fields
        await ref.set({
          'online': isOnline,
          'lastSeen': ServerValue.timestamp,
          'username': 'User', // Set a default username
          'points': 0,
          'level': 1,
          'xp': 0,
          'role': 'Student',
        });
      }
    } catch (e) {
      print('Error in updateUserOnlineStatus: $e');
      // Don't throw - this is called in critical paths where we don't want to fail
    }
  }

  // Save user data to Realtime Database with better error handling
  Future<void> saveUserToRealtimeDB(UserModel user) async {
    try {
      // First check if the database path is valid
      final ref = userRef(user.uid);

      // Use a map that matches exactly what we need
      final userData = {
        'email': user.email,
        'username': user.username,
        'role': user.role,
        'points': user.points,
        'level': user.level,
        'xp': user.xp,
        'online': true,
        'lastSeen': ServerValue.timestamp,
      };

      // Set the data
      await ref.set(userData);

      // Verify it was saved correctly
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        throw Exception('Data was not saved properly');
      }

      print('User data saved to RTDB successfully for ${user.uid}');
    } catch (e) {
      print('Error in saveUserToRealtimeDB: $e');
      // Re-throw to allow caller to handle
      rethrow;
    }
  }

  // Get user data from Realtime Database with improved type safety
  Future<Map<String, dynamic>?> getUserRealtimeData(String uid) async {
    try {
      print('Fetching RTDB data for user: $uid');
      DataSnapshot snapshot = await userRef(uid).get();

      if (!snapshot.exists) {
        print('No RTDB data exists for user: $uid');
        return null;
      }

      // Log the actual type we're getting
      print('RTDB data type: ${snapshot.value.runtimeType}');

      // Handle different types that might come from RTDB
      if (snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else if (snapshot.value is List) {
        print('Warning: RTDB returned a List for user $uid');
        // Convert the list to a map or return null
        return null;
      } else {
        print(
            'RTDB data for user $uid is not a usable type: ${snapshot.value}');
        return null;
      }
    } catch (e) {
      print('Error in getUserRealtimeData: $e');
      return null;
    }
  }

  // Listen to user data changes
  Stream<DatabaseEvent> getUserStream(String uid) {
    return userRef(uid).onValue;
  }

  // Get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    DataSnapshot snapshot =
        await leaderboardRef.orderByChild('points').limitToLast(limit).get();

    List<Map<String, dynamic>> leaderboard = [];

    if (snapshot.exists && snapshot.value != null) {
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

      values.forEach((key, value) {
        if (value is Map) {
          leaderboard.add(Map<String, dynamic>.from(value as Map));
        }
      });

      // Sort by points (highest first)
      leaderboard
          .sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    }

    return leaderboard;
  }

  // Update user points and sync with leaderboard
  Future<void> updateUserPoints(String uid, int points) async {
    try {
      // Get current user data
      DataSnapshot userSnapshot = await userRef(uid).get();

      if (userSnapshot.exists && userSnapshot.value is Map) {
        Map<dynamic, dynamic> userData =
            userSnapshot.value as Map<dynamic, dynamic>;
        int currentPoints = userData['points'] as int? ?? 0;
        int newPoints = currentPoints + points;
        String username = userData['username'] as String? ?? 'User';

        // Update user points
        await userRef(uid).update({'points': newPoints});

        // Update leaderboard
        await leaderboardRef.child(uid).update({
          'username': username,
          'points': newPoints,
          'lastUpdated': ServerValue.timestamp,
        });
      }
    } catch (e) {
      print("Error updating user points: $e");
    }
  }

  // Get daily quiz questions (works with both legacy path and date-specific path)
  Future<List<Map<String, dynamic>>> getDailyQuizQuestions(
      [String? date]) async {
    try {
      // If date is provided, fetch from daily_quizzes/date
      if (date != null) {
        print('Fetching daily quiz questions for date: $date');
        DataSnapshot snapshot = await dailyQuizzesRef.child(date).get();

        if (!snapshot.exists || snapshot.value == null) {
          print('No quiz found for date: $date');
          return [];
        }

        // Check if snapshot value is a map
        if (snapshot.value is! Map) {
          print(
              'Unexpected data format for quiz: ${snapshot.value.runtimeType}');
          return [];
        }

        Map<dynamic, dynamic> quizData =
            snapshot.value as Map<dynamic, dynamic>;

        // Check if questions exist in the quiz data
        if (!quizData.containsKey('questions')) {
          print('Quiz exists but no questions found for date: $date');
          return [];
        }

        // Questions array
        List<dynamic> questionsRaw = quizData['questions'] as List<dynamic>;
        List<Map<String, dynamic>> questions = [];

        int questionNumber = 0;
        for (var question in questionsRaw) {
          if (question is Map) {
            // Process question with options if available
            Map<String, dynamic> questionMap =
                Map<String, dynamic>.from(question);

            // Generate options if not present
            if (!questionMap.containsKey('options')) {
              questionMap['options'] = [
                'Option A',
                'Option B',
                'Option C',
                'Option D'
              ];

              // Map correct_index to correctOption for compatibility
              if (questionMap.containsKey('correct_index')) {
                questionMap['correctOption'] = questionMap['correct_index'];
              } else {
                // Default to first option if no correct answer specified
                questionMap['correct_index'] = 0;
                questionMap['correctOption'] = 0;
              }
            }

            // Add question index for reference
            questionMap['id'] = questionNumber.toString();
            questions.add(questionMap);
            questionNumber++;
          }
        }

        print(
            'Successfully loaded ${questions.length} questions for date: $date');
        return questions;
      }

      // Legacy path - use the old method implementation
      else {
        DataSnapshot snapshot = await questionsRef
            .child('daily')
            .orderByChild('date')
            .limitToLast(10)
            .get();

        List<Map<String, dynamic>> questions = [];

        if (snapshot.exists && snapshot.value != null) {
          Map<dynamic, dynamic> values =
              snapshot.value as Map<dynamic, dynamic>;

          values.forEach((key, value) {
            if (value is Map) {
              Map<String, dynamic> question =
                  Map<String, dynamic>.from(value as Map);
              question['id'] = key;
              questions.add(question);
            }
          });
        }

        return questions;
      }
    } catch (e) {
      print('Error fetching daily quiz questions: $e');
      return [];
    }
  }

  // Get list of available daily quizzes
  Future<List<String>> getAvailableDailyQuizDates() async {
    try {
      DataSnapshot snapshot = await dailyQuizzesRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> quizzes = snapshot.value as Map<dynamic, dynamic>;
      List<String> dates = quizzes.keys.cast<String>().toList();

      // Sort dates in descending order (newest first)
      dates.sort((a, b) => b.compareTo(a));

      return dates;
    } catch (e) {
      print('Error fetching daily quiz dates: $e');
      return [];
    }
  }

  // Get most recent daily quiz
  Future<String?> getMostRecentDailyQuizDate() async {
    try {
      List<String> dates = await getAvailableDailyQuizDates();
      return dates.isNotEmpty ? dates.first : null;
    } catch (e) {
      print('Error getting most recent quiz date: $e');
      return null;
    }
  }

  // Get user classrooms
  Future<List<Map<String, dynamic>>> getUserClassrooms(String uid) async {
    DataSnapshot snapshot =
        await classroomsRef.orderByChild('members/$uid').equalTo(true).get();

    List<Map<String, dynamic>> classrooms = [];

    if (snapshot.exists && snapshot.value != null) {
      Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;

      values.forEach((key, value) {
        if (value is Map) {
          Map<String, dynamic> classroom =
              Map<String, dynamic>.from(value as Map);
          classroom['id'] = key;
          classrooms.add(classroom);
        }
      });
    }

    return classrooms;
  }

  // Join a classroom
  Future<void> joinClassroom(String uid, String classroomId) async {
    await classroomsRef
        .child(classroomId)
        .child('members')
        .child(uid)
        .set(true);
    await userRef(uid).child('classrooms').child(classroomId).set(true);
  }

  // Leave a classroom
  Future<void> leaveClassroom(String uid, String classroomId) async {
    await classroomsRef.child(classroomId).child('members').child(uid).remove();
    await userRef(uid).child('classrooms').child(classroomId).remove();
  }

  // Get leaderboard dates for a specific category
  Future<List<String>> getLeaderboardDatesForCategory(String category) async {
    try {
      DataSnapshot snapshot =
          await _databaseRef.child('leaderboards').child(category).get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      // Get dates from the leaderboard category
      Map<dynamic, dynamic> datesMap = snapshot.value as Map<dynamic, dynamic>;
      List<String> dates = datesMap.keys.cast<String>().toList();

      // Sort dates in descending order (newest first)
      dates.sort((a, b) => b.compareTo(a));

      return dates;
    } catch (e) {
      print('Error getting leaderboard dates: $e');
      return [];
    }
  }

  // Get leaderboard data for a specific date and category
  Future<List<Map<String, dynamic>>> getLeaderboardByDateAndCategory({
    required String category,
    required String date,
  }) async {
    try {
      DataSnapshot snapshot = await _databaseRef
          .child('leaderboards')
          .child(category)
          .child(date)
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> usersMap = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> leaderboardData = [];

      usersMap.forEach((userId, userData) {
        // Skip if userData is not a map
        if (userData is! Map) return;

        Map<String, dynamic> entry = Map<String, dynamic>.from(userData);
        // Add the userId to the entry for reference
        entry['userId'] = userId;

        // Ensure there's a score - default to 0
        if (!entry.containsKey('score')) {
          entry['score'] = 0;
        }

        leaderboardData.add(entry);
      });

      return leaderboardData;
    } catch (e) {
      print('Error getting leaderboard data: $e');
      return [];
    }
  }
}
