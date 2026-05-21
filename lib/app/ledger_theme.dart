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
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.12,
        ),
        titleLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
            onPrimary: Colors.white,
            secondary: LedgerColors.bidanBlue,
            surface: LedgerColors.surface,
            surfaceContainerHighest: LedgerColors.surfaceAlt,
            outline: LedgerColors.line,
            error: LedgerColors.review,
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LedgerColors.surface,
        surfaceTintColor: LedgerColors.glow,
        showDragHandle: true,
        dragHandleColor: LedgerColors.inkMuted,
        modalBarrierColor: Color(0x660B1F17),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LedgerColors.surface,
        surfaceTintColor: LedgerColors.glow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LedgerColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LedgerColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LedgerColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: LedgerColors.review),
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
