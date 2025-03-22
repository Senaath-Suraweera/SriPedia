import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import
import '../providers/user_provider.dart'; // Add this import
import '../main.dart'; // Import for AppTheme

class MyClassroomsPage extends StatefulWidget {
  const MyClassroomsPage({Key? key}) : super(key: key);

  @override
  _MyClassroomsPageState createState() => _MyClassroomsPageState();
}

class _MyClassroomsPageState extends State<MyClassroomsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _classrooms = [];
  String? _errorMessage;

  // Add animation controller for gamified effects
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when the page is revisited
    final userProvider = Provider.of<UserProvider>(context);
    if (!_isLoading && userProvider.user != null) {
      _loadClassrooms();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    if (_auth.currentUser == null) {
      setState(() {
        _errorMessage = "You need to be logged in to view your classrooms";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _auth.currentUser!.uid;
      final classroomsSnapshot = await _database.ref('classrooms').get();

      if (!classroomsSnapshot.exists) {
        setState(() {
          _classrooms = [];
          _isLoading = false;
        });
        return;
      }

      final classroomsData =
          Map<String, dynamic>.from(classroomsSnapshot.value as Map);
      List<Map<String, dynamic>> userClassrooms = [];

      classroomsData.forEach((classroomId, classroomData) {
        final classroom = Map<String, dynamic>.from(classroomData as Map);
        classroom['id'] = classroomId;

        // Check if the user is a student in this classroom
        if (classroom.containsKey('students') &&
            classroom['students'] is Map &&
            (classroom['students'] as Map).containsKey(userId)) {
          userClassrooms.add(classroom);
        }

        // Check if the user is the teacher of this classroom
        if (classroom['teacher_id'] == userId) {
          classroom['isTeacher'] = true;
          userClassrooms.add(classroom);
        }
      });

      setState(() {
        _classrooms = userClassrooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading classrooms: $e";
        _isLoading = false;
      });
    }
  }

  // Get an icon based on classroom subject/type
  IconData _getClassroomIcon(Map<String, dynamic> classroom) {
    final name = classroom['name']?.toString().toLowerCase() ?? '';

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
    } else if (name.contains('art') || name.contains('drawing')) {
      return FontAwesomeIcons.paintbrush;
    } else if (name.contains('music')) {
      return FontAwesomeIcons.music;
    } else if (name.contains('physics')) {
      return FontAwesomeIcons.atom;
    } else {
      return FontAwesomeIcons.graduationCap;
    }
  }

  Widget _buildClassroomCard(Map<String, dynamic> classroom, bool isTeacher) {
    final icon = _getClassroomIcon(classroom);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/classroom_details',
              arguments: classroom['id'],
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        icon,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classroom['name'] ?? 'Unnamed Classroom',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isTeacher ? Icons.stars : Icons.person,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTeacher
                                    ? 'You teach this class'
                                    : 'You\'re a student',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isTeacher)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              'Teacher',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  classroom['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.primaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated, otherwise show login prompt
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Classrooms'),
          elevation: 0,
          backgroundColor: AppTheme.cardColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to log in to access classrooms'),
              const SizedBox(height: 16),
              Container(
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
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                  child: const Text('Log In'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.userGraduate, size: 18),
            const SizedBox(width: 10),
            const Text('My Classrooms'),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClassrooms, // Add refresh button
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/join_classroom')
                  .then((_) => _loadClassrooms()); // Reload after joining
            },
            tooltip: 'Join Classroom',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _classrooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.bookOpen,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          const Text("You haven't joined any classrooms yet."),
                          const SizedBox(height: 16),
                          Container(
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
                              onPressed: () {
                                Navigator.pushNamed(context, '/join_classroom');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                              ),
                              child: const Text('Join a Classroom'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _classrooms.length,
                      itemBuilder: (context, index) {
                        final classroom = _classrooms[index];
                        final isTeacher = classroom['isTeacher'] == true;

                        return _buildClassroomCard(classroom, isTeacher);
                      },
                    ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: AppTheme.buttonColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowDark(context),
              offset: const Offset(2, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/join_classroom');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const FaIcon(FontAwesomeIcons.plus),
          tooltip: 'Join a Classroom',
        ),
      ),
    );
  }
}
