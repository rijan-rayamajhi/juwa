import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juwa/widgets/juwa_popup.dart';
import 'package:juwa/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.load();
  });

  testWidgets('JuwaPopup renders luxury frame, title, crown, and content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const JuwaPopup(
                    title: 'Test Header',
                    subtitle: 'Test Subtitle',
                    child: Text('Popup Content Body'),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    // Tap Open to show dialog
    await tester.tap(find.text('Open'));
    await tester.pump(); // Start entrance
    await tester.pump(const Duration(milliseconds: 300)); // Finish entrance

    // Verify Title & Subtitle
    expect(find.text('TEST HEADER'), findsOneWidget);
    expect(find.text('Test Subtitle'), findsOneWidget);
    expect(find.text('Popup Content Body'), findsOneWidget);

    // Verify Crown & Close button
    expect(find.byType(JuwaCloseButton), findsOneWidget);

    // Tap close button to pop
    await tester.tap(find.byType(JuwaCloseButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Should be dismissed
    expect(find.text('TEST HEADER'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('JuwaButton triggers onTap callback', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: JuwaButton(
              label: 'Claim Bonus',
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('CLAIM BONUS'), findsOneWidget);
    await tester.tap(find.text('CLAIM BONUS'));
    await tester.pump();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('close button works on its outer corner and ignores double taps',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false, // only the X can close it
                builder: (_) => const JuwaPopup(title: 'T', child: Text('Body')),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final r = tester.getRect(find.byType(JuwaCloseButton));
    final corner = r.topRight + const Offset(-4, 4);
    await tester.tapAt(corner);
    await tester.tapAt(corner); // second tap during exit animation
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsNothing);
    expect(find.text('Open'), findsOneWidget, reason: 'screen underneath stays');
  });
}
