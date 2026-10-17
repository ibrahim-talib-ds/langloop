import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────
///  LangLoop design tokens (matches the UI ref)
/// ─────────────────────────────────────────────

class AppPalette {
  // ─── Light (cream + deep olive) ───
  static const lightBg        = Color(0xFFF2F4E4);  // stronger cream
  static const lightSurface   = Color(0xFFFFFFFF);
  static const lightBorder    = Color(0xFFDCE0C4);  // visible border
  static const lightText      = Color(0xFF0C0F04);  // near-black olive
  static const lightTextSub   = Color(0xFF5A6042);
  static const lightPrimary   = Color(0xFF7A8A1E);  // deeper olive (button)
  static const lightPrimaryFg = Color(0xFFF2F4E4);  // cream on olive
  static const lightAccent    = Color(0xFFD4E85A);  // lime highlight

  // ─── Dark (near-black + punchy lime) ───
  static const darkBg         = Color(0xFF070B04);  // deeper black-olive
  static const darkSurface    = Color(0xFF121810);
  static const darkBorder     = Color(0xFF293320);  // visible border
  static const darkText       = Color(0xFFF2F4E4);  // cream text
  static const darkTextSub    = Color(0xFF8E9779);
  static const darkPrimary    = Color(0xFFE5FF6B);  // PUNCHY lime
  static const darkPrimaryFg  = Color(0xFF070B04);  // near-black on lime
  static const darkAccent     = Color(0xFF7A8A1E);  // deeper olive

  // Common
  static const danger = Color(0xFFE5484D);
}

/// Semantic color set for the current mode.
class AppColors {
  final Color bg;
  final Color surface;
  final Color border;
  final Color text;
  final Color textSub;
  final Color primary;
  final Color primaryFg;
  final Color accent;
  final Color danger = AppPalette.danger;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.border,
    required this.text,
    required this.textSub,
    required this.primary,
    required this.primaryFg,
    required this.accent,
  });

  static const light = AppColors(
    bg:        AppPalette.lightBg,
    surface:   AppPalette.lightSurface,
    border:    AppPalette.lightBorder,
    text:      AppPalette.lightText,
    textSub:   AppPalette.lightTextSub,
    primary:   AppPalette.lightPrimary,
    primaryFg: AppPalette.lightPrimaryFg,
    accent:    AppPalette.lightAccent,
  );

  static const dark = AppColors(
    bg:        AppPalette.darkBg,
    surface:   AppPalette.darkSurface,
    border:    AppPalette.darkBorder,
    text:      AppPalette.darkText,
    textSub:   AppPalette.darkTextSub,
    primary:   AppPalette.darkPrimary,
    primaryFg: AppPalette.darkPrimaryFg,
    accent:    AppPalette.darkAccent,
  );
}

/// Radius
class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 22.0;
  static const xl = 30.0;
  static const pill = 999.0;
}

/// Spacing
class AppSpacing {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 34.0;
}

/// Theme builder
class AppTheme {
  static ThemeData build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: c.text,
      displayColor: c.text,
    );

    return base.copyWith(
      textTheme: textTheme.apply(fontSizeFactor: 1.05),
      visualDensity: VisualDensity.standard,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.primaryFg,
        secondary: c.accent,
        onSecondary: c.primaryFg,
        error: c.danger,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: c.text),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: c.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: c.textSub.withValues(alpha: 0.65), fontSize: 14),
        labelStyle: TextStyle(color: c.textSub, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: c.primary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.primary, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryFg,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.text),
      ),
    );
  }
}
