import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bets from any game feed one XP bar; level-up drops a mail gift',
      () async {
    final w = WalletService.instance;
    await w.load();
    await w.resetProgress();
    int? leveled;
    w.onLevelUp = (l) => leveled = l;

    expect(w.mail.single.id, 'welcome');
    expect(w.level, 1);

    // 500 xp to level 2 = 5000 coins wagered, split across games.
    for (var i = 0; i < 3; i++) {
      w.bet(1000, game: 'PLINKO');
    }
    w.bet(1000, game: 'FORTUNE WHEEL');
    expect(w.level, 1);
    w.bet(1000, game: 'FORTUNE 777');
    expect(w.level, 2);
    expect(leveled, 2);
    expect(w.player.favoriteGame, 'PLINKO');
    expect(w.mail.first.id, 'level_2');

    final coins = w.coins, gems = w.gems;
    final (c, g) = w.claimAllMail();
    expect(w.coins, coins + c);
    expect(w.gems, gems + g);
    expect(w.mail, isEmpty);
    expect(w.claimMail('welcome'), isNull, reason: 'no double claim');
    w.onLevelUp = null;
  });

  test('gems exchange for coins; rescue only when broke; state persists',
      () async {
    final w = WalletService.instance;
    await w.load();
    await w.resetProgress();

    final coins = w.coins;
    expect(w.exchangeGems(10), isTrue);
    expect(w.coins, coins + 10 * WalletService.coinsPerGem);
    expect(w.exchangeGems(w.gems + 1), isFalse);

    expect(w.claimRescue(), isFalse);
    w.bet(w.coins, game: 'PLINKO');
    expect(w.claimRescue(), isTrue);
    expect(w.coins, WalletService.rescueCoins);

    w.payout(777);
    await Future<void>.delayed(Duration.zero);
    await w.load(); // reload from prefs
    expect(w.player.biggestWin, 777);
    expect(w.player.plays['PLINKO'], 1);
    expect(w.mail.map((m) => m.id), contains('welcome'));
    expect(w.mail.map((m) => m.id), contains('level_2'));
  });
}
