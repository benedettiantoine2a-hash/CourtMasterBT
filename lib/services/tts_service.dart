import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final Random _random = Random();
  bool voiceEnabled = true;

  final Map<String, List<String>> _phraseBank = {
    'start': [
      "Que le meilleur gagne, ou au moins celui qui ne tremble pas !",
      "C'est parti pour le show ! Bonne chance à tous.",
      "Silence sur le court, les titans vont s'affronter."
    ],
    'golden_point': [
      "Punto de Oro ! La pression est à son maximum.",
      "C'est maintenant que tout se joue. Qui a les nerfs d'acier ?",
      "Point décisif ! Respirez un grand coup."
    ],
    'match_point': [
      "Balle de match ! Ne tremblez pas maintenant.",
      "C'est le moment de vérité ! Allez, on y croit.",
      "Chers joueurs, la victoire est à portée de raquette."
    ],
    'comeback': [
      "Quelle remontada incroyable !",
      "Ils reviennent de nulle part !",
      "Ils ne lâchent rien, quel mental !"
    ],
    'win': [
      "Et c'est la victoire ! Bravo, quel beau match.",
      "Match terminé, félicitations aux vainqueurs.",
      "Fin de la partie. Les perdants paieront la bière !"
    ],
    'fun': [
      "Magnifique coup ! Oh non, c'était de la chance, avouez.",
      "C'est du padel ou du ping-pong ?",
      "Attention à la vitre, elle n'a rien fait de mal !",
      "Quel smatch ! On dirait Bela dans ses grands jours."
    ]
  };

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
    if (!voiceEnabled) return;
    await _flutterTts.speak(text);
  }

  Future<void> speakScore(String scoreA, String scoreB, String nameA, String nameB) async {
    if (!voiceEnabled) return;
    await _flutterTts.speak("$scoreA à $scoreB");
  }

  Future<void> announceGameWinner(String name) async {
    if (!voiceEnabled) return;
    await _flutterTts.speak("Jeu équipe $name");
  }

  Future<void> speakRandom(String category) async {
    if (!voiceEnabled || !_phraseBank.containsKey(category)) return;
    final phrases = _phraseBank[category]!;
    final phrase = phrases[_random.nextInt(phrases.length)];
    await _flutterTts.speak(phrase);
  }
}
