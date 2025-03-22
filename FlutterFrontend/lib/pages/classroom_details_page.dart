import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClassroomDetailsPage extends StatefulWidget {
  final String classroomId;

  const ClassroomDetailsPage({
    Key? key,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ClassroomDetailsPageState createState() => _ClassroomDetailsPageState();
}

class _ClassroomDetailsPageState extends State<ClassroomDetailsPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _classroomData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClassroomData();
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

  Widget _buildMaterialsList() {
    if (_classroomData == null || !_classroomData!.containsKey('materials')) {
      return const Center(child: Text('No materials available'));
    }

    final materials =
        Map<String, dynamic>.from(_classroomData!['materials'] as Map);
    if (materials.isEmpty) {
      return const Center(child: Text('No materials available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final materialId = materials.keys.elementAt(index);
        final material =
            Map<String, dynamic>.from(materials[materialId] as Map);

        final uploadedAt = DateTime.parse(material['uploaded_at'] as String);
        final formattedDate = DateFormat('MMM d, yyyy').format(uploadedAt);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(3, 3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.grey.shade800,
                offset: const Offset(-3, -3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ListTile(
            title: Text(material['title'] ?? 'Untitled Material'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(material['description'] ?? 'No description'),
                Text('Uploaded on: $formattedDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.download_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            onTap: () {
              // Handle material download or view
              if (material.containsKey('firebase_path')) {
                // Implement file download/view
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${material['title']}...'),
                  ),
                );
              }
            },
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

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: studentId == _auth.currentUser?.uid
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(student['username'][0].toUpperCase()),
            ),
            title: Text(student['username'] ?? 'Anonymous'),
            subtitle: Text('Joined on: $formattedDate'),
            trailing: studentId == _auth.currentUser?.uid
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Classroom'), elevation: 0),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(className),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(5, 5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.grey.shade800,
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
                    Text(
                      className,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text('Teacher: $teacherName'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[400], height: 1.5),
                    ),
                    if (_classroomData!.containsKey('join_code'))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            const Text('Join Code: '),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _classroomData!['join_code'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
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
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Learning Materials',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMaterialsList(),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.6),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildStudentsList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
