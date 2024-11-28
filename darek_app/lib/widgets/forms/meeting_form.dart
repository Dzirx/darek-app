import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/models/meeting.dart';

class ReminderOption {
  final String label;
  final Duration duration;

  const ReminderOption(this.label, this.duration);
}

class MeetingForm extends StatefulWidget {
  final Meeting? meeting;
  final Function(String, String, DateTime, bool, List<Duration>) onSubmit;
  final DateTime initialDate;
  
  const MeetingForm({
    Key? key,
    this.meeting,
    required this.onSubmit,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<MeetingForm> createState() => _MeetingFormState();
}

class _MeetingFormState extends State<MeetingForm> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late DateTime selectedDateTime;
  late TimeOfDay selectedTime;
  late bool hasReminder;
  List<Duration> selectedReminders = [const Duration(minutes: 30)];

  final List<ReminderOption> reminderOptions = const [
    ReminderOption('W czasie wydarzenia', Duration.zero),
    ReminderOption('5 minut przed', Duration(minutes: 5)),
    ReminderOption('10 minut przed', Duration(minutes: 10)),
    ReminderOption('15 minut przed', Duration(minutes: 15)),
    ReminderOption('30 minut przed', Duration(minutes: 30)),
    ReminderOption('1 godzina przed', Duration(hours: 1)),
    ReminderOption('2 godziny przed', Duration(hours: 2)),
    ReminderOption('1 dzień przed', Duration(days: 1)),
    ReminderOption('2 dni przed', Duration(days: 2)),
    ReminderOption('1 tydzień przed', Duration(days: 7)),
  ];

  @override
  void initState() {
    super.initState();
    final meeting = widget.meeting;
    titleController = TextEditingController(text: meeting?.title ?? '');
    descriptionController = TextEditingController(text: meeting?.description ?? '');
    selectedDateTime = meeting?.dateTime ?? widget.initialDate;
    selectedTime = TimeOfDay.fromDateTime(meeting?.dateTime ?? widget.initialDate);
    hasReminder = meeting?.hasReminder ?? true;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Tytuł spotkania',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 16),
        _buildDateTimePickers(),
        SwitchListTile(
          title: const Text('Przypomnienie'),
          value: hasReminder,
          onChanged: (value) => setState(() => hasReminder = value),
        ),
        if (hasReminder) _buildReminderSelector(),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Opis spotkania',
            prefixIcon: Icon(Icons.description),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () => widget.onSubmit(
                titleController.text,
                descriptionController.text,
                selectedDateTime,
                hasReminder,
                selectedReminders,
              ),
              child: Text(widget.meeting == null ? 'Dodaj' : 'Zapisz'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReminderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedReminders.map((duration) {
              final option = reminderOptions.firstWhere(
                (opt) => opt.duration == duration,
                orElse: () => ReminderOption('Niestandardowe', duration),
              );
              return Chip(
                label: Text(option.label),
                onDeleted: () {
                  setState(() {
                    selectedReminders.remove(duration);
                  });
                },
              );
            }).toList(),
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Dodaj przypomnienie'),
          onPressed: _showReminderPicker,
        ),
      ],
    );
  }

  void _showReminderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        children: reminderOptions
            .where((option) => !selectedReminders.contains(option.duration))
            .map((option) => ListTile(
                  title: Text(option.label),
                  onTap: () {
                    setState(() {
                      selectedReminders.add(option.duration);
                    });
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(DateFormat('dd.MM.yyyy').format(selectedDateTime)),
          onTap: () => _selectDate(context),
        ),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(selectedTime.format(context)),
          onTap: () => _selectTime(context),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (time != null) {
      setState(() {
        selectedTime = time;
        selectedDateTime = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }
}