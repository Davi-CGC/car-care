import 'package:flutter/material.dart';

import '../theme/cores_app.dart';

/// Botão principal que mostra um indicador de carregamento enquanto [carregando] em português.
class BotaoCarregamento extends StatelessWidget {
  final String rotulo;
  final bool carregando;
  final VoidCallback? aoPressionar;
  final IconData? icone;

  const BotaoCarregamento({
    super.key,
    required this.rotulo,
    required this.aoPressionar,
    this.carregando = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: carregando ? null : aoPressionar,
      child: carregando
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: CoresApp.obsidian),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[Icon(icone), const SizedBox(width: 8)],
                Flexible(child: Text(rotulo, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class LoadingButton extends BotaoCarregamento {
  const LoadingButton({
    super.key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) : super(
         rotulo: label,
         aoPressionar: onPressed,
         carregando: loading,
         icone: icon,
       );
}
