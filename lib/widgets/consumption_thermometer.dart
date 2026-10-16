import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/calculations.dart';

/// Card e barra visual no formato de "termômetro" indicando se o veículo
/// está consumindo muito (vermelho), normal (amarelo) ou pouco (verde).
class ConsumptionThermometer extends StatelessWidget {
  final ConsumptionEvaluation evaluation;
  final String unit;

  const ConsumptionThermometer({
    super.key,
    required this.evaluation,
    this.unit = 'km/l',
  });

  Color get _color => switch (evaluation.level) {
        ConsumptionLevel.otimo => AppColors.success,
        ConsumptionLevel.moderado => AppColors.goldenPollen,
        ConsumptionLevel.alto => AppColors.danger,
      };

  IconData get _icon => switch (evaluation.level) {
        ConsumptionLevel.otimo => Icons.eco,
        ConsumptionLevel.moderado => Icons.speed,
        ConsumptionLevel.alto => Icons.local_fire_department,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: _color.withValues(alpha: isDark ? 0.15 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _color.withValues(alpha: 0.2),
                  child: Icon(_icon, color: _color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Termômetro de Consumo',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        evaluation.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${evaluation.kmPerLiter.toStringAsFixed(1)} $unit',
                  style: theme.textTheme.titleMedium?.copyWith(
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.danger,
                          AppColors.goldenPollen,
                          AppColors.success,
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: evaluation.score.clamp(0.05, 1.0),
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _color, width: 3),
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
              evaluation.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
