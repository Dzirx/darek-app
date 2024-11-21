// lib/services/voice_command_service.dart

import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';

class VoiceCommandService {
  static final VoiceCommandService instance = VoiceCommandService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  VoiceCommandService._init();

  Future<String> processCommand(String command, int userId) async {
    final lowercaseCommand = command.toLowerCase();
    
    // Rozpoznawanie różnych wariantów komend
    if (_isMeetingCommand(lowercaseCommand)) {
      return await _processMeetingCommand(command, userId);
    }
    
    return 'Nie rozpoznano komendy. Przykłady komend:\n'
           '- "spotkanie Kowalski jutro 15"\n'
           '- "wizyta u klienta Nowak środa rano"\n'
           '- "umów Malinowski przyszły wtorek 13:30"';
  }

  bool _isMeetingCommand(String command) {
    final meetingKeywords = [
      'spotkanie',
      'spotka',
      'wizyta',
      'wizyty',
      'umów',
      'umow',
      'zaplanuj',
      'zapisz',
      'klient',
      'wstaw',
    ];

    return meetingKeywords.any((keyword) => command.contains(keyword));
  }

  Future<String> _processMeetingCommand(String command, int userId) async {
    try {
      // Bardziej elastyczne przetwarzanie komend
      final dateTime = _extractDateTime(command);
      final clientInfo = _extractClientInfo(command);
      
      if (dateTime == null) {
        return 'Nie rozpoznano daty i godziny. Przykłady:\n'
               '- "jutro 15"\n'
               '- "środa rano"\n'
               '- "przyszły wtorek 13:30"';
      }
      
      if (clientInfo == null) {
        return 'Nie rozpoznano danych klienta. Proszę podać nazwę/nazwisko.';
      }

      final meeting = Meeting(
        title: clientInfo.title,
        description: clientInfo.description,
        dateTime: dateTime,
        hasReminder: true,
        userId: userId,
      );

      await _dbHelper.createMeeting(meeting);
      
      final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
      return 'Dodano spotkanie:\n'
             '${clientInfo.title}\n'
             'Data: $formattedDate\n'
             'Szczegóły: ${clientInfo.description}';
    } catch (e) {
      return 'Błąd podczas dodawania spotkania: $e';
    }
  }

  DateTime? _extractDateTime(String command) {
    final now = DateTime.now();
    DateTime? date;
    int? hour;
    int minute = 0;

    // Rozpoznawanie dat względnych
    if (command.contains('dzisiaj') || command.contains('dziś')) {
      date = now;
    } else if (command.contains('jutro')) {
      date = now.add(const Duration(days: 1));
    } else if (command.contains('pojutrze')) {
      date = now.add(const Duration(days: 2));
    }

    // Rozpoznawanie dni tygodnia
    if (date == null) {
      final daysMap = {
        'poniedziałek': 1, 'wtorek': 2, 'środa': 3, 'czwartek': 4,
        'piątek': 5, 'sobota': 6, 'niedziela': 7,
        'poniedzialek': 1, 'sroda': 3, 'piatek': 5,
      };

      bool isNextWeek = command.contains('przyszły') || 
                       command.contains('przyszla') ||
                       command.contains('następny') ||
                       command.contains('nastepny');

      for (var entry in daysMap.entries) {
        if (command.contains(entry.key)) {
          final currentWeekday = now.weekday;
          var daysToAdd = entry.value - currentWeekday;
          if (daysToAdd <= 0 || isNextWeek) daysToAdd += 7;
          date = now.add(Duration(days: daysToAdd));
          break;
        }
      }
    }

    // Rozpoznawanie pór dnia
    if (command.contains('rano')) {
      hour = 9;
    } else if (command.contains('południe')) {
      hour = 12;
    } else if (command.contains('popołudniu') || command.contains('popoludniu')) {
      hour = 15;
    } else {
      // Szukanie konkretnej godziny
      final timeRegex = RegExp(r'(\d{1,2})(?::(\d{2}))?\b');
      final timeMatches = timeRegex.allMatches(command);
      
      for (var match in timeMatches) {
        final potentialHour = int.parse(match.group(1)!);
        if (potentialHour >= 0 && potentialHour <= 23) {
          hour = potentialHour;
          if (match.group(2) != null) {
            minute = int.parse(match.group(2)!);
          }
          break;
        }
      }
    }

    if (date != null && hour != null) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return null;
  }

  ClientInfo? _extractClientInfo(String command) {
    // Usuwanie typowych słów kluczowych, aby nie przeszkadzały w ekstrakcji nazwy klienta
    final cleanCommand = command.toLowerCase()
      .replaceAll('spotkanie', '')
      .replaceAll('wizyta', '')
      .replaceAll('umów', '')
      .replaceAll('umow', '')
      .replaceAll('zaplanuj', '')
      .replaceAll('klient', '')
      .replaceAll('u', '')
      .replaceAll('z', '');

    // Szukanie słów, które mogą być nazwą klienta (duże litery)
    final words = command.split(' ');
    String? clientName;
    for (var word in words) {
      if (word.length > 2 && 
          word[0].toUpperCase() == word[0] &&
          !word.toLowerCase().contains('przyszły') &&
          !word.toLowerCase().contains('następny')) {
        clientName = word;
        break;
      }
    }

    if (clientName != null) {
      String description = '';
      if (command.contains('preorder') || command.contains('pre-order')) {
        description = 'Omówienie preorderu';
      } else if (command.contains('ofert')) {
        description = 'Przedstawienie oferty';
      } else if (command.contains('prezentac')) {
        description = 'Prezentacja produktów';
      } else {
        description = 'Spotkanie handlowe';
      }

      return ClientInfo(
        title: 'Spotkanie - $clientName',
        description: description,
      );
    }

    return null;
  }
}

class ClientInfo {
  final String title;
  final String description;

  ClientInfo({
    required this.title,
    required this.description,
  });
}