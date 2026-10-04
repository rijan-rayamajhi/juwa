import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/games/plinko/plinko_screen.dart';
import 'package:juwa/games/plinko/plinko_physics.dart';
import 'package:juwa/games/plinko/plinko_config.dart';
import 'package:juwa/services/settings_service.dart';
import 'package:juwa/services/wallet_service.dart';
import 'package:juwa/widgets/game_footer.dart';

PlinkoPhysics physicsOf(WidgetTester tester) {
  final painter =
      tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((widget) => widget.painter)
              .firstWhere((p) => p.runtimeType.toString() == '_PlinkoPainter')
          as dynamic;
  return painter.physics as PlinkoPhysics;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound': false});
    await WalletService.instance.load();
    await SettingsService.instance.load();
  });
  for (final size in [
    const Size(844, 390),
    const Size(1024, 768),
    const Size(390, 844),
  ]) {
    testWidgets('Uniform board ratio and ten taps produce ten balls at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: PlinkoScreen()));
      await tester.pumpAndSettle();
      final board = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_PlinkoPainter',
      );
      final boardSize = tester.getSize(board);
      expect(boardSize.width / boardSize.height, closeTo(900 / 620, .001));
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('DROP'));
      }
      await tester.pump();
      final balls = List<PlinkoBall>.of(physicsOf(tester).balls);
      expect(balls.length, 10);
      expect(WalletService.instance.coins, 9000);
      expect(WalletService.instance.player.gamesPlayed, 10);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 16),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 30),
      );
      final expected = balls.fold<int>(
        0,
        (sum, ball) => sum + plinkoPayout(ball.bucket!, ball.bet),
      );
      expect(WalletService.instance.coins, 9000 + expected);
      expect(WalletService.instance.player.totalWon, expected);
      expect(physicsOf(tester).balls, isEmpty);
      expect(find.textContaining('PAYOUT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Each ball retains its launch bet and settles on route removal', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PlinkoScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DROP'));
    await tester.pump();
    tester.widget<GameFooter>(find.byType(GameFooter)).onBetChange!(1);
    await tester.pump();
    await tester.tap(find.text('DROP'));
    await tester.pump();
    final balls = List<PlinkoBall>.of(physicsOf(tester).balls);
    expect(balls.map((b) => b.bet), [100, 250]);
    expect(WalletService.instance.coins, 9650);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final expected = balls.fold<int>(
      0,
      (sum, b) => sum + plinkoPayout(b.bucket!, b.bet),
    );
    expect(WalletService.instance.coins, 9650 + expected);
    await tester.pumpAndSettle();
    expect(WalletService.instance.player.totalWon, expected);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Unaffordable taps never create or charge a ball', (
    tester,
  ) async {
    WalletService.instance.player.coins = 150;
    await tester.pumpWidget(const MaterialApp(home: PlinkoScreen()));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('DROP'));
    }
    await tester.pump();
    expect(WalletService.instance.coins, 50);
    expect(physicsOf(tester).balls.length, 1);
    expect(WalletService.instance.player.gamesPlayed, 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
