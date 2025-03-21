class UserModel {
  final String uid;
  final String email;
  final String username;
  final String role;
  final int points;
  final int level;
  final int xp;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    this.points = 0,
    this.level = 1,
    this.xp = 0,
  });

  // Create UserModel from Firebase user data
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      role: data['role'] ?? 'Student',
      points: data['points'] ?? 0,
      level: data['level'] ?? 1,
      xp: data['xp'] ?? 0,
    );
  }

  // Convert UserModel to map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'points': points,
      'level': level,
      'xp': xp,
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? role,
    int? points,
    int? level,
    int? xp,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      points: points ?? this.points,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }
}
