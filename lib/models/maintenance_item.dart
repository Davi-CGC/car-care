import 'package:flutter/material.dart';

/// Item do plano de manutenção (ex.: "Troca de óleo e filtro").
/// [intervalKm] e [intervalMonths] são sugestões usadas para calcular o
/// próximo serviço. Ficam definidos em utils/maintenance_catalog.dart.
class MaintenanceItem {
  final String name;
  final IconData icon;
  final int? intervalKm;
  final int? intervalMonths;

  /// true = só aparece para carros com câmbio manual (ex.: embreagem).
  final bool onlyManual;

  const MaintenanceItem(
    this.name,
    this.icon, {
    this.intervalKm,
    this.intervalMonths,
    this.onlyManual = false,
  });

  String get intervalLabel {
    final parts = <String>[
      if (intervalKm != null) '$intervalKm km',
      if (intervalMonths != null) '$intervalMonths meses',
    ];
    return parts.isEmpty ? 'Conforme necessidade' : 'A cada ${parts.join(' ou ')}';
  }
}
