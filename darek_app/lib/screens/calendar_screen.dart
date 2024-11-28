import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';
import '../widgets/calendar_filters.dart';
import '../widgets/meeting_card.dart';
import '../widgets/dialogs/meeting_add_dialog.dart';
import '../widgets/dialogs/meeting_edit_dialog.dart';
import '../widgets/dialogs/meeting_delete_dialog.dart';

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
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<Meeting>> _meetings;
  String? _selectedFilter;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _meetings = {};
    _loadMeetings();
    _selectedFilter = null;
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

  Future<List<Meeting>> _getFilteredMeetings(DateTime day) async {
    final meetings = await _dbHelper.getMeetingsForDay(day, widget.userId);
    
    if (_selectedFilter == null) return meetings;

    switch (_selectedFilter) {
      case 'today':
        return meetings.where((m) => 
          m.dateTime.year == DateTime.now().year &&
          m.dateTime.month == DateTime.now().month &&
          m.dateTime.day == DateTime.now().day
        ).toList();
      case 'week':
        final weekStart = DateTime.now().subtract(
          Duration(days: DateTime.now().weekday - 1)
        );
        final weekEnd = weekStart.add(const Duration(days: 7));
        return meetings.where((m) => 
          m.dateTime.isAfter(weekStart) && 
          m.dateTime.isBefore(weekEnd)
        ).toList();
      case 'upcoming':
        return meetings.where((m) => 
          m.dateTime.isAfter(DateTime.now())
        ).toList();
      default:
        return meetings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendarz spotkań'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await MeetingAddDialog.show(
                context, 
                _selectedDay,
                widget.userId,
                _dbHelper
              );
              if (result == true) {
                setState(() => _loadMeetings());
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CalendarFilters(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() {
                _selectedFilter = filter;
                _loadMeetings();
              });
            },
          ),
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
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
              future: _getFilteredMeetings(_selectedDay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Błąd: ${snapshot.error}'));
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
                    return MeetingCard(
                      meeting: meeting,
                      onEdit: () async {
                        final result = await MeetingEditDialog.show(
                          context,
                          meeting,
                          widget.userId,
                          _dbHelper
                        );
                        if (result == true) {
                          setState(() => _loadMeetings());
                        }
                      },
                      onDelete: () async {
                        final result = await MeetingDeleteDialog.show(
                          context,
                          meeting,
                          _dbHelper
                        );
                        if (result == true) {
                          setState(() => _loadMeetings());
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}