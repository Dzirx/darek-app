import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';
import '../widgets/calendar_filters.dart';
import '../widgets/meeting_card.dart';
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
                      onEdit: () => _showEditMeetingDialog(context, meeting),
                      onDelete: () => _showDeleteConfirmation(context, meeting),
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

  Future<void> _showAddMeetingDialog(BuildContext context) async {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = _selectedDay;
  TimeOfDay selectedTime = TimeOfDay.now();
  // Używamy StatefulBuilder
  bool hasReminder = true;

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder( // Dodaj StatefulBuilder
      builder: (context, setState) => AlertDialog(
        title: const Text('Dodaj spotkanie'),
        content: SingleChildScrollView(
          child: Column(
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
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  DateFormat('dd.MM.yyyy').format(selectedDate),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(selectedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Przypomnienie'),
                value: hasReminder,
                onChanged: (value) {
                  setState(() { // Używamy setState z StatefulBuilder
                    hasReminder = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis spotkania',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Proszę podać tytuł spotkania'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final meeting = Meeting(
                title: titleController.text,
                description: descriptionController.text,
                dateTime: selectedDate,
                hasReminder: hasReminder,
                userId: widget.userId,
              );

              await _dbHelper.createMeeting(meeting);
              
              if (!context.mounted) return;
              Navigator.pop(context);
              
              setState(() {
                _loadMeetings();
              });

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Spotkanie zostało dodane'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    ),
  );
}


  Future<void> _showEditMeetingDialog(BuildContext context, Meeting meeting) async {
  final titleController = TextEditingController(text: meeting.title);
  final descriptionController = TextEditingController(text: meeting.description);
  DateTime selectedDate = meeting.dateTime;
  TimeOfDay selectedTime = TimeOfDay.fromDateTime(meeting.dateTime);
  bool hasReminder = meeting.hasReminder;

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder( // Dodaj StatefulBuilder
      builder: (context, setState) => AlertDialog(
        title: const Text('Edytuj spotkanie'),
        content: SingleChildScrollView(
          child: Column(
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
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat('dd.MM.yyyy').format(selectedDate),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(selectedTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
            SwitchListTile(
                title: const Text('Przypomnienie'),
                value: hasReminder,
                onChanged: (value) {
                  setState(() { // Używamy setState z StatefulBuilder
                    hasReminder = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Opis spotkania',
                prefixIcon: Icon(Icons.description),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: () async {
            // Tworzenie zaktualizowanego obiektu spotkania
            final updatedMeeting = Meeting(
              id: meeting.id,
              title: titleController.text,
              description: descriptionController.text,
              dateTime: selectedDate,
              hasReminder: hasReminder,
              userId: widget.userId,
            );

            // Aktualizacja w bazie danych
            await _dbHelper.updateMeeting(updatedMeeting);
            
            if (!context.mounted) return;
            Navigator.pop(context);
            
            // Odświeżenie widoku
            setState(() {
              _loadMeetings();
            });

            // Opcjonalnie: Pokaż potwierdzenie
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Spotkanie zostało zaktualizowane'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Zapisz'),
        ),
      ],
    ),
    )
  );
}
  Future<void> _showDeleteConfirmation(BuildContext context, Meeting meeting) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Usunąć spotkanie?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Czy na pewno chcesz usunąć spotkanie:'),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          onPressed: () async {
            try {
              await _dbHelper.deleteMeeting(meeting.id!);
              
              if (!context.mounted) return;
              Navigator.pop(context);

              // Odświeżenie widoku
              setState(() {
                _loadMeetings();
              });

              // Pokaż potwierdzenie
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Spotkanie zostało usunięte'),
                  duration: Duration(seconds: 2),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Błąd podczas usuwania spotkania: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Usuń'),
        ),
      ],
    ),
  );
}
  void _showMeetingDetails(BuildContext context, Meeting meeting) {
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
        // Przycisk usuwania
        TextButton(
          onPressed: () async {
            // Potwierdzenie usunięcia
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Potwierdź usunięcie'),
                content: const Text('Czy na pewno chcesz usunąć to spotkanie?'),
                actions: [
                  TextButton(
                    child: const Text('Anuluj'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text('Usuń'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await DatabaseHelper.instance.deleteMeeting(meeting.id!);
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Zamknij szczegóły
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Spotkanie zostało usunięte')),
              );
              setState(() {
                _loadMeetings(); // Odśwież listę spotkań
              });
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Usuń'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
      ],
    ),
  );
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

  // Dodaj filtr chips na górze ekranu
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Dziś'),
            selected: _selectedFilter == 'today',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = selected ? 'today' : null;
                _loadMeetings();
              });
            },
          ),
          FilterChip(
            label: const Text('Ten tydzień'),
            selected: _selectedFilter == 'week',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = selected ? 'week' : null;
                _loadMeetings();
              });
            },
          ),
          FilterChip(
            label: const Text('Przyszłe'),
            selected: _selectedFilter == 'upcoming',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = selected ? 'upcoming' : null;
                _loadMeetings();
              });
            },
          ),
        ],
      ),
    );
  }

  // Dodaj nowy widget dla spotkania
  Widget _buildMeetingCard(Meeting meeting) {
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
              onPressed: () => _showEditMeetingDialog(context, meeting),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, meeting),
            ),
          ],
        ) : null,
      ),
    );
}
}


