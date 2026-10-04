import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted music and effects preferences, observed by AudioService.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  late SharedPreferences _prefs;
  bool sound = true;
  bool music = true;
  bool haptics = true;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    sound = _prefs.getBool('sound') ?? true;
    music = _prefs.getBool('music') ?? true;
    haptics = _prefs.getBool('haptics') ?? true;
  }

  void setSound(bool v) {
    sound = v;
    _prefs.setBool('sound', v);
    notifyListeners();
  }

  void setMusic(bool v) {
    music = v;
    _prefs.setBool('music', v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    haptics = v;
    _prefs.setBool('haptics', v);
    notifyListeners();
  }
}
