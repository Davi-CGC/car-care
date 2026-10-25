import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço realizado em um veículo (troca de óleo, freios, revisão...).
/// Salvo em: users/{uid}/maintenances/{id}
class Manutencao {
  final String id;
  final String idVeiculo;
  final String categoria;
  final DateTime data;
  final int km;
  final double custo;
  final String observacoes;

  /// Próximo serviço (opcional). Usado para gerar os alertas.
  final int? proximoKm;
  final DateTime? proximaData;

  final DateTime criadoEm;

  Manutencao({
    this.id = '',
    String? idVeiculo,
    String? vehicleId,
    String? categoria,
    String? category,
    DateTime? data,
    DateTime? date,
    required this.km,
    double? custo,
    double? cost,
    String observacoes = '',
    String notes = '',
    int? proximoKm,
    int? nextKm,
    DateTime? proximaData,
    DateTime? nextDate,
    DateTime? criadoEm,
    DateTime? createdAt,
  })  : idVeiculo = idVeiculo ?? vehicleId ?? '',
        categoria = categoria ?? category ?? '',
        data = data ?? date ?? DateTime.now(),
        custo = custo ?? cost ?? 0.0,
        observacoes = observacoes.isNotEmpty ? observacoes : notes,
        proximoKm = proximoKm ?? nextKm,
        proximaData = proximaData ?? nextDate,
        criadoEm = criadoEm ?? createdAt ?? DateTime.now();

  // Aliases de compatibilidade
  String get vehicleId => idVeiculo;
  String get category => categoria;
  DateTime get date => data;
  double get cost => custo;
  String get notes => observacoes;
  int? get nextKm => proximoKm;
  DateTime? get nextDate => proximaData;
  DateTime get createdAt => criadoEm;

  Map<String, dynamic> toMap() => {
        'vehicleId': idVeiculo,
        'category': categoria,
        'date': Timestamp.fromDate(data),
        'km': km,
        'cost': custo,
        'notes': observacoes,
        'nextKm': proximoKm,
        'nextDate': proximaData == null ? null : Timestamp.fromDate(proximaData!),
        'createdAt': Timestamp.fromDate(criadoEm),
      };

  factory Manutencao.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Manutencao(
      id: doc.id,
      idVeiculo: d['idVeiculo'] ?? d['vehicleId'] ?? '',
      categoria: d['categoria'] ?? d['category'] ?? '',
      data: (d['data'] as Timestamp?)?.toDate() ?? (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      km: (d['km'] as num?)?.toInt() ?? 0,
      custo: (d['custo'] as num?)?.toDouble() ?? (d['cost'] as num?)?.toDouble() ?? 0,
      observacoes: d['observacoes'] ?? d['notes'] ?? '',
      proximoKm: (d['proximoKm'] as num?)?.toInt() ?? (d['nextKm'] as num?)?.toInt(),
      proximaData: (d['proximaData'] as Timestamp?)?.toDate() ?? (d['nextDate'] as Timestamp?)?.toDate(),
      criadoEm: (d['criadoEm'] as Timestamp?)?.toDate() ?? (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Alias para manter compatibilidade
typedef Maintenance = Manutencao;
