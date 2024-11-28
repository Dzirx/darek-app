import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/models/meeting.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MeetingCard({
    Key? key,
    required this.meeting,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUpcoming = meeting.dateTime.isAfter(DateTime.now());
    final isPast = meeting.dateTime.isBefore(
      DateTime.now().subtract(const Duration(hours: 1))
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isPast ? Colors.grey[100] : 
             isUpcoming ? Colors.blue[50] : Colors.white,
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('HH:mm').format(meeting.dateTime),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPast ? Colors.grey : Colors.black,
              ),
            ),
            if (meeting.hasReminder)
              Icon(
                Icons.notifications_active, 
                size: 16, 
                color: isPast ? Colors.grey : Colors.orange
              ),
          ],
        ),
        title: Text(
          meeting.title,
          style: TextStyle(
            decoration: isPast ? TextDecoration.lineThrough : null,
            color: isPast ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: meeting.description.isNotEmpty
          ? Text(
              meeting.description,
              style: TextStyle(color: isPast ? Colors.grey : null),
            )
          : null,
        trailing: isUpcoming ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ) : null,
      ),
    );
  }
}