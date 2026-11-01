import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0C0B09);
  static const Color surface = Color(0xFF1C1915);
  static const Color surfaceElevated = Color(0xFF24201B);
  static const Color surfaceLight = Color(0xFF2C2721);

  static const Color gold = Color(0xFFC9A45C);
  static const Color goldLight = Color(0xFFDDBB74);
  static const Color goldDark = Color(0xFFB58E45);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, goldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color textDark = Color(0xFF14110B);
  static const Color textIvory = Color(0xFFF3EDE0);
  static const Color textMuted = Color(0xFFA39B8B);
  static const Color textDim = Color(0xFF6B655A);

  static const Color positive = Color(0xFF8FBF8F); // Lena
  static const Color negative = Color(0xFFD98A7A); // Dena

  static const Color hairline = Color.fromRGBO(201, 164, 92, 0.18);
  static const Color hairlineActive = Color.fromRGBO(201, 164, 92, 0.45);
}

class AppRadii {
  AppRadii._();

  static const double sm = 6.0;
  static const double md = 12.0;
  static const double lg = 18.0;
  static const double full = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseTextTheme = Typography.material2021().white;

    final playfair = GoogleFonts.playfairDisplayTextTheme(baseTextTheme);
    final inter = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        onPrimary: AppColors.textDark,
        surface: AppColors.surface,
        onSurface: AppColors.textIvory,
        surfaceContainerHighest: AppColors.surfaceElevated,
        error: AppColors.negative,
      ),
      textTheme: TextTheme(
        // Headings & big amounts in Playfair Display
        displayLarge: playfair.displayLarge?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        displayMedium: playfair.displayMedium?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: playfair.displaySmall?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: playfair.headlineLarge?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: playfair.headlineMedium?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: playfair.headlineSmall?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
        ),

        // Body & UI labels in Inter
        titleLarge: inter.titleLarge?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: inter.titleMedium?.copyWith(
          color: AppColors.textIvory,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: inter.titleSmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: inter.bodyLarge?.copyWith(
          color: AppColors.textIvory,
          fontSize: 15,
        ),
        bodyMedium: inter.bodyMedium?.copyWith(
          color: AppColors.textMuted,
          fontSize: 13,
        ),
        bodySmall: inter.bodySmall?.copyWith(
          color: AppColors.textDim,
          fontSize: 11,
        ),
        labelLarge: inter.labelLarge?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        labelSmall: inter.labelSmall?.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.gold),
        titleTextStyle: TextStyle(
          color: AppColors.textIvory,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.hairline, width: 1),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.hairline, width: 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.negative, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
        hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 0.8,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textIvory),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.hairline),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
