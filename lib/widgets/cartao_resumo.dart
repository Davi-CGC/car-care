import 'package:flutter/material.dart';

import '../theme/cores_app.dart';

/// Card pequeno com ícone, valor e rótulo (usado nos resumos) em português.
class CartaoResumo extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final Color? cor;

  const CartaoResumo({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.valor,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = cor ?? CoresApp.amareloPolen;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: c.withValues(alpha: 0.15),
              child: Icon(icone, color: c, size: 19),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valor,
                      style: tema.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rotulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall
                        ?.copyWith(fontSize: 11, height: 1.15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class SummaryCard extends CartaoResumo {
  const SummaryCard({
    super.key,
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) : super(
         icone: icon,
         rotulo: label,
         valor: value,
         cor: color,
       );
}

/// Organiza os [CartaoResumo] em grade: 2 colunas no celular, 4 em telas largas.
class GradeResumo extends StatelessWidget {
  final List<Widget> filhos;
  const GradeResumo({super.key, required this.filhos});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, restricoes) {
      final colunas = restricoes.maxWidth >= 700 ? 4 : (restricoes.maxWidth >= 300 ? 2 : 1);
      const espacamento = 12.0;
      final largura = (restricoes.maxWidth - espacamento * (colunas - 1)) / colunas;
      return Wrap(
        spacing: espacamento,
        runSpacing: espacamento,
        children: [for (final c in filhos) SizedBox(width: largura, child: c)],
      );
    });
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class SummaryGrid extends GradeResumo {
  const SummaryGrid({
    super.key,
    required List<Widget> children,
  }) : super(filhos: children);
}
