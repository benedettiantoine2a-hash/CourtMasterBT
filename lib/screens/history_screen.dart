import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/locker_room.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LockerRoom _locker = LockerRoom();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _locker.getMatchHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(String matchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.pureBlack,
        title: const Text("Supprimer le match ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Cette action est irréversible. Si le match comptait pour les stats, celles-ci seront décrémentées.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULER")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _locker.deleteMatch(matchId);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HISTORIQUE DES MATCHS", style: TextStyle(color: AppTheme.neonYellow)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
               ? const Center(child: Text("Aucun match enregistré", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final match = _history[index];
                    final String matchId = match['id'] ?? "";
                    final DateTime date = DateTime.parse(match['date']);
                    final List<dynamic> teamA = match['teamA'];
                    final List<dynamic> teamB = match['teamB'];
                    final List<dynamic> scoreA = match['scoreA'];
                    final List<dynamic> scoreB = match['scoreB'];
                    final String winner = match['winner'];
                    final bool isRanked = match['isRanked'] ?? true;
                    final bool isDouble = match['isDouble'] ?? false;

                    return Card(
                      color: Colors.white12,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(date),
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isRanked ? AppTheme.electricCyan.withOpacity(0.2) : Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: isRanked ? AppTheme.electricCyan : Colors.white24),
                                      ),
                                      child: Text(
                                        isRanked ? "OFFICIEL" : "AMICAL",
                                        style: TextStyle(
                                          color: isRanked ? AppTheme.electricCyan : Colors.white38,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonYellow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "VICTOIRE EQUIPE $winner",
                                        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                                      onPressed: () => _confirmDelete(matchId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        teamA.join(" & "), 
                                        style: TextStyle(
                                          color: winner == "A" ? AppTheme.neonYellow : Colors.white, 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        teamB.join(" & "), 
                                        style: TextStyle(
                                          color: winner == "B" ? AppTheme.neonYellow : Colors.white,
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(scoreA.length, (i) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      child: Column(
                                        children: [
                                          Text(scoreA[i].toString(), style: TextStyle(color: scoreA[i] > scoreB[i] ? AppTheme.neonYellow : Colors.white38, fontWeight: FontWeight.bold)),
                                          Text(scoreB[i].toString(), style: TextStyle(color: scoreB[i] > scoreA[i] ? AppTheme.neonYellow : Colors.white38)),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isDouble ? "Double 🎾🎾" : "Simple 🎾",
                                style: const TextStyle(color: Colors.white24, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
