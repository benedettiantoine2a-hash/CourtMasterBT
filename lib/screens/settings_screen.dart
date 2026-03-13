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
  int _p1Key = 0;
  int _p2Key = 0;
  int? _listeningFor; // null, 1 ou 2

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _keyCaptureService = VolumeKeyService(onKeyCaptured: _handleKeyCaptured);
  }

  Future<void> _loadSettings() async {
    final enabled = await _settingsService.isInterceptionEnabled();
    final p1 = await _settingsService.getPlayer1KeyCode();
    final p2 = await _settingsService.getPlayer2KeyCode();
    setState(() {
      _enabled = enabled;
      _p1Key = p1;
      _p2Key = p2;
    });
  }

  void _handleKeyCaptured(int player, int keyCode) {
    if (_listeningFor == player) {
      setState(() {
        if (player == 1) {
          _p1Key = keyCode;
          _settingsService.setPlayer1KeyCode(keyCode);
        } else {
          _p2Key = keyCode;
          _settingsService.setPlayer2KeyCode(keyCode);
        }
        _listeningFor = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Touche enregistrée pour Joueur $player : $keyCode")),
      );
    }
  }

  void _startListening(int player) {
    setState(() {
      _listeningFor = player;
    });
    _settingsService.startListening(player);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PARAMÈTRES", style: TextStyle(color: AppTheme.neonYellow, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            
            _sectionTitle("CONFIGURATION DES TOUCHES"),
            _keyConfigTile(1, _p1Key),
            const SizedBox(height: 16),
            _keyConfigTile(2, _p2Key),
            
            const Spacer(),
            const Text(
              "Note: Les touches configurées ne fonctionneront que si l'interrupteur ci-dessus est activé.",
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

  Widget _keyConfigTile(int player, int keyCode) {
    bool isListening = _listeningFor == player;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isListening ? AppTheme.neonYellow : Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Joueur $player", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isListening ? "Appuyez sur une touche..." : "Code actuel : $keyCode",
                  style: TextStyle(color: isListening ? AppTheme.neonYellow : Colors.white54),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isListening ? null : () => _startListening(player),
            style: ElevatedButton.styleFrom(
              backgroundColor: isListening ? Colors.grey : AppTheme.electricCyan.withOpacity(0.2),
              foregroundColor: AppTheme.electricCyan,
            ),
            child: Text(isListening ? "ÉCOUTE..." : "CONFIGURER"),
          ),
        ],
      ),
    );
  }
}
