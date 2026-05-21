import 'package:flutter/material.dart';

class LedgerColors {
  static const paper = Color(0xFFFAF7F1);
  static const surface = Color(0xFFFFFEFA);
  static const surfaceAlt = Color(0xFFF0F5EF);
  static const line = Color(0xFFE1D8CA);
  static const ink = Color(0xFF25231F);
  static const inkSoft = Color(0xFF5D594F);
  static const inkMuted = Color(0xFF817A70);
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
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 15, height: 1.4),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
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
        backgroundColor: LedgerColors.paper,
        foregroundColor: LedgerColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: LedgerColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: LedgerColors.surface,
        indicatorColor: LedgerColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: LedgerColors.ink,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
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
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LedgerColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LedgerColors.primary,
          side: const BorderSide(color: LedgerColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
