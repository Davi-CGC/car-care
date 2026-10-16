import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de combustíveis suportados.
class FuelTypes {
  static const String gasolina = 'Gasolina';
  static const String etanol = 'Etanol';
  static const String diesel = 'Diesel';
  static const String gnv = 'GNV';

  static const List<String> all = [gasolina, etanol, diesel, gnv];
}

/// Abastecimento. Usado para calcular o consumo médio (km/l ou km/m³) e os gastos.
/// Salvo em: users/{uid}/fuel/{id}
class FuelRecord {
  final String id;
  final String vehicleId;
  final String fuelType;
  final DateTime date;
  final int km;
  final double liters;
  final double totalPrice;
  final DateTime createdAt;

  FuelRecord({
    this.id = '',
    required this.vehicleId,
    this.fuelType = FuelTypes.gasolina,
    required this.date,
    required this.km,
    required this.liters,
    required this.totalPrice,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isGnv => fuelType == FuelTypes.gnv;
  String get unit => isGnv ? 'm³' : 'L';
  String get consumptionUnit => isGnv ? 'km/m³' : 'km/l';

  double get pricePerLiter => liters > 0 ? totalPrice / liters : 0;

  Map<String, dynamic> toMap() => {
        'vehicleId': vehicleId,
        'fuelType': fuelType,
        'date': Timestamp.fromDate(date),
        'km': km,
        'liters': liters,
        'totalPrice': totalPrice,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory FuelRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FuelRecord(
      id: doc.id,
      vehicleId: d['vehicleId'] ?? '',
      fuelType: d['fuelType'] ?? FuelTypes.gasolina,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      km: (d['km'] as num?)?.toInt() ?? 0,
      liters: (d['liters'] as num?)?.toDouble() ?? 0,
      totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
