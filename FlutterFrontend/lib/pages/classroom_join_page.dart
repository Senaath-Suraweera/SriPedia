import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import '../providers/user_provider.dart';
import '../main.dart'; // Import for AppTheme

class ClassroomJoinPage extends StatefulWidget {
  const ClassroomJoinPage({Key? key}) : super(key: key);

  @override
  _ClassroomJoinPageState createState() => _ClassroomJoinPageState();
}

class _ClassroomJoinPageState extends State<ClassroomJoinPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isCodeValid = false;
  bool _isJoining = false;
  bool _hasJoined = false;
  String? _errorMessage;
  Map<String, dynamic>? _classroomData;

  // Add animation controller for gamified effects
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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

      // Show celebration instead of simple snackbar
      _showCelebration();

      // Animate the card
      _controller.reset();
      _controller.forward();
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

  // Celebration effect when joining successfully
  void _showCelebration() {
    // This would be enhanced with a confetti package in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Successfully joined the classroom!'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.rightToBracket, size: 16),
            SizedBox(width: 10),
            Text('Join Classroom'),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.cardColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                FaIcon(FontAwesomeIcons.circleInfo, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter the 8-digit classroom code to join',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Add a fun "code entry" widget with individual boxes for a game-like feel
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.cardColor, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Classroom Code',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'Enter 8-digit code',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12.0, right: 8.0),
                      child: FaIcon(FontAwesomeIcons.key,
                          size: 18, color: Colors.amber),
                    ),
                    border: InputBorder.none,
                    errorText: _errorMessage,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 3.0,
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
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Searching for classroom...",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            if (_classroomData != null && _isCodeValid)
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowDark(context),
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: AppTheme.shadowLight(context),
                          offset: const Offset(-4, -4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Add a classroom icon based on name
                              Transform.rotate(
                                angle: math.pi / 30, // Slight tilt for fun
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getClassroomIcon(
                                        _classroomData!['name'] ?? ''),
                                    color: AppTheme.primaryColor,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _classroomData!['name'] ??
                                          'Unnamed Classroom',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.school,
                                            size: 14, color: Colors.amber),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Teacher: ${_classroomData!['teacher_name'] ?? 'Unknown'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black26),
                            ),
                            child: Text(
                              _classroomData!['description'] ??
                                  'No description',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),

                          // Stats section - gamified element
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                  'Students',
                                  _getStudentCount(_classroomData!),
                                  FontAwesomeIcons.userGroup),
                              _buildStatItem(
                                  'Materials',
                                  _getMaterialsCount(_classroomData!),
                                  FontAwesomeIcons.book),
                              _buildStatItem(
                                  'Created',
                                  _getClassroomAge(_classroomData!),
                                  FontAwesomeIcons.calendarDays),
                            ],
                          ),

                          const SizedBox(height: 24),
                          if (!_hasJoined)
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.buttonColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.shadowDark(context),
                                    offset: const Offset(2, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isJoining ? null : _joinClassroom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isJoining
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text('Joining...'),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const FaIcon(
                                              FontAwesomeIcons.rightToBracket,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Join Classroom',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.green.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'You have joined this classroom',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // When no classroom is displayed yet, show a fun hint
            if (_classroomData == null && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: -math.pi / 20,
                        child: const FaIcon(
                          FontAwesomeIcons.magnifyingGlass,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Enter an 8-digit code to find your classroom',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Example: ABCD1234',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Courier',
                          letterSpacing: 2,
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

  // Helper methods for gamified elements

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.buttonColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            icon,
            size: 16,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  IconData _getClassroomIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('math') || name.contains('maths')) {
      return FontAwesomeIcons.squareRootVariable;
    } else if (name.contains('science') || name.contains('biology')) {
      return FontAwesomeIcons.flask;
    } else if (name.contains('computer') || name.contains('programming')) {
      return FontAwesomeIcons.laptopCode;
    } else if (name.contains('history')) {
      return FontAwesomeIcons.bookOpen;
    } else if (name.contains('language') || name.contains('english')) {
      return FontAwesomeIcons.language;
    } else {
      return FontAwesomeIcons.graduationCap;
    }
  }

  String _getStudentCount(Map<String, dynamic> classroom) {
    if (!classroom.containsKey('students')) return '0';
    final students = classroom['students'] as Map?;
    return students == null ? '0' : students.length.toString();
  }

  String _getMaterialsCount(Map<String, dynamic> classroom) {
    if (!classroom.containsKey('materials')) return '0';
    final materials = classroom['materials'] as Map?;
    return materials == null ? '0' : materials.length.toString();
  }

  String _getClassroomAge(Map<String, dynamic> classroom) {
    if (!classroom.containsKey('created_at')) return 'New';
    try {
      final createdAt = DateTime.parse(classroom['created_at']);
      final days = DateTime.now().difference(createdAt).inDays;
      if (days == 0) return 'Today';
      if (days == 1) return '1 day';
      if (days < 7) return '$days days';
      if (days < 30) return '${(days / 7).floor()} wk';
      if (days < 365) return '${(days / 30).floor()} mo';
      return '${(days / 365).floor()} yr';
    } catch (e) {
      return 'New';
    }
  }
}
