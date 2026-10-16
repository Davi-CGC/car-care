import '../models/fuel_record.dart';
import '../models/maintenance.dart';
import '../models/maintenance_alert.dart';
import '../models/vehicle.dart';
import 'constants.dart';

/// Cálculos do app: alertas, consumo médio e gastos.
class Calculations {
  Calculations._();

  /// Situação de uma manutenção em relação ao próximo serviço.
  static AlertStatus statusOf(Maintenance m, Vehicle v) {
    if (m.nextKm == null && m.nextDate == null) return AlertStatus.none;
    final now = DateTime.now();
    var status = AlertStatus.ok;

    if (m.nextKm != null) {
      final remaining = m.nextKm! - v.currentKm;
      if (remaining <= 0) return AlertStatus.overdue;
      if (remaining <= alertKmBefore) status = AlertStatus.soon;
    }
    if (m.nextDate != null) {
      final days = m.nextDate!.difference(now).inDays;
      if (!now.isBefore(m.nextDate!)) return AlertStatus.overdue;
      if (days <= alertDaysBefore) status = AlertStatus.soon;
    }
    return status;
  }

  /// Última manutenção de cada categoria de cada veículo.
  static Map<String, Maintenance> latestByCategory(List<Maintenance> list) {
    final latest = <String, Maintenance>{};
    for (final m in list) {
      final key = '${m.vehicleId}|${m.category}';
      final current = latest[key];
      if (current == null || m.date.isAfter(current.date)) latest[key] = m;
    }
    return latest;
  }

  /// Alertas (atrasados primeiro, depois os próximos).
  static List<MaintenanceAlert> alerts(
      List<Vehicle> vehicles, List<Maintenance> maintenances) {
    final byId = {for (final v in vehicles) v.id: v};
    final result = <MaintenanceAlert>[];
    for (final m in latestByCategory(maintenances).values) {
      final vehicle = byId[m.vehicleId];
      if (vehicle == null) continue;
      final status = statusOf(m, vehicle);
      if (status == AlertStatus.soon || status == AlertStatus.overdue) {
        result.add(MaintenanceAlert(vehicle, m, status));
      }
    }
    result.sort((a, b) => b.status.index.compareTo(a.status.index));
    return result;
  }

  /// Consumo médio em km/l. Considera que todo abastecimento enche o tanque:
  /// distância entre o primeiro e o último registro ÷ litros (sem o primeiro).
  static double? averageConsumption(List<FuelRecord> records) {
    if (records.length < 2) return null;
    final sorted = [...records]..sort((a, b) => a.km.compareTo(b.km));
    final distance = sorted.last.km - sorted.first.km;
    final liters = sorted.skip(1).fold<double>(0, (sum, r) => sum + r.liters);
    if (distance <= 0 || liters <= 0) return null;
    return distance / liters;
  }

  static double maintenanceTotal(Iterable<Maintenance> list) =>
      list.fold(0, (sum, m) => sum + m.cost);

  static double fuelTotal(Iterable<FuelRecord> list) =>
      list.fold(0, (sum, f) => sum + f.totalPrice);

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
