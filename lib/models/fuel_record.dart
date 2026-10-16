import 'package:cloud_firestore/cloud_firestore.dart';

/// Abastecimento. Usado para calcular o consumo médio (km/l) e os gastos.
/// Salvo em: users/{uid}/fuel/{id}
class FuelRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int km;
  final double liters;
  final double totalPrice;
  final DateTime createdAt;

  FuelRecord({
    this.id = '',
    required this.vehicleId,
    required this.date,
    required this.km,
    required this.liters,
    required this.totalPrice,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get pricePerLiter => liters > 0 ? totalPrice / liters : 0;

  Map<String, dynamic> toMap() => {
        'vehicleId': vehicleId,
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
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      km: (d['km'] as num?)?.toInt() ?? 0,
      liters: (d['liters'] as num?)?.toDouble() ?? 0,
      totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
