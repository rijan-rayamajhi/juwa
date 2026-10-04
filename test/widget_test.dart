import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/services/wallet_service.dart';
import 'package:juwa/util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('wallet: bet deducts, payout credits, insufficient funds blocked', () async {
    final w = WalletService.instance;
    await w.load();
    await w.resetProgress();

    expect(w.coins, WalletService.startingCoins);

    expect(w.bet(1000), isTrue);
    expect(w.coins, WalletService.startingCoins - 1000);

    w.payout(2500);
    expect(w.coins, WalletService.startingCoins - 1000 + 2500);
    expect(w.player.totalWon, 2500);
    expect(w.player.gamesPlayed, 1);

    expect(w.bet(w.coins + 1), isFalse, reason: 'cannot bet more than balance');
  });

  test('wallet: daily bonus claims once then blocks until cooldown', () async {
    final w = WalletService.instance;
    await w.load();
    await w.resetProgress();

    expect(w.bonusReady, isTrue);
    final r = w.claimDailyBonus();
    expect(r.coins, WalletService.dailyCoinBonus);
    expect(r.gems, WalletService.dailyGemBonus);
    expect(w.bonusReady, isFalse);
    expect(w.claimDailyBonus().coins, 0, reason: 'second claim blocked');
  });

  test('coin formatting adds thousands separators', () {
    expect(formatCoins(10000), '10,000');
    expect(formatCoins(1234567), '1,234,567');
    expect(formatCoins(500), '500');
  });
}
