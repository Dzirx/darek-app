import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';

class MeetingHandlers {
  static Future<void> handleAdd(
    BuildContext context,
    String title,
    String description,
    DateTime dateTime,
    bool hasReminder,
    List<Duration> reminders,
    int userId,
    DatabaseHelper dbHelper,
  ) async {
    if (title.isEmpty) {
      _showErrorSnackBar(context, 'Proszę podać tytuł spotkania');
      return;
    }

    final meeting = Meeting(
      title: title,
      description: description,
      dateTime: dateTime,
      hasReminder: hasReminder,
      reminderTimes: reminders,
      userId: userId,
    );

    await dbHelper.createMeeting(meeting);
    if (!context.mounted) return;
    
    Navigator.pop(context, true);
    _showSuccessSnackBar(context, 'Spotkanie zostało dodane');
  }

  static Future<void> handleEdit(
    BuildContext context,
    Meeting originalMeeting,
    String title,
    String description,
    DateTime dateTime,
    bool hasReminder,
    List<Duration> reminders,
    int userId,
    DatabaseHelper dbHelper,
  ) async {
    if (title.isEmpty) {
      _showErrorSnackBar(context, 'Proszę podać tytuł spotkania');
      return;
    }

    final updatedMeeting = Meeting(
      id: originalMeeting.id,
      title: title,
      description: description,
      dateTime: dateTime,
      hasReminder: hasReminder,
      reminderTimes: reminders,
      userId: userId,
    );

    await dbHelper.updateMeeting(updatedMeeting);
    if (!context.mounted) return;
    
    Navigator.pop(context, true);
    _showSuccessSnackBar(context, 'Spotkanie zostało zaktualizowane');
  }

  static Future<void> handleDelete(
    BuildContext context,
    Meeting meeting,
    DatabaseHelper dbHelper,
  ) async {
    try {
      await dbHelper.deleteMeeting(meeting.id!);
      if (!context.mounted) return;
      
      Navigator.pop(context, true);
      _showSuccessSnackBar(context, 'Spotkanie zostało usunięte');
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, 'Błąd podczas usuwania spotkania: $e');
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}