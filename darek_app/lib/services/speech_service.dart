import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _currentLocaleId = '';
  int _retryCount = 0;
  static const int maxRetries = 3;
  
  bool get isEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;

  Future<bool> initSpeech() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    try {
      if (_retryCount >= maxRetries) {
        print('Exceeded maximum retry attempts');
        return false;
      }
      _retryCount++;

      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        print('Microphone permission denied');
        return false;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech error: ${error.errorMsg}');
          if (error.permanent) {
            _speechEnabled = false;
          } else {
            // Próba ponownej inicjalizacji dla tymczasowych błędów
            Future.delayed(const Duration(seconds: 1), () {
              if (_retryCount < maxRetries) initSpeech();
            });
          }
        },
        onStatus: (status) => print('Status: $status'),
        debugLogging: true,
      );

      if (_speechEnabled) {
        final locales = await _speechToText.locales();
        try {
          _currentLocaleId = locales.firstWhere(
            (locale) => locale.localeId.startsWith('pl_'),
            orElse: () => locales.first,
          ).localeId;
        } catch (e) {
          _currentLocaleId = 'pl_PL';
        }
        _retryCount = 0; // Reset licznika po udanej inicjalizacji
      }

      return _speechEnabled;
    } catch (e) {
      print('Init error: $e');
      _speechEnabled = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function(double level) onSoundLevel,
  }) async {
    if (!_speechEnabled) {
      final initialized = await initSpeech();
      if (!initialized) return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (result.finalResult && words.isNotEmpty) {
            onResult(words);
          }
        },
        localeId: _currentLocaleId,
        onSoundLevelChange: onSoundLevel,
        listenMode: ListenMode.confirmation,
        partialResults: false,
        cancelOnError: false,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onDevice: false,
      );
    } catch (e) {
      print('Listen error: $e');
      // Próba ponownej inicjalizacji w przypadku błędu
      if (_retryCount < maxRetries) {
        await initSpeech();
        await startListening(
          onResult: onResult,
          onSoundLevel: onSoundLevel,
        );
      }
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      print('Stop error: $e');
    }
  }
}