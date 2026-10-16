import 'package:flutter/material.dart';

import '../models/fuel_record.dart';
import '../models/maintenance.dart';
import '../models/maintenance_alert.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/maintenance_catalog.dart';
import 'status_chip.dart';

/// Linha de manutenção usada no histórico.
class MaintenanceTile extends StatelessWidget {
  final Maintenance maintenance;
  final String? vehicleName;
  final VoidCallback? onTap;

  const MaintenanceTile({
    super.key,
    required this.maintenance,
    this.vehicleName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = maintenance;
    final subtitle = [
      ?vehicleName,
      formatDate(m.date),
      formatKm(m.km),
    ].join(' • ');
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: _IconBox(MaintenanceCatalog.iconOf(m.category)),
        title: Text(m.category, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(formatMoney(m.cost),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Linha de abastecimento.
class FuelTile extends StatelessWidget {
  final FuelRecord record;
  final VoidCallback? onTap;

  const FuelTile({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const _IconBox(Icons.local_gas_station),
        title: Text('${formatNumber(r.liters, 2)} L • ${formatMoney(r.pricePerLiter)}/L'),
        subtitle: Text('${formatDate(r.date)} • ${formatKm(r.km)}'),
        trailing: Text(formatMoney(r.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Linha de alerta (serviço atrasado ou próximo).
class AlertTile extends StatelessWidget {
  final MaintenanceAlert alert;
  final VoidCallback? onTap;

  const AlertTile({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = alert.maintenance;
    final color = StatusChip.colorOf(alert.status);
    final due = [
      if (m.nextKm != null) formatKm(m.nextKm!),
      if (m.nextDate != null) formatDate(m.nextDate!),
    ].join(' ou ');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          alert.status == AlertStatus.overdue ? Icons.error : Icons.schedule,
          color: color,
        ),
        title: Text(m.category, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${alert.vehicle.name}\nPróximo: $due',
            maxLines: 3, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: StatusChip(alert.status),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  const _IconBox(this.icon);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: AppColors.goldenPollen.withValues(alpha: 0.18),
      child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.goldenPollen
          : AppColors.obsidian),
    );
  }
}
