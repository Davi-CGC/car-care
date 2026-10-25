import 'package:flutter/material.dart';

import 'cores_app.dart';

/// Temas claro e escuro do CarCare em português, construídos a partir de [CoresApp].
class TemaApp {
  TemaApp._();

  static ThemeData get claro => _construir(Brightness.light);
  static ThemeData get escuro => _construir(Brightness.dark);

  // Aliases de compatibilidade
  static ThemeData get light => claro;
  static ThemeData get dark => escuro;

  static ThemeData _construir(Brightness brilho) {
    final eEscuro = brilho == Brightness.dark;
    final fundo = eEscuro ? CoresApp.obsidian : CoresApp.brancoGelo;
    final corCard = eEscuro ? CoresApp.obsidianClaro : Colors.white;
    final corTexto = eEscuro ? Colors.white : CoresApp.obsidian;
    // No tema claro o amarelo tem pouco contraste sobre o branco,
    // por isso textos/ícones de destaque usam o obsidian.
    final destaque = eEscuro ? CoresApp.amareloPolen : CoresApp.obsidian;

    final esquema = ColorScheme.fromSeed(
      seedColor: CoresApp.amareloPolen,
      brightness: brilho,
    ).copyWith(
      primary: CoresApp.amareloPolen,
      onPrimary: CoresApp.obsidian,
      secondary: CoresApp.amareloPolen,
      onSecondary: CoresApp.obsidian,
      surface: fundo,
      onSurface: corTexto,
      surfaceContainerHighest: corCard,
      error: CoresApp.perigo,
    );

    final raioBorda = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      scaffoldBackgroundColor: fundo,
      appBarTheme: AppBarTheme(
        backgroundColor: fundo,
        foregroundColor: corTexto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: corTexto,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: corCard,
        elevation: eEscuro ? 0 : 1,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: corCard,
        border: OutlineInputBorder(borderRadius: raioBorda),
        enabledBorder: OutlineInputBorder(
          borderRadius: raioBorda,
          borderSide: BorderSide(color: corTexto.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: raioBorda,
          borderSide: const BorderSide(color: CoresApp.amareloPolen, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: destaque),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CoresApp.amareloPolen,
          foregroundColor: CoresApp.obsidian,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: raioBorda),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: destaque,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: CoresApp.amareloPolen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: raioBorda),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: destaque),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CoresApp.amareloPolen,
        foregroundColor: CoresApp.obsidian,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: corCard,
        indicatorColor: CoresApp.amareloPolen,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: corCard,
        indicatorColor: CoresApp.amareloPolen,
        selectedIconTheme: const IconThemeData(color: CoresApp.obsidian),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: destaque,
        indicatorColor: CoresApp.amareloPolen,
        unselectedLabelColor: corTexto.withValues(alpha: 0.6),
      ),
      chipTheme: ChipThemeData(
        selectedColor: CoresApp.amareloPolen,
        checkmarkColor: CoresApp.obsidian,
        side: BorderSide(color: corTexto.withValues(alpha: 0.2)),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: CoresApp.amareloPolen),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// Alias para manter compatibilidade
typedef AppTheme = TemaApp;
