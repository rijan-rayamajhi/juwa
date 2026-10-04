import 'package:flutter/material.dart';

/// Juwa dark Vegas gold-and-black theme tokens.
class JuwaColors {
  static const black = Color(0xFF0A0805);
  static const panel = Color(0xFF1A1510);
  static const gold = Color(0xFFF5C24B);
  static const goldDark = Color(0xFFB8860B);
  static const red = Color(0xFFD32F2F);
  static const green = Color(0xFF4CAF50);
  static const textDim = Color(0xFFBFae8f);

  static const goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBE9A0), gold, goldDark],
  );
}

ThemeData juwaTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: JuwaColors.black,
    colorScheme: base.colorScheme.copyWith(
      primary: JuwaColors.gold,
      secondary: JuwaColors.red,
      surface: JuwaColors.panel,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}
