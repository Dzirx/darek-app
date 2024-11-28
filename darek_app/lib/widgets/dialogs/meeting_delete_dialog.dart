import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../database/models/meeting.dart';
import '../../utils/meeting_handlers.dart';

class MeetingDeleteDialog {
  static Future<bool?> show(
    BuildContext context,
    Meeting meeting,
    DatabaseHelper dbHelper
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć spotkanie?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Czy na pewno chcesz usunąć spotkanie:'),
              const SizedBox(height: 8),
              Text(
                meeting.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Data: ${DateFormat('dd.MM.yyyy HH:mm').format(meeting.dateTime)}',
              ),
              if (meeting.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Opis: ${meeting.description}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => MeetingHandlers.handleDelete(context, meeting, dbHelper),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }
}
