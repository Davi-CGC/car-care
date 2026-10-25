import 'package:flutter/material.dart';

import '../theme/cores_app.dart';

/// Mensagem amigável para listas vazias em português, com ação opcional.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final VoidCallback? aoClicarAcao;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.aoClicarAcao,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: CoresApp.amareloPolen.withValues(alpha: 0.15),
                child: Icon(icone, size: 40, color: CoresApp.amareloPolen),
              ),
              const SizedBox(height: 16),
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(mensagem, textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
              if (rotuloAcao != null && aoClicarAcao != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: aoClicarAcao,
                  icon: const Icon(Icons.add),
                  label: Text(rotuloAcao!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class EmptyState extends EstadoVazio {
  const EmptyState({
    super.key,
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : super(
         icone: icon,
         titulo: title,
         mensagem: message,
         rotuloAcao: actionLabel,
         aoClicarAcao: onAction,
       );
}
