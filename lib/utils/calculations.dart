import 'dart:math' as math;

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

/// Estatísticas de Rotina de Abastecimento (reproduz fielmente o card de rotina).
class FuelRoutineStats {
  final double avgDistanceBetweenFuels; // km
  final double avgFrequencyDays; // Dias
  final double estimatedAutonomy; // km
  final double monthlyProjection; // R$
  final int fullTankCount;
  final int totalFuels;
  final double fullTankPercentage; // %
  final double? fullTankAverageConsumption; // km/l dos ciclos de tanque cheio

  const FuelRoutineStats({
    required this.avgDistanceBetweenFuels,
    required this.avgFrequencyDays,
    required this.estimatedAutonomy,
    required this.monthlyProjection,
    required this.fullTankCount,
    required this.totalFuels,
    required this.fullTankPercentage,
    this.fullTankAverageConsumption,
  });
}

/// Cálculos do app: alertas, consumo médio, rotina de abastecimento, termômetro e gastos.
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

  /// Método oficial do Tanque Cheio:
  /// Calcula o consumo real medido de um tanque cheio até o próximo.
  static double? fullTankConsumption(List<FuelRecord> records) {
    if (records.length < 2) return null;
    final sorted = [...records]..sort((a, b) => a.km.compareTo(b.km));

    double totalDistance = 0;
    double totalLiters = 0;

    int lastFullIndex = -1;
    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].isFullTank) {
        if (lastFullIndex != -1) {
          final distance = sorted[i].km - sorted[lastFullIndex].km;
          if (distance > 0) {
            double cycleLiters = 0;
            for (int j = lastFullIndex + 1; j <= i; j++) {
              cycleLiters += sorted[j].liters;
            }
            if (cycleLiters > 0) {
              totalDistance += distance;
              totalLiters += cycleLiters;
            }
          }
        }
        lastFullIndex = i;
      }
    }

    if (totalDistance > 0 && totalLiters > 0) {
      return totalDistance / totalLiters;
    }
    return null;
  }

  /// Estatísticas completas da Rotina de Abastecimento (Card idêntico à imagem).
  static FuelRoutineStats fuelRoutine(Vehicle vehicle, List<FuelRecord> fuels) {
    if (fuels.isEmpty) {
      return const FuelRoutineStats(
        avgDistanceBetweenFuels: 0,
        avgFrequencyDays: 0,
        estimatedAutonomy: 0,
        monthlyProjection: 0,
        fullTankCount: 0,
        totalFuels: 0,
        fullTankPercentage: 0,
      );
    }

    final sorted = [...fuels]..sort((a, b) => a.km.compareTo(b.km));
    final totalFuels = sorted.length;
    final fullTankCount = sorted.where((f) => f.isFullTank).length;
    final fullTankPercentage =
        totalFuels > 0 ? (fullTankCount / totalFuels) * 100 : 0.0;

    // Distância e frequência entre abastecimentos consecutivos
    final distances = <double>[];
    final dayIntervals = <double>[];
    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      final dKm = (curr.km - prev.km).toDouble();
      if (dKm > 0) distances.add(dKm);

      final diffDays = curr.date.difference(prev.date).inHours / 24.0;
      if (diffDays > 0) dayIntervals.add(diffDays);
    }

    final avgDistance = distances.isNotEmpty
        ? distances.reduce((a, b) => a + b) / distances.length
        : (sorted.first.km > 0 ? sorted.first.km.toDouble() : 0.0);

    final avgFrequency = dayIntervals.isNotEmpty
        ? dayIntervals.reduce((a, b) => a + b) / dayIntervals.length
        : 0.0;

    // Consumo médio geral e por tanque cheio
    final generalAvg = averageConsumption(sorted);
    final fullTankAvg = fullTankConsumption(sorted);
    final effectiveAvg = fullTankAvg ?? generalAvg;

    // Autonomia estimada com tanque cheio
    final tankCap = vehicle.effectiveTankCapacity;
    double estimatedAutonomy = 0.0;
    if (effectiveAvg != null && effectiveAvg > 0) {
      estimatedAutonomy = effectiveAvg * tankCap;
    } else if (avgDistance > 0) {
      estimatedAutonomy = avgDistance * 1.25;
    }

    // Projeção mensal em R$
    double monthlyProjection = 0.0;
    final totalSpent = sorted.fold<double>(0, (sum, f) => sum + f.totalPrice);
    if (avgFrequency > 0 && totalFuels > 0) {
      final avgCostPerFill = totalSpent / totalFuels;
      final fillsPerMonth = 30.0 / avgFrequency;
      monthlyProjection = fillsPerMonth * avgCostPerFill;
    } else if (sorted.length >= 2) {
      final firstDate = sorted.first.date;
      final lastDate = sorted.last.date;
      final totalDays =
          math.max(1.0, lastDate.difference(firstDate).inHours / 24.0);
      monthlyProjection = (totalSpent / totalDays) * 30.0;
    } else if (totalFuels > 0) {
      monthlyProjection = sorted.first.totalPrice;
    }

    return FuelRoutineStats(
      avgDistanceBetweenFuels: avgDistance,
      avgFrequencyDays: avgFrequency,
      estimatedAutonomy: estimatedAutonomy,
      monthlyProjection: monthlyProjection,
      fullTankCount: fullTankCount,
      totalFuels: totalFuels,
      fullTankPercentage: fullTankPercentage,
      fullTankAverageConsumption: effectiveAvg,
    );
  }

  /// Média diária de distância percorrida (km/dia).
  static double dailyAverageDistance(List<FuelRecord> fuels) {
    if (fuels.length < 2) return 0.0;
    final sorted = [...fuels]..sort((a, b) => a.km.compareTo(b.km));
    final distance = sorted.last.km - sorted.first.km;
    final days = math.max(
        1.0, sorted.last.date.difference(sorted.first.date).inHours / 24.0);
    if (distance <= 0) return 0.0;
    return distance / days;
  }

  /// Avalia a eficiência do consumo (Termômetro: Econômico / Normal / Alto).
  static ConsumptionEvaluation? evaluateConsumption(
    double? kmPerUnit, {
    bool isCar = true,
    bool isTruck = false,
    VehicleType? vehicleType,
    String fuelType = FuelTypes.gasolina,
  }) {
    if (kmPerUnit == null || kmPerUnit <= 0) return null;

    final type = vehicleType ??
        (isTruck
            ? VehicleType.caminhao
            : (isCar ? VehicleType.carro : VehicleType.moto));

    if (type == VehicleType.moto) {
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

    if (type == VehicleType.caminhao) {
      // Caminhão (Diesel pesado)
      if (kmPerUnit >= 3.5) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.otimo,
          label: 'Excelente Rendimento',
          description: 'Ótima média para caminhão pesado!',
          score: 0.90,
        );
      } else if (kmPerUnit >= 2.4) {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.moderado,
          label: 'Normal / Moderado',
          description: 'Consumo dentro do padrão para caminhão.',
          score: 0.55,
        );
      } else {
        return ConsumptionEvaluation(
          kmPerLiter: kmPerUnit,
          level: ConsumptionLevel.alto,
          label: 'Alto Consumo',
          description:
              'Consumo elevado. Verifique filtros, bicos e calibragem.',
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
      // Gasolina / Diesel (Carro)
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
