import 'package:flutter/material.dart';

import '../theme/cores_app.dart';
import '../utils/constantes.dart';

/// Logo do app em português (assets/images/logo.png). Se a imagem faltar, mostra um ícone.
class LogoApp extends StatelessWidget {
  final double tamanho;
  const LogoApp({super.key, this.tamanho = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(tamanho * 0.22),
      child: Image.asset(
        caminhoLogoApp,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: tamanho,
          height: tamanho,
          color: CoresApp.obsidian,
          child: Icon(Icons.car_repair, color: CoresApp.amareloPolen, size: tamanho * 0.6),
        ),
      ),
    );
  }
}

/// Subclasse para compatibilidade com chamadas em inglês
class AppLogo extends LogoApp {
  const AppLogo({super.key, double size = 96}) : super(tamanho: size);
}
