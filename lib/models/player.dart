class Player {
  final String id;
  final String name;
  final String emoji;
  final int level; // 1-10 (Legacy, will be calculated from Elo)
  final String hand; // 'Gaucher' or 'Droitier'
  final String avatarPath;
  final String streak; // ex: 'VVV', 'DDV' (V=Victoire, D=Défaite)
  
  // Système Elo
  final double elo;
  final List<double> eloHistory;

  // Stats Totales
  final int wins;
  final int losses;

  // Stats Spécifiques
  final int singleWins;
  final int singleLosses;
  final int doubleWins;
  final int doubleLosses;

  Player({
    required this.id,
    required this.name,
    required this.emoji,
    this.level = 5,
    this.hand = 'Droitier',
    this.avatarPath = '',
    this.streak = '',
    this.elo = 1500.0,
    List<double>? eloHistory,
    this.wins = 0,
    this.losses = 0,
    this.singleWins = 0,
    this.singleLosses = 0,
    this.doubleWins = 0,
    this.doubleLosses = 0,
  }) : eloHistory = eloHistory ?? [1500.0];

  bool get isOnFire => streak.endsWith('VVV');
  bool get isZombie => streak.endsWith('DDD');
  
  double get winRate => (wins + losses) == 0 ? 0 : (wins / (wins + losses)) * 100;
  double get singleWinRate => (singleWins + singleLosses) == 0 ? 0 : (singleWins / (singleWins + singleLosses)) * 100;
  double get doubleWinRate => (doubleWins + doubleLosses) == 0 ? 0 : (doubleWins / (doubleWins + doubleLosses)) * 100;

  // Calcul du niveau visuel (1-10) basé sur l'Elo (par ex: 1000=1, 2000=10)
  int get calculatedLevel {
    double lev = (elo - 1000) / 100;
    if (lev < 1) return 1;
    if (lev > 10) return 10;
    return lev.toInt();
  }

  Player copyWith({
    String? name,
    String? emoji,
    int? level,
    String? hand,
    String? avatarPath,
    String? streak,
    double? elo,
    List<double>? eloHistory,
    int? wins,
    int? losses,
    int? singleWins,
    int? singleLosses,
    int? doubleWins,
    int? doubleLosses,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      level: level ?? this.level,
      hand: hand ?? this.hand,
      avatarPath: avatarPath ?? this.avatarPath,
      streak: streak ?? this.streak,
      elo: elo ?? this.elo,
      eloHistory: eloHistory ?? List.from(this.eloHistory),
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      singleWins: singleWins ?? this.singleWins,
      singleLosses: singleLosses ?? this.singleLosses,
      doubleWins: doubleWins ?? this.doubleWins,
      doubleLosses: doubleLosses ?? this.doubleLosses,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'level': level,
        'hand': hand,
        'avatarPath': avatarPath,
        'streak': streak,
        'elo': elo,
        'eloHistory': eloHistory,
        'wins': wins,
        'losses': losses,
        'singleWins': singleWins,
        'singleLosses': singleLosses,
        'doubleWins': doubleWins,
        'doubleLosses': doubleLosses,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        emoji: json['emoji'],
        level: json['level'] ?? 5,
        hand: json['hand'] ?? 'Droitier',
        avatarPath: json['avatarPath'] ?? '',
        streak: json['streak'] ?? '',
        elo: (json['elo'] ?? 1500.0).toDouble(),
        eloHistory: (json['eloHistory'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [1500.0],
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        singleWins: json['singleWins'] ?? 0,
        singleLosses: json['singleLosses'] ?? 0,
        doubleWins: json['doubleWins'] ?? 0,
        doubleLosses: json['doubleLosses'] ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
