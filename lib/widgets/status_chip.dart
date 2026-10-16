import 'package:flutter/material.dart';

import '../models/maintenance_alert.dart';
import '../theme/app_colors.dart';

/// Etiqueta colorida com a situação de um serviço.
class StatusChip extends StatelessWidget {
  final AlertStatus status;
  const StatusChip(this.status, {super.key});

  static Color colorOf(AlertStatus status) => switch (status) {
        AlertStatus.overdue => AppColors.danger,
        AlertStatus.soon => AppColors.warning,
        AlertStatus.ok => AppColors.success,
        AlertStatus.none => Colors.grey,
      };

  static String labelOf(AlertStatus status) => switch (status) {
        AlertStatus.overdue => 'Atrasado',
        AlertStatus.soon => 'Em breve',
        AlertStatus.ok => 'Em dia',
        AlertStatus.none => 'Sem registro',
      };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labelOf(status),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
