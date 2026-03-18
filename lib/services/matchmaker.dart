import '../models/player.dart';

class Matchmaker {
  /// Organise 4 joueurs en 2 équipes de la manière la plus équilibrée possible
  /// en se basant sur leur niveau (level).
  static List<List<Player>> balanceTeams(List<Player> players) {
    if (players.length != 4) return [players.sublist(0, 2), players.sublist(2, 4)];

    // On trie les joueurs par niveau décroissant
    final sorted = List<Player>.from(players)..sort((a, b) => b.level.compareTo(a.level));

    // Combinaisons possibles (3 pour 4 joueurs) :
    // 1. (1+4) vs (2+3) -> Souvent le plus équilibré
    // 2. (1+2) vs (3+4) -> Le plus déséquilibré
    // 3. (1+3) vs (2+4) -> Intermédiaire

    final team1 = [sorted[0], sorted[3]];
    final team2 = [sorted[1], sorted[2]];

    return [team1, team2];
  }

  /// Organise 4 joueurs en 2 équipes de manière totalement aléatoire.
  static List<List<Player>> randomTeams(List<Player> players) {
    final shuffled = List<Player>.from(players)..shuffle();
    return [
      [shuffled[0], shuffled[1]],
      [shuffled[2], shuffled[3]],
    ];
  }
}
