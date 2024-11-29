import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../database/models/meeting.dart';
import '../../database/models/client.dart';
import '../../database/models/client_note.dart';

class ContextProcess {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> buildContext(int userId) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));
    final startDate = now.subtract(const Duration(days: 30));

    final meetings = await _dbHelper.getMeetingsForPeriod(
      userId, 
      startDate,
      endDate,
    );

    final clients = await _dbHelper.getRecentClients(userId);
    final notes = await _dbHelper.getRecentNotes(userId);
    final formatter = DateFormat('dd.MM.yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return {
      'current_time': now.toIso8601String(),
      'meetings': meetings.map((m) => {
        'title': m.title,
        'dateTime': m.dateTime.toIso8601String(),
        'description': m.description,
        'formatted_date': formatter.format(m.dateTime),
        'formatted_time': timeFormatter.format(m.dateTime),
      }).toList(),
      
      'clients': clients.map((c) => {
        'name': c.name,
        'company': c.company,
        'category': c.category.toString(),
        'full_name': c.company != null ? '${c.name} (${c.company})' : c.name,
      }).toList(),
      
      'notes': notes.map((n) => {
        'client': clients.firstWhere((c) => c.id == n.clientId).name,
        'content': n.content,
        'type': n.type.toString(),
        'createdAt': n.createdAt.toIso8601String(),
        'formatted_date': formatter.format(n.createdAt),
      }).toList(),
    };
  }
}