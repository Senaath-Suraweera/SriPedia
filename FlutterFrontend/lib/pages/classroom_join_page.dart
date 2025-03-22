import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ClassroomJoinPage extends StatefulWidget {
  const ClassroomJoinPage({Key? key}) : super(key: key);

  @override
  _ClassroomJoinPageState createState() => _ClassroomJoinPageState();
}

class _ClassroomJoinPageState extends State<ClassroomJoinPage> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isCodeValid = false;
  bool _isJoining = false;
  bool _hasJoined = false;
  String? _errorMessage;
  Map<String, dynamic>? _classroomData;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode(String code) async {
    if (code.length != 8) {
      setState(() {
        _isCodeValid = false;
        _errorMessage = "Join code must be 8 characters";
        _classroomData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Instead of querying with orderByChild, get all classrooms and filter in code
      // This approach doesn't require an index on join_code
      final snapshot = await _database.ref('classrooms').get();

      if (snapshot.exists) {
        final allClassrooms = Map<String, dynamic>.from(snapshot.value as Map);
        String? matchingClassroomId;
        Map<String, dynamic>? matchingClassroom;

        // Find the classroom with the matching join code
        allClassrooms.forEach((classroomId, classroomValue) {
          final classroom = Map<String, dynamic>.from(classroomValue as Map);
          if (classroom['join_code'] == code.toUpperCase()) {
            matchingClassroomId = classroomId;
            matchingClassroom = classroom;
          }
        });

        if (matchingClassroomId != null && matchingClassroom != null) {
          // Add the ID to the classroom data
          matchingClassroom!['id'] = matchingClassroomId;

          // Check if user is already a student in this classroom
          final currentUserId = _auth.currentUser?.uid;
          if (currentUserId != null &&
              matchingClassroom!.containsKey('students') &&
              matchingClassroom!['students'] is Map &&
              (matchingClassroom!['students'] as Map)
                  .containsKey(currentUserId)) {
            setState(() {
              _isCodeValid = true;
              _hasJoined = true;
              _classroomData = matchingClassroom;
              _errorMessage = "You are already a member of this classroom.";
            });
          } else {
            setState(() {
              _isCodeValid = true;
              _hasJoined = false;
              _classroomData = matchingClassroom;
              _errorMessage = null;
            });
          }
        } else {
          setState(() {
            _isCodeValid = false;
            _classroomData = null;
            _errorMessage = "Invalid classroom code";
          });
        }
      } else {
        setState(() {
          _isCodeValid = false;
          _classroomData = null;
          _errorMessage = "No classrooms found";
        });
      }
    } catch (e) {
      setState(() {
        _isCodeValid = false;
        _classroomData = null;
        _errorMessage = "Error validating code: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinClassroom() async {
    if (_classroomData == null || _hasJoined) return;

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _auth.currentUser;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.user;

      if (currentUser == null || userData == null) {
        setState(() {
          _errorMessage = "User not authenticated";
        });
        return;
      }

      final classroomId = _classroomData!['id'];
      final studentData = {
        'id': currentUser.uid,
        'username': userData.username,
        'joined_at': DateTime.now().toUtc().toString(),
      };

      // Add the student to the classroom's students list
      await _database
          .ref('classrooms/$classroomId/students/${currentUser.uid}')
          .set(studentData);

      setState(() {
        _hasJoined = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the classroom!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error joining classroom: $e";
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Classroom'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the 8-digit classroom code to join',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Classroom Code',
                hintText: 'Enter 8-digit code',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              maxLength: 8,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                if (value.length == 8) {
                  _validateCode(value);
                } else {
                  setState(() {
                    _isCodeValid = false;
                    _classroomData = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_classroomData != null && _isCodeValid)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _classroomData!['name'] ?? 'Unnamed Classroom',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _classroomData!['description'] ?? 'No description',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Teacher: ${_classroomData!['teacher_name'] ?? 'Unknown'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (!_hasJoined)
                        ElevatedButton(
                          onPressed: _isJoining ? null : _joinClassroom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isJoining
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Join Classroom'),
                        )
                      else
                        const Text(
                          'You have joined this classroom',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
