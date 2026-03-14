import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _channel = MethodChannel('com.antigravity.courtmaster_bt/volume_keys');
  
  static const String _keyTeamA = 'teamA_keycodes';
  static const String _keyTeamB = 'teamB_keycodes';
  static const String _keyEnabled = 'external_commands_enabled';

  // KeyCodes par défaut
  static const List<int> defaultTeamA = [24]; // Volume Up
  static const List<int> defaultTeamB = [25]; // Volume Down

  Future<List<int>> getTeamAKeyCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_keyTeamA);
    if (encoded == null) return defaultTeamA;
    return List<int>.from(jsonDecode(encoded));
  }

  Future<List<int>> getTeamBKeyCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_keyTeamB);
    if (encoded == null) return defaultTeamB;
    return List<int>.from(jsonDecode(encoded));
  }

  Future<bool> isInterceptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<void> setTeamAKeyCodes(List<int> keyCodes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTeamA, jsonEncode(keyCodes));
    await _syncWithNative();
  }

  Future<void> setTeamBKeyCodes(List<int> keyCodes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTeamB, jsonEncode(keyCodes));
    await _syncWithNative();
  }

  Future<void> setInterceptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await _syncWithNative();
  }

  Future<void> _syncWithNative() async {
    final p1 = await getTeamAKeyCodes();
    final p2 = await getTeamBKeyCodes();
    final enabled = await isInterceptionEnabled();
    
    await _channel.invokeMethod('updateConfig', {
      'p1': p1,
      'p2': p2,
      'enabled': enabled,
    });
  }

  Future<void> startListening(int teamIndex) async {
    await _channel.invokeMethod('startListening', {'player': teamIndex});
  }

  // Initialisation au démarrage de l'app
  Future<void> init() async {
    await _syncWithNative();
  }
}
