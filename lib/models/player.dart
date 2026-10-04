/// Local player state. Serialized to shared_preferences as individual keys.
class Player {
  String username;
  int avatar; // reserved for future avatar set
  int coins;
  int gems; // secondary currency
  int totalWon;
  int gamesPlayed;
  int lastBonusClaim; // epoch ms, 0 = never
  int xp;
  int biggestWin;
  Map<String, int> plays; // game title -> rounds played

  Player({
    this.username = 'Player',
    this.avatar = 0,
    this.coins = 10000,
    this.gems = 50,
    this.totalWon = 0,
    this.gamesPlayed = 0,
    this.lastBonusClaim = 0,
    this.xp = 0,
    this.biggestWin = 0,
    Map<String, int>? plays,
  }) : plays = plays ?? {};

  /// Most-played game title, or null before the first round.
  String? get favoriteGame => plays.isEmpty
      ? null
      : plays.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

/// A claimable gift in the mailbox.
class MailItem {
  final String id;
  final String title;
  final String body;
  final int coins;
  final int gems;

  const MailItem({
    required this.id,
    required this.title,
    required this.body,
    this.coins = 0,
    this.gems = 0,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'body': body, 'coins': coins, 'gems': gems};

  factory MailItem.fromJson(Map<String, dynamic> j) => MailItem(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        coins: j['coins'] as int? ?? 0,
        gems: j['gems'] as int? ?? 0,
      );
}
