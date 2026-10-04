import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/widgets/game_header.dart';
import 'package:juwa/widgets/game_footer.dart';
import 'package:juwa/services/wallet_service.dart';
import 'package:juwa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    await WalletService.instance.load();
  });

  group('GameHeader Reusable Widget', () {
    testWidgets('renders title, subtitle, and triggers onBack and onInfo',
        (WidgetTester tester) async {
      bool backTapped = false;
      bool infoTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameHeader(
              title: 'KENO 80',
              subtitle: 'PICK 10 NUMBERS',
              onBack: () => backTapped = true,
              onInfo: () => infoTapped = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('KENO 80'), findsOneWidget);
      expect(find.text('PICK 10 NUMBERS'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backTapped, isTrue);

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      expect(infoTapped, isTrue);
    });

    testWidgets('renders custom trailing and custom action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameHeader(
              title: 'CUSTOM GAME',
              showCurrencies: false,
              customActions: [
                Icon(Icons.star, key: Key('custom_star')),
              ],
              customTrailing: Text('CUSTOM TRAILING', key: Key('trailing_text')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('custom_star')), findsOneWidget);
      expect(find.byKey(const Key('trailing_text')), findsOneWidget);
    });
  });

  group('GameFooter Reusable Widget', () {
    testWidgets('renders bet stepper, win marquee, and triggers events',
        (WidgetTester tester) async {
      int betChangeDir = 0;
      bool maxBetCalled = false;
      bool spinCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameFooter(
              bet: 250,
              onBetChange: (dir) => betChangeDir = dir,
              onMaxBet: () => maxBetCalled = true,
              lastWin: 1200,
              displayedWin: 1200,
              onSpin: () => spinCalled = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('250'), findsOneWidget);
      expect(find.text('+1,200'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(betChangeDir, 1);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(betChangeDir, -1);

      await tester.tap(find.text('MAX BET'));
      expect(maxBetCalled, isTrue);

      await tester.tap(find.text('SPIN'));
      expect(spinCalled, isTrue);
    });

    testWidgets('renders spinning state and auto toggle state cleanly',
        (WidgetTester tester) async {
      bool autoToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameFooter(
              bet: 100,
              isAuto: true,
              onToggleAuto: () => autoToggled = true,
              isSpinning: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STOP'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('STOP').first);
      expect(autoToggled, isTrue);
    });
  });
}
