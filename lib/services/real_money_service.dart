import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../widgets/juwa_snackbar.dart';

/// Real money registration and redirection URL.
const String kRealMoneyRegisterUrl =
    'https://spinnerlog.com/register?src=5d8cdf1a-edb7-4569-bc96-b175fc1816ea&utm_source=juwa_app&utm_medium=banner&utm_campaign=return_traffic';

/// Launches the real money registration portal in the external browser.
Future<bool> launchRealMoneyPortal([BuildContext? context]) async {
  try {
    if (SettingsService.instance.sound) {
      AudioService.instance.play(GameSound.win);
    }
    final uri = Uri.parse(kRealMoneyRegisterUrl);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context != null && context.mounted) {
      showJuwaSnackBar(context, 'Could not open real money portal');
    }
    return launched;
  } catch (e) {
    if (context != null && context.mounted) {
      showJuwaSnackBar(context, 'Failed to launch portal: $e');
    }
    return false;
  }
}
