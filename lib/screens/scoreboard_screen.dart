import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../services/match_logic.dart';
import '../services/volume_key_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class ScoreboardScreen extends StatefulWidget {
  final MatchSettings settings;

  const ScoreboardScreen({super.key, required this.settings});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late MatchLogic _logic;
  late VolumeKeyService _keyService;
  late TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _logic = MatchLogic(widget.settings);
    _ttsService = TtsService();
    _keyService = VolumeKeyService(onKeyAction: _handleKeyAction);
    
    // Annonce de début
    _ttsService.speak("Début du match. Bon jeu !");
  }

  void _handleKeyAction(VolumeKey key, bool isLongPress) {
    setState(() {
      if (key == VolumeKey.UP) {
        if (isLongPress) {
          _announceScore();
        } else {
          _logic.addPoint("A");
          _checkEvent();
        }
      } else {
        if (isLongPress) {
          _logic.undo();
          _ttsService.speak("Annulé");
        } else {
          _logic.addPoint("B");
          _checkEvent();
        }
      }
    });
  }

  void _checkEvent() {
    final state = _logic.state;
    if (state.matchFinished) {
       _ttsService.speak("Match terminé ! Victoire de l'équipe ${state.winner == "A" ? "A" : "B"}");
    } else if (state.pointsA == 0 && state.pointsB == 0) {
      // Game transition
      _ttsService.announceGameWinner(state.gamesTeamA.last > state.gamesTeamB.last ? "A" : "B");
    }
  }

  void _announceScore() {
    final state = _logic.state;
    String scoreA = _logic.getFormattedPoints("A");
    String scoreB = _logic.getFormattedPoints("B");
    _ttsService.speak("Le score est de $scoreA à $scoreB");
  }

  @override
  Widget build(BuildContext context) {
    final state = _logic.state;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Sets Score (Small)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _setScoreDisplay(state.gamesTeamA),
                      Text("SETS", style: TextStyle(color: AppTheme.electricCyan, fontSize: 20)),
                      _setScoreDisplay(state.gamesTeamB),
                    ],
                  ),
                ),
                
                // Points Score (Massive)
                Expanded(
                  child: Column(
                    children: [
                       _scoreBox("A", _logic.getFormattedPoints("A"), state.serverIndex < 2),
                       const Divider(color: Colors.white24, height: 1),
                       _scoreBox("B", _logic.getFormattedPoints("B"), state.serverIndex >= 2),
                    ],
                  ),
                ),
              ],
            ),
            
            // Match Card Overlay
            if (state.matchFinished)
              _buildMatchCard(state),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(ScoreState state) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.neonYellow, size: 100),
          const SizedBox(height: 20),
          Text(
            "VICTOIRE TEAM ${state.winner}",
            style: const TextStyle(color: AppTheme.neonYellow, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _summaryBox(state.gamesTeamA, "A"),
              const SizedBox(width: 20),
              _summaryBox(state.gamesTeamB, "B"),
            ],
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NOUVEAU MATCH"),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(List<int> sets, String team) {
    return Column(
      children: [
        Text(team, style: const TextStyle(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 10),
        Row(
          children: sets.map((s) => Text("$s ", style: const TextStyle(color: AppTheme.electricCyan, fontSize: 32))).toList(),
        ),
      ],
    );
  }

  Widget _setScoreDisplay(List<int> sets) {
    return Row(
      children: sets.map((s) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.electricCyan),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(s.toString(), style: const TextStyle(color: AppTheme.electricCyan, fontSize: 24)),
      )).toList(),
    );
  }

  Widget _scoreBox(String team, String score, bool isServing) {
    return Expanded(
      child: Container(
        width: double.infinity,
        color: AppTheme.pureBlack,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Display Server Arrow
            if (isServing)
              Positioned(
                left: 20,
                child: Icon(Icons.arrow_forward_ios, color: AppTheme.neonYellow, size: 40),
              ),
            
            Text(
              score,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: score.length > 2 ? 140 : 180,
              ),
            ),
            
            Positioned(
              top: 20,
              right: 20,
              child: Text("EQUIPE $team", style: const TextStyle(color: Colors.white38, fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
