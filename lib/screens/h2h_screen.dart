import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class HeadToHeadScreen extends StatelessWidget {
  final Player p1;
  final Player p2;

  const HeadToHeadScreen({super.key, required this.p1, required this.p2});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FACE-À-FACE", style: TextStyle(color: AppTheme.neonYellow)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _playerProfile(p1),
                const Text("VS", style: TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold, fontSize: 24)),
                _playerProfile(p2),
              ],
            ),
            const SizedBox(height: 40),
            _comparisonRow("POINTS ELO", p1.elo.toInt().toString(), p2.elo.toInt().toString(), p1.elo > p2.elo),
            _comparisonRow("NIVEAU", p1.calculatedLevel.toString(), p2.calculatedLevel.toString(), p1.calculatedLevel > p2.calculatedLevel),
            _comparisonRow("RÉUSSITE SIMPLE", "${p1.singleWinRate.toStringAsFixed(0)}%", "${p2.singleWinRate.toStringAsFixed(0)}%", p1.singleWinRate > p2.singleWinRate),
            _comparisonRow("RÉUSSITE DOUBLE", "${p1.doubleWinRate.toStringAsFixed(0)}%", "${p2.doubleWinRate.toStringAsFixed(0)}%", p1.doubleWinRate > p2.doubleWinRate),
            _comparisonRow("SÉRIE (STREAK)", p1.streak.isEmpty ? "-" : p1.streak, p2.streak.isEmpty ? "-" : p2.streak, p1.wins > p2.wins),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neonYellow.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.analytics, color: AppTheme.neonYellow, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    _getAdvice(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerProfile(Player p) {
    return Column(
      children: [
        CircleAvatar(radius: 40, backgroundColor: AppTheme.electricCyan.withOpacity(0.2), child: Text(p.emoji, style: const TextStyle(fontSize: 32))),
        const SizedBox(height: 12),
        Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _comparisonRow(String label, String v1, String v2, bool p1Better) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(v1, style: TextStyle(color: p1Better ? AppTheme.neonYellow : Colors.white70, fontWeight: p1Better ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: 0.5, // Simple visual center
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(p1Better ? AppTheme.neonYellow : AppTheme.electricCyan),
                  ),
                ),
              ),
              Text(v2, style: TextStyle(color: !p1Better ? AppTheme.neonYellow : Colors.white70, fontWeight: !p1Better ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  String _getAdvice() {
    if ((p1.elo - p2.elo).abs() > 200) {
      return "Match déséquilibré sur le papier. ${p1.elo > p2.elo ? p1.name : p2.name} est largement favori avec un classement Elo supérieur.";
    }
    return "Duel très serré ! Les statistiques sont proches, le mental et l'endurance feront la différence aujourd'hui.";
  }
}
