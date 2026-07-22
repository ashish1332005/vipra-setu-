import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const saffron = Color(0xFFF45A2A);
  static const navy = Color(0xFF24324A);
  static const emerald = Color(0xFF228B5B);
  static const red = saffron;
  static const deepRed = navy;
  static const crimson = Color(0xFFD64545);
  static const success = emerald;
  static const amber = Color(0xFFD99018);
  static const gold = Color(0xFFEAB84E);
  static const ink = Color(0xFF2C2927);
  static const muted = Color(0xFF706966);
  static const softText = Color(0xFF4F4946);
  static const line = Color(0xFFE8DDD6);
  static const canvas = Color(0xFFFFFBF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFF3EA);
  static const _themeModeKey = 'themeMode';
  static final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value =
        prefs.getBool(_themeModeKey) == true ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool value) async {
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, value);
  }

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: saffron,
      primary: saffron,
      secondary: navy,
      tertiary: emerald,
      surface: surface,
      error: crimson,
    );
    final baseText = Typography.material2021().black.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['Noto Sans', 'Arial'],
          bodyColor: ink,
          displayColor: ink,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans', 'Arial'],
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0, color: ink),
        headlineMedium: baseText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0, color: ink),
        headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0, color: ink),
        titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0, color: ink),
        titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0, color: ink),
        bodyLarge: baseText.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400, letterSpacing: 0, color: softText),
        bodyMedium: baseText.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400, letterSpacing: 0, color: muted),
        bodySmall: baseText.bodySmall?.copyWith(
            fontWeight: FontWeight.w400, letterSpacing: 0, color: muted),
        labelLarge: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0, color: ink),
        labelMedium: baseText.labelMedium?.copyWith(
            fontWeight: FontWeight.w600, letterSpacing: 0, color: softText),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle:
            TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: surface,
        elevation: 0.5,
        shadowColor: navy.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          disabledBackgroundColor: saffron.withValues(alpha: .38),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: Color(0xFFFFD5C2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFFFFE3D5),
        surfaceTintColor: surface,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? saffron : muted,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: saffron, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: saffron,
      primary: saffron,
      secondary: const Color(0xFF8FB2F5),
      tertiary: const Color(0xFF60D394),
      brightness: Brightness.dark,
      surface: const Color(0xFF171B22),
      error: crimson,
    );
    final baseText = Typography.material2021().white.apply(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['Noto Sans', 'Arial'],
          bodyColor: const Color(0xFFE9EDF3),
          displayColor: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['Noto Sans', 'Arial'],
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101318),
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        headlineMedium: baseText.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        titleLarge: baseText.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
        bodyLarge: baseText.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w400, letterSpacing: 0),
        bodyMedium: baseText.bodyMedium?.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: const Color(0xFFC8CED8)),
        labelLarge: baseText.labelLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101318),
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF171B22),
        surfaceTintColor: const Color(0xFF171B22),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF303744)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFB291),
          side: const BorderSide(color: Color(0xFF5A4036)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF171B22),
        indicatorColor: const Color(0xFF4B2D24),
        surfaceTintColor: const Color(0xFF171B22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF171B22),
        labelStyle: const TextStyle(
            color: Color(0xFFC8CED8), fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF303744)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: saffron, width: 1.5),
        ),
      ),
    );
  }
}
