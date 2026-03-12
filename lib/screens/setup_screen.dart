import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import 'scoreboard_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  MatchMode _mode = MatchMode.tennis;
  int _sets = 3;
  bool _goldenPoint = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("COURTMASTER BT", style: TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("MODE DE JEU"),
            Row(
              children: [
                _choiceChip("TENNIS", _mode == MatchMode.tennis, () => setState(() => _mode = MatchMode.tennis)),
                const SizedBox(width: 12),
                _choiceChip("PADEL", _mode == MatchMode.padel, () => setState(() => _mode = MatchMode.padel)),
              ],
            ),
            const SizedBox(height: 32),
            
            _sectionTitle("FORMAT"),
            Row(
              children: [
                _choiceChip("1 SET", _sets == 1, () => setState(() => _sets = 1)),
                const SizedBox(width: 12),
                _choiceChip("3 SETS", _sets == 3, () => setState(() => _sets = 3)),
              ],
            ),
            const SizedBox(height: 32),

            if (_mode == MatchMode.padel) ...[
              _sectionTitle("RÈGLES PADEL"),
              SwitchListTile(
                title: const Text("Punto de Oro (Point décisif)", style: TextStyle(color: Colors.white)),
                value: _goldenPoint,
                activeColor: AppTheme.neonYellow,
                onChanged: (val) => setState(() => _goldenPoint = val),
              ),
              const SizedBox(height: 32),
            ],

            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startMatch,
                child: const Text("LANCER LE MATCH"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onSelected) {
    return Expanded(
      child: InkWell(
        onTap: onSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.neonYellow : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppTheme.neonYellow : Colors.white24),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startMatch() {
    final settings = MatchSettings(
      mode: _mode,
      numberOfSets: _sets,
      goldenPoint: _goldenPoint,
      teamA: [Player(id: '1', name: 'Joueur A', emoji: '🎾')],
      teamB: [Player(id: '2', name: 'Joueur B', emoji: '⭐')],
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScoreboardScreen(settings: settings)),
    );
  }
}
