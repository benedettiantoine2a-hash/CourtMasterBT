import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class LockerRoom {
  static const String _playersKey = 'players';
  static const String _matchesKey = 'matches';

  // --- Gestion des Joueurs ---

  Future<List<Player>> getPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_playersKey);
    if (data == null) return [];
    try {
      final List<dynamic> json = jsonDecode(data);
      return json.map((e) => Player.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> savePlayer(Player player) async {
    final players = await getPlayers();
    final index = players.indexWhere((p) => p.id == player.id);
    if (index >= 0) {
      players[index] = player;
    } else {
      players.add(player);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playersKey, jsonEncode(players.map((e) => e.toJson()).toList()));
  }

  Future<void> removePlayer(String id) async {
    final players = await getPlayers();
    players.removeWhere((p) => p.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playersKey, jsonEncode(players.map((e) => e.toJson()).toList()));
  }

  // --- Gestion de l'Historique des Matchs ---

  Future<List<Map<String, dynamic>>> getMatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_matchesKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> saveMatch(Map<String, dynamic> matchData) async {
    final history = await getMatchHistory();
    history.insert(0, matchData); // Le plus récent en premier
    if (history.length > 50) history.removeLast(); // On garde les 50 derniers
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_matchesKey, jsonEncode(history));
  }

  Future<void> deleteMatch(String matchId) async {
    final history = await getMatchHistory();
    final index = history.indexWhere((m) => m['id'] == matchId);
    if (index == -1) return;

    final match = history[index];
    final bool isRanked = match['isRanked'] ?? false;
    
    // Si le match comptait pour les stats, on décrémente et rollback Elo
    if (isRanked) {
      final String winner = match['winner'];
      final List<dynamic> pIdsA = match['playerIdsA'] ?? [];
      final List<dynamic> pIdsB = match['playerIdsB'] ?? [];
      final bool isDouble = match['isDouble'] ?? false;

      final players = await getPlayers();
      
      for (var id in pIdsA) {
        _rollbackPlayerStats(players, id, winner == "A", isDouble);
      }
      for (var id in pIdsB) {
        _rollbackPlayerStats(players, id, winner == "B", isDouble);
      }
      
      // Sauvegarder les joueurs mis à jour
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playersKey, jsonEncode(players.map((e) => e.toJson()).toList()));
    }

    history.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_matchesKey, jsonEncode(history));
  }

  void _rollbackPlayerStats(List<Player> players, dynamic id, bool won, bool isDouble) {
    final pIdx = players.indexWhere((p) => p.id == id.toString());
    if (pIdx != -1) {
      final p = players[pIdx];
      
      // Rollback Elo
      List<double> newEloHistory = List.from(p.eloHistory);
      double prevElo = p.elo;
      if (newEloHistory.length > 1) {
        newEloHistory.removeLast();
        prevElo = newEloHistory.last;
      }

      // Rollback Streak
      String newStreak = p.streak;
      if (newStreak.isNotEmpty) {
        newStreak = newStreak.substring(0, newStreak.length - 1);
      }

      players[pIdx] = p.copyWith(
        wins: p.wins - (won ? 1 : 0),
        losses: p.losses - (won ? 0 : 1),
        singleWins: !isDouble ? p.singleWins - (won ? 1 : 0) : p.singleWins,
        singleLosses: !isDouble ? p.singleLosses - (won ? 0 : 1) : p.singleLosses,
        doubleWins: isDouble ? p.doubleWins - (won ? 1 : 0) : p.doubleWins,
        doubleLosses: isDouble ? p.doubleLosses - (won ? 0 : 1) : p.doubleLosses,
        elo: prevElo,
        eloHistory: newEloHistory,
        streak: newStreak,
      );
    }
  }
}
