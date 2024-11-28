import 'dart:convert';
class Meeting {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool hasReminder;
  final List<Duration> reminderTimes;
  final int userId;

  Meeting({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.hasReminder = true,
    this.reminderTimes = const [Duration(minutes: 30)],
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'hasReminder': hasReminder ? 1 : 0,
      'reminderTimes': jsonEncode(reminderTimes.map((d) => d.inMinutes).toList()),
      'userId': userId,
    };
  }

  static Meeting fromMap(Map<String, dynamic> map) {
    final reminderMinutes = (jsonDecode(map['reminderTimes'] ?? '[30]') as List)
        .map((minutes) => Duration(minutes: minutes as int))
        .toList();

    return Meeting(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
      hasReminder: map['hasReminder'] == 1,
      reminderTimes: reminderMinutes,
      userId: map['userId'],
    );
  }
}
enum ReminderTime {
  none,
  atTime,
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  oneDay,
  twoDays,
  oneWeek;

  Duration get duration {
    switch (this) {
      case ReminderTime.none: return Duration.zero;
      case ReminderTime.atTime: return Duration.zero;
      case ReminderTime.fiveMinutes: return const Duration(minutes: 5);
      case ReminderTime.tenMinutes: return const Duration(minutes: 10);
      case ReminderTime.fifteenMinutes: return const Duration(minutes: 15);
      case ReminderTime.thirtyMinutes: return const Duration(minutes: 30);
      case ReminderTime.oneHour: return const Duration(hours: 1);
      case ReminderTime.twoHours: return const Duration(hours: 2);
      case ReminderTime.oneDay: return const Duration(days: 1);
      case ReminderTime.twoDays: return const Duration(days: 2);
      case ReminderTime.oneWeek: return const Duration(days: 7);
    }
  }

  String get displayName {
    switch (this) {
      case ReminderTime.none: return 'Brak';
      case ReminderTime.atTime: return 'W czasie wydarzenia';
      case ReminderTime.fiveMinutes: return '5 minut przed';
      case ReminderTime.tenMinutes: return '10 minut przed';
      case ReminderTime.fifteenMinutes: return '15 minut przed';
      case ReminderTime.thirtyMinutes: return '30 minut przed';
      case ReminderTime.oneHour: return '1 godzina przed';
      case ReminderTime.twoHours: return '2 godziny przed';
      case ReminderTime.oneDay: return '1 dzień przed';
      case ReminderTime.twoDays: return '2 dni przed';
      case ReminderTime.oneWeek: return '1 tydzień przed';
    }
  }
}
