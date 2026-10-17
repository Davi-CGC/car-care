import '../models/vehicle.dart';
import 'rodizio_helper.dart';

class IpvaInfo {
  final int month;
  final String monthName;
  final double estimatedValue;
  final bool isPaid;
  final bool isOverdue;

  const IpvaInfo({
    required this.month,
    required this.monthName,
    required this.estimatedValue,
    required this.isPaid,
    required this.isOverdue,
  });
}

class LicensingInfo {
  final int month;
  final String monthName;
  final bool isPaid;
  final bool isDueSoon;
  final bool isOverdue;
  final String deadlineDescription;

  const LicensingInfo({
    required this.month,
    required this.monthName,
    required this.isPaid,
    required this.isDueSoon,
    required this.isOverdue,
    required this.deadlineDescription,
  });
}

class InsuranceInfo {
  final String company;
  final String policy;
  final String phone;
  final DateTime? expiryDate;
  final int? daysRemaining;
  final bool isExpired;
  final bool isDueSoon;

  const InsuranceInfo({
    required this.company,
    required this.policy,
    required this.phone,
    this.expiryDate,
    this.daysRemaining,
    required this.isExpired,
    required this.isDueSoon,
  });
}

class TireRotationInfo {
  final int? lastKm;
  final int intervalKm;
  final int nextKm;
  final int remainingKm;
  final double progress; // 0.0 a 1.0
  final bool isDue;
  final bool isSoon;

  const TireRotationInfo({
    required this.lastKm,
    required this.intervalKm,
    required this.nextKm,
    required this.remainingKm,
    required this.progress,
    required this.isDue,
    required this.isSoon,
  });
}

class VehicleDocumentsHelper {
  VehicleDocumentsHelper._();

  static const List<String> monthNames = [
    '',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  /// Informações e cálculo de IPVA do veículo.
  static IpvaInfo getIpvaInfo(Vehicle v) {
    final digit = RodizioHelper.extractLastDigit(v.plate);
    final now = DateTime.now();

    // Mês padrão em SP para parcela única ou início: Janeiro/Fevereiro
    int month = v.ipvaDueMonth ?? 1;
    if (v.ipvaDueMonth == null && digit != null) {
      if (digit >= 1 && digit <= 5) {
        month = 1; // Janeiro
      } else {
        month = 2; // Fevereiro
      }
    }

    // Estimativa de IPVA baseada na Tabela FIPE
    double estimated = v.ipvaAmount ?? 0.0;
    if (estimated <= 0 && v.fipeValue.isNotEmpty) {
      final cleanedFipe = v.fipeValue
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final fipeNum = double.tryParse(cleanedFipe) ?? 0.0;
      if (fipeNum > 0) {
        // Alíquotas comuns: 4% para carros de passeio, 2% para motos, 1.5% para caminhões
        final rate = v.isMotorcycle ? 0.02 : (v.isTruck ? 0.015 : 0.04);
        estimated = fipeNum * rate;
      }
    }

    final isPaid = v.ipvaPaid;
    final isOverdue = !isPaid && (now.month > month);

    return IpvaInfo(
      month: month,
      monthName: month >= 1 && month <= 12 ? monthNames[month] : 'A Definir',
      estimatedValue: estimated,
      isPaid: isPaid,
      isOverdue: isOverdue,
    );
  }

  /// Informações oficiais do Calendário de Licenciamento Detran.
  static LicensingInfo getLicensingInfo(Vehicle v) {
    final digit = RodizioHelper.extractLastDigit(v.plate);
    final now = DateTime.now();

    int month = 12;
    if (digit != null) {
      if (v.isTruck) {
        // Calendário de Caminhões Detran
        switch (digit) {
          case 1:
          case 2:
            month = 9; // Setembro
            break;
          case 3:
          case 4:
          case 5:
            month = 10; // Outubro
            break;
          case 6:
          case 7:
          case 8:
            month = 11; // Novembro
            break;
          case 9:
          case 0:
            month = 12; // Dezembro
            break;
        }
      } else {
        // Carros e Motos Detran
        switch (digit) {
          case 1:
          case 2:
            month = 7; // Julho
            break;
          case 3:
          case 4:
            month = 8; // Agosto
            break;
          case 5:
          case 6:
            month = 9; // Setembro
            break;
          case 7:
          case 8:
            month = 10; // Outubro
            break;
          case 9:
            month = 11; // Novembro
            break;
          case 0:
            month = 12; // Dezembro
            break;
        }
      }
    }

    final isPaid = v.licensingPaid;
    final isDueSoon = !isPaid && now.month == month;
    final isOverdue = !isPaid && now.month > month;

    final mName = month >= 1 && month <= 12 ? monthNames[month] : 'Dezembro';
    final deadlineDesc = digit != null
        ? 'Final $digit: Vence até o final de $mName'
        : 'Informe a placa com número final para ver o mês exato.';

    return LicensingInfo(
      month: month,
      monthName: mName,
      isPaid: isPaid,
      isDueSoon: isDueSoon,
      isOverdue: isOverdue,
      deadlineDescription: deadlineDesc,
    );
  }

  /// Informações da apólice e assistência do seguro.
  static InsuranceInfo getInsuranceInfo(Vehicle v) {
    final now = DateTime.now();
    final expiry = v.insuranceExpiryDate;
    int? days;
    bool expired = false;
    bool dueSoon = false;

    if (expiry != null) {
      days = expiry.difference(now).inDays;
      if (days < 0) {
        expired = true;
      } else if (days <= 30) {
        dueSoon = true;
      }
    }

    return InsuranceInfo(
      company: v.insuranceCompany,
      policy: v.insurancePolicy,
      phone: v.insurancePhone,
      expiryDate: expiry,
      daysRemaining: days,
      isExpired: expired,
      isDueSoon: dueSoon,
    );
  }

  /// Informações de Rodízio de Pneus (troca periódica de posição).
  static TireRotationInfo getTireRotationInfo(Vehicle v) {
    final interval = v.tireRotationIntervalKm > 0 ? v.tireRotationIntervalKm : 10000;
    final lastKm = v.lastTireRotationKm ?? 0;
    final nextKm = lastKm + interval;
    final remainingKm = nextKm - v.currentKm;

    final kmSinceLast = v.currentKm - lastKm;
    double progress = 0.0;
    if (interval > 0) {
      progress = (kmSinceLast / interval).clamp(0.0, 1.0);
    }

    final isDue = remainingKm <= 0;
    final isSoon = remainingKm > 0 && remainingKm <= 1000;

    return TireRotationInfo(
      lastKm: v.lastTireRotationKm,
      intervalKm: interval,
      nextKm: nextKm,
      remainingKm: remainingKm,
      progress: progress,
      isDue: isDue,
      isSoon: isSoon,
    );
  }
}
