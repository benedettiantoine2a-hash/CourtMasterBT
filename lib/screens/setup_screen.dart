import 'package:flutter/material.dart';
import '../models/match_state.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../services/locker_room.dart';
import '../services/matchmaker.dart';
import 'scoreboard_screen.dart';
import 'settings_screen.dart';
import 'player_management_screen.dart';
import 'history_screen.dart';
import 'h2h_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final LockerRoom _locker = LockerRoom();
  MatchMode _mode = MatchMode.padel;
  int _sets = 3;
  bool _goldenPoint = true;
  bool _isDouble = false;
  bool _isCompetition = false;
  bool _isRanked = true; // Match amical ou sérieux
  
  List<Player> _allPlayers = [];
  Player? _pA1;
  Player? _pA2;
  Player? _pB1;
  Player? _pB2;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _locker.getPlayers();
    setState(() {
      _allPlayers = players;
      if (_allPlayers.isNotEmpty) {
        if (_pA1 == null) _pA1 = _allPlayers[0];
        if (_pB1 == null && _allPlayers.length > 1) _pB1 = _allPlayers[1];
        if (_pA2 == null && _allPlayers.length > 2) _pA2 = _allPlayers[2];
        if (_pB2 == null && _allPlayers.length > 3) _pB2 = _allPlayers[3];
      }
    });
  }

  void _autoBalance() {
    if (!_isDouble) return;
    final players = [_pA1, _pA2, _pB1, _pB2].whereType<Player>().toList();
    if (players.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélectionnez 4 joueurs d'abord")));
      return;
    }
    final balanced = Matchmaker.balanceTeams(players);
    setState(() {
      _pA1 = balanced[0][0];
      _pA2 = balanced[0][1];
      _pB1 = balanced[1][0];
      _pB2 = balanced[1][1];
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Équipes équilibrées par niveau !")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("COURTMASTER BT", style: TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
           IconButton(
            icon: const Icon(Icons.history, color: AppTheme.electricCyan),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.neonYellow),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("ORIENTATION"),
            Row(
              children: [
                _choiceChip("FUN & SOCIAL", !_isCompetition, () => setState(() {
                  _isCompetition = false;
                })),
                const SizedBox(width: 12),
                _choiceChip("COMPÉTITION", _isCompetition, () => setState(() {
                  _isCompetition = true;
                  _goldenPoint = true; 
                  _isRanked = true; // En compet, ça compte toujours
                })),
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

            _sectionTitle("TYPE DE MATCH"),
            Row(
              children: [
                _choiceChip("SIMPLE", !_isDouble, () => setState(() => _isDouble = false)),
                const SizedBox(width: 12),
                _choiceChip("DOUBLE", _isDouble, () => setState(() => _isDouble = true)),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle("ÉQUIPE A"),
                if (_isDouble) 
                  TextButton.icon(
                    onPressed: _autoBalance, 
                    icon: const Icon(Icons.balance, size: 16, color: AppTheme.neonYellow),
                    label: const Text("ÉQUILIBRER", style: TextStyle(color: AppTheme.neonYellow, fontSize: 10)),
                  ),
              ],
            ),
            _playerSelector(_pA1, (p) => setState(() => _pA1 = p)),
            if (_isDouble) ...[
              const SizedBox(height: 8),
              _playerSelector(_pA2, (p) => setState(() => _pA2 = p)),
            ],
            const SizedBox(height: 24),

            _sectionTitle("ÉQUIPE B"),
            _playerSelector(_pB1, (p) => setState(() => _pB1 = p)),
            if (_isDouble) ...[
              const SizedBox(height: 8),
              _playerSelector(_pB2, (p) => setState(() => _pB2 = p)),
            ],
            const SizedBox(height: 32),

            _sectionTitle("OPTIONS"),
            SwitchListTile(
              title: const Text("Punto de Oro (Point décisif)", style: TextStyle(color: Colors.white)),
              subtitle: _isCompetition ? const Text("Activé en mode compétition", style: TextStyle(color: AppTheme.neonYellow, fontSize: 10)) : null,
              value: _goldenPoint,
              activeColor: AppTheme.neonYellow,
              onChanged: _isCompetition ? null : (val) => setState(() => _goldenPoint = val),
            ),
            SwitchListTile(
              title: const Text("Compte pour les statistiques", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Match sérieux vs Entraînement", style: TextStyle(color: Colors.white54, fontSize: 10)),
              value: _isRanked,
              activeColor: AppTheme.electricCyan,
              onChanged: _isCompetition ? null : (val) => setState(() => _isRanked = val),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startMatch,
                child: const Text("LANCER LE MATCH"),
              ),
            ),
            const SizedBox(height: 12),
            if (!_isDouble && _pA1 != null && _pB1 != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => HeadToHeadScreen(p1: _pA1!, p2: _pB1!))
                  ),
                  child: const Text("COMPARER (FACE-À-FACE)", style: TextStyle(color: AppTheme.neonYellow)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const PlayerManagementScreen())
                ).then((_) => _loadPlayers()),
                child: const Text("STATS & CLASSEMENT"),
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

  Widget _playerSelector(Player? selected, Function(Player?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Player>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppTheme.pureBlack,
          hint: const Text("Sélectionner un joueur", style: TextStyle(color: Colors.white38)),
          items: _allPlayers.map((p) => DropdownMenuItem(
            value: p,
            child: Row(
              children: [
                Text(p.emoji),
                const SizedBox(width: 12),
                Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.winRate >= 50 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${p.winRate.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: p.winRate >= 50 ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _startMatch() {
    List<Player> teamA = [];
    if (_pA1 != null) teamA.add(_pA1!);
    if (_isDouble && _pA2 != null) teamA.add(_pA2!);

    List<Player> teamB = [];
    if (_pB1 != null) teamB.add(_pB1!);
    if (_isDouble && _pB2 != null) teamB.add(_pB2!);

    if (teamA.isEmpty || teamB.isEmpty || (_isDouble && (teamA.length < 2 || teamB.length < 2))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner tous les joueurs")),
      );
      return;
    }

    final settings = MatchSettings(
      mode: _mode,
      numberOfSets: _sets,
      goldenPoint: _goldenPoint,
      isDouble: _isDouble,
      isRanked: _isRanked,
      teamA: teamA,
      teamB: teamB,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScoreboardScreen(settings: settings)),
    ).then((_) => _loadPlayers());
  }
}
