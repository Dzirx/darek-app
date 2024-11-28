import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/chatgpt_assistant_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart'; // Dodany brakujący import


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
  bool _isListening = false;
  String _lastWords = '';
  bool _isProcessing = false;

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
        await _assistant.processCommand(_lastWords, widget.userId);
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
                // Status i mikrofon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isProcessing ? Icons.sync : (_isListening ? Icons.record_voice_over : Icons.mic_none),
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
                
                // Przykładowe komendy (pokazywane tylko gdy nie słucha)
                if (!_isListening && !_isProcessing && _lastWords.isEmpty) ...[
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
                    '• "Jakie mam jutro spotkania?"\n'
                    '• "Umów spotkanie z [klient] na jutro na 15:00"\n'
                    '• "Dodaj notatkę dla [klient]"\n'
                    '• "Pokaż sprzedaż w tym miesiącu"',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          
          // Przycisk mikrofonu na całej powierzchni
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

  Color _getStatusColor() {
    if (_isProcessing) return Colors.orange;
    if (_isListening) return Colors.red;
    return Colors.blue;
  }

  String _getStatusText() {
    if (_isProcessing) return 'Przetwarzam...';
    if (_isListening) return 'Słucham...';
    return 'Kliknij, aby wydać polecenie';
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}