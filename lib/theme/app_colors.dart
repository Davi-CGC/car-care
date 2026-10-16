import 'package:flutter/material.dart';

/// Paleta oficial do CarCare.
/// Para mudar as cores do aplicativo inteiro, altere apenas os valores abaixo.
class AppColors {
  AppColors._();

  /// Amarelo pólen de ouro — cor principal da marca (botões, destaques).
  static const Color goldenPollen = Color(0xFFE8B004);

  /// Branco gelo — fundo do tema claro.
  static const Color iceWhite = Color(0xFFF7F7F2);

  /// Obsidian Black Metallic — fundo do tema escuro e textos no tema claro.
  static const Color obsidian = Color(0xFF121214);

  /// Variação um pouco mais clara do obsidian, usada em cards no tema escuro.
  static const Color obsidianLight = Color(0xFF1F1F23);

  // Cores de status (alertas de manutenção).
  static const Color danger = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
  static const Color success = Color(0xFF2E7D32);
}
