import '../database/database_helper.dart';
import '../database/models/client.dart';
import '../database/models/client_note.dart';

class InteractiveNoteProcessor {
  final DatabaseHelper _dbHelper;
  Client? _selectedClient;
  bool _isWaitingForContent = false;
  
  InteractiveNoteProcessor(this._dbHelper);

  Future<Map<String, dynamic>> processCommand(String command, int userId) async {
    try {
      // Jeśli czekamy na treść notatki
      if (_isWaitingForContent && _selectedClient != null) {
        return await _createNote(command, userId);
      }

      // Wyszukiwanie klienta
      if (command.toLowerCase().contains('dodaj notatkę dla')) {
        final clientName = _extractClientName(command);
        final clients = await _dbHelper.searchClients(clientName, userId);

        if (clients.isEmpty) {
          return {
            'success': false,
            'message': 'Nie znaleziono klienta $clientName. Spróbuj ponownie.',
            'awaitingResponse': false
          };
        }

        _selectedClient = clients.first;
        _isWaitingForContent = true;

        return {
          'success': true,
          'message': 'Znaleziono klienta ${_selectedClient!.name}. Możesz teraz podyktować treść notatki.',
          'awaitingResponse': true
        };
      }

      return {
        'success': false,
        'message': 'Nie rozpoznano komendy. Powiedz "dodaj notatkę dla [nazwa klienta]"',
        'awaitingResponse': false
      };
    } catch (e) {
      _resetState();
      return {
        'success': false,
        'message': 'Wystąpił błąd: $e',
        'awaitingResponse': false
      };
    }
  }

  Future<Map<String, dynamic>> _createNote(String content, int userId) async {
    try {
      if (_selectedClient == null) {
        throw Exception('Nie wybrano klienta');
      }

      // Tworzenie notatki
      final note = ClientNote(
        clientId: _selectedClient!.id!,
        content: content,
        createdAt: DateTime.now(),
        userId: userId,
        type: _determineNoteType(content),
        importance: _determineImportance(content),
        tags: _generateTags(content),
      );

      // Zapisywanie notatki
      await _dbHelper.createNote(note);

      // Resetowanie stanu
      final response = _generateResponse(note);
      _resetState();

      return {
        'success': true,
        'message': response,
        'awaitingResponse': false
      };
    } catch (e) {
      _resetState();
      return {
        'success': false,
        'message': 'Błąd podczas zapisywania notatki: $e',
        'awaitingResponse': false
      };
    }
  }

  void _resetState() {
    _selectedClient = null;
    _isWaitingForContent = false;
  }

  String _extractClientName(String command) {
    final match = RegExp(r'dla\s+(.+)$').firstMatch(command);
    return match?.group(1)?.trim() ?? '';
  }

  NoteType _determineNoteType(String content) {
    // Implementacja determinacji typu notatki
    return NoteType.general;
  }

  NoteImportance _determineImportance(String content) {
    // Implementacja determinacji ważności
    return NoteImportance.normal;
  }

  List<String> _generateTags(String content) {
    // Implementacja generowania tagów
    return [];
  }

  String _generateResponse(ClientNote note) {
    return 'Zapisano notatkę dla klienta ${_selectedClient!.name}';
  }
}