import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../database/models/meeting.dart';
import '../database/models/client_note.dart';
import '../database/models/client.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GPTAssistantService {
  static final GPTAssistantService instance = GPTAssistantService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterTts _tts = FlutterTts();
  final String _apiKey = 'sk-w5-PlSSZJvpa6jRYChA1-8Q2pOPDa2R46IL17pMCWwT3BlbkFJMIgIBPbjSkc-dgHJC_eyHFqRHGehI6Wm7hHHOGrx0A';
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  GPTAssistantService._init() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('pl-PL');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      
      // Konfiguracja obsługi stanów
      _tts.setStartHandler(() {
        print('Started speaking');
      });
      
      _tts.setCompletionHandler(() {
        print('Completed speaking');
      });
      
      _tts.setErrorHandler((message) {
        print('Error: $message');
      });
      
      _tts.setCancelHandler(() {
        print('Cancelled speaking');
      });
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  Future<String> processCommand(String command, int userId) async {
    try {
      final context = await _buildContext(userId);
      final prompt = _buildPrompt(command, context);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''
                      Jesteś asystentem kalendarza dla handlowca. 
                      Rozumiesz język polski i odpowiadasz po polsku.
                      
                      WAŻNE ZASADY:
                      1. Zawsze odpowiadaj w formacie JSON
                      2. Bądź krótki i zwięzły
                      3. Nie dodawaj zbędnych informacji
                      
                      Przykłady odpowiedzi:
                      
                      Dla "umów spotkanie z Ela":
                      {
                        "action": "add_meeting",
                        "parameters": {
                          "client": "Ela",
                          "date": "2024-01-24",
                          "time": "15:00",
                          "description": ""
                        },
                        "response": "Umówiłem spotkanie z Elą na jutro na 15:00"
                      }


                      Dla "usuń spotkanie z Ela na jutro" lub "odwołaj spotkanie z Ela na jutro":
                      {
                        "action": "delete_meeting",
                        "parameters": {
                          "client": "Ela",
                          "date": "2024-01-24"
                        },
                        "response": "Usunąłem spotkanie z Elą zaplanowane na jutro"
                      }


                      Dla "umów spotkanie z Ela na temat sprzedaży":
                      {
                        "action": "add_meeting",
                        "parameters": {
                          "client": "Ela",
                          "date": "2024-01-24",
                          "time": "15:00",
                          "description": "Temat: sprzedaż"
                        },
                        "response": "Umówiłem spotkanie z Elą na jutro na 15:00 "
                      }
                      

                      Dla "umów spotkanie biznesowe":
                      {
                        "action": "add_meeting",
                        "parameters": {
                          "client": "",
                          "date": "2024-01-24",
                          "time": "15:00",
                          "description": "Temat: sprzedaż"
                        },
                        "response": "Umówiłem spotkanie biznesowe"
                      }


                      Dla "jakie mam jutro spotkania":
                      {
                        "action": "check_meetings",
                        "parameters": {
                          "date": "2024-01-24"
                        },
                        "response": "Sprawdzam spotkania na jutro"
                      }
                    '''
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final assistantResponse = jsonDecode(
          jsonResponse['choices'][0]['message']['content']
        );
        
        // Modyfikujemy odpowiedź dla check_meetings
        if (assistantResponse['action'] == 'check_meetings') {
          final meetings = await _checkMeetings(assistantResponse['parameters'], userId);
          if (meetings != null) {
            assistantResponse['response'] = meetings;
          }
        }
        
        await _executeAction(assistantResponse, userId);
        await _speak(assistantResponse['response']);
        
        return assistantResponse['response'];
      } else {
        throw Exception('Błąd komunikacji z asystentem');
      }
    } catch (e) {
      print('Error in processCommand: $e');
      return 'Przepraszam, wystąpił błąd: $e';
    }
  }

  Future<String?> _checkMeetings(Map<String, dynamic> params, int userId) async {
    try {
      final date = DateTime.parse(params['date']);
      final meetings = await _dbHelper.getMeetingsForDay(date, userId);
      
      if (meetings.isEmpty) {
        return 'Nie masz zaplanowanych spotkań na ten dzień.';
      }

      final formatter = DateFormat('HH:mm');
      String response = 'Oto twoje spotkania:\n';
      
      for (var meeting in meetings) {
        response += '- O ${formatter.format(meeting.dateTime)}: ${meeting.title}';
        if (meeting.description.isNotEmpty) {
          response += ', ${meeting.description}';
        }
        response += '\n';
      }
      
      return response;
    } catch (e) {
      print('Error checking meetings: $e');
      return null;
    }
  }

  Future<void> _executeAction(Map<String, dynamic> action, int userId) async {
    try {
      final params = action['parameters'];
      
      switch (action['action']) {
        case 'add_meeting':
          await _addMeeting(params, userId);
          break;
        case 'delete_meeting':
          await _deleteMeeting(params, userId);
          break;
        case 'add_note':
          await _addNote(params, userId);
          break;
        case 'check_notes':
          await _checkNotes(params, userId);
          break;
        case 'analyze_sales':
          await _analyzeSales(params, userId);
          break;
      }
    } catch (e) {
      print('Error executing action: $e');
    }
  }

  Future<void> _addMeeting(Map<String, dynamic> params, int userId) async {
    final dateTime = DateTime.parse('${params['date']} ${params['time']}');
    
    final meeting = Meeting(
      title: 'Spotkanie z ${params['client']}',
      description: params['description'] ?? '',
      dateTime: dateTime,
      userId: userId,
      hasReminder: true,
    );

    await _dbHelper.createMeeting(meeting);
  }

  Future<void> _addNote(Map<String, dynamic> params, int userId) async {
    final clients = await _dbHelper.searchClients(params['client'], userId);
    if (clients.isEmpty) {
      throw Exception('Nie znaleziono klienta ${params['client']}');
    }

    final note = ClientNote(
      clientId: clients.first.id!,
      content: params['content'],
      createdAt: DateTime.now(),
      userId: userId,
      type: _parseNoteType(params['type'] ?? 'general'),
      importance: _parseNoteImportance(params['importance'] ?? 'normal'),
      tags: List<String>.from(params['tags'] ?? []),
    );

    await _dbHelper.createNote(note);
  }
  

  Future<void> _deleteMeeting(Map<String, dynamic> params, int userId) async {
  try {
    final date = DateTime.parse(params['date']);
    final client = params['client'];
    
    // Pobierz spotkania na dany dzień
    final meetings = await _dbHelper.getMeetingsForDay(date, userId);
    
    // Znajdź spotkanie z danym klientem
    final meetingsToDelete = meetings.where(
      (meeting) => meeting.title.toLowerCase().contains(client.toLowerCase())
    ).toList();
    
    if (meetingsToDelete.isNotEmpty) {
      // Usuń znalezione spotkanie
      await _dbHelper.deleteMeeting(meetingsToDelete.first.id!);
      await _speak('Spotkanie zostało usunięte');
    } else {
      await _speak('Nie znaleziono spotkania z tym klientem na podany dzień');
    }
  } catch (e) {
    print('Error deleting meeting: $e');
    await _speak('Wystąpił błąd podczas usuwania spotkania');
  }
  }

  Future<void> _checkNotes(Map<String, dynamic> params, int userId) async {
    final clientName = params['client'];
    final clients = await _dbHelper.searchClients(clientName, userId);
    
    if (clients.isEmpty) {
      await _speak('Nie znaleziono klienta $clientName');
      return;
    }

    final notes = await _dbHelper.getNotesForClient(clients.first.id!);
    if (notes.isEmpty) {
      await _speak('Nie ma żadnych notatek dla klienta $clientName');
      return;
    }

    String response = 'Ostatnie notatki dla klienta $clientName:\n';
    for (var note in notes.take(3)) {
      response += '- ${note.content}\n';
    }
    
    if (notes.length > 3) {
      response += 'oraz ${notes.length - 3} więcej notatek.';
    }
    
    await _speak(response);
  }

  Future<void> _analyzeSales(Map<String, dynamic> params, int userId) async {
    final period = params['period'] ?? 'month';
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    final total = await _dbHelper.getTotalSalesForPeriod(
      userId,
      startDate,
      endDate,
    );

    final response = 'Całkowita sprzedaż w tym okresie wynosi ${total.toStringAsFixed(2)} złotych';
    await _speak(response);
  }

  NoteType _parseNoteType(String type) {
    switch (type.toLowerCase()) {
      case 'reklamacja':
        return NoteType.complaint;
      case 'spotkanie':
        return NoteType.meeting;
      case 'zamówienie':
      case 'zamowienie':
        return NoteType.order;
      case 'cena':
      case 'cennik':
        return NoteType.price;
      default:
        return NoteType.general;
    }
  }

  NoteImportance _parseNoteImportance(String importance) {
    switch (importance.toLowerCase()) {
      case 'pilne':
      case 'urgent':
        return NoteImportance.urgent;
      case 'wysokie':
      case 'ważne':
      case 'wazne':
        return NoteImportance.high;
      case 'niskie':
        return NoteImportance.low;
      default:
        return NoteImportance.normal;
    }
  }

  Future<void> _speak(String text) async {
  try {
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 300)); // Przerwa przed mówieniem
    
    // Podziel tekst na zdania i mów je z przerwami
    final sentences = text.split(RegExp(r'[.!?]\s+')).where((s) => s.isNotEmpty).toList();
    
    for (var sentence in sentences) {
      await _tts.speak(sentence.trim() + '.');
      await Future.delayed(const Duration(milliseconds: 500)); // Przerwa między zdaniami
    }
  } catch (e) {
    print('Error speaking: $e');
  }
  }
  String _buildPrompt(String command, Map<String, dynamic> context) {
    final now = DateTime.now();
    final formatter = DateFormat('dd.MM.yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Pobierz nadchodzące spotkania
    final upcomingMeetings = (context['meetings'] as List)
        .where((m) => DateTime.parse(m['dateTime']).isAfter(now))
        .take(5)
        .map((m) => {
          'title': m['title'],
          'date': formatter.format(DateTime.parse(m['dateTime'])),
          'time': timeFormatter.format(DateTime.parse(m['dateTime'])),
        })
        .toList();

    // Przygotuj kontekst notatek
    final recentNotes = (context['notes'] as List)
        .take(5)
        .map((n) => {
          'client': n['client'],
          'content': n['content'],
          'date': formatter.format(DateTime.parse(n['createdAt'])),
        })
        .toList();

    // Zbuduj prompt z kontekstem
    return '''
Aktualny kontekst:
Data i godzina: ${formatter.format(now)} ${timeFormatter.format(now)}

Nadchodzące spotkania:
${upcomingMeetings.isEmpty ? 'Brak nadchodzących spotkań' : upcomingMeetings.map((m) => 
  "- ${m['date']} ${m['time']}: ${m['title']}"
).join('\n')}

Ostatnie notatki:
${recentNotes.isEmpty ? 'Brak ostatnich notatek' : recentNotes.map((n) => 
  "- ${n['date']}: ${n['client']} - ${n['content']}"
).join('\n')}

Dostępni klienci:
${(context['clients'] as List).map((c) => 
  "- ${c['name']}${c['company'] != null ? ' (${c['company']})' : ''}"
).join('\n')}

Polecenie użytkownika:
$command

Proszę przetworzyć to polecenie i zwrócić odpowiedź w formacie JSON z odpowiednią akcją i parametrami.
''';
  }

  Future<Map<String, dynamic>> _buildContext(int userId) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));
    final startDate = now.subtract(const Duration(days: 30));

    final meetings = await _dbHelper.getMeetingsForPeriod(
      userId, 
      startDate,
      endDate,
    );

    final clients = await _dbHelper.getRecentClients(userId);
    final notes = await _dbHelper.getRecentNotes(userId);

    return {
      'current_time': now.toIso8601String(),
      'meetings': meetings.map((m) => {
        'title': m.title,
        'dateTime': m.dateTime.toIso8601String(),
        'description': m.description,
      }).toList(),
      
      'clients': clients.map((c) => {
        'name': c.name,
        'company': c.company,
        'category': c.category.toString(),
      }).toList(),
      
      'notes': notes.map((n) => {
        'client': clients.firstWhere((c) => c.id == n.clientId).name,
        'content': n.content,
        'type': n.type.toString(),
        'createdAt': n.createdAt.toIso8601String(),
      }).toList(),
    };
  }
}