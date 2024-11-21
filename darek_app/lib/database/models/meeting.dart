// lib/models/meeting.dart
class Meeting {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool hasReminder;
  final int userId;

  Meeting({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.hasReminder = true,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'hasReminder': hasReminder ? 1 : 0,
      'userId': userId,
    };
  }

  static Meeting fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
      hasReminder: map['hasReminder'] == 1,
      userId: map['userId'],
    );
  }
}
