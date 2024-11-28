import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../database/models/meeting.dart';
import '../../utils/meeting_handlers.dart';
import '../forms/meeting_form.dart';

class MeetingEditDialog {
  static Future<bool?> show(
    BuildContext context,
    Meeting meeting,
    int userId,
    DatabaseHelper dbHelper
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj spotkanie'),
        content: SingleChildScrollView(
          child: MeetingForm(
            meeting: meeting,
            initialDate: meeting.dateTime,
            onSubmit: (title, description, dateTime, hasReminder, reminders) =>
              MeetingHandlers.handleEdit(
                context,
                meeting,
                title,
                description,
                dateTime,
                hasReminder,
                reminders,
                userId,
                dbHelper,
              ),
          ),
        ),
      ),
    );
  }
}
