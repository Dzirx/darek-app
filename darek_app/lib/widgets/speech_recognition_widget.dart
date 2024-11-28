import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/chatgpt_assistant_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechRecognitionWidget extends StatefulWidget {
  final int userId;  // Upewnij się, że to jest int

  const SpeechRecognitionWidget({
    Key? key,
    required this.userId,  // Ten parametr musi być przekazany jako int
  }) : super(key: key);

  @override
  State<SpeechRecognitionWidget> createState() => _SpeechRecognitionWidgetState();
}

class _SpeechRecognitionWidgetState extends State<SpeechRecognitionWidget> {
  final SpeechToText _speech = SpeechToText();
  final GPTAssistantService _assistant = GPTAssistantService.instance;
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
          if (status == 'done' && _isInNoteMode) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (_isInNoteMode && !_isListening && mounted) {
                _startListening();
              }
            });
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
          await _speech.listen(
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
    setState(() {
      _isListening = false;
      _isInNoteMode = false;
    });
  }

  Future<void> _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult && !_isProcessing) {
      setState(() => _isProcessing = true);
      try {
        // Używamy widget.userId, który jest na pewno typu int
        final response = await _assistant.processCommand(_lastWords, widget.userId);
        
        // Bezpieczne sprawdzenie typu i konwersja
        if (response is Map<String, dynamic>) {
          setState(() {
            _isInNoteMode = response['isNoteMode'] as bool? ?? false;
          });

          if (_isInNoteMode && mounted) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (_isInNoteMode && !_isListening && mounted) {
                _startListening();
              }
            });
          }
        }
      } catch (e) {
        print('Error processing command: $e');
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
                    '• "Dodaj notatkę dla [klient]"\n'
                    '• "Jakie mam jutro spotkania?"\n'
                    '• "Umów spotkanie z [klient] na jutro na 15:00"',
                    style: TextStyle(fontSize: 14),
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
    super.dispose();
  }
}