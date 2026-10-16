import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/constants.dart';

/// Logo do app (assets/images/logo.png). Se a imagem faltar, mostra um ícone.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        appLogoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.obsidian,
          child: Icon(Icons.car_repair, color: AppColors.goldenPollen, size: size * 0.6),
        ),
      ),
    );
  }
}
