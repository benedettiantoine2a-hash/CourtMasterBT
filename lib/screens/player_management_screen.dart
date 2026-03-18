import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player.dart';
import '../services/locker_room.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  final LockerRoom _locker = LockerRoom();
  final TtsService _tts = TtsService();
  List<Player> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _locker.getPlayers();
    players.sort((a, b) => b.elo.compareTo(a.elo));
    setState(() {
      _players = players;
      _isLoading = false;
    });
  }

  void _showAddPlayerDialog([Player? player]) {
    final nameController = TextEditingController(text: player?.name ?? "");
    String hand = player?.hand ?? "Droitier";
    String emoji = player?.emoji ?? "🎾";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player == null ? "AJOUTER UN JOUEUR" : "MODIFIER LE JOUEUR",
                style: const TextStyle(color: AppTheme.neonYellow, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nom du joueur",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text("MAIN FORTE", style: TextStyle(color: Colors.white70)),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("DROITIER"),
                    selected: hand == "Droitier",
                    onSelected: (val) => setModalState(() => hand = "Droitier"),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("GAUCHER"),
                    selected: hand == "Gaucher",
                    onSelected: (val) => setModalState(() => hand = "Gaucher"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    final newPlayer = (player ?? Player(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      emoji: emoji,
                    )).copyWith(
                      name: nameController.text,
                      hand: hand,
                    );
                    await _locker.savePlayer(newPlayer);
                    Navigator.pop(context);
                    _loadPlayers();
                  },
                  child: Text(player == null ? "AJOUTER" : "ENREGISTRER"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("STATS & CLASSEMENT", style: TextStyle(color: AppTheme.neonYellow)),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppTheme.electricCyan),
            onPressed: _showTtsTestDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _players.isEmpty
              ? const Center(child: Text("Aucun joueur pour le moment", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final p = _players[index];
                    return _playerStatCard(p, index + 1);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.neonYellow,
        onPressed: () => _showAddPlayerDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _playerStatCard(Player p, int rank) {
    return Card(
      color: Colors.white12,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: p.isOnFire ? Colors.orange : p.isZombie ? Colors.grey : AppTheme.electricCyan.withOpacity(0.2),
                  child: Text(p.emoji),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Rang #$rank • ${p.hand}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${p.elo.toInt()} pts",
                      style: const TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text("Niveau ${p.calculatedLevel}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white24, size: 20),
                  onPressed: () => _showAddPlayerDialog(p),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: _buildSparkline(p.eloHistory),
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat("SIMPLE", p.singleWins, p.singleLosses, p.singleWinRate, AppTheme.neonYellow),
                _miniStat("DOUBLE", p.doubleWins, p.doubleLosses, p.doubleWinRate, AppTheme.electricCyan),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("STREAK: ", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                ...p.streak.characters.map((c) => Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: c == "V" ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Text(c, style: TextStyle(color: c == "V" ? Colors.greenAccent : Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                )).toList(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(List<double> history) {
    if (history.length < 2) return const SizedBox();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: AppTheme.neonYellow.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.neonYellow.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int w, int l, double rate, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text("$w V", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const Text(" / ", style: TextStyle(color: Colors.white24)),
            Text("$l D", style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        Text("${rate.toStringAsFixed(0)}% Victoires", style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }

  void _showTtsTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.pureBlack,
        title: const Text("TEST AUDIO", style: TextStyle(color: AppTheme.neonYellow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ttsButton("Début Match", "start"),
            _ttsButton("Punto de Oro", "golden_point"),
            _ttsButton("Balle de match", "match_point"),
            _ttsButton("Remontada", "comeback"),
            _ttsButton("Commentaire Fun", "fun"),
            _ttsButton("Victoire", "win"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FERMER")),
        ],
      ),
    );
  }

  Widget _ttsButton(String label, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
          onPressed: () => _tts.speakRandom(category),
          child: Text(label),
        ),
      ),
    );
  }
}
