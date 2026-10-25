import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoVeiculo { carro, moto, caminhao }

extension TipoVeiculoExt on TipoVeiculo {
  String get rotulo {
    switch (this) {
      case TipoVeiculo.carro:
        return 'Carro';
      case TipoVeiculo.moto:
        return 'Moto';
      case TipoVeiculo.caminhao:
        return 'Caminhão';
    }
  }

  String get label => rotulo;
}

/// Alias para manter compatibilidade
typedef VehicleType = TipoVeiculo;

/// Veículo do usuário em português. Salvo em: users/{uid}/vehicles/{id}
class Veiculo {
  final String id;
  final TipoVeiculo tipo;
  final String marca;
  final String modelo;
  final String ano;
  final String placa;
  final int kmAtual;

  /// 'Manual', 'Automático' ou '' (motos).
  final String transmissao;

  // Dados da Tabela FIPE (vazios se o usuário não consultou).
  final String codigoFipe;
  final String valorFipe;
  final String referenciaFipe;

  // Capacidade do tanque de combustível (Litros ou m³ no caso de GNV)
  final double capacidadeTanque;

  // Documentos e Lembretes (IPVA, Licenciamento, Seguro, Rodízio de Pneus)
  final int? mesVencimentoIpva;
  final bool ipvaPago;
  final double? valorIpva;
  final bool licenciamentoPago;
  final String seguradora;
  final String apoliceSeguro;
  final String telefoneSeguro;
  final DateTime? dataVencimentoSeguro;
  final int? ultimoRodizioPneusKm;
  final int intervaloRodizioPneusKm;

  final DateTime criadoEm;

  Veiculo({
    this.id = '',
    TipoVeiculo? tipo,
    TipoVeiculo? type,
    String? marca,
    String? brand,
    String? modelo,
    String? model,
    String? ano,
    String? year,
    String? placa,
    String? plate,
    int? kmAtual,
    int? currentKm,
    String? transmissao,
    String? transmission,
    String? codigoFipe,
    String? fipeCode,
    String? valorFipe,
    String? fipeValue,
    String? referenciaFipe,
    String? fipeReference,
    double? capacidadeTanque,
    double? tankCapacity,
    int? mesVencimentoIpva,
    int? ipvaDueMonth,
    bool? ipvaPago,
    bool? ipvaPaid,
    double? valorIpva,
    double? ipvaAmount,
    bool? licenciamentoPago,
    bool? licensingPaid,
    String? seguradora,
    String? insuranceCompany,
    String? apoliceSeguro,
    String? insurancePolicy,
    String? telefoneSeguro,
    String? insurancePhone,
    DateTime? dataVencimentoSeguro,
    DateTime? insuranceExpiryDate,
    int? ultimoRodizioPneusKm,
    int? lastTireRotationKm,
    int? intervaloRodizioPneusKm,
    int? tireRotationIntervalKm,
    DateTime? criadoEm,
    DateTime? createdAt,
  })  : tipo = tipo ?? type ?? TipoVeiculo.carro,
        marca = marca ?? brand ?? '',
        modelo = modelo ?? model ?? '',
        ano = ano ?? year ?? '',
        placa = placa ?? plate ?? '',
        kmAtual = kmAtual ?? currentKm ?? 0,
        transmissao = transmissao ?? transmission ?? '',
        codigoFipe = codigoFipe ?? fipeCode ?? '',
        valorFipe = valorFipe ?? fipeValue ?? '',
        referenciaFipe = referenciaFipe ?? fipeReference ?? '',
        capacidadeTanque = capacidadeTanque ?? tankCapacity ?? 0,
        mesVencimentoIpva = mesVencimentoIpva ?? ipvaDueMonth,
        ipvaPago = ipvaPago ?? ipvaPaid ?? false,
        valorIpva = valorIpva ?? ipvaAmount,
        licenciamentoPago = licenciamentoPago ?? licensingPaid ?? false,
        seguradora = seguradora ?? insuranceCompany ?? '',
        apoliceSeguro = apoliceSeguro ?? insurancePolicy ?? '',
        telefoneSeguro = telefoneSeguro ?? insurancePhone ?? '',
        dataVencimentoSeguro = dataVencimentoSeguro ?? insuranceExpiryDate,
        ultimoRodizioPneusKm = ultimoRodizioPneusKm ?? lastTireRotationKm,
        intervaloRodizioPneusKm = intervaloRodizioPneusKm ?? tireRotationIntervalKm ?? 10000,
        criadoEm = criadoEm ?? createdAt ?? DateTime.now();

  // Getters em português e aliases em inglês
  TipoVeiculo get type => tipo;
  String get brand => marca;
  String get model => modelo;
  String get year => ano;
  String get plate => placa;
  int get currentKm => kmAtual;
  String get transmission => transmissao;
  String get fipeCode => codigoFipe;
  String get fipeValue => valorFipe;
  String get fipeReference => referenciaFipe;
  double get tankCapacity => capacidadeTanque;
  int? get ipvaDueMonth => mesVencimentoIpva;
  bool get ipvaPaid => ipvaPago;
  double? get ipvaAmount => valorIpva;
  bool get licensingPaid => licenciamentoPago;
  String get insuranceCompany => seguradora;
  String get insurancePolicy => apoliceSeguro;
  String get insurancePhone => telefoneSeguro;
  DateTime? get insuranceExpiryDate => dataVencimentoSeguro;
  int? get lastTireRotationKm => ultimoRodizioPneusKm;
  int get tireRotationIntervalKm => intervaloRodizioPneusKm;
  DateTime get createdAt => criadoEm;

  bool get eCarro => tipo == TipoVeiculo.carro;
  bool get isCar => eCarro;
  bool get eMoto => tipo == TipoVeiculo.moto;
  bool get isMotorcycle => eMoto;
  bool get eCaminhao => tipo == TipoVeiculo.caminhao;
  bool get isTruck => eCaminhao;

  String get nome => '$marca $modelo'.trim();
  String get name => nome;

  String get rotuloTipo {
    switch (tipo) {
      case TipoVeiculo.carro:
        return 'Carro';
      case TipoVeiculo.caminhao:
        return 'Caminhão';
      case TipoVeiculo.moto:
        return 'Moto';
    }
  }

  String get typeLabel => rotuloTipo;

  /// Capacidade efetiva do tanque (usa o valor cadastrado ou um padrão comum).
  double get capacidadeEfetivaTanque {
    if (capacidadeTanque > 0) return capacidadeTanque;
    if (eCarro) return 50.0;
    if (eCaminhao) return 300.0;
    return 14.0; // Moto
  }

  double get effectiveTankCapacity => capacidadeEfetivaTanque;

  Map<String, dynamic> toMap() => {
        'type': tipo.name,
        'brand': marca,
        'model': modelo,
        'year': ano,
        'plate': placa,
        'currentKm': kmAtual,
        'transmission': eMoto ? '' : transmissao,
        'fipeCode': codigoFipe,
        'fipeValue': valorFipe,
        'fipeReference': referenciaFipe,
        'tankCapacity': capacidadeTanque,
        'ipvaDueMonth': mesVencimentoIpva,
        'ipvaPaid': ipvaPago,
        'ipvaAmount': valorIpva,
        'licensingPaid': licenciamentoPago,
        'insuranceCompany': seguradora,
        'insurancePolicy': apoliceSeguro,
        'insurancePhone': telefoneSeguro,
        'insuranceExpiryDate': dataVencimentoSeguro != null
            ? Timestamp.fromDate(dataVencimentoSeguro!)
            : null,
        'lastTireRotationKm': ultimoRodizioPneusKm,
        'tireRotationIntervalKm': intervaloRodizioPneusKm,
        'createdAt': Timestamp.fromDate(criadoEm),
      };

  factory Veiculo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final typeStr = (d['tipo'] ?? d['type'])?.toString().toLowerCase() ?? '';
    TipoVeiculo tipoResolvido;
    if (typeStr == 'moto') {
      tipoResolvido = TipoVeiculo.moto;
    } else if (typeStr == 'caminhao') {
      tipoResolvido = TipoVeiculo.caminhao;
    } else {
      tipoResolvido = TipoVeiculo.carro;
    }

    return Veiculo(
      id: doc.id,
      tipo: tipoResolvido,
      marca: d['marca'] ?? d['brand'] ?? '',
      modelo: d['modelo'] ?? d['model'] ?? '',
      ano: d['ano'] ?? d['year'] ?? '',
      placa: d['placa'] ?? d['plate'] ?? '',
      kmAtual: (d['kmAtual'] ?? d['currentKm'] as num?)?.toInt() ?? 0,
      transmissao: d['transmissao'] ?? d['transmission'] ?? '',
      codigoFipe: d['codigoFipe'] ?? d['fipeCode'] ?? '',
      valorFipe: d['valorFipe'] ?? d['fipeValue'] ?? '',
      referenciaFipe: d['referenciaFipe'] ?? d['fipeReference'] ?? '',
      capacidadeTanque: (d['capacidadeTanque'] ?? d['tankCapacity'] as num?)?.toDouble() ?? 0,
      mesVencimentoIpva: (d['mesVencimentoIpva'] ?? d['ipvaDueMonth'] as num?)?.toInt(),
      ipvaPago: (d['ipvaPago'] ?? d['ipvaPaid']) == true,
      valorIpva: (d['valorIpva'] ?? d['ipvaAmount'] as num?)?.toDouble(),
      licenciamentoPago: (d['licenciamentoPago'] ?? d['licensingPaid']) == true,
      seguradora: d['seguradora'] ?? d['insuranceCompany'] ?? '',
      apoliceSeguro: d['apoliceSeguro'] ?? d['insurancePolicy'] ?? '',
      telefoneSeguro: d['telefoneSeguro'] ?? d['insurancePhone'] ?? '',
      dataVencimentoSeguro:
          ((d['dataVencimentoSeguro'] ?? d['insuranceExpiryDate']) as Timestamp?)?.toDate(),
      ultimoRodizioPneusKm: (d['ultimoRodizioPneusKm'] ?? d['lastTireRotationKm'] as num?)?.toInt(),
      intervaloRodizioPneusKm:
          (d['intervaloRodizioPneusKm'] ?? d['tireRotationIntervalKm'] as num?)?.toInt() ?? 10000,
      criadoEm: ((d['criadoEm'] ?? d['createdAt']) as Timestamp?)?.toDate(),
    );
  }
}

/// Alias para manter compatibilidade
typedef Vehicle = Veiculo;
