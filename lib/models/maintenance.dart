import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço realizado em um veículo (troca de óleo, freios, revisão...).
/// Salvo em: users/{uid}/maintenances/{id}
class Maintenance {
  final String id;
  final String vehicleId;
  final String category;
  final DateTime date;
  final int km;
  final double cost;
  final String notes;

  /// Próximo serviço (opcional). Usado para gerar os alertas.
  final int? nextKm;
  final DateTime? nextDate;

  final DateTime createdAt;

  Maintenance({
    this.id = '',
    required this.vehicleId,
    required this.category,
    required this.date,
    required this.km,
    required this.cost,
    this.notes = '',
    this.nextKm,
    this.nextDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'vehicleId': vehicleId,
        'category': category,
        'date': Timestamp.fromDate(date),
        'km': km,
        'cost': cost,
        'notes': notes,
        'nextKm': nextKm,
        'nextDate': nextDate == null ? null : Timestamp.fromDate(nextDate!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Maintenance.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Maintenance(
      id: doc.id,
      vehicleId: d['vehicleId'] ?? '',
      category: d['category'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      km: (d['km'] as num?)?.toInt() ?? 0,
      cost: (d['cost'] as num?)?.toDouble() ?? 0,
      notes: d['notes'] ?? '',
      nextKm: (d['nextKm'] as num?)?.toInt(),
      nextDate: (d['nextDate'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
