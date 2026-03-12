import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setLanguage("fr-FR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> speakScore(String scoreA, String scoreB, String nameA, String nameB) async {
    await _flutterTts.speak("$scoreA à $scoreB");
  }

  Future<void> announceGameWinner(String name) async {
    await _flutterTts.speak("Jeu équipe $name");
  }
}
