import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import '../main.dart'; // Import for AppTheme

class ClassroomDetailsPage extends StatefulWidget {
  final String classroomId;

  const ClassroomDetailsPage({
    Key? key,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ClassroomDetailsPageState createState() => _ClassroomDetailsPageState();
}

class _ClassroomDetailsPageState extends State<ClassroomDetailsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _classroomData;
  String? _errorMessage;

  // Add animation controller for gamified effects
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadClassroomData();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadClassroomData() async {
    try {
      final snapshot =
          await _database.ref('classrooms/${widget.classroomId}').get();

      if (snapshot.exists) {
        setState(() {
          _classroomData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Classroom not found";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading classroom data: $e";
        _isLoading = false;
      });
    }
  }

  // Get an icon based on material type
  IconData _getMaterialIcon(Map<String, dynamic> material) {
    final title = material['title']?.toString().toLowerCase() ?? '';

    if (title.contains('assignment') || title.contains('homework')) {
      return FontAwesomeIcons.fileLines;
    } else if (title.contains('pdf') || title.contains('document')) {
      return FontAwesomeIcons.filePdf;
    } else if (title.contains('video') || title.contains('watch')) {
      return FontAwesomeIcons.video;
    } else if (title.contains('quiz') || title.contains('test')) {
      return FontAwesomeIcons.clipboardQuestion;
    } else if (title.contains('reading') || title.contains('book')) {
      return FontAwesomeIcons.bookOpen;
    } else if (title.contains('presentation') || title.contains('slides')) {
      return FontAwesomeIcons.display;
    } else {
      return FontAwesomeIcons.fileCode;
    }
  }

  Widget _buildMaterialsList() {
    if (_classroomData == null || !_classroomData!.containsKey('materials')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.folderOpen,
              size: 40,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            const Text('No materials available'),
          ],
        ),
      );
    }

    final materials =
        Map<String, dynamic>.from(_classroomData!['materials'] as Map);
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.folderOpen,
              size: 40,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            const Text('No materials available'),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final materialId = materials.keys.elementAt(index);
        final material =
            Map<String, dynamic>.from(materials[materialId] as Map);
        final icon = _getMaterialIcon(material);
        final uploadedAt = DateTime.parse(material['uploaded_at'] as String);
        final formattedDate = DateFormat('MMM d, yyyy').format(uploadedAt);

        // Add a small staggered animation effect
        final itemAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animation,
          curve: Interval(
            0.1 + (index / materials.length * 0.8),
            0.3 + (index / materials.length * 0.7),
            curve: Curves.easeOutCubic,
          ),
        ));

        return SlideTransition(
          position: itemAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark(context),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppTheme.shadowLight(context),
                  offset: const Offset(-3, -3),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      material['title'] ?? 'Untitled Material',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Add a "NEW" badge for recently added materials
                  if (DateTime.now().difference(uploadedAt).inDays < 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(material['description'] ?? 'No description'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Uploaded on: $formattedDate',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppTheme.buttonColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowDark(context).withOpacity(0.2),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Handle material download or view
                      if (material.containsKey('firebase_path')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.download_rounded,
                                    color: Colors.white),
                                const SizedBox(width: 10),
                                Text('Downloading ${material['title']}...'),
                              ],
                            ),
                            action: SnackBarAction(
                              label: 'CANCEL',
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    },
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.download,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentsList() {
    if (_classroomData == null || !_classroomData!.containsKey('students')) {
      return const Center(child: Text('No students enrolled'));
    }

    final students =
        Map<String, dynamic>.from(_classroomData!['students'] as Map);
    if (students.isEmpty) {
      return const Center(child: Text('No students enrolled'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final studentId = students.keys.elementAt(index);
        final student = Map<String, dynamic>.from(students[studentId] as Map);

        final joinedAt = DateTime.parse(student['joined_at'] as String);
        final formattedDate = DateFormat('MMM d, yyyy').format(joinedAt);

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _animation,
            curve: Interval(
              0.3 + (index / students.length * 0.6),
              0.6 + (index / students.length * 0.4),
              curve: Curves.easeIn,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: studentId == _auth.currentUser?.uid
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowDark(context),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(student['username'][0].toUpperCase()),
                  ),
                  if (studentId == _auth.currentUser?.uid)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.cardColor,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(student['username'] ?? 'Anonymous'),
              subtitle: Text('Joined on: $formattedDate'),
              trailing: studentId == _auth.currentUser?.uid
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Classroom'),
            elevation: 0,
            backgroundColor: AppTheme.cardColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Classroom'), elevation: 0),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    final className = _classroomData?['name'] ?? 'Untitled Classroom';
    final teacherName = _classroomData?['teacher_name'] ?? 'Unknown Teacher';
    final description =
        _classroomData?['description'] ?? 'No description available';

    // Get classroom icon based on name
    IconData classIcon = FontAwesomeIcons.graduationCap;
    final name = className.toLowerCase();
    if (name.contains('math')) {
      classIcon = FontAwesomeIcons.squareRootVariable;
    } else if (name.contains('science')) {
      classIcon = FontAwesomeIcons.flask;
    } else if (name.contains('computer')) {
      classIcon = FontAwesomeIcons.laptopCode;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(classIcon, size: 16),
            const SizedBox(width: 8),
            Text(className),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.cardColor,
        actions: [
          IconButton(
            icon: Transform.rotate(
              angle: math.pi / 8,
              child: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 20),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Study tips coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Study Tips',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowDark(context),
                      offset: const Offset(5, 5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppTheme.shadowLight(context),
                      offset: const Offset(-5, -5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FaIcon(
                              classIcon,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  className,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Teacher: $teacherName'),
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
                          color: AppTheme.buttonColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.quoteLeft,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                description,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const FaIcon(
                              FontAwesomeIcons.quoteRight,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      if (_classroomData!.containsKey('join_code'))
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.key,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              const Text('Join Code: '),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _classroomData!['join_code'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Courier',
                                        letterSpacing: 1.5,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        // Copy to clipboard logic would go here
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Code copied to clipboard!'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.buttonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.book,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Learning Materials',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildMaterialsList(),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.buttonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.userGroup,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildStudentsList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
