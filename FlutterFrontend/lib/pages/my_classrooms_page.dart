import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Add this import
import '../providers/user_provider.dart'; // Add this import

class MyClassroomsPage extends StatefulWidget {
  const MyClassroomsPage({Key? key}) : super(key: key);

  @override
  _MyClassroomsPageState createState() => _MyClassroomsPageState();
}

class _MyClassroomsPageState extends State<MyClassroomsPage> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _classrooms = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
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

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated, otherwise show login prompt
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Classrooms'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to log in to access classrooms'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classrooms'),
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
                          const Text("You haven't joined any classrooms yet."),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/join_classroom');
                            },
                            child: const Text('Join a Classroom'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _classrooms.length,
                      itemBuilder: (context, index) {
                        final classroom = _classrooms[index];
                        final isTeacher = classroom['isTeacher'] == true;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title:
                                Text(classroom['name'] ?? 'Unnamed Classroom'),
                            subtitle: Text(
                                classroom['description'] ?? 'No description'),
                            trailing: isTeacher
                                ? const Chip(
                                    label: Text('Teacher'),
                                    backgroundColor: Colors.blue,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/classroom_details',
                                arguments: classroom['id'],
                              );
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/join_classroom');
        },
        child: const Icon(Icons.add),
        tooltip: 'Join a Classroom',
      ),
    );
  }
}
