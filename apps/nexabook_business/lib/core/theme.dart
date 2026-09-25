import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF6750A4),
      scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none)),
      cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))));
}
