import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'theme.dart';
import 'services/wallet_service.dart';
import 'services/settings_service.dart';
import 'services/audio_service.dart';
import 'screens/lobby_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await WalletService.instance.load();
  await SettingsService.instance.load();
  await AudioService.instance.initialize();
  WalletService.instance.onLevelUp = (level) {
    AudioService.instance.play(GameSound.bigWin);
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('LEVEL UP! You reached level $level. '
            'Your reward is waiting in the Mailbox.'),
        backgroundColor: JuwaColors.panel,
        behavior: SnackBarBehavior.floating,
      ));
  };
  runApp(const JuwaApp());
  FlutterNativeSplash.remove();
}

final messengerKey = GlobalKey<ScaffoldMessengerState>();

class JuwaApp extends StatelessWidget {
  const JuwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juwa',
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: juwaTheme(),
      home: const LobbyScreen(),
    );
  }
}
