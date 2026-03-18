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
  String _inputMode = 'two_buttons';
  List<int> _teamAKeys = [];
  List<int> _teamBKeys = [];
  int? _listeningFor;
  bool _vibrationEnabled = true;
  bool _sideChangeEnabled = true;
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _keyCaptureService = VolumeKeyService(onKeyCaptured: _handleKeyCaptured);
  }

  Future<void> _loadSettings() async {
    final enabled = await _settingsService.isInterceptionEnabled();
    final mode = await _settingsService.getInputMode();
    final p1 = await _settingsService.getTeamAKeyCodes();
    final p2 = await _settingsService.getTeamBKeyCodes();
    final vibration = await _settingsService.isVibrationEnabled();
    final sideChange = await _settingsService.isSideChangeAlertEnabled();
    final voice = await _settingsService.isVoiceEnabled();
    setState(() {
      _enabled = enabled;
      _inputMode = mode;
      _teamAKeys = p1;
      _teamBKeys = p2;
      _vibrationEnabled = vibration;
      _sideChangeEnabled = sideChange;
      _voiceEnabled = voice;
    });
  }

  void _handleKeyCaptured(int teamIndex, int keyCode) {
    if (_listeningFor == teamIndex) {
      setState(() {
        if (_inputMode == 'one_button') {
          // En mode 1 bouton, on configure les DEUX équipes avec le même code
          _teamAKeys = [keyCode];
          _teamBKeys = [keyCode];
          _settingsService.setTeamAKeyCodes(_teamAKeys);
          _settingsService.setTeamBKeyCodes(_teamBKeys);
        } else {
          if (teamIndex == 1) {
            _teamAKeys = [keyCode];
            _settingsService.setTeamAKeyCodes(_teamAKeys);
          } else {
            _teamBKeys = [keyCode];
            _settingsService.setTeamBKeyCodes(_teamBKeys);
          }
        }
        _listeningFor = null;
      });
      
      if (_inputMode == 'one_button') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bouton configuré : code $keyCode")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Touche définie pour l'Équipe ${teamIndex == 1 ? 'A' : 'B'} : code $keyCode")),
        );
      }
    }
  }

  void _startListening(int teamIndex) {
    setState(() {
      _listeningFor = teamIndex;
    });
    _settingsService.startListening(teamIndex);
  }

  void _resetToDefaults() {
    setState(() {
      _teamAKeys = [24]; // Volume Up
      _teamBKeys = [25]; // Volume Down
      _settingsService.setTeamAKeyCodes(_teamAKeys);
      _settingsService.setTeamBKeyCodes(_teamBKeys);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Touches réinitialisées : Vol+ → Équipe A, Vol- → Équipe B")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOneButton = _inputMode == 'one_button';

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
      body: SingleChildScrollView(
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

            _sectionTitle("MODE D'ENTRÉE"),
            Row(
              children: [
                _modeChip("2 BOUTONS", 'two_buttons', Icons.gamepad_outlined),
                const SizedBox(width: 12),
                _modeChip("1 BOUTON", 'one_button', Icons.watch_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOneButton
                ? "Clic = Éq. A · Double-clic = Éq. B · Maintenu = Annuler"
                : "Chaque bouton correspond à une équipe",
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),

            _sectionTitle("PRÉFÉRENCES DE JEU"),
            SwitchListTile(
              title: const Text("Vibrations", style: TextStyle(color: Colors.white, fontSize: 18)),
              subtitle: const Text("Vibre lors de l'ajout d'un point", style: TextStyle(color: Colors.white54)),
              value: _vibrationEnabled,
              activeColor: AppTheme.neonYellow,
              onChanged: (val) {
                setState(() => _vibrationEnabled = val);
                _settingsService.setVibrationEnabled(val);
              },
            ),
            SwitchListTile(
              title: const Text("Alerte Changement de Côté", style: TextStyle(color: Colors.white, fontSize: 18)),
              subtitle: const Text("Annonce vocale tous les deux jeux", style: TextStyle(color: Colors.white54)),
              value: _sideChangeEnabled,
              activeColor: AppTheme.neonYellow,
              onChanged: (val) {
                setState(() => _sideChangeEnabled = val);
                _settingsService.setSideChangeAlertEnabled(val);
              },
            ),
            SwitchListTile(
              title: const Text("Annonces Vocales", style: TextStyle(color: Colors.white, fontSize: 18)),
              subtitle: const Text("Activer l'arbitrage vocal (TTS)", style: TextStyle(color: Colors.white54)),
              value: _voiceEnabled,
              activeColor: AppTheme.neonYellow,
              onChanged: (val) {
                setState(() => _voiceEnabled = val);
                _settingsService.setVoiceEnabled(val);
              },
            ),
            const SizedBox(height: 32),
            
            // Configuration des touches
            if (isOneButton) ...[
              _sectionTitle("VOTRE BOUTON"),
              _oneButtonConfigTile(),
            ] else ...[
              _sectionTitle("CONFIGURATION DES ÉQUIPES"),
              _keyConfigTile(1, _teamAKeys, "A"),
              const SizedBox(height: 16),
              _keyConfigTile(2, _teamBKeys, "B"),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.restore, color: Colors.white54),
                  label: const Text("RÉINITIALISER LES TOUCHES", style: TextStyle(color: Colors.white54)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                ),
              ),
            ],
            
            const SizedBox(height: 48),
            Text(
              isOneButton
                ? "Appuyez sur 'CONFIGURER' puis sur le bouton de votre appareil (montre, télécommande à 1 bouton...)."
                : "Appuyez sur 'CONFIGURER' puis sur une touche de votre module Bluetooth.",
              style: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, String mode, IconData icon) {
    final selected = _inputMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _inputMode = mode);
          _settingsService.setInputMode(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.neonYellow : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppTheme.neonYellow : Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.black : Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _oneButtonConfigTile() {
    bool isListening = _listeningFor == 1;
    final keyCodes = _teamAKeys;
    
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
              const Icon(Icons.watch_outlined, color: AppTheme.electricCyan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Bouton unique", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      isListening ? "Appuyez sur votre bouton..." : (keyCodes.isEmpty ? "Pas de touche configurée" : "Code : ${keyCodes.first}"),
                      style: TextStyle(color: isListening ? AppTheme.neonYellow : Colors.white54),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isListening ? null : () => _startListening(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isListening ? Colors.grey : AppTheme.electricCyan.withOpacity(0.2),
                  foregroundColor: AppTheme.electricCyan,
                ),
                child: Text(isListening ? "ÉCOUTE..." : "CONFIGURER"),
              ),
            ],
          ),
        ],
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Équipe $teamLetter", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  isListening ? "Appuyez sur une touche..." : (keyCodes.isEmpty ? "Pas de touche configurée" : "Code : ${keyCodes.join(', ')}"),
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
    );
  }
}
