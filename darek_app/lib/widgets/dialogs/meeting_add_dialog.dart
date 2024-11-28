import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../utils/meeting_handlers.dart';
import '../forms/meeting_form.dart';

class MeetingAddDialog {
  static Future<bool?> show(BuildContext context, DateTime selectedDate, int userId, DatabaseHelper dbHelper) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: const Text('Dodaj spotkanie'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                automaticallyImplyLeading: false,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MeetingForm(
                    initialDate: selectedDate,
                    onSubmit: (title, description, dateTime, hasReminder, reminders) => 
                      MeetingHandlers.handleAdd(
                        context,
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
            ],
          ),
        ),
      ),
    );
  }
}