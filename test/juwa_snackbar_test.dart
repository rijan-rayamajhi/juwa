import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juwa/theme.dart';
import 'package:juwa/widgets/juwa_snackbar.dart';

void main() {
  testWidgets('JuwaSnackBarBanner displays text and gold styling correctly',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: juwaTheme(),
        home: const Scaffold(
          body: JuwaSnackBarBanner(
            message: 'Claimed +1,000 coins & +5 gems!',
          ),
        ),
      ),
    );

    expect(find.textContaining('Claimed', findRichText: true), findsOneWidget);
    expect(find.textContaining('+1,000', findRichText: true), findsOneWidget);
    expect(find.textContaining('+5', findRichText: true), findsOneWidget);
  });

  testWidgets('showJuwaSnackBar renders floating banner without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: juwaTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showJuwaSnackBar(
                  context,
                  'Claimed +1,000 coins & +5 gems!',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300)); // Finish slide in

    expect(find.byType(JuwaSnackBarBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('JuwaSnackBarBanner renders level up and reset variants',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: juwaTheme(),
        home: const Scaffold(
          body: Column(
            children: [
              JuwaSnackBarBanner(message: 'LEVEL UP! You reached level 2.'),
              JuwaSnackBarBanner(message: 'Progress reset'),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('LEVEL UP!', findRichText: true), findsOneWidget);
    expect(find.textContaining('Progress reset', findRichText: true), findsOneWidget);
  });

  testWidgets('showJuwaSnackBar has elevated margin to clear bottom console and dismisses on tap',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: juwaTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showJuwaSnackBar(
                  context,
                  'Refilled +10,000 coins',
                );
              },
              child: const Text('Refill'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Refill'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);

    final SnackBar snackBar = tester.widget(snackBarFinder);
    final margin = snackBar.margin as EdgeInsets;
    // Must clear footer height of ~68-76px
    expect(margin.bottom, greaterThanOrEqualTo(80.0));

    // Tap on the snackbar banner to clear/dismiss it
    await tester.tap(find.byType(JuwaSnackBarBanner));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(JuwaSnackBarBanner), findsNothing);
  });
}
