// lib/models/user.dart
class User {
  final int? id;
  final String username;
  final String hashedPassword;
  final String role;

  User({
    this.id,
    required this.username,
    required this.hashedPassword,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': hashedPassword,
      'role': role,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      hashedPassword: map['password'],
      role: map['role'],
    );
  }

  // Pomocnicze gettery
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';
}