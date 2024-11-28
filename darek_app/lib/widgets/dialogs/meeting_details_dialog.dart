import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/models/meeting.dart';

class MeetingDetailsDialog {
  static void show(BuildContext context, Meeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szczegóły spotkania'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tytuł: ${meeting.title}'),
            const SizedBox(height: 8),
            Text('Data: ${DateFormat('dd.MM.yyyy HH:mm').format(meeting.dateTime)}'),
            const SizedBox(height: 8),
            if (meeting.description.isNotEmpty)
              Text('Opis: ${meeting.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}

