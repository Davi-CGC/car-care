import '../models/fuel_record.dart';
import '../models/maintenance.dart';
import '../models/maintenance_alert.dart';
import '../models/vehicle.dart';
import 'constants.dart';

enum ConsumptionLevel {
  otimo, // Verde: Muito econômico
  moderado, // Amarelo: Consumo padrão/normal
  alto, // Vermelho: Consumo alto / Gastando muito
}

class ConsumptionEvaluation {
  final double kmPerLiter;
  final ConsumptionLevel level;
  final String label;
  final String description;
  final double score; // 0.0 a 1.0 para barra de termômetro

  const ConsumptionEvaluation({
    required this.kmPerLiter,
    required this.level,
    required this.label,
    required this.description,
    required this.score,
  });
}

/// Cálculos do app: alertas, consumo médio, termômetro e gastos.
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

  /// Consumo médio em km/l ou km/m³.
  /// distância entre o primeiro e o último registro ÷ litros (sem o primeiro).
  static double? averageConsumption(List<FuelRecord> records) {
    if (records.length < 2) return null;
    final sorted = [...records]..sort((a, b) => a.km.compareTo(b.km));
    final distance = sorted.last.km - sorted.first.km;
    final liters = sorted.skip(1).fold<double>(0, (sum, r) => sum + r.liters);
    if (distance <= 0 || liters <= 0) return null;
    return distance / liters;
  }

  /// Avalia a eficiência do consumo (Termômetro: Econômico / Normal / Alto).
  static ConsumptionEvaluation? evaluateConsumption(
    double? kmPerUnit, {
    bool isCar = true,
    String fuelType = FuelTypes.gasolina,
  }) {
    if (kmPerUnit == null || kmPerUnit <= 0) return null;

    if (!isCar) {
      // Motos
      if (kmPerUnit >= 33.0) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.otimo,
          label: 'Muito Econômico',
          description: 'Excelente rendimento para a moto!',
          score: 0.90,
        );
      } else if (kmPerUnit >= 24.0) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.moderado,
          label: 'Normal / Moderado',
          description: 'Média de consumo dentro do esperado.',
          score: 0.55,
        );
      } else {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.alto,
          label: 'Alto Consumo',
          description: 'Consumindo bastante. Verifique velas, filtro e pneus.',
          score: 0.20,
        );
      }
    }

    // Carros
    if (fuelType == FuelTypes.etanol) {
      if (kmPerUnit >= 9.5) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.otimo,
          label: 'Muito Econômico',
          description: 'Excelente média rodando no etanol!',
          score: 0.90,
        );
      } else if (kmPerUnit >= 7.0) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.moderado,
          label: 'Normal / Moderado',
          description: 'Consumo padrão para combustível vegetal.',
          score: 0.55,
        );
      } else {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.alto,
          label: 'Alto Consumo',
          description: 'Consumo alto. Atenção ao peso, calibragem e bicos.',
          score: 0.20,
        );
      }
    } else if (fuelType == FuelTypes.gnv) {
      if (kmPerUnit >= 13.5) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.otimo,
          label: 'Muito Econômico',
          description: 'Ótima autonomia no gás natural!',
          score: 0.90,
        );
      } else if (kmPerUnit >= 10.0) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.moderado,
          label: 'Normal / Moderado',
          description: 'Consumo esperado para GNV.',
          score: 0.55,
        );
      } else {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.alto,
          label: 'Alto Consumo',
          description: 'Rendimento baixo no GNV. Cheque regulagem do kit.',
          score: 0.20,
        );
      }
    } else {
      // Gasolina / Diesel
      if (kmPerUnit >= 13.0) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.otimo,
          label: 'Muito Econômico',
          description: 'Carro muito econômico!',
          score: 0.90,
        );
      } else if (kmPerUnit >= 9.0) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.moderado,
          label: 'Normal / Moderado',
          description: 'Consumo equilibrado para o dia a dia.',
          score: 0.55,
        );
      } else {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.alto,
          label: 'Alto Consumo',
          description: 'Consumindo muito. Verifique alinhamento e filtros.',
          score: 0.20,
        );
      }
    }
  }

  static double maintenanceTotal(Iterable<Maintenance> list) =>
      list.fold(0, (sum, m) => sum + m.cost);

  static double fuelTotal(Iterable<FuelRecord> list) =>
      list.fold(0, (sum, f) => sum + f.totalPrice);

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
