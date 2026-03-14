import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/volume_key_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  late VolumeKeyService _keyCaptureService;

  bool _enabled = false;
  List<int> _teamAKeys = [];
  List<int> _teamBKeys = [];
  int? _listeningFor; // null, 1 (Team A) ou 2 (Team B)

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _keyCaptureService = VolumeKeyService(onKeyCaptured: _handleKeyCaptured);
  }

  Future<void> _loadSettings() async {
    final enabled = await _settingsService.isInterceptionEnabled();
    final p1 = await _settingsService.getTeamAKeyCodes();
    final p2 = await _settingsService.getTeamBKeyCodes();
    setState(() {
      _enabled = enabled;
      _teamAKeys = p1;
      _teamBKeys = p2;
    });
  }

  void _handleKeyCaptured(int teamIndex, int keyCode) {
    if (_listeningFor == teamIndex) {
      setState(() {
        if (teamIndex == 1) {
          if (!_teamAKeys.contains(keyCode)) {
            _teamAKeys.add(keyCode);
            _settingsService.setTeamAKeyCodes(_teamAKeys);
          }
        } else {
          if (!_teamBKeys.contains(keyCode)) {
            _teamBKeys.add(keyCode);
            _settingsService.setTeamBKeyCodes(_teamBKeys);
          }
        }
        _listeningFor = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Touche ajoutée pour l'Équipe ${teamIndex == 1 ? 'A' : 'B'} : $keyCode")),
      );
    }
  }

  void _startListening(int teamIndex) {
    setState(() {
      _listeningFor = teamIndex;
    });
    _settingsService.startListening(teamIndex);
  }

  void _clearKeys(int teamIndex) {
    setState(() {
      if (teamIndex == 1) {
        _teamAKeys = [];
        _settingsService.setTeamAKeyCodes([]);
      } else {
        _teamBKeys = [];
        _settingsService.setTeamBKeyCodes([]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PARAMÈTRES", style: TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("COMMANDES EXTERNES"),
            SwitchListTile(
              title: const Text("Activer les commandes", style: TextStyle(color: Colors.white, fontSize: 18)),
              subtitle: const Text("Intercepte les touches Bluetooth/Volume", style: TextStyle(color: Colors.white54)),
              value: _enabled,
              activeColor: AppTheme.neonYellow,
              onChanged: (val) {
                setState(() => _enabled = val);
                _settingsService.setInterceptionEnabled(val);
              },
            ),
            const SizedBox(height: 32),
            
            _sectionTitle("CONFIGURATION DES ÉQUIPES"),
            _keyConfigTile(1, _teamAKeys, "A"),
            const SizedBox(height: 16),
            _keyConfigTile(2, _teamBKeys, "B"),
            
            const Spacer(),
            const Text(
              "Note: Appuyez sur 'CONFIGURER' puis sur une touche de votre module Bluetooth pour l'ajouter. Vous pouvez ajouter plusieurs touches par équipe.",
              style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _keyConfigTile(int teamIndex, List<int> keyCodes, String teamLetter) {
    bool isListening = _listeningFor == teamIndex;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isListening ? AppTheme.neonYellow : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Équipe $teamLetter", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      isListening ? "Appuyez sur une touche..." : (keyCodes.isEmpty ? "Pas de touche configurée" : "Codes : ${keyCodes.join(', ')}"),
                      style: TextStyle(color: isListening ? AppTheme.neonYellow : Colors.white54),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isListening ? null : () => _startListening(teamIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isListening ? Colors.grey : AppTheme.electricCyan.withOpacity(0.2),
                  foregroundColor: AppTheme.electricCyan,
                ),
                child: Text(isListening ? "ÉCOUTE..." : "CONFIGURER"),
              ),
            ],
          ),
          if (keyCodes.isNotEmpty && !isListening)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _clearKeys(teamIndex),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: const Text("Effacer", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
