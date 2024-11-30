import 'package:flutter_tts/flutter_tts.dart';

class TTSProcess {
  final FlutterTts _tts = FlutterTts();
  
  TTSProcess() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _tts.setLanguage('pl-PL');
      await _tts.setSpeechRate(0.6);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      
      _setupHandlers();
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  void _setupHandlers() {
    _tts.setStartHandler(() {
      print('Started speaking');
    });
    
    _tts.setCompletionHandler(() {
      print('Completed speaking');
    });
    
    _tts.setErrorHandler((message) {
      print('Error: $message');
    });
    
    _tts.setCancelHandler(() {
      print('Cancelled speaking');
    });
  }

  Future<void> speak(String text) async {
    try {
      await _tts.stop(); // Zatrzymaj poprzednie wypowiedzi
      await Future.delayed(const Duration(milliseconds: 300));
      
      final sentences = text.split(RegExp(r'[.!?]\s+'))
          .where((s) => s.isNotEmpty)
          .toList();
      
      for (var sentence in sentences) {
        await _tts.speak(sentence.trim() + '.');
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  void dispose() {
    _tts.stop();
  }
}