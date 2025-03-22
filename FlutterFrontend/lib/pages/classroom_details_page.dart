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

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
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
            trailing: const Icon(Icons.download_rounded),
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

        return ListTile(
          leading: CircleAvatar(
            child: Text(student['username'][0].toUpperCase()),
          ),
          title: Text(student['username'] ?? 'Anonymous'),
          subtitle: Text('Joined on: $formattedDate'),
          trailing: studentId == _auth.currentUser?.uid
              ? const Chip(label: Text('You'), backgroundColor: Colors.green)
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Classroom')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Classroom')),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Teacher: $teacherName'),
                    const SizedBox(height: 8),
                    Text(description),
                    if (_classroomData!.containsKey('join_code'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Text('Join Code: '),
                            Chip(
                              label: Text(
                                _classroomData!['join_code'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Learning Materials',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildMaterialsList(),
            const SizedBox(height: 24),
            const Text(
              'Students',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStudentsList(),
          ],
        ),
      ),
    );
  }
}
