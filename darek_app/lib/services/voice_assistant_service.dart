// lib/services/voice_assistant_service.dart

import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';

class VoiceAssistantService {
  static final VoiceAssistantService instance = VoiceAssistantService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterTts _tts = FlutterTts();
  
  VoiceAssistantService._init() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('pl-PL');
    await _tts.setSpeechRate(0.9); // Nieco wolniejsza mowa dla lepszej zrozumiałości
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> processCommand(String command, int userId) async {
    final lowercaseCommand = command.toLowerCase();
    
    try {
      if (_isMeetingCreationCommand(lowercaseCommand)) {
        await _processMeetingCreation(command, userId);
      } 
      else if (_isMeetingQueryCommand(lowercaseCommand)) {
        await _processMeetingQuery(command, userId);
      }
      else {
        await _speak(
          'Nie rozpoznano komendy. Możesz zapytać o spotkania mówiąc na przykład: '
          'jakie mam spotkania jutro, '
          'gdzie byłem w zeszłym tygodniu, '
          'lub dodać nowe spotkanie mówiąc: umów spotkanie.'
        );
      }
    } catch (e) {
      await _speak('Wystąpił błąd podczas przetwarzania komendy: $e');
    }
  }

  bool _isMeetingCreationCommand(String command) {
    final keywords = [
      'dodaj spotkanie',
      'nowe spotkanie',
      'umów',
      'zaplanuj',
      'zapisz spotkanie'
    ];
    return keywords.any((keyword) => command.contains(keyword));
  }

  bool _isMeetingQueryCommand(String command) {
    final keywords = [
      'jakie',
      'kiedy',
      'gdzie',
      'pokaż',
      'wyświetl',
      'sprawdź',
      'lista',
      'spotkania'
    ];
    return keywords.any((keyword) => command.contains(keyword));
  }

  Future<void> _processMeetingQuery(String command, int userId) async {
    final dates = await _extractQueryDates(command);
    if (dates == null) {
      await _speak('Nie rozpoznałem daty w zapytaniu. Spróbuj określić konkretny dzień lub okres.');
      return;
    }

    final meetings = await _dbHelper.getMeetingsForPeriod(
      userId,
      dates.start,
      dates.end,
    );

    if (meetings.isEmpty) {
      await _speak('Nie znaleziono żadnych spotkań w podanym okresie.');
      return;
    }

    // Formatowanie odpowiedzi głosowej
    String response = _formatMeetingsResponse(meetings, dates);
    await _speak(response);
  }

  Future<void> _processMeetingCreation(String command, int userId) async {
    // ... (poprzednia implementacja dodawania spotkań)
  }

  String _formatMeetingsResponse(List<Meeting> meetings, DateRange dates) {
    if (dates.start == dates.end) {
      // Odpowiedź dla jednego dnia
      return _formatSingleDayMeetings(meetings, dates.start);
    } else {
      // Odpowiedź dla okresu
      return _formatPeriodMeetings(meetings, dates);
    }
  }

  String _formatSingleDayMeetings(List<Meeting> meetings, DateTime date) {
    final dateStr = DateFormat('EEEE, d MMMM', 'pl').format(date);
    
    if (meetings.isEmpty) {
      return 'Na $dateStr nie masz zaplanowanych spotkań.';
    }

    var response = 'Na $dateStr masz ${meetings.length} ${_meetingsInflection(meetings.length)}:';
    
    for (var meeting in meetings) {
      final time = DateFormat('HH:mm').format(meeting.dateTime);
      response += ' o $time ${meeting.title},';
    }

    return response.substring(0, response.length - 1) + '.';
  }

  String _formatPeriodMeetings(List<Meeting> meetings, DateRange dates) {
    final startStr = DateFormat('d MMMM', 'pl').format(dates.start);
    final endStr = DateFormat('d MMMM', 'pl').format(dates.end);
    
    if (meetings.isEmpty) {
      return 'W okresie od $startStr do $endStr nie masz zaplanowanych spotkań.';
    }

    var response = 'W okresie od $startStr do $endStr masz ${meetings.length} ${_meetingsInflection(meetings.length)}:';
    
    // Grupowanie spotkań po dniach
    final meetingsByDay = <DateTime, List<Meeting>>{};
    for (var meeting in meetings) {
      final day = DateTime(meeting.dateTime.year, meeting.dateTime.month, meeting.dateTime.day);
      meetingsByDay.putIfAbsent(day, () => []).add(meeting);
    }

    // Formatowanie spotkań pogrupowanych po dniach
    for (var entry in meetingsByDay.entries) {
      final dayStr = DateFormat('EEEE, d MMMM', 'pl').format(entry.key);
      response += '\n$dayStr:';
      
      for (var meeting in entry.value) {
        final time = DateFormat('HH:mm').format(meeting.dateTime);
        response += ' o $time ${meeting.title},';
      }
      
      response = response.substring(0, response.length - 1);
    }

    return response;
  }

  String _meetingsInflection(int count) {
    if (count == 1) return 'spotkanie';
    if (count < 5 && count > 1) return 'spotkania';
    return 'spotkań';
  }

  Future<void> _speak(String text) async {
    await _tts.stop(); // Zatrzymaj poprzednie wypowiedzi
    await _tts.speak(text);
  }

  Future<DateRange?> _extractQueryDates(String command) async {
    final now = DateTime.now();
    
    // Zapytanie o konkretny dzień
    if (command.contains('dzisiaj') || command.contains('dziś')) {
      return DateRange(now, now);
    }
    if (command.contains('jutro')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateRange(tomorrow, tomorrow);
    }
    if (command.contains('wczoraj')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateRange(yesterday, yesterday);
    }

    // Zapytanie o tydzień
    if (command.contains('ten tydzień') || command.contains('tego tygodnia')) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateRange(startOfWeek, endOfWeek);
    }
    if (command.contains('zeszły tydzień') || 
        command.contains('poprzedni tydzień') ||
        command.contains('ostatni tydzień')) {
      final endOfLastWeek = now.subtract(Duration(days: now.weekday));
      final startOfLastWeek = endOfLastWeek.subtract(const Duration(days: 6));
      return DateRange(startOfLastWeek, endOfLastWeek);
    }

    // Zapytanie o miesiąc
    if (command.contains('ten miesiąc') || command.contains('tego miesiąca')) {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      return DateRange(startOfMonth, endOfMonth);
    }
    if (command.contains('zeszły miesiąc') || 
        command.contains('poprzedni miesiąc') ||
        command.contains('ostatni miesiąc')) {
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      return DateRange(startOfLastMonth, endOfLastMonth);
    }

    // Dni tygodnia
    final daysMap = {
      'poniedziałek': 1, 'wtorek': 2, 'środa': 3, 'czwartek': 4,
      'piątek': 5, 'sobota': 6, 'niedziela': 7
    };

    for (var entry in daysMap.entries) {
      if (command.contains(entry.key)) {
        var targetDay = now;
        while (targetDay.weekday != entry.value) {
          targetDay = targetDay.add(const Duration(days: 1));
        }
        return DateRange(targetDay, targetDay);
      }
    }

    return null;
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}