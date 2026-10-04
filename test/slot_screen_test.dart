import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/games/slots/slot_screen.dart';
import 'package:juwa/games/slots/slot_theme.dart';
import 'package:juwa/services/wallet_service.dart';
import 'package:juwa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    final w = WalletService.instance;
    await w.load();
    if (w.coins < 1000) {
      w.payout(5000);
    }
  });

  testWidgets('SlotScreen renders without any overflow on narrow screen',
      (WidgetTester tester) async {
    // Test on narrow phone in landscape (667 x 375, e.g. iPhone SE / 8)
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SlotScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify key UI elements render
    expect(find.text('FORTUNE 777'), findsOneWidget);
    expect(find.text('TOTAL BET'), findsOneWidget);
    expect(find.text('MAX BET'), findsOneWidget);
    expect(find.text('WIN'), findsOneWidget);
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.text('SPIN'), findsOneWidget);

    // Verify no overflow exceptions occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('SlotScreen renders on modern phone screen (844 x 390)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SlotScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('SPIN'), findsOneWidget);

    // Tap SPIN button
    await tester.tap(find.text('SPIN'));
    await tester.pump(const Duration(milliseconds: 100));

    // When spinning, STOP should appear on spin button
    expect(find.text('STOP'), findsWidgets);

    // Tap STOP to quick stop
    await tester.tap(find.text('STOP').first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });

  testWidgets('SlotScreen info button opens paytable dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SlotScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Info button
    final infoBtn = find.byIcon(Icons.help_outline_rounded);
    expect(infoBtn, findsOneWidget);
    await tester.tap(infoBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify paytable is visible
    expect(find.text('FORTUNE 777 PAYTABLE'), findsOneWidget);
    expect(find.text('SEVEN'), findsOneWidget);
    expect(find.text('BAR'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Fish Hunter theme renders its title and fish paytable',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: SlotScreen(theme: fishTheme)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('FISH HUNTER'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('FISH HUNTER PAYTABLE'), findsOneWidget);
    expect(find.text('SHARK'), findsOneWidget);
    expect(find.text('GOLDFISH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SlotScreen header has no separate sound button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SlotScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vampire Queen theme renders its title and paytable',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: SlotScreen(theme: vampireTheme)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('VAMPIRE QUEEN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('VAMPIRE QUEEN PAYTABLE'), findsOneWidget);
    expect(find.text('LORD'), findsOneWidget);
    expect(find.text('WOLF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
