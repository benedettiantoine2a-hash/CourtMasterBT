import 'package:flutter/material.dart';

class AppTheme {
  static const Color neonYellow = Color(0xFFCCFF00);
  static const Color electricCyan = Color(0xFF00FFFF);
  static const Color pureBlack = Color(0xFF000000);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: pureBlack,
      primaryColor: neonYellow,
      hintColor: electricCyan,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: neonYellow,
          fontSize: 180,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          color: electricCyan,
          fontSize: 80,
          fontWeight: FontWeight.w300,
        ),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonYellow,
          foregroundColor: pureBlack,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        ),
      ),
    );
  }
}
