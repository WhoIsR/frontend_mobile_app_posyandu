import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

class LedgerColors {
  static const paper = AppColors.background;
  static const surface = AppColors.surface;
  static const surfaceAlt = AppColors.background;
  static const line = AppColors.divider;
  static const ink = AppColors.textPrimary;
  static const inkSoft = AppColors.textSecondary;
  static const inkMuted = AppColors.textLight;
  static const primary = AppColors.primary;
  static const primaryDeep = AppColors.primaryDark;
  static const primarySoft = AppColors.primarySoft;
  static const healthAqua = AppColors.info;
  static const healthAquaSoft = AppColors.infoSoft;
  static const bidanBlue = AppColors.info;
  static const attention = AppColors.warning;
  static const attentionSoft = AppColors.warningSoft;
  static const review = AppColors.error;
  static const reviewSoft = AppColors.errorSoft;
  static const glow = AppColors.background;
}

class LedgerTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LedgerColors.paper,
      visualDensity: VisualDensity.standard,
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
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
        backgroundColor: Color(0xFF0F766E), // Premium dark teal header background
        foregroundColor: Colors.white, // White icons/action text
        elevation: 4,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x29000000), // Subtle shadow
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white, // White title text
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
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
        elevation: 2,
        shadowColor: LedgerColors.primary.withValues(alpha: 0.05),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: LedgerColors.line.withValues(alpha: 0.4),
            width: 1.0,
          ),
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
