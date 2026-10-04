import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/screens/lobby_screen.dart';
import 'package:juwa/services/wallet_service.dart';
import 'package:juwa/services/settings_service.dart';
import 'package:juwa/games/slots/slot_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    await WalletService.instance.load();
  });

  testWidgets('LobbyScreen renders cleanly on narrow landscape screen without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(667, 375); // iPhone SE / 8 landscape
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: LobbyScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify both premier game cards are front and center
    expect(find.text('FORTUNE 777'), findsOneWidget);
    expect(find.text('FISH HUNTER'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Fortune 777 navigates to Fortune SlotScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: LobbyScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('FORTUNE 777'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SlotScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping Fish Hunter navigates to Fish Hunter SlotScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: LobbyScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap on Fish Hunter card
    await tester.tap(find.text('FISH HUNTER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Should now be on Fish Hunter slot screen
    expect(find.byType(SlotScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
