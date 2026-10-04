import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/widgets/coin_flow_overlay.dart';
import 'package:juwa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
  });

  testWidgets('CoinFlowController triggers burst and overlay renders particles',
      (WidgetTester tester) async {
    final controller = CoinFlowController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 400,
            child: CoinFlowOverlay(
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Initially idle (no coins rendered)
    expect(find.byType(Image), findsNothing);

    // Trigger 20 coins
    controller.trigger(count: 20);
    await tester.pump(); // schedule and mount particles
    await tester.pump(const Duration(milliseconds: 400));

    // Coins should now be flying and visible
    expect(find.byType(Image), findsWidgets);

    // Advance animation to finish
    await tester.pump(const Duration(milliseconds: 2000));

    // Coins should have completed and absorbed
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
