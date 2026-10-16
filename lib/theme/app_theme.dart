import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Temas claro e escuro do CarCare, construídos a partir de [AppColors].
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.obsidian : AppColors.iceWhite;
    final cardColor = isDark ? AppColors.obsidianLight : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.obsidian;
    // No tema claro o amarelo tem pouco contraste sobre o branco,
    // por isso textos/ícones de destaque usam o obsidian.
    final accent = isDark ? AppColors.goldenPollen : AppColors.obsidian;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.goldenPollen,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.goldenPollen,
      onPrimary: AppColors.obsidian,
      secondary: AppColors.goldenPollen,
      onSecondary: AppColors.obsidian,
      surface: background,
      onSurface: textColor,
      surfaceContainerHighest: cardColor,
      error: AppColors.danger,
    );

    final radius = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.goldenPollen, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: accent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.goldenPollen,
          foregroundColor: AppColors.obsidian,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.goldenPollen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.goldenPollen,
        foregroundColor: AppColors.obsidian,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: AppColors.goldenPollen,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        indicatorColor: AppColors.goldenPollen,
        selectedIconTheme: const IconThemeData(color: AppColors.obsidian),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        indicatorColor: AppColors.goldenPollen,
        unselectedLabelColor: textColor.withValues(alpha: 0.6),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.goldenPollen,
        checkmarkColor: AppColors.obsidian,
        side: BorderSide(color: textColor.withValues(alpha: 0.2)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.goldenPollen),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
