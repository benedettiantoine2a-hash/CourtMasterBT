import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class LockerRoom {
  static const String _key = 'players';

  Future<List<Player>> getPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    final List<dynamic> json = jsonDecode(data);
    return json.map((e) => Player.fromJson(e)).toList();
  }

  Future<void> savePlayer(Player player) async {
    final players = await getPlayers();
    players.add(player);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(players.map((e) => e.toJson()).toList()));
  }

  Future<void> removePlayer(String id) async {
    final players = await getPlayers();
    players.removeWhere((p) => p.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(players.map((e) => e.toJson()).toList()));
  }
}
