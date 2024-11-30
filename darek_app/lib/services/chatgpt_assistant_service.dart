import 'process/meeting_process.dart';
import 'process/note_process.dart';
import 'process/sales_process.dart';
import 'process/tts_process.dart';
import 'process/openai_process.dart';
import 'process/context_process.dart';


class GPTAssistantService {
  static final GPTAssistantService instance = GPTAssistantService._init();
  
  final TTSProcess _ttsProcess;
  final OpenAIProcess _openAIProcess;
  final MeetingProcess _meetingProcess;
  final NoteProcess _noteProcess;
  final SalesProcess _salesProcess;
  final ContextProcess _contextProcess;

  GPTAssistantService._init()
      : _ttsProcess = TTSProcess(),
        _openAIProcess = OpenAIProcess(),
        _meetingProcess = MeetingProcess(),
        _noteProcess = NoteProcess(),
        _salesProcess = SalesProcess(),
        _contextProcess = ContextProcess();

  Future<Map<String, dynamic>> processCommand(String command, int userId) async {
  try {
    print('Processing command: $command');

      if (_noteProcess.isProcessing || command.toLowerCase().contains('dodaj notatkę')) {
      final normalizedCommand = command.toLowerCase();
      String clientName = '';
      
      if (normalizedCommand.contains('dodaj notatkę dla')) {
        clientName = normalizedCommand.split('dodaj notatkę dla').last.trim();
      } else if (_noteProcess.isProcessing) {
        clientName = command;
      }
      
      final result = await _noteProcess.process(clientName, userId);
      await _ttsProcess.speak(result['message']);
      
      return {
        'message': result['message'],
        'isNoteMode': result['awaitingResponse'],
        'success': result['success']
      };
    }

    final context = await _contextProcess.buildContext(userId);
    final response = await _openAIProcess.getResponse(command, context);
    await _executeAction(response, userId);
    await _ttsProcess.speak(response['response']);
    
    return {
      'message': response['response'],
      'isNoteMode': false,
      'success': true
    };
  } catch (e) {
    print('Error: $e');
    return {
      'message': 'Wystąpił błąd: $e',
      'isNoteMode': false,
      'success': false
    };
  }
}

  Future<void> _executeAction(Map<String, dynamic> action, int userId) async {
    try {
      final params = action['parameters'];
      
      switch (action['action']) {
        case 'check_meetings':
          final meetings = await _meetingProcess.check(params, userId);
          if (meetings != null) action['response'] = meetings;
          break;
          
        case 'add_meeting':
          await _meetingProcess.add(params, userId);
          break;
          
        case 'delete_meeting':
          await _meetingProcess.delete(params, userId);
          break;
          
        case 'add_note':
          final command = 'dodaj notatkę dla ${params['client']}';
          final result = await _noteProcess.process(command, userId);
          if (!result['success']) {
            throw Exception(result['message']);
          }
          action['response'] = result['message'];
          break;
          
        case 'check_notes':
          final notes = await _noteProcess.check(params, userId);
          if (notes != null) action['response'] = notes;
          break;
          
        case 'analyze_sales':
          final result = await _salesProcess.analyze(params, userId);
          if (result['success']) {
            action['response'] = result['message'];
          } else {
            throw Exception(result['message']);
          }
          break;
      }
    } catch (e) {
      print('Error executing action: $e');
      throw Exception('Błąd podczas wykonywania polecenia: $e');
    }
  }
}