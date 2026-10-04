import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/widgets/game_press.dart';
import 'package:juwa/games/slots/slot_screen.dart';
import 'package:juwa/games/slots/slot_theme.dart';
import 'package:juwa/games/slots/slot_config.dart';
import 'package:juwa/games/slots/slot_engine.dart';
import 'package:juwa/services/settings_service.dart';
import 'package:juwa/services/wallet_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound': false});
    await SettingsService.instance.load();
    await WalletService.instance.load();
  });
  testWidgets('Button press animates and calls action once on release', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: GamePress(
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 50, child: Text('GO')),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('GO')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(taps, 0);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .95);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  final theme = SlotTheme(
    title: fortuneTheme.title,
    subtitle: fortuneTheme.subtitle,
    paytableTitle: fortuneTheme.paytableTitle,
    background: fortuneTheme.background,
    frame: fortuneTheme.frame,
    thumb: fortuneTheme.thumb,
    frameAspect: fortuneTheme.frameAspect,
    winL: fortuneTheme.winL,
    winR: fortuneTheme.winR,
    winT: fortuneTheme.winT,
    winB: fortuneTheme.winB,
    symbolAssets: fortuneTheme.symbolAssets,
    symbolLabels: fortuneTheme.symbolLabels,
    weights: {Sym.seven: 1},
    payTable: fortuneTheme.payTable,
  );
  for (final leaveEarly in [false, true]) {
    testWidgets('Animated slot pays exactly once, leaveEarly=$leaveEarly', (
      tester,
    ) async {
      final expected = SlotEngine(
        null,
        theme.weights,
        theme.payTable,
      ).spin(100).totalWin;
      expect(expected, greaterThan(0));
      await tester.pumpWidget(MaterialApp(home: SlotScreen(theme: theme)));
      await tester.pump();
      await tester.tap(find.text('SPIN'));
      await tester.pump(const Duration(milliseconds: 120));
      expect(WalletService.instance.coins, 9900);
      if (leaveEarly) {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      } else {
        await tester.tap(find.text('STOP'));
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      }
      await tester.pumpAndSettle();
      expect(WalletService.instance.coins, 9900 + expected);
      expect(WalletService.instance.player.totalWon, expected);
      expect(tester.takeException(), isNull);
    });
  }
}
