import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_state.dart';
import '../models/player.dart';
import '../services/match_logic.dart';
import '../services/tts_service.dart';
import '../services/volume_key_service.dart';
import '../theme/app_theme.dart';
import '../services/share_service.dart';
import '../services/settings_service.dart';

class ScoreboardScreen extends StatefulWidget {
  final MatchSettings settings;

  const ScoreboardScreen({super.key, required this.settings});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  late MatchLogic _logic;
  final TtsService _tts = TtsService();
  VolumeKeyService? _keyService;
  final SettingsService _settings = SettingsService();

  bool _vibrationEnabled = true;
  bool _sideChangeEnabled = true;

  @override
  void initState() {
    super.initState();
    _logic = MatchLogic(
      widget.settings,
      teamAPlayers: widget.settings.teamA,
      teamBPlayers: widget.settings.teamB,
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final vibration = await _settings.isVibrationEnabled();
    final sideChange = await _settings.isSideChangeAlertEnabled();
    final voice = await _settings.isVoiceEnabled();
    final inputMode = await _settings.getInputMode();
    
    final isOneButton = inputMode == 'one_button';
    
    _keyService = VolumeKeyService(
      onKeyAction: isOneButton ? null : _handleVolumeKey,
      onGesture: isOneButton ? _handleGesture : null,
      oneButtonMode: isOneButton,
    );

    setState(() {
      _vibrationEnabled = vibration;
      _sideChangeEnabled = sideChange;
      _tts.voiceEnabled = voice;
    });
    
    _tts.speakRandom("start");
  }

  void _handleGesture(GestureType gesture) {
    switch (gesture) {
      case GestureType.singleTap:
        _addPoint("A");
        break;
      case GestureType.doubleTap:
        _addPoint("B");
        break;
      case GestureType.longPress:
        setState(() => _logic.undo());
        if (_vibrationEnabled) HapticFeedback.vibrate();
        break;
    }
  }

  void _handleVolumeKey(VolumeKey key, bool isLongPress) {
    if (isLongPress && key == VolumeKey.TeamB) {
      setState(() => _logic.undo());
      if (_vibrationEnabled) HapticFeedback.vibrate();
    } else if (!isLongPress) {
      _addPoint(key == VolumeKey.TeamA ? "A" : "B");
    }
  }

  void _addPoint(String team) {
    if (_vibrationEnabled) HapticFeedback.lightImpact();
    setState(() {
      _logic.addPoint(team);
      _checkEvent(team);
    });
  }

  void _checkEvent(String teamScored) {
    final state = _logic.state;
    if (state.matchFinished) {
      _tts.speakRandom("win");
    } else if (state.pointsA == 0 && state.pointsB == 0) {
      // Un jeu vient d'être gagné
      _tts.announceGameWinner(teamScored == "A" ? "A" : "B");
      
      // Annonce du changement de côté
      int totalGames = state.gamesTeamA.reduce((a, b) => a + b) + state.gamesTeamB.reduce((a, b) => a + b);
      if (_sideChangeEnabled && totalGames % 2 != 0) {
        _tts.speak("Changement de côté !");
      }
    } else if (state.pointsA == 40 && state.pointsB == 40 && widget.settings.goldenPoint) {
      _tts.speakRandom("golden_point");
    } else {
      _tts.speakScore(_logic.getFormattedPoints("A"), _logic.getFormattedPoints("B"), "", "");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _logic.state;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _setScoreDisplay(state.gamesTeamA),
                const Text("SETS", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                _setScoreDisplay(state.gamesTeamB),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _addPoint("A"),
                    child: _scoreBox("A", _logic.getFormattedPoints("A"), state.serverIndex % 2 == 0, widget.settings.teamA),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _addPoint("B"),
                    child: _scoreBox("B", _logic.getFormattedPoints("B"), state.serverIndex % 2 != 0, widget.settings.teamB),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              "Maintenir Volume Bas pour annuler (Undo)",
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
            const SizedBox(height: 20),
            if (state.matchFinished)
              _buildMatchCard(state),
            if (!state.matchFinished)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text("QUITTER LE MATCH"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _setScoreDisplay(List<int> sets) {
    return Row(
      children: sets.map((games) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          games.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      )).toList(),
    );
  }

  Widget _scoreBox(String team, String score, bool isServing, List<Player> players) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isServing ? AppTheme.neonYellow : Colors.white10, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Wrap(
              spacing: -10,
              children: players.map((p) => CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.electricCyan.withOpacity(0.2),
                child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
              )).toList(),
            ),
          ),
          Text(
            score,
            style: TextStyle(
              color: isServing ? AppTheme.neonYellow : Colors.white,
              fontSize: 100,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            players.map((p) => p.name).join(" & "),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ScoreState state) {
    final shooter = ShareService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureBlack,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.neonYellow),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("MATCH TERMINÉ", style: TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            "VICTOIRE EQUIPE ${state.winner}",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("RETOUR"),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.share, color: AppTheme.neonYellow),
                onPressed: () => shooter.shareMatchCard(_buildResultImageWidget(state)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultImageWidget(ScoreState state) {
    return Container(
      padding: const EdgeInsets.all(30),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("COURTMASTER BT", style: TextStyle(color: AppTheme.neonYellow, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(
            "VICTOIRE : ${state.winner == "A" ? widget.settings.teamA.map((e) => e.name).join(' & ') : widget.settings.teamB.map((e) => e.name).join(' & ')}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.gamesTeamA.join(' / '), style: const TextStyle(color: AppTheme.electricCyan, fontSize: 30, fontWeight: FontWeight.bold)),
              const Text("  VS  ", style: TextStyle(color: Colors.white24, fontSize: 20)),
              Text(state.gamesTeamB.join(' / '), style: const TextStyle(color: AppTheme.electricCyan, fontSize: 30, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
