import 'package:flutter/material.dart';

/// Espaçamento das páginas com lista em português: 16px no celular e, em telas largas,
/// margens laterais maiores para o conteúdo ficar com no máximo [larguraMaxima].
EdgeInsets espacamentoPagina(BuildContext context, {double larguraMaxima = 900}) {
  final largura = MediaQuery.sizeOf(context).width;
  final lateral = largura > larguraMaxima + 32 ? (largura - larguraMaxima) / 2 : 16.0;
  return EdgeInsets.fromLTRB(lateral, 16, lateral, 96);
}

// Alias de compatibilidade
EdgeInsets pagePadding(BuildContext context, {double maxWidth = 900}) =>
    espacamentoPagina(context, larguraMaxima: maxWidth);

/// Centraliza o conteúdo e limita a largura em telas grandes (tablet/web) em português.
class CentroResponsivo extends StatelessWidget {
  final Widget filho;
  final double larguraMaxima;

  const CentroResponsivo({
    super.key,
    required this.filho,
    this.larguraMaxima = 900,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: filho,
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class ResponsiveCenter extends CentroResponsivo {
  const ResponsiveCenter({
    super.key,
    required Widget child,
    double maxWidth = 900,
  }) : super(filho: child, larguraMaxima: maxWidth);
}

/// Título de seção com ação opcional à direita em português.
class TituloSecao extends StatelessWidget {
  final String titulo;
  final Widget? acaoDireita;

  const TituloSecao(this.titulo, {super.key, this.acaoDireita});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          ?acaoDireita,
        ],
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class SectionTitle extends TituloSecao {
  const SectionTitle(super.titulo, {super.key, Widget? trailing})
      : super(acaoDireita: trailing);
}
