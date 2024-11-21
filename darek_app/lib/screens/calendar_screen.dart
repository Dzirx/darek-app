import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';

class CalendarScreen extends StatefulWidget {
  final int userId;
  
  const CalendarScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<Meeting>> _meetings;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _meetings = {};
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final monthMeetings = await _dbHelper.getMeetingsForMonth(
        widget.userId,
        _focusedDay.year,
        _focusedDay.month,
      );
      
      setState(() {
        _meetings = {};
        for (var meeting in monthMeetings) {
          final day = DateTime(
            meeting.dateTime.year,
            meeting.dateTime.month,
            meeting.dateTime.day,
          );
          if (_meetings[day] == null) {
            _meetings[day] = [];
          }
          _meetings[day]!.add(meeting);
        }
      });
    } catch (e) {
      print('Error loading meetings: $e');
    }
  }

  List<Meeting> _getMeetingsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _meetings[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendarz spotkań'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMeetingDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadMeetings();
            },
            eventLoader: _getMeetingsForDay,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Meeting>>(
              future: _dbHelper.getMeetingsForDay(_selectedDay, widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Błąd: ${snapshot.error}'),
                  );
                }
                
                final meetings = snapshot.data ?? [];
                
                if (meetings.isEmpty) {
                  return const Center(
                    child: Text('Brak spotkań na wybrany dzień'),
                  );
                }

                return ListView.builder(
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(meeting.title),
                        subtitle: Text(meeting.description),
                        trailing: Text(
                          DateFormat('HH:mm').format(meeting.dateTime),
                        ),
                        onTap: () => _showMeetingDetails(context, meeting),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement voice command handling
        },
        child: const Icon(Icons.mic),
      ),
    );
  }

  Future<void> _showAddMeetingDialog(BuildContext context) async {
    // TODO: Implement add meeting dialog
  }

  void _showMeetingDetails(BuildContext context, Meeting meeting) {
    // TODO: Implement meeting details view
  }
}