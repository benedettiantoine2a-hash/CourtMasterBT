import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class MatchCardWidget extends StatelessWidget {
  final List<int> gamesTeamA;
  final List<int> gamesTeamB;
  final List<Player> teamAPlayers;
  final List<Player> teamBPlayers;
  final String? winner;

  const MatchCardWidget({
    super.key,
    required this.gamesTeamA,
    required this.gamesTeamB,
    required this.teamAPlayers,
    required this.teamBPlayers,
    this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.pureBlack, Color(0xFF1A1A1A)],
        ),
        border: Border.all(color: AppTheme.neonYellow.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MATCH CARD",
                style: TextStyle(
                  color: AppTheme.neonYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "PADEL SCORE & FUN",
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _teamSection("ÉQUIPE A", teamAPlayers, gamesTeamA, winner == "A"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white12),
          ),
          _teamSection("ÉQUIPE B", teamBPlayers, gamesTeamB, winner == "B"),
          
          const SizedBox(height: 30),
          const Text(
            "Félicitations aux joueurs !",
            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _teamSection(String name, List<Player> players, List<int> sets, bool isWinner) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isWinner ? AppTheme.neonYellow : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.emoji_events, color: AppTheme.neonYellow, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: players.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _miniAvatar(p),
                  )).toList(),
                ),
              ],
            ),
            Row(
              children: sets.map((s) => Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sets.indexOf(s) == sets.length - 1 ? AppTheme.electricCyan.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(color: AppTheme.electricCyan.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.toString(),
                  style: const TextStyle(color: AppTheme.electricCyan, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              )).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniAvatar(Player player) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.electricCyan, width: 1),
          ),
          child: Center(child: Text(player.emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(height: 4),
        Text(player.name, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }
}
