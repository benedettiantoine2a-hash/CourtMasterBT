import 'player.dart';

enum MatchMode { padel }

class MatchSettings {
  final MatchMode mode;
  final int numberOfSets; // 1 or 3
  final bool goldenPoint; // For Padel
  final bool isDouble;
  final bool isRanked; // Nouveau : si faux, ne change pas les stats des joueurs
  final List<Player> teamA;
  final List<Player> teamB;

  MatchSettings({
    required this.mode,
    required this.numberOfSets,
    required this.goldenPoint,
    this.isDouble = false,
    this.isRanked = true,
    required this.teamA,
    required this.teamB,
  });
}

class ScoreState {
  final List<int> gamesTeamA; // Games per set
  final List<int> gamesTeamB;
  final int pointsA; // 0, 15, 30, 40, ADV
  final int pointsB;
  final int tieBreakPointsA;
  final int tieBreakPointsB;
  final bool isTieBreak;
  final int currentSet;
  final int serverIndex; // 0-3 based on rotation
  final bool matchFinished;
  final String? winner; // "A" or "B"

  ScoreState({
    required this.gamesTeamA,
    required this.gamesTeamB,
    required this.pointsA,
    required this.pointsB,
    this.tieBreakPointsA = 0,
    this.tieBreakPointsB = 0,
    this.isTieBreak = false,
    required this.currentSet,
    required this.serverIndex,
    this.matchFinished = false,
    this.winner,
  });

  ScoreState copyWith({
    List<int>? gamesTeamA,
    List<int>? gamesTeamB,
    int? pointsA,
    int? pointsB,
    int? tieBreakPointsA,
    int? tieBreakPointsB,
    bool? isTieBreak,
    int? currentSet,
    int? serverIndex,
    bool? matchFinished,
    String? winner,
  }) {
    return ScoreState(
      gamesTeamA: gamesTeamA ?? List.from(this.gamesTeamA),
      gamesTeamB: gamesTeamB ?? List.from(this.gamesTeamB),
      pointsA: pointsA ?? this.pointsA,
      pointsB: pointsB ?? this.pointsB,
      tieBreakPointsA: tieBreakPointsA ?? this.tieBreakPointsA,
      tieBreakPointsB: tieBreakPointsB ?? this.tieBreakPointsB,
      isTieBreak: isTieBreak ?? this.isTieBreak,
      currentSet: currentSet ?? this.currentSet,
      serverIndex: serverIndex ?? this.serverIndex,
      matchFinished: matchFinished ?? this.matchFinished,
      winner: winner ?? this.winner,
    );
  }
}
