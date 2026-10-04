import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

/// Result of claiming the daily bonus.
class BonusResult {
  final int coins;
  final int gems;
  const BonusResult(this.coins, this.gems);
}

/// Single source of truth for the player's currencies and stats.
/// Every game bets and pays out through here; state persists to disk.
class WalletService extends ChangeNotifier {
  WalletService._();
  static final WalletService instance = WalletService._();

  static const int startingCoins = 10000;
  static const int startingGems = 50;
  static const int dailyCoinBonus = 1000;
  static const int dailyGemBonus = 5;
  static const Duration bonusCooldown = Duration(hours: 24);

  /// Below the smallest bet in any game -> free rescue top-up is offered.
  static const int rescueThreshold = 50;
  static const int rescueCoins = 2000;
  static const int coinsPerGem = 200;

  /// Called on every level-up (the app shows a toast). Gift goes to mail.
  void Function(int level)? onLevelUp;

  late SharedPreferences _prefs;
  final Player player = Player();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    player.username = _prefs.getString('username') ?? 'Player';
    player.avatar = _prefs.getInt('avatar') ?? 0;
    player.coins = _prefs.getInt('coins') ?? startingCoins;
    player.gems = _prefs.getInt('gems') ?? startingGems;
    player.totalWon = _prefs.getInt('totalWon') ?? 0;
    player.gamesPlayed = _prefs.getInt('gamesPlayed') ?? 0;
    player.lastBonusClaim = _prefs.getInt('lastBonusClaim') ?? 0;
    player.xp = _prefs.getInt('xp') ?? 0;
    player.biggestWin = _prefs.getInt('biggestWin') ?? 0;
    final plays = _prefs.getString('plays');
    player.plays = plays == null
        ? {}
        : Map<String, int>.from(jsonDecode(plays) as Map);
    final mail = _prefs.getString('mail');
    _mail
      ..clear()
      ..addAll(mail == null
          ? [_welcomeMail]
          : (jsonDecode(mail) as List)
              .map((e) => MailItem.fromJson(e as Map<String, dynamic>)));
  }

  static const _welcomeMail = MailItem(
    id: 'welcome',
    title: 'Welcome Gift',
    body: 'Thanks for playing! Here is a little something to get started.',
    coins: 5000,
    gems: 25,
  );

  Future<void> _save() async {
    await _prefs.setString('username', player.username);
    await _prefs.setInt('avatar', player.avatar);
    await _prefs.setInt('coins', player.coins);
    await _prefs.setInt('gems', player.gems);
    await _prefs.setInt('totalWon', player.totalWon);
    await _prefs.setInt('gamesPlayed', player.gamesPlayed);
    await _prefs.setInt('lastBonusClaim', player.lastBonusClaim);
    await _prefs.setInt('xp', player.xp);
    await _prefs.setInt('biggestWin', player.biggestWin);
    await _prefs.setString('plays', jsonEncode(player.plays));
    await _prefs.setString(
        'mail', jsonEncode(_mail.map((m) => m.toJson()).toList()));
  }

  int get coins => player.coins;
  int get gems => player.gems;

  bool canBet(int amount) => amount > 0 && player.coins >= amount;

  /// Deducts a bet and earns XP (1 per 10 coins wagered) in [game].
  /// Returns false if insufficient funds (caller must check).
  bool bet(int amount, {String? game}) {
    if (!canBet(amount)) return false;
    player.coins -= amount;
    player.gamesPlayed += 1;
    if (game != null) player.plays[game] = (player.plays[game] ?? 0) + 1;
    _addXp(amount ~/ 10);
    _save();
    notifyListeners();
    return true;
  }

  /// Credits winnings (0 is fine — just refreshes stats).
  void payout(int amount) {
    if (amount > 0) {
      player.coins += amount;
      player.totalWon += amount;
      if (amount > player.biggestWin) player.biggestWin = amount;
    }
    _save();
    notifyListeners();
  }

  // ---- XP / Level ----
  /// Level L -> L+1 costs 500 * L xp.
  static int xpToNext(int level) => 500 * level;

  int get level => _levelInfo.$1;
  int get xpIntoLevel => _levelInfo.$2;

  (int, int) get _levelInfo {
    var lvl = 1, left = player.xp;
    while (left >= xpToNext(lvl)) {
      left -= xpToNext(lvl);
      lvl++;
    }
    return (lvl, left);
  }

  void _addXp(int amount) {
    final before = level;
    player.xp += amount;
    for (var l = before + 1; l <= level; l++) {
      _mail.insert(
        0,
        MailItem(
          id: 'level_$l',
          title: 'Level $l Reward',
          body: 'You reached level $l. Keep playing to unlock bigger gifts!',
          coins: 1000 * l,
          gems: 5 + l,
        ),
      );
      onLevelUp?.call(l);
    }
  }

  // ---- Mailbox ----
  final List<MailItem> _mail = [];
  List<MailItem> get mail => List.unmodifiable(_mail);

  /// Credits one gift and removes it. Returns null if already claimed.
  MailItem? claimMail(String id) {
    final i = _mail.indexWhere((m) => m.id == id);
    if (i < 0) return null;
    final m = _mail.removeAt(i);
    player.coins += m.coins;
    player.gems += m.gems;
    _save();
    notifyListeners();
    return m;
  }

  /// Claims everything; returns (coins, gems) credited.
  (int, int) claimAllMail() {
    var c = 0, g = 0;
    for (final m in _mail) {
      c += m.coins;
      g += m.gems;
    }
    _mail.clear();
    player.coins += c;
    player.gems += g;
    _save();
    notifyListeners();
    return (c, g);
  }

  // ---- Gems & rescue ----
  bool exchangeGems(int gems) {
    if (gems <= 0 || player.gems < gems) return false;
    player.gems -= gems;
    player.coins += gems * coinsPerGem;
    _save();
    notifyListeners();
    return true;
  }

  bool get rescueReady => player.coins < rescueThreshold;

  bool claimRescue() {
    if (!rescueReady) return false;
    player.coins += rescueCoins;
    _save();
    notifyListeners();
    return true;
  }

  void addGems(int amount) {
    if (amount <= 0) return;
    player.gems += amount;
    _save();
    notifyListeners();
  }

  // ---- Daily bonus ----
  bool get bonusReady =>
      DateTime.now().millisecondsSinceEpoch - player.lastBonusClaim >=
      bonusCooldown.inMilliseconds;

  Duration get bonusRemaining {
    final elapsed = Duration(
      milliseconds:
          DateTime.now().millisecondsSinceEpoch - player.lastBonusClaim,
    );
    final left = bonusCooldown - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Claims the daily bonus. Returns claimed amounts, or zeros if not ready.
  BonusResult claimDailyBonus() {
    if (!bonusReady) return const BonusResult(0, 0);
    player.coins += dailyCoinBonus;
    player.gems += dailyGemBonus;
    player.lastBonusClaim = DateTime.now().millisecondsSinceEpoch;
    _save();
    notifyListeners();
    return const BonusResult(dailyCoinBonus, dailyGemBonus);
  }

  // ---- Profile ----
  void setUsername(String name) {
    player.username = name.trim().isEmpty ? 'Player' : name.trim();
    _save();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    player
      ..username = 'Player'
      ..avatar = 0
      ..coins = startingCoins
      ..gems = startingGems
      ..totalWon = 0
      ..gamesPlayed = 0
      ..lastBonusClaim = 0
      ..xp = 0
      ..biggestWin = 0
      ..plays = {};
    _mail
      ..clear()
      ..add(_welcomeMail);
    await _save();
    notifyListeners();
  }
}
