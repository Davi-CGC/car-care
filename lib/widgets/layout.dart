import 'package:flutter/material.dart';

/// Espaçamento das páginas com lista: 16px no celular e, em telas largas,
/// margens laterais maiores para o conteúdo ficar com no máximo [maxWidth].
EdgeInsets pagePadding(BuildContext context, {double maxWidth = 900}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = width > maxWidth + 32 ? (width - maxWidth) / 2 : 16.0;
  return EdgeInsets.fromLTRB(side, 16, side, 96);
}

/// Centraliza o conteúdo e limita a largura em telas grandes (tablet/web),
/// evitando campos e listas esticados de ponta a ponta.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Título de seção com ação opcional à direita.
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
