import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleType { carro, moto }

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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCar => type == VehicleType.carro;
  String get name => '$brand $model';
  String get typeLabel => isCar ? 'Carro' : 'Moto';

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'brand': brand,
        'model': model,
        'year': year,
        'plate': plate,
        'currentKm': currentKm,
        'transmission': isCar ? transmission : '',
        'fipeCode': fipeCode,
        'fipeValue': fipeValue,
        'fipeReference': fipeReference,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Vehicle.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Vehicle(
      id: doc.id,
      type: d['type'] == 'moto' ? VehicleType.moto : VehicleType.carro,
      brand: d['brand'] ?? '',
      model: d['model'] ?? '',
      year: d['year'] ?? '',
      plate: d['plate'] ?? '',
      currentKm: (d['currentKm'] as num?)?.toInt() ?? 0,
      transmission: d['transmission'] ?? '',
      fipeCode: d['fipeCode'] ?? '',
      fipeValue: d['fipeValue'] ?? '',
      fipeReference: d['fipeReference'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
