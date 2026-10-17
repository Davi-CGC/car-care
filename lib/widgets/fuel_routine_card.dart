import 'package:flutter/material.dart';

import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../utils/calculations.dart';
import '../utils/formatters.dart';

/// Card de Rotina de Abastecimento fiel à referência visual do usuário.
class FuelRoutineCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<FuelRecord> fuels;

  const FuelRoutineCard({
    super.key,
    required this.vehicle,
    required this.fuels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stats = Calculations.fuelRoutine(vehicle, fuels);

    const orangeColor = Color(0xFFF59E0B); // Amber / Laranja do design
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final distanceLabel = stats.avgDistanceBetweenFuels > 0
        ? '${formatNumber(stats.avgDistanceBetweenFuels, 0)} km'
        : '-- km';

    final freqLabel = stats.avgFrequencyDays > 0
        ? '${formatNumber(stats.avgFrequencyDays, 2)} Dias'
        : '-- Dias';

    final autonomyLabel = stats.estimatedAutonomy > 0
        ? '${formatNumber(stats.estimatedAutonomy, 0)} km'
        : '-- km';

    final monthlyLabel = stats.monthlyProjection > 0
        ? formatMoney(stats.monthlyProjection)
        : 'R\$ --';

    final progressVal = (stats.fullTankPercentage / 100.0).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com Ícone Laranja e Título
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: orangeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.show_chart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rotina de abastecimento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: orangeColor,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grade 2x2 com as métricas
            Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: 'Entre abastecimentos',
                    value: distanceLabel,
                  ),
                ),
                Expanded(
                  child: _MetricItem(
                    label: 'Frequência',
                    value: freqLabel,
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: 'Autonomia estimada',
                    value: autonomyLabel,
                  ),
                ),
                Expanded(
                  child: _MetricItem(
                    label: 'Projeção mensal',
                    value: monthlyLabel,
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Rodapé com barra de progresso e texto explicativo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressVal > 0 ? progressVal : 0.05,
                      minHeight: 10,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFF1F1F4),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(orangeColor),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    stats.totalFuels > 0
                        ? '${stats.fullTankCount} de ${stats.totalFuels} abastecimentos com tanque cheio (${formatNumber(stats.fullTankPercentage, 1)}%) — a média é medida de um tanque cheio até o próximo.'
                        : 'Cadastre abastecimentos para acompanhar sua rotina e projeção mensal.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment crossAxisAlignment;

  const _MetricItem({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[400] : const Color(0xFF8E8E93),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
