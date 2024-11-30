import '../../database/database_helper.dart';
import '../../database/models/client_note.dart';

class NoteProcess {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool isProcessing = false;
  String? _currentClient;
  NoteType _currentType = NoteType.general;
  NoteImportance _currentImportance = NoteImportance.normal;

  Future<Map<String, dynamic>> process(String command, int userId) async {
    try {
      if (!isProcessing) {
        return await _startNoteProcess(command, userId);
      } else {
        return await _continueNoteProcess(command, userId);
      }
    } catch (e) {
      isProcessing = false;
      return {
        'success': false,
        'message': 'Błąd podczas przetwarzania notatki: $e',
        'awaitingResponse': false
      };
    }
  }

  Future<Map<String, dynamic>> _startNoteProcess(String command, int userId) async {
    final clients = await _dbHelper.searchClients(command, userId);
    if (clients.isEmpty) {
      return {
        'success': false,
        'message': 'Nie znaleziono klienta.',
        'awaitingResponse': false
      };
    }

    _currentClient = clients.first.name;
    isProcessing = true;
    return {
      'success': true,
      'message': 'Podaj treść notatki dla klienta $_currentClient:',
      'awaitingResponse': true
    };
  }

  Future<Map<String, dynamic>> _continueNoteProcess(String command, int userId) async {
    if (_currentClient == null) {
      isProcessing = false;
      return {
        'success': false,
        'message': 'Błąd: nie wybrano klienta.',
        'awaitingResponse': false
      };
    }

    final clients = await _dbHelper.searchClients(_currentClient!, userId);
    if (clients.isEmpty) {
      isProcessing = false;
      return {
        'success': false,
        'message': 'Błąd: nie znaleziono klienta.',
        'awaitingResponse': false
      };
    }

    final note = ClientNote(
      clientId: clients.first.id!,
      content: command,
      createdAt: DateTime.now(),
      userId: userId,
      type: _currentType,
      importance: _currentImportance,
    );

    await _dbHelper.createNote(note);
    isProcessing = false;
    return {
      'success': true,
      'message': 'Notatka została dodana.',
      'awaitingResponse': false
    };
  }

  Future<String?> check(Map<String, dynamic> params, int userId) async {
    try {
      final clients = await _dbHelper.searchClients(params['client'], userId);
      if (clients.isEmpty) {
        return 'Nie znaleziono klienta ${params['client']}';
      }

      final notes = await _dbHelper.getNotesForClient(clients.first.id!);
      if (notes.isEmpty) {
        return 'Brak notatek dla klienta ${clients.first.name}';
      }

      String response = 'Notatki dla klienta ${clients.first.name}:\n';
      for (var note in notes.take(5)) {
        response += '- ${note.content}\n';
      }
      
      if (notes.length > 5) {
        response += '\n...oraz ${notes.length - 5} więcej notatek.';
      }
      
      return response;
    } catch (e) {
      print('Error checking notes: $e');
      return null;
    }
  }
}