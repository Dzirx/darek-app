import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIProcess {
  final String _apiKey = 'sk-w5-PlSSZJvpa6jRYChA1-8Q2pOPDa2R46IL17pMCWwT3BlbkFJMIgIBPbjSkc-dgHJC_eyHFqRHGehI6Wm7hHHOGrx0A';
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<Map<String, dynamic>> getResponse(
    String command, 
    Map<String, dynamic> context
  ) async {
    try {
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
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': _buildPrompt(command, context),
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonDecode(jsonResponse['choices'][0]['message']['content']);
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in OpenAI process: $e');
      rethrow;
    }
  }

  String _getSystemPrompt() {
    return '''
    Jesteś asystentem kalendarza dla handlowca. 
    Rozumiesz język polski i odpowiadasz po polsku.

    WAŻNE ZASADY:
    1. Zawsze odpowiadaj w formacie JSON
    2. Bądź krótki i zwięzły
    3. Nie dodawaj zbędnych informacji

    Obsługiwane akcje:
    1. Sprawdzanie spotkań
    2. Dodawanie spotkań
    3. Usuwanie spotkań
    4. Analizowanie sprzedaży
    5. Dodawanie notatek
    6. Sprawdzanie notatek

    USUWANIE SPOTKAŃ:
    - Zawsze wymagaj dokładnej godziny
    - Format czasu musi być 24h (np. "15:30")
    {
      "action": "delete_meeting",
      "parameters": {
        "date": "YYYY-MM-DD",
        "time": "HH:mm"
      },
      "response": "Usuwam spotkanie z dnia X (dzien) o godzinie Y"
    }

    SPRAWDZANIE SPOTKAŃ:
    {
      "action": "check_meetings",
      "parameters": {
        "date": "YYYY-MM-DD"
      },
      "response": "Sprawdzam spotkania"
    }

    DODAWANIE SPOTKAŃ:
    {
      "action": "add_meeting",
      "parameters": {
        "client": "Nazwa",
        "date": "YYYY-MM-DD",
        "time": "HH:mm",
        "description": "treść"
      },
      "response": "Dodano spotkanie"
    }

    DODAWANIE NOTATEK:
    {
      "action": "add_note",
      "parameters": {
        "client": "Nazwa",
        "content": "treść notatki",
        "type": "general|order|price|meeting|contact|feedback|preorder|complaint",
        "importance": "normal|high|urgent|low"
      },
      "response": "Rozpoczynam dodawanie notatki dla klienta X"
    }

    SPRAWDZANIE NOTATEK:
    {
      "action": "check_notes",
      "parameters": {
        "client": "Nazwa",
        "type": "general|order|price|meeting|contact|feedback|preorder|complaint",
        "dateFrom": "YYYY-MM-DD",
        "dateTo": "YYYY-MM-DD"
      },
      "response": "Sprawdzam notatki"
    }

    PRZYKŁADY KOMEND:
    SPOTKANIA:
    - "usuń spotkanie na jutro na 15:30"
    - "usuń spotkanie z Kowalskim na dziś na 22:00"
    - "jakie mam spotkania jutro"
    - "umów spotkanie z Kowalskim na jutro na 14:00"

    NOTATKI:
    - "dodaj notatkę dla klienta Kowalski"
    - "sprawdź notatki dla klienta ABC"
    - "pokaż reklamacje klienta XYZ"
    - "dodaj pilną notatkę dla firmy ABC"
    }''';
  }

  String _buildPrompt(String command, Map<String, dynamic> context) {
    final meetingsText = (context['meetings'] as List)
        .map((m) => "- ${m['formatted_date']} ${m['formatted_time']}: ${m['title']}")
        .join('\n');

    final notesText = (context['notes'] as List)
        .map((n) => "- ${n['formatted_date']}: ${n['client']} - ${n['content']}")
        .join('\n');

    final clientsText = (context['clients'] as List)
        .map((c) => "- ${c['full_name']}")
        .join('\n');

    return '''
      Aktualny kontekst:
      Data i godzina: ${DateTime.now().toString()}

      Nadchodzące spotkania:
      $meetingsText

      Ostatnie notatki:
      $notesText

      Dostępni klienci:
      $clientsText

      Polecenie użytkownika:
      $command
    ''';
  }
}