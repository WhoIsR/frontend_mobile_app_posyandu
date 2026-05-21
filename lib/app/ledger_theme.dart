import 'package:flutter/material.dart';

class LedgerColors {
  static const paper = Color(0xFFF6FAF5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEAF7F0);
  static const line = Color(0xFFD8E5DD);
  static const ink = Color(0xFF18201B);
  static const inkSoft = Color(0xFF536159);
  static const inkMuted = Color(0xFF76857C);
  static const primary = Color(0xFF197B59);
  static const primaryDeep = Color(0xFF0E5F49);
  static const primarySoft = Color(0xFFDDF3E9);
  static const healthAqua = Color(0xFF1B9AAA);
  static const healthAquaSoft = Color(0xFFDDF3F5);
  static const bidanBlue = Color(0xFF376B9B);
  static const attention = Color(0xFFB46B18);
  static const attentionSoft = Color(0xFFFFEAC7);
  static const review = Color(0xFFB64D3B);
  static const reviewSoft = Color(0xFFFBE0DA);
  static const glow = Color(0xFFEAFBF3);
}

class LedgerTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LedgerColors.paper,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
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
        backgroundColor: LedgerColors.surface,
        foregroundColor: LedgerColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: LedgerColors.primarySoft,
        titleTextStyle: TextStyle(
          color: LedgerColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: LedgerColors.surface,
        indicatorColor: LedgerColors.primarySoft,
        surfaceTintColor: LedgerColors.glow,
        elevation: 8,
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
        elevation: 1,
        shadowColor: LedgerColors.primary.withValues(alpha: 0.10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LedgerColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LedgerColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: LedgerColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LedgerColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LedgerColors.primary,
          side: const BorderSide(color: LedgerColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
