import '../models/vehicle.dart';

/// Utilitário para cálculo e aviso de Rodízio Veicular Municipal (padrão São Paulo e capitais).
/// Regra baseada no último dígito da placa do veículo:
/// - Finais 1 e 2: Segunda-feira
/// - Finais 3 e 4: Terça-feira
/// - Finais 5 e 6: Quarta-feira
/// - Finais 7 e 8: Quinta-feira
/// - Finais 9 e 0: Sexta-feira
/// - Sábados e Domingos: Livre
/// - Motocicletas: Isentas de rodízio municipal
/// - Caminhões: Sujeitos ao rodízio de caminhões / ZMRC (05h às 21h em dias úteis)
class RodizioInfo {
  final int? lastDigit;
  final String dayName;
  final int weekday; // DateTime.monday .. DateTime.friday
  final bool isToday;
  final bool isExempt;
  final String description;
  final String timeRange;

  const RodizioInfo({
    required this.lastDigit,
    required this.dayName,
    required this.weekday,
    required this.isToday,
    required this.isExempt,
    required this.description,
    this.timeRange = '07h às 10h e 17h às 20h',
  });
}

class RodizioHelper {
  RodizioHelper._();

  /// Extrai o último dígito numérico da placa (válido para placas antigas ABC-1234 e padrão Mercosul ABC1D23).
  static int? extractLastDigit(String plate) {
    final cleaned = plate.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned.substring(cleaned.length - 1));
  }

  /// Retorna as informações de rodízio para um veículo.
  static RodizioInfo getInfo(
    String plate, {
    bool isCar = true,
    bool isTruck = false,
    VehicleType? type,
  }) {
    final effectiveType = type ??
        (isTruck
            ? VehicleType.caminhao
            : (isCar ? VehicleType.carro : VehicleType.moto));

    if (effectiveType == VehicleType.moto) {
      return const RodizioInfo(
        lastDigit: null,
        dayName: 'Isento',
        weekday: 0,
        isToday: false,
        isExempt: true,
        description: 'Motocicletas são isentas do rodízio municipal.',
      );
    }

    final digit = extractLastDigit(plate);
    if (digit == null) {
      return const RodizioInfo(
        lastDigit: null,
        dayName: 'Placa não informada',
        weekday: 0,
        isToday: false,
        isExempt: false,
        description: 'Informe a placa com número final para ver o dia do rodízio.',
      );
    }

    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final timeRange = effectiveType == VehicleType.caminhao
        ? '05h às 21h (ZMRC)'
        : '07h às 10h e 17h às 20h';

    switch (digit) {
      case 1:
      case 2:
        return RodizioInfo(
          lastDigit: digit,
          dayName: 'Segunda-feira',
          weekday: DateTime.monday,
          isToday: currentWeekday == DateTime.monday,
          isExempt: false,
          timeRange: timeRange,
          description: 'Segunda-feira (finais 1 e 2)',
        );
      case 3:
      case 4:
        return RodizioInfo(
          lastDigit: digit,
          dayName: 'Terça-feira',
          weekday: DateTime.tuesday,
          isToday: currentWeekday == DateTime.tuesday,
          isExempt: false,
          timeRange: timeRange,
          description: 'Terça-feira (finais 3 e 4)',
        );
      case 5:
      case 6:
        return RodizioInfo(
          lastDigit: digit,
          dayName: 'Quarta-feira',
          weekday: DateTime.wednesday,
          isToday: currentWeekday == DateTime.wednesday,
          isExempt: false,
          timeRange: timeRange,
          description: 'Quarta-feira (finais 5 e 6)',
        );
      case 7:
      case 8:
        return RodizioInfo(
          lastDigit: digit,
          dayName: 'Quinta-feira',
          weekday: DateTime.thursday,
          isToday: currentWeekday == DateTime.thursday,
          isExempt: false,
          timeRange: timeRange,
          description: 'Quinta-feira (finais 7 e 8)',
        );
      case 9:
      case 0:
        return RodizioInfo(
          lastDigit: digit,
          dayName: 'Sexta-feira',
          weekday: DateTime.friday,
          isToday: currentWeekday == DateTime.friday,
          isExempt: false,
          timeRange: timeRange,
          description: 'Sexta-feira (finais 9 e 0)',
        );
      default:
        return const RodizioInfo(
          lastDigit: null,
          dayName: 'Inválido',
          weekday: 0,
          isToday: false,
          isExempt: false,
          description: 'Placa com formato não identificado.',
        );
    }
  }
}
