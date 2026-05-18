import 'package:flutter/material.dart';

class LedgerColors {
  static const paper = Color(0xFFF8F4EC);
  static const surface = Color(0xFFFFFDF8);
  static const line = Color(0xFFDDD2C3);
  static const ink = Color(0xFF25231F);
  static const inkSoft = Color(0xFF5D594F);
  static const primary = Color(0xFF4E6F5C);
  static const primarySoft = Color(0xFFDDE8DE);
  static const bidanBlue = Color(0xFF4F6F86);
  static const attention = Color(0xFF9A6A2F);
  static const attentionSoft = Color(0xFFF1E2C9);
  static const review = Color(0xFF9A4E3A);
  static const reviewSoft = Color(0xFFF0D8D1);
}

class LedgerTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LedgerColors.paper,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: LedgerColors.primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: LedgerColors.primary,
            secondary: LedgerColors.bidanBlue,
            surface: LedgerColors.surface,
            outline: LedgerColors.line,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: LedgerColors.surface,
        foregroundColor: LedgerColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: LedgerColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: LedgerColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LedgerColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LedgerColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: LedgerColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: LedgerColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
