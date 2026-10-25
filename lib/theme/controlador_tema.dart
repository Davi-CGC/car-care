import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o tema escolhido (claro/escuro) e salva a preferência no aparelho.
class ControladorTema extends ValueNotifier<ThemeMode> {
  ControladorTema() : super(ThemeMode.light);

  static const _chave = 'dark_mode';

  bool get eEscuro => value == ThemeMode.dark;
  bool get isDark => eEscuro;

  Future<void> carregar() async {
    final preferencias = await SharedPreferences.getInstance();
    value = (preferencias.getBool(_chave) ?? false) ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> load() => carregar();

  Future<void> alternar() async {
    value = eEscuro ? ThemeMode.light : ThemeMode.dark;
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setBool(_chave, eEscuro);
  }

  Future<void> toggle() => alternar();
}

/// Instância única em português.
final controladorTema = ControladorTema();

/// Alias para manter compatibilidade
typedef ThemeController = ControladorTema;
final themeController = controladorTema;
