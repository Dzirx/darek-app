// lib/widgets/speech_recognition_widget.dart

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/voice_command_service.dart';

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
  final VoiceCommandService _commandService = VoiceCommandService.instance;
  String _lastWords = '';
  String _lastResponse = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('Error: ${error.errorMsg}'),
        onStatus: (status) => print('Status: $status'),
      );
      setState(() {});
    } catch (e) {
      print('Init error: $e');
      setState(() {
        _isInitialized = false;
      });
    }
  }

  void _startListening() async {
    try {
      await _speech.listen(
        onResult: (result) async {
          setState(() {
            _lastWords = result.recognizedWords;
          });
          
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            final response = await _commandService.processCommand(
              result.recognizedWords,
              widget.userId,
            );
            setState(() {
              _lastResponse = response;
            });
          }
        },
        localeId: 'pl_PL',
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('Listen error: $e');
    }
  }

  void _stopListening() {
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isInitialized ? Icons.check_circle : Icons.error,
                      color: _isInitialized ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${_isInitialized ? "Gotowy" : "Niedostępny"}',
                      style: TextStyle(
                        color: _isInitialized ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isInitialized)
                      TextButton(
                        onPressed: _initSpeech,
                        child: const Text('Spróbuj ponownie'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rozpoznany tekst:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _lastWords.isEmpty ? 'Powiedz coś...' : _lastWords,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (_lastResponse.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Odpowiedź:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: _lastResponse.contains('Błąd') ? 
                        Colors.red.shade50 : Colors.green.shade50,
                    ),
                    child: Text(
                      _lastResponse,
                      style: TextStyle(
                        fontSize: 16,
                        color: _lastResponse.contains('Błąd') ? 
                          Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isInitialized
              ? (_speech.isListening ? _stopListening : _startListening)
              : null,
          icon: Icon(_speech.isListening ? Icons.mic_off : Icons.mic),
          label: Text(_speech.isListening ? 'Zatrzymaj' : 'Rozpocznij nagrywanie'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _speech.isListening ? Colors.red : null,
          ),
        ),
      ],
    );
  }
}