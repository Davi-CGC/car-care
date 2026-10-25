import 'package:flutter/material.dart';

import '../theme/cores_app.dart';
import '../utils/calculos.dart';

/// Card e barra visual no formato de "termômetro" indicando se o veículo
/// está consumindo muito (vermelho), normal (amarelo) ou pouco (verde) em português.
class TermometroConsumo extends StatelessWidget {
  final AvaliacaoConsumo avaliacao;
  final String unidade;

  const TermometroConsumo({
    super.key,
    required this.avaliacao,
    this.unidade = 'km/l',
  });

  Color get _cor => switch (avaliacao.nivel) {
        NivelConsumo.otimo => CoresApp.sucesso,
        NivelConsumo.moderado => CoresApp.amareloPolen,
        NivelConsumo.alto => CoresApp.perigo,
      };

  IconData get _icone => switch (avaliacao.nivel) {
        NivelConsumo.otimo => Icons.eco,
        NivelConsumo.moderado => Icons.speed,
        NivelConsumo.alto => Icons.local_fire_department,
      };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final eEscuro = tema.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: _cor.withValues(alpha: eEscuro ? 0.15 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _cor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _cor.withValues(alpha: 0.2),
                  child: Icon(_icone, color: _cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Termômetro de Consumo',
                        style: tema.textTheme.labelMedium?.copyWith(
                          color: eEscuro ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        avaliacao.rotulo,
                        style: tema.textTheme.titleMedium?.copyWith(
                          color: _cor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${avaliacao.kmPorLitro.toStringAsFixed(1)} $unidade',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra horizontal de 3 estágios (Termômetro)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CoresApp.perigo,
                          CoresApp.amareloPolen,
                          CoresApp.sucesso,
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: avaliacao.pontuacao.clamp(0.05, 1.0),
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _cor, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Alto Consumo', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('Moderado', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('Econômico', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              avaliacao.descricao,
              style: tema.textTheme.bodySmall?.copyWith(
                color: eEscuro ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class ConsumptionThermometer extends TermometroConsumo {
  const ConsumptionThermometer({
    super.key,
    required AvaliacaoConsumo evaluation,
    String unit = 'km/l',
  }) : super(avaliacao: evaluation, unidade: unit);
}
