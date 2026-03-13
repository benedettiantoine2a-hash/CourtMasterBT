import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _channel = MethodChannel('com.antigravity.courtmaster_bt/volume_keys');
  
  static const String _keyP1 = 'player1_keycode';
  static const String _keyP2 = 'player2_keycode';
  static const String _keyEnabled = 'external_commands_enabled';

  // KeyCodes par défaut (Volume Up / Down sur Android)
  static const int defaultP1 = 24;
  static const int defaultP2 = 25;

  Future<int> getPlayer1KeyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyP1) ?? defaultP1;
  }

  Future<int> getPlayer2KeyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyP2) ?? defaultP2;
  }

  Future<bool> isInterceptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setPlayer1KeyCode(int keyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyP1, keyCode);
    await _syncWithNative();
  }

  Future<void> setPlayer2KeyCode(int keyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyP2, keyCode);
    await _syncWithNative();
  }

  Future<void> setInterceptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await _syncWithNative();
  }

  Future<void> _syncWithNative() async {
    final p1 = await getPlayer1KeyCode();
    final p2 = await getPlayer2KeyCode();
    final enabled = await isInterceptionEnabled();
    
    await _channel.invokeMethod('updateConfig', {
      'p1': p1,
      'p2': p2,
      'enabled': enabled,
    });
  }

  Future<void> startListening(int player) async {
    await _channel.invokeMethod('startListening', {'player': player});
  }

  // Initialisation au démarrage de l'app
  Future<void> init() async {
    await _syncWithNative();
  }
}
