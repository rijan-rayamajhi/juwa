import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/widgets/top_bar.dart';
import 'package:juwa/services/wallet_service.dart';
import 'package:juwa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
    await WalletService.instance.load();
  });

  testWidgets('TopBar renders VIP avatar, currencies, logo and actions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TopBar(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify VIP avatar badge
    expect(find.text('LV 1'), findsOneWidget);

    // Verify currency pills
    expect(find.byType(CurrencyPill), findsNWidgets(2));

    // Sound lives in Settings only; no separate speaker button.
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

    // Settings exposes Sound, Music and Vibration toggles.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Vibration'), findsOneWidget);
    await tester.tap(find.byType(Switch).at(2));
    await tester.pump();
    expect(SettingsService.instance.haptics, isFalse);
    expect(SettingsService.instance.sound, isTrue);

    // Verify no overflow occurred
    expect(tester.takeException(), isNull);
  });
}
