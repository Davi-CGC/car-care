import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleType { carro, moto, caminhao }

/// Veículo do usuário. Salvo em: users/{uid}/vehicles/{id}
class Vehicle {
  final String id;
  final VehicleType type;
  final String brand;
  final String model;
  final String year;
  final String plate;
  final int currentKm;

  /// 'Manual', 'Automático' ou '' (motos).
  final String transmission;

  // Dados da Tabela FIPE (vazios se o usuário não consultou).
  final String fipeCode;
  final String fipeValue;
  final String fipeReference;

  // Capacidade do tanque de combustível (Litros ou m³ no caso de GNV)
  final double tankCapacity;

  // Documentos e Lembretes (IPVA, Licenciamento, Seguro, Rodízio de Pneus)
  final int? ipvaDueMonth;
  final bool ipvaPaid;
  final double? ipvaAmount;
  final bool licensingPaid;
  final String insuranceCompany;
  final String insurancePolicy;
  final String insurancePhone;
  final DateTime? insuranceExpiryDate;
  final int? lastTireRotationKm;
  final int tireRotationIntervalKm;

  final DateTime createdAt;

  Vehicle({
    this.id = '',
    required this.type,
    required this.brand,
    required this.model,
    required this.year,
    this.plate = '',
    this.currentKm = 0,
    this.transmission = '',
    this.fipeCode = '',
    this.fipeValue = '',
    this.fipeReference = '',
    this.tankCapacity = 0,
    this.ipvaDueMonth,
    this.ipvaPaid = false,
    this.ipvaAmount,
    this.licensingPaid = false,
    this.insuranceCompany = '',
    this.insurancePolicy = '',
    this.insurancePhone = '',
    this.insuranceExpiryDate,
    this.lastTireRotationKm,
    this.tireRotationIntervalKm = 10000,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCar => type == VehicleType.carro;
  bool get isMotorcycle => type == VehicleType.moto;
  bool get isTruck => type == VehicleType.caminhao;

  String get name => '$brand $model';

  String get typeLabel {
    switch (type) {
      case VehicleType.carro:
        return 'Carro';
      case VehicleType.caminhao:
        return 'Caminhão';
      case VehicleType.moto:
        return 'Moto';
    }
  }

  /// Capacidade efetiva do tanque (usa o valor cadastrado ou um padrão comum).
  double get effectiveTankCapacity {
    if (tankCapacity > 0) return tankCapacity;
    if (isCar) return 50.0;
    if (isTruck) return 300.0;
    return 14.0; // Moto
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'brand': brand,
        'model': model,
        'year': year,
        'plate': plate,
        'currentKm': currentKm,
        'transmission': isMotorcycle ? '' : transmission,
        'fipeCode': fipeCode,
        'fipeValue': fipeValue,
        'fipeReference': fipeReference,
        'tankCapacity': tankCapacity,
        'ipvaDueMonth': ipvaDueMonth,
        'ipvaPaid': ipvaPaid,
        'ipvaAmount': ipvaAmount,
        'licensingPaid': licensingPaid,
        'insuranceCompany': insuranceCompany,
        'insurancePolicy': insurancePolicy,
        'insurancePhone': insurancePhone,
        'insuranceExpiryDate': insuranceExpiryDate != null
            ? Timestamp.fromDate(insuranceExpiryDate!)
            : null,
        'lastTireRotationKm': lastTireRotationKm,
        'tireRotationIntervalKm': tireRotationIntervalKm,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Vehicle.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final typeStr = d['type']?.toString().toLowerCase() ?? '';
    VehicleType resolvedType;
    if (typeStr == 'moto') {
      resolvedType = VehicleType.moto;
    } else if (typeStr == 'caminhao') {
      resolvedType = VehicleType.caminhao;
    } else {
      resolvedType = VehicleType.carro;
    }

    return Vehicle(
      id: doc.id,
      type: resolvedType,
      brand: d['brand'] ?? '',
      model: d['model'] ?? '',
      year: d['year'] ?? '',
      plate: d['plate'] ?? '',
      currentKm: (d['currentKm'] as num?)?.toInt() ?? 0,
      transmission: d['transmission'] ?? '',
      fipeCode: d['fipeCode'] ?? '',
      fipeValue: d['fipeValue'] ?? '',
      fipeReference: d['fipeReference'] ?? '',
      tankCapacity: (d['tankCapacity'] as num?)?.toDouble() ?? 0,
      ipvaDueMonth: (d['ipvaDueMonth'] as num?)?.toInt(),
      ipvaPaid: d['ipvaPaid'] == true,
      ipvaAmount: (d['ipvaAmount'] as num?)?.toDouble(),
      licensingPaid: d['licensingPaid'] == true,
      insuranceCompany: d['insuranceCompany'] ?? '',
      insurancePolicy: d['insurancePolicy'] ?? '',
      insurancePhone: d['insurancePhone'] ?? '',
      insuranceExpiryDate:
          (d['insuranceExpiryDate'] as Timestamp?)?.toDate(),
      lastTireRotationKm: (d['lastTireRotationKm'] as num?)?.toInt(),
      tireRotationIntervalKm:
          (d['tireRotationIntervalKm'] as num?)?.toInt() ?? 10000,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
