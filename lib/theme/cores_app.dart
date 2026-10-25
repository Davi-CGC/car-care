import 'package:flutter/material.dart';

/// Paleta oficial do CarCare em português.
/// Para mudar as cores do aplicativo inteiro, altere os valores abaixo.
class CoresApp {
  CoresApp._();

  /// Amarelo pólen de ouro — cor principal da marca (botões, destaques).
  static const Color amareloPolen = Color(0xFFE8B004);

  /// Branco gelo — fundo do tema claro.
  static const Color brancoGelo = Color(0xFFF7F7F2);

  /// Obsidian Black Metallic — fundo do tema escuro e textos no tema claro.
  static const Color obsidian = Color(0xFF121214);

  /// Variação um pouco mais clara do obsidian, usada em cards no tema escuro.
  static const Color obsidianClaro = Color(0xFF1F1F23);

  // Cores de status (alertas de manutenção).
  static const Color perigo = Color(0xFFD32F2F);
  static const Color aviso = Color(0xFFF57C00);
  static const Color sucesso = Color(0xFF2E7D32);

  // Aliases para compatibilidade total
  static const Color goldenPollen = amareloPolen;
  static const Color iceWhite = brancoGelo;
  static const Color obsidianLight = obsidianClaro;
  static const Color danger = perigo;
  static const Color warning = aviso;
  static const Color success = sucesso;
}

/// Alias para manter compatibilidade com referências existentes
typedef AppColors = CoresApp;
