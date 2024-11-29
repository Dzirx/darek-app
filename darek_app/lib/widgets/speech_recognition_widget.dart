import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../services/chatgpt_assistant_service.dart';
import '../services/process/tts_process.dart';

class SpeechRecognitionWidget extends StatefulWidget {
  final int userId;

  const SpeechRecognitionWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SpeechRecognitionWidget> createState() => _SpeechRecognitionWidgetState();
}

class _SpeechRecognitionWidgetState extends State<SpeechRecognitionWidget> {
  final SpeechToText _speech = SpeechToText();
  final GPTAssistantService _assistant = GPTAssistantService.instance;
  final TTSProcess _ttsProcess = TTSProcess();
  bool _isListening = false;
  String _lastWords = '';
  bool _isProcessing = false;
  bool _isInNoteMode = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isListening = await _speech.initialize(
        onError: (error) => print('Error: ${error.errorMsg}'),
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_isListening) {
        if (await _speech.initialize()) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: _onSpeechResult,
            localeId: 'pl_PL',
            listenMode: ListenMode.confirmation,
          );
        }
      }
    } catch (e) {
      print('Error starting listening: $e');
      setState(() => _isListening = false);
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult && !_isProcessing) {
      setState(() => _isProcessing = true);
      try {
        final response = await _assistant.processCommand(_lastWords, widget.userId);
        
        if (response['success']) {
          await _ttsProcess.speak(response['message']);
          setState(() {
            _isInNoteMode = response['isNoteMode'] ?? false;
          });
        } else {
          await _ttsProcess.speak('Przepraszam, wystąpił błąd podczas przetwarzania polecenia');
        }
      } catch (e) {
        print('Error processing command: $e');
        await _ttsProcess.speak('Wystąpił nieoczekiwany błąd');
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _lastWords = '';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 32,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 16,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
                if (!_isListening && !_isProcessing && _lastWords.isEmpty && !_isInNoteMode) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Przykładowe komendy:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• "Dodaj notatkę [klient]"\n'
                    '• "Jakie mam jutro spotkania?"\n'
                    '• "Umów spotkanie z [klient] na jutro na 15:00"\n'
                    '• "Pokaż sprzedaż w tym miesiącu"',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
                if (_lastWords.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _lastWords,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isProcessing ? null : (_isListening ? _stopListening : _startListening),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    if (_isProcessing) return Icons.sync;
    if (_isInNoteMode) return Icons.note_add;
    if (_isListening) return Icons.record_voice_over;
    return Icons.mic_none;
  }

  Color _getStatusColor() {
    if (_isProcessing) return Colors.orange;
    if (_isInNoteMode) return Colors.green;
    if (_isListening) return Colors.red;
    return Colors.blue;
  }

  String _getStatusText() {
    if (_isProcessing) return 'Przetwarzam...';
    if (_isInNoteMode) return 'Tryb notatki - mów treść...';
    if (_isListening) return 'Słucham...';
    return 'Kliknij, aby wydać polecenie';
  }

  @override
  void dispose() {
    _speech.stop();
    _ttsProcess.dispose();
    super.dispose();
  }
}