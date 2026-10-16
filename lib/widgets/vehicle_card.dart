import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Card de veículo usado na lista de veículos.
class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final int alertCount;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.alertCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      vehicle.year,
      if (vehicle.plate.isNotEmpty) vehicle.plate.toUpperCase(),
      formatKm(vehicle.currentKm),
    ].where((s) => s.isNotEmpty).join(' • ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.obsidian,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  vehicle.isCar ? Icons.directions_car : Icons.two_wheeler,
                  color: AppColors.goldenPollen,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (vehicle.fipeValue.isNotEmpty)
                      Text('FIPE: ${vehicle.fipeValue}',
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (alertCount > 0)
                Badge(
                  label: Text('$alertCount'),
                  backgroundColor: AppColors.danger,
                  child: const Icon(Icons.notifications_active),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
