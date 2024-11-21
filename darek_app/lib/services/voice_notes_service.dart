// lib/services/voice_notes_service.dart

import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';
import '../database/models/client_note.dart';
import '../database/models/client.dart';

class VoiceNotesService {
  static final VoiceNotesService instance = VoiceNotesService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final FlutterTts _tts = FlutterTts();

  VoiceNotesService._init() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('pl-PL');
    await _tts.setSpeechRate(0.9);
  }

  Future<void> processCommand(String command, int userId) async {
    final lowercaseCommand = command.toLowerCase();

    try {
      if (_isAddNoteCommand(lowercaseCommand)) {
        await _processAddNoteCommand(command, userId);
      } else if (_isReadNotesCommand(lowercaseCommand)) {
        await _processReadNotesCommand(command, userId);
      } else {
        await _speak(
          'Nie rozpoznano komendy. Możesz powiedzieć:\n'
          '- "dodaj notatkę dla [klient]: [treść]"\n'
          '- "zapisz spotkanie z [klient]: [treść]"\n'
          '- "dodaj reklamację [klient]: [treść]"\n'
          '- "przeczytaj notatki [klient]"\n'
          '- "jakie są notatki dla [klient]"'
        );
      }
    } catch (e) {
      await _speak('Wystąpił błąd: $e');
    }
  }

  bool _isAddNoteCommand(String command) {
    final addKeywords = [
      'dodaj notatkę',
      'dodaj notatke',
      'zapisz notatkę',
      'zapisz notatke',
      'nowa notatka',
      'dodaj reklamację',
      'dodaj reklamacje',
      'zapisz spotkanie'
    ];
    return addKeywords.any((keyword) => command.contains(keyword));
  }

  bool _isReadNotesCommand(String command) {
    final readKeywords = [
      'przeczytaj notatki',
      'przeczytaj notatkę',
      'pokaż notatki',
      'pokaz notatki',
      'jakie są notatki',
      'jakie sa notatki',
      'odczytaj notatki'
    ];
    return readKeywords.any((keyword) => command.contains(keyword));
  }

  Future<void> _processAddNoteCommand(String command, int userId) async {
    // Wyodrębnienie nazwy klienta
    final clientName = _extractClientName(command);
    if (clientName == null) {
      await _speak('Nie rozpoznano nazwy klienta. Podaj nazwę klienta po słowie "dla" lub "z".');
      return;
    }

    // Znalezienie klienta
    final clients = await _dbHelper.searchClients(clientName, userId);
    if (clients.isEmpty) {
      await _speak('Nie znaleziono klienta o nazwie $clientName');
      return;
    }

    // Określenie typu notatki
    final noteType = _determineNoteType(command);
    final importance = _determineImportance(command);
    final content = _extractContent(command);
    final tags = _extractTags(command);

    if (content == null || content.isEmpty) {
      await _speak('Nie rozpoznano treści notatki. Podaj treść po dwukropku.');
      return;
    }

    // Utworzenie notatki
    final note = ClientNote(
      clientId: clients.first.id!,
      content: content,
      createdAt: DateTime.now(),
      userId: userId,
      type: noteType,
      importance: importance,
      tags: tags,
    );

    await _dbHelper.createNote(note);
    await _speak('Dodano notatkę dla klienta ${clients.first.name}');
  }

  Future<void> _processReadNotesCommand(String command, int userId) async {
    // Wyodrębnienie nazwy klienta
    final clientName = _extractClientName(command);
    if (clientName == null) {
      await _speak('Nie rozpoznano nazwy klienta. Podaj nazwę klienta.');
      return;
    }

    // Znalezienie klienta
    final clients = await _dbHelper.searchClients(clientName, userId);
    if (clients.isEmpty) {
      await _speak('Nie znaleziono klienta o nazwie $clientName');
      return;
    }

    // Pobranie notatek
    final notes = await _dbHelper.getNotesForClient(clients.first.id!);
    if (notes.isEmpty) {
      await _speak('Brak notatek dla klienta ${clients.first.name}');
      return;
    }

    // Przygotowanie tekstu do odczytania
    String response = 'Notatki dla klienta ${clients.first.name}:\n';
    for (var note in notes.take(5)) { // Odczytujemy max 5 ostatnich notatek
      response += '\nData: ${_formatDate(note.createdAt)}\n';
      response += '${_getNoteTypeName(note.type)}: ${note.content}\n';
    }

    if (notes.length > 5) {
      response += '\nPozostało jeszcze ${notes.length - 5} notatek.';
    }

    await _speak(response);
  }

  String? _extractClientName(String command) {
    // Szukamy nazwy klienta po słowach kluczowych
    final keywords = ['dla', 'z', 'klient', 'klienta'];
    for (var keyword in keywords) {
      if (command.contains(keyword)) {
        final parts = command.split(keyword);
        if (parts.length > 1) {
          final namePart = parts[1].split(':')[0].trim();
          // Zwracamy pierwszy wyraz zaczynający się wielką literą
          final words = namePart.split(' ');
          for (var word in words) {
            if (word.length > 0 && word[0].toUpperCase() == word[0]) {
              return word;
            }
          }
        }
      }
    }
    return null;
  }

  String? _extractContent(String command) {
    final parts = command.split(':');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return null;
  }

  NoteType _determineNoteType(String command) {
    if (command.contains('reklamac')) return NoteType.complaint;
    if (command.contains('spotkani')) return NoteType.meeting;
    if (command.contains('cen')) return NoteType.price;
    if (command.contains('zamówieni') || command.contains('zamowieni')) return NoteType.order;
    if (command.contains('preorder')) return NoteType.preorder;
    return NoteType.general;
  }

  NoteImportance _determineImportance(String command) {
    if (command.contains('pilne') || command.contains('urgent')) return NoteImportance.urgent;
    if (command.contains('ważne') || command.contains('wazne')) return NoteImportance.high;
    if (command.contains('mało ważne') || command.contains('malo wazne')) return NoteImportance.low;
    return NoteImportance.normal;
  }

  List<String> _extractTags(String command) {
    final tags = <String>[];
    
    // Dodawanie tagów na podstawie typu notatki
    if (command.contains('reklamac')) tags.add('reklamacja');
    if (command.contains('spotkani')) tags.add('spotkanie');
    if (command.contains('cen')) tags.add('cennik');
    if (command.contains('zamówieni') || command.contains('zamowieni')) tags.add('zamówienie');
    if (command.contains('preorder')) tags.add('preorder');

    // Dodawanie tagów na podstawie ważności
    if (command.contains('pilne')) tags.add('pilne');
    if (command.contains('ważne') || command.contains('wazne')) tags.add('ważne');

    return tags;
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getNoteTypeName(NoteType type) {
    switch (type) {
      case NoteType.general: return 'Notatka';
      case NoteType.order: return 'Zamówienie';
      case NoteType.price: return 'Cennik';
      case NoteType.meeting: return 'Spotkanie';
      case NoteType.contact: return 'Kontakt';
      case NoteType.feedback: return 'Opinia';
      case NoteType.preorder: return 'Preorder';
      case NoteType.complaint: return 'Reklamacja';
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop(); // Zatrzymaj poprzednie wypowiedzi
    await _tts.speak(text);
  }
}