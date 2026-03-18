import 'dart:collection';
import 'dart:math' as math;
import '../models/match_state.dart';
import '../models/player.dart';
import 'locker_room.dart';

class MatchLogic {
  final MatchSettings settings;
  final List<Player> teamAPlayers;
  final List<Player> teamBPlayers;
  final ListQueue<ScoreState> _history = ListQueue<ScoreState>();
  late ScoreState _currentState;

  MatchLogic(this.settings, {required this.teamAPlayers, required this.teamBPlayers}) {
    _currentState = ScoreState(
      gamesTeamA: List.filled(settings.numberOfSets, 0),
      gamesTeamB: List.filled(settings.numberOfSets, 0),
      pointsA: 0,
      pointsB: 0,
      currentSet: 0,
      serverIndex: 0,
    );
  }

  ScoreState get state => _currentState;

  void addPoint(String team) {
    if (_currentState.matchFinished) return;
    _history.addLast(_currentState.copyWith());
    
    if (_currentState.isTieBreak) {
      _handleTieBreakPoint(team);
    } else {
      _handleNormalPoint(team);
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      _currentState = _history.removeLast();
    }
  }

  void _handleNormalPoint(String team) {
    int pA = _currentState.pointsA;
    int pB = _currentState.pointsB;

    if (team == "A") {
      if (pA == 40) {
        if (settings.goldenPoint && pB == 40) {
          _winGame("A");
        } else if (pB == 40) {
          _currentState = _currentState.copyWith(pointsA: 41); // Advantage
        } else if (pB == 41) {
          _currentState = _currentState.copyWith(pointsB: 40); // Back to deuce
        } else {
          _winGame("A");
        }
      } else if (pA == 41) {
        _winGame("A");
      } else {
        _currentState = _currentState.copyWith(pointsA: _nextPoint(pA));
      }
    } else {
      if (pB == 40) {
        if (settings.goldenPoint && pA == 40) {
          _winGame("B");
        } else if (pA == 40) {
          _currentState = _currentState.copyWith(pointsB: 41); // Advantage
        } else if (pA == 41) {
          _currentState = _currentState.copyWith(pointsA: 40); // Back to deuce
        } else {
          _winGame("B");
        }
      } else if (pB == 41) {
        _winGame("B");
      } else {
        _currentState = _currentState.copyWith(pointsB: _nextPoint(pB));
      }
    }
  }

  int _nextPoint(int current) {
    if (current == 0) return 15;
    if (current == 15) return 30;
    if (current == 30) return 40;
    return 40;
  }

  void _handleTieBreakPoint(String team) {
    int tpA = _currentState.tieBreakPointsA;
    int tpB = _currentState.tieBreakPointsB;

    if (team == "A") tpA++; else tpB++;

    int totalPoints = tpA + tpB;
    if (totalPoints % 2 != 0) {
       _currentState = _currentState.copyWith(serverIndex: (_currentState.serverIndex + 1) % (settings.isDouble ? 4 : 2));
    }

    _currentState = _currentState.copyWith(tieBreakPointsA: tpA, tieBreakPointsB: tpB);

    if (tpA >= 7 && (tpA - tpB) >= 2) {
      _winGame("A");
    } else if (tpB >= 7 && (tpB - tpA) >= 2) {
      _winGame("B");
    }
  }

  void _winGame(String team) {
    int currentSet = _currentState.currentSet;
    List<int> gA = List.from(_currentState.gamesTeamA);
    List<int> gB = List.from(_currentState.gamesTeamB);

    if (team == "A") gA[currentSet]++; else gB[currentSet]++;

    _currentState = _currentState.copyWith(
      pointsA: 0,
      pointsB: 0,
      tieBreakPointsA: 0,
      tieBreakPointsB: 0,
      isTieBreak: false,
      gamesTeamA: gA,
      gamesTeamB: gB,
      serverIndex: (_currentState.serverIndex + 1) % (settings.isDouble ? 4 : 2),
    );

    _checkSetStatus();
  }

  void _checkSetStatus() {
    int currentSet = _currentState.currentSet;
    int gA = _currentState.gamesTeamA[currentSet];
    int gB = _currentState.gamesTeamB[currentSet];

    if (gA == 6 && gB == 6) {
      _currentState = _currentState.copyWith(isTieBreak: true);
    } else if ((gA >= 6 && (gA - gB) >= 2) || (gA == 7 && gB == 6)) {
      _winSet("A");
    } else if ((gB >= 6 && (gB - gA) >= 2) || (gB == 7 && gA == 6)) {
      _winSet("B");
    }
  }

  void _winSet(String team) {
    int completedSetsA = 0;
    int completedSetsB = 0;
    for(int i=0; i <= _currentState.currentSet; i++) {
      int sA = _currentState.gamesTeamA[i];
      int sB = _currentState.gamesTeamB[i];
      if ((sA >= 6 && sA - sB >= 2) || (sA == 7 && sB == 6)) completedSetsA++;
      if ((sB >= 6 && sB - sA >= 2) || (sB == 7 && sA == 6)) completedSetsB++;
    }

    int winThreshold = (settings.numberOfSets / 2).ceil();

    if (completedSetsA >= winThreshold) {
      _currentState = _currentState.copyWith(matchFinished: true, winner: "A");
      _finalizeMatch("A");
    } else if (completedSetsB >= winThreshold) {
      _currentState = _currentState.copyWith(matchFinished: true, winner: "B");
      _finalizeMatch("B");
    } else {
      _currentState = _currentState.copyWith(currentSet: _currentState.currentSet + 1);
    }
  }

  void _finalizeMatch(String winner) async {
    final locker = LockerRoom();
    
    await locker.saveMatch({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateTime.now().toIso8601String(),
      'teamA': teamAPlayers.map((p) => p.name).toList(),
      'teamB': teamBPlayers.map((p) => p.name).toList(),
      'playerIdsA': teamAPlayers.map((p) => p.id).toList(), 
      'playerIdsB': teamBPlayers.map((p) => p.id).toList(),
      'scoreA': _currentState.gamesTeamA,
      'scoreB': _currentState.gamesTeamB,
      'winner': winner,
      'isDouble': settings.isDouble,
      'isRanked': settings.isRanked,
    });

    if (!settings.isRanked) return;

    // Calcul Elo
    double avgEloA = teamAPlayers.map((p) => p.elo).reduce((a, b) => a + b) / teamAPlayers.length;
    double avgEloB = teamBPlayers.map((p) => p.elo).reduce((a, b) => a + b) / teamBPlayers.length;

    for (var p in teamAPlayers) {
      bool isWinner = (winner == "A");
      double delta = _calculateEloDelta(p.elo, avgEloB, isWinner);
      _updatePlayerStats(p, isWinner, delta, locker);
    }
    for (var p in teamBPlayers) {
      bool isWinner = (winner == "B");
      double delta = _calculateEloDelta(p.elo, avgEloA, isWinner);
      _updatePlayerStats(p, isWinner, delta, locker);
    }
  }

  double _calculateEloDelta(double playerElo, double opponentAvgElo, bool isWinner) {
    const double K = 32.0;
    double expectedScore = 1.0 / (1.0 + math.pow(10.0, (opponentAvgElo - playerElo) / 400.0));
    double actualScore = isWinner ? 1.0 : 0.0;
    return K * (actualScore - expectedScore);
  }

  void _updatePlayerStats(Player p, bool isWinner, double eloDelta, LockerRoom locker) async {
    String newStreak = (p.streak + (isWinner ? "V" : "D"));
    if (newStreak.length > 5) newStreak = newStreak.substring(newStreak.length - 5);
    
    double newElo = p.elo + eloDelta;
    List<double> newHistory = List.from(p.eloHistory)..add(newElo);
    if (newHistory.length > 20) newHistory.removeAt(0);

    await locker.savePlayer(p.copyWith(
      streak: newStreak, 
      elo: newElo,
      eloHistory: newHistory,
      wins: p.wins + (isWinner ? 1 : 0),
      losses: p.losses + (isWinner ? 0 : 1),
      singleWins: !settings.isDouble ? p.singleWins + (isWinner ? 1 : 0) : p.singleWins,
      singleLosses: !settings.isDouble ? p.singleLosses + (isWinner ? 0 : 1) : p.singleLosses,
      doubleWins: settings.isDouble ? p.doubleWins + (isWinner ? 1 : 0) : p.doubleWins,
      doubleLosses: settings.isDouble ? p.doubleLosses + (isWinner ? 0 : 1) : p.doubleLosses,
    ));
  }

  String getFormattedPoints(String team) {
    int p = (team == "A") ? _currentState.pointsA : _currentState.pointsB;
    if (_currentState.isTieBreak) {
      return (team == "A") ? _currentState.tieBreakPointsA.toString() : _currentState.tieBreakPointsB.toString();
    }
    if (p == 41) return "AD";
    return p.toString();
  }
}
