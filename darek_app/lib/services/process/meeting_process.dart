import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../database/models/meeting.dart';

class MeetingProcess {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

Future<void> add(Map<String, dynamic> params, int userId) async {
  try {
    print('Adding meeting with params: $params'); // Dodane logowanie
    
    // Walidacja parametrów
    if (params['date'] == null) {
      throw ArgumentError('Date is required');
    }
    
    DateTime dateTime;
    try {
      // Bezpieczne parsowanie daty
      final date = params['date'].toString();
      final time = params['time']?.toString() ?? '12:00';
      dateTime = DateTime.parse('$date $time');
    } catch (e) {
      print('Error parsing date: $e');
      // Użyj jutra jako daty domyślnej
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      dateTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0);
    }
    
    String title;
    if (params['client'] != null && params['client'].toString().isNotEmpty) {
      title = 'Spotkanie z ${params['client']}';
    } else {
      title = 'Spotkanie';
    }
    
    final meeting = Meeting(
      title: title,
      description: params['description']?.toString() ?? '',
      dateTime: dateTime,
      userId: userId,
      hasReminder: true,
      reminderTimes: [const Duration(minutes: 30)],
    );
    
    print('Creating meeting: ${meeting.title} at ${meeting.dateTime}'); // Dodane logowanie
    await _dbHelper.createMeeting(meeting);
  } catch (e) {
    print('Error in MeetingProcess.add: $e');
    throw Exception('Failed to add meeting: $e');
  }
}

  Future<void> delete(Map<String, dynamic> params, int userId) async {
    try {
      final requestedDate = DateTime.parse(params['date']);
      final requestedTime = params['time']?.split(':') ?? [];
      final meetings = await _dbHelper.getMeetingsForDay(requestedDate, userId);
      
      if (requestedTime.length == 2) {
        final targetHour = int.parse(requestedTime[0]);
        final targetMinute = int.parse(requestedTime[1]);
        
        final matchingMeetings = meetings.where((meeting) => 
          meeting.dateTime.hour == targetHour && 
          meeting.dateTime.minute == targetMinute
        ).toList();
        
        if (matchingMeetings.isNotEmpty) {
          await _dbHelper.deleteMeeting(matchingMeetings.first.id!);
        }
      }
    } catch (e) {
      print('Error deleting meeting: $e');
      rethrow;
    }
  }

  Future<String?> check(Map<String, dynamic> params, int userId) async {
    try {
      final date = DateTime.parse(params['date']);
      final meetings = await _dbHelper.getMeetingsForDay(date, userId);
      
      if (meetings.isEmpty) {
        return 'Nie masz zaplanowanych spotkań na ten dzień.';
      }

      final formatter = DateFormat('HH:mm');
      String response = 'Oto twoje spotkania:\n';
      
      for (var meeting in meetings) {
        response += '- O ${formatter.format(meeting.dateTime)}: ${meeting.title}';
        if (meeting.description.isNotEmpty) {
          response += ', ${meeting.description}';
        }
        response += '\n';
      }
      
      return response;
    } catch (e) {
      print('Error checking meetings: $e');
      return null;
    }
  }
}