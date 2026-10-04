import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/games/wheel/wheel_screen.dart';
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

  testWidgets(
    'WheelScreen renders without any overflow on narrow screen (667 x 375)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(667, 375);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: WheelScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify key UI elements render matching the standard theme
      expect(find.text('FORTUNE WHEEL'), findsOneWidget);
      expect(find.text('TOTAL BET'), findsOneWidget);
      expect(find.text('MAX BET'), findsOneWidget);
      expect(find.text('WIN'), findsOneWidget);
      expect(find.text('AUTO'), findsOneWidget);
      expect(find.text('SPIN'), findsOneWidget);

      // Verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WheelScreen renders on modern phone screen (844 x 390)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WheelScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('SPIN'), findsOneWidget);

    // Tap SPIN button
    await tester.tap(find.text('SPIN'));
    await tester.pump(const Duration(milliseconds: 100));

    // When spinning, STOP should appear on spin button
    expect(find.text('WAIT'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('WheelScreen info button opens prizes dialog', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WheelScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Info button
    final infoBtn = find.byIcon(Icons.help_outline_rounded);
    expect(infoBtn, findsOneWidget);
    await tester.tap(infoBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify prize dialog is visible
    expect(find.text('FORTUNE WHEEL PRIZES'), findsOneWidget);
    expect(find.text('50× bet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WheelScreen auto toggle and bet adjustments work properly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WheelScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    // Default bet is 100
    expect(find.text('100'), findsOneWidget);

    // Tap MAX BET
    await tester.tap(find.text('MAX BET'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1,000'), findsOneWidget);

    // Tap minus button
    final minusBtn = find.byIcon(Icons.remove_rounded);
    await tester.tap(minusBtn);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('500'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
