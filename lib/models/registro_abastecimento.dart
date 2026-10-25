import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de combustíveis suportados em português.
class TiposCombustivel {
  static const String gasolina = 'Gasolina';
  static const String etanol = 'Etanol';
  static const String diesel = 'Diesel';
  static const String gnv = 'GNV';

  static const List<String> todos = [gasolina, etanol, diesel, gnv];
  static const List<String> all = todos;
}

/// Alias para manter compatibilidade
typedef FuelTypes = TiposCombustivel;

/// Abastecimento em português. Usado para calcular o consumo médio (km/l ou km/m³) e os gastos.
/// Salvo em: users/{uid}/fuel/{id}
class RegistroAbastecimento {
  final String id;
  final String idVeiculo;
  final String tipoCombustivel;
  final DateTime data;
  final int km;
  final double litros;
  final double precoTotal;
  final bool tanqueCheio;
  final String postoCombustivel;
  final DateTime criadoEm;

  RegistroAbastecimento({
    this.id = '',
    String? idVeiculo,
    String? vehicleId,
    String? tipoCombustivel,
    String? fuelType,
    DateTime? data,
    DateTime? date,
    required this.km,
    double? litros,
    double? liters,
    double? precoTotal,
    double? totalPrice,
    bool? tanqueCheio,
    bool? isFullTank,
    String? postoCombustivel,
    String? gasStation,
    DateTime? criadoEm,
    DateTime? createdAt,
  })  : idVeiculo = idVeiculo ?? vehicleId ?? '',
        tipoCombustivel = tipoCombustivel ?? fuelType ?? TiposCombustivel.gasolina,
        data = data ?? date ?? DateTime.now(),
        litros = litros ?? liters ?? 0.0,
        precoTotal = precoTotal ?? totalPrice ?? 0.0,
        tanqueCheio = tanqueCheio ?? isFullTank ?? true,
        postoCombustivel = postoCombustivel ?? gasStation ?? '',
        criadoEm = criadoEm ?? createdAt ?? DateTime.now();

  // Aliases de compatibilidade
  String get vehicleId => idVeiculo;
  String get fuelType => tipoCombustivel;
  DateTime get date => data;
  double get liters => litros;
  double get totalPrice => precoTotal;
  bool get isFullTank => tanqueCheio;
  String get gasStation => postoCombustivel;
  DateTime get createdAt => criadoEm;

  bool get eGnv => tipoCombustivel == TiposCombustivel.gnv;
  bool get isGnv => eGnv;

  String get unidade => eGnv ? 'm³' : 'L';
  String get unit => unidade;

  String get unidadeConsumo => eGnv ? 'km/m³' : 'km/l';
  String get consumptionUnit => unidadeConsumo;

  double get precoPorLitro => litros > 0 ? precoTotal / litros : 0;
  double get pricePerLiter => precoPorLitro;

  Map<String, dynamic> toMap() => {
        'vehicleId': idVeiculo,
        'fuelType': tipoCombustivel,
        'date': Timestamp.fromDate(data),
        'km': km,
        'liters': litros,
        'totalPrice': precoTotal,
        'isFullTank': tanqueCheio,
        'gasStation': postoCombustivel,
        'createdAt': Timestamp.fromDate(criadoEm),
      };

  factory RegistroAbastecimento.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RegistroAbastecimento(
      id: doc.id,
      idVeiculo: d['idVeiculo'] ?? d['vehicleId'] ?? '',
      tipoCombustivel: d['tipoCombustivel'] ?? d['fuelType'] ?? TiposCombustivel.gasolina,
      data: (d['data'] as Timestamp?)?.toDate() ?? (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      km: (d['km'] as num?)?.toInt() ?? 0,
      litros: (d['litros'] as num?)?.toDouble() ?? (d['liters'] as num?)?.toDouble() ?? 0,
      precoTotal: (d['precoTotal'] as num?)?.toDouble() ?? (d['totalPrice'] as num?)?.toDouble() ?? 0,
      tanqueCheio: d['tanqueCheio'] ?? d['isFullTank'] ?? true,
      postoCombustivel: d['postoCombustivel'] ?? d['gasStation'] ?? '',
      criadoEm: (d['criadoEm'] as Timestamp?)?.toDate() ?? (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Alias para manter compatibilidade
typedef FuelRecord = RegistroAbastecimento;
