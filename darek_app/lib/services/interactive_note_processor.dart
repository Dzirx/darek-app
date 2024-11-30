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
    if (_isWaitingForContent) {
      final normalizedCommand = command.toLowerCase();
      if (normalizedCommand.contains('anuluj') || 
          normalizedCommand.contains('wyjdź') ||
          normalizedCommand.contains('wyjść') ||
          normalizedCommand.contains('zakończ')) {
        _resetState();
        return {
          'success': true,
          'message': 'Anulowano dodawanie notatki.',
          'awaitingResponse': false
        };
      }
      
      if (_selectedClient != null) {
        return await _createNote(command, userId);
      }
    }

      // Rozpoznawanie różnych wariantów komend
      final normalizedCommand = command.toLowerCase();
      if (_isNoteCommand(normalizedCommand)) {
        final clientName = _extractClientName(normalizedCommand);
        if (clientName.isEmpty) {
          return {
            'success': false,
            'message': 'Nie rozpoznano nazwy klienta. Powiedz "dodaj notatkę dla [nazwa klienta]"',
            'awaitingResponse': false
          };
        }

        final clients = await _searchClients(clientName, userId);
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
          'message': 'Znaleziono klienta ${_selectedClient!.name}.  Możesz teraz podyktować treść notatki lub powiedz "anuluj" aby wyjść.',
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

  bool _isNoteCommand(String command) {
    final patterns = [
      'dodaj notatkę dla',
      'zapisz notatkę dla',
      'nowa notatka dla',
      'stwórz notatkę dla',
      'zrób notatkę dla'
    ];
    return patterns.any((pattern) => command.contains(pattern));
  }

  String _extractClientName(String command) {
    for (var pattern in [
      RegExp(r'dla\s+(.+)$'),
      RegExp(r'dla\s+firmy\s+(.+)$'),
      RegExp(r'dla\s+klienta\s+(.+)$')
    ]) {
      final match = pattern.firstMatch(command);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    return '';
  }

Future<List<Client>> _searchClients(String query, int userId) async {
  // Usuń zbędne słowa i znaki
  query = query.toLowerCase()
    .replaceAll(RegExp(r'(firmy|klienta)\s+'), '')
    .trim();
  
  final clients = await _dbHelper.searchClients(query, userId);
  
  // Jeśli znaleziono dokładne dopasowanie, użyj go
  final exactMatch = clients.where((c) => 
    c.name.toLowerCase() == query || 
    (c.company?.toLowerCase() ?? '') == query
  ).toList();
  
  if (exactMatch.isNotEmpty) {
    return exactMatch;
  }
  
  // Jeśli nie, zwróć wszystkie częściowe dopasowania
  return clients;
}

Future<Map<String, dynamic>> _createNote(String content, int userId) async {
    try {
        if (_selectedClient == null) {
            throw Exception('Nie wybrano klienta');
        }

        final note = ClientNote(
            clientId: _selectedClient!.id!,
            content: content,
            createdAt: DateTime.now(),
            userId: userId,
            type: _determineNoteType(content),
            importance: _determineImportance(content),
            tags: _generateTags(content),
        );

        await _dbHelper.createNote(note);
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