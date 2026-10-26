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

/// Tipo de motorização / propulsão do veículo (Combustão, Híbrido ou 100% Elétrico).
enum TipoPropulsao { combustao, hibrido, eletrico }

extension TipoPropulsaoExt on TipoPropulsao {
  String get rotulo {
    switch (this) {
      case TipoPropulsao.combustao:
        return 'Combustão / Flex';
      case TipoPropulsao.hibrido:
        return 'Híbrido';
      case TipoPropulsao.eletrico:
        return '100% Elétrico';
    }
  }

  String get rotuloCurto {
    switch (this) {
      case TipoPropulsao.combustao:
        return 'Combustão';
      case TipoPropulsao.hibrido:
        return 'Híbrido';
      case TipoPropulsao.eletrico:
        return 'Elétrico';
    }
  }

  String get label => rotulo;
  String get shortLabel => rotuloCurto;
}

typedef VehiclePropulsion = TipoPropulsao;

/// Veículo do usuário em português. Salvo em: users/{uid}/vehicles/{id}
class Veiculo {
  final String id;
  final TipoVeiculo tipo;
  final TipoPropulsao propulsao;
  final String marca;
  final String modelo;
  final String ano;
  final String placa;
  final int kmAtual;

  /// 'Manual', 'Automático', 'Redutor Direto (Elétrico)' ou '' (motos).
  final String transmissao;

  // Dados da Tabela FIPE (vazios se o usuário não consultou).
  final String codigoFipe;
  final String valorFipe;
  final String referenciaFipe;

  // Capacidade do tanque de combustível (Litros, m³ no caso de GNV, ou kWh da bateria nos elétricos)
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

  // Configuração de Caminhão / Frota e Controle de Viagem Ativa
  final String tipoCarroceria; // Ex: 'Baú', 'Caçamba', 'Sider', 'Graneleiro', 'Prancha', 'Tanque'
  final int? numeroEixos; // Ex: 2, 3, 4, 5, 6, 7, 9
  final bool viagemAtiva;
  final int? viagemKmInicial;
  final String viagemTipoCarroceria;
  final int? viagemNumeroEixos;
  final double? viagemPesoCargaTon;
  final String viagemNotaFiscalCte;
  final String viagemRota;
  final DateTime? viagemIniciadaEm;

  final DateTime criadoEm;

  Veiculo({
    this.id = '',
    TipoVeiculo? tipo,
    TipoVeiculo? type,
    TipoPropulsao? propulsao,
    TipoPropulsao? propulsion,
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
    this.tipoCarroceria = '',
    this.numeroEixos,
    this.viagemAtiva = false,
    this.viagemKmInicial,
    this.viagemTipoCarroceria = '',
    this.viagemNumeroEixos,
    this.viagemPesoCargaTon,
    this.viagemNotaFiscalCte = '',
    this.viagemRota = '',
    this.viagemIniciadaEm,
    DateTime? criadoEm,
    DateTime? createdAt,
  })  : tipo = tipo ?? type ?? TipoVeiculo.carro,
        propulsao = propulsao ??
            propulsion ??
            inferirPropulsao(marca ?? brand ?? '', modelo ?? model ?? ''),
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

  /// Infere automaticamente se um modelo conhecido é elétrico ou híbrido.
  static TipoPropulsao inferirPropulsao(String marca, String modelo) {
    final m = marca.trim().toLowerCase();
    final mod = modelo.trim().toLowerCase();
    final completo = '$m $mod';

    // Marcas 100% elétricas
    if (m == 'tesla' || m == 'voltz' || m == 'watts' || m == 'super soco' || m == 'gws') {
      return TipoPropulsao.eletrico;
    }

    // Modelos 100% elétricos conhecidos (Carros, Motos e Caminhões)
    const palavrasEletrico = [
      'dolphin',
      'yuan',
      'seal',
      'tan ',
      'han ',
      'ora 03',
      'ora ',
      'icar',
      'kwid e-tech',
      'e-tech',
      'mottu-e',
      'evs',
      'ev1',
      'e-delivery',
      'iev',
      'e-js',
      'ex30',
      'xc40 recharge',
      'c40',
      'bolt',
      'blazer ev',
      'equinox ev',
      'taycan',
      'e-tron',
      'ix ',
      'i4 ',
      'ix1',
      'ix3',
      'leaf',
      'zoe',
      'megane e-tech',
      '500e',
      'e-208',
      'e-2008',
      'fm electric',
      'fh electric',
      'et7',
      'elétrico',
      'eletrico',
    ];
    for (final p in palavrasEletrico) {
      if (completo.contains(p)) return TipoPropulsao.eletrico;
    }

    // Modelos híbridos conhecidos
    const palavrasHibrido = [
      'song',
      'king',
      'shark',
      'haval',
      'prius',
      'corolla hybrid',
      'corolla cross hybrid',
      'rav4',
      'niro',
      'stonic',
      'tiggo 8 pro plug-in',
      'arrizo 6 pro hybrid',
      'híbrido',
      'hibrido',
      'hybrid',
      'phev',
      'mhev',
    ];
    for (final p in palavrasHibrido) {
      if (completo.contains(p)) return TipoPropulsao.hibrido;
    }

    return TipoPropulsao.combustao;
  }

  // Getters em português e aliases em inglês
  TipoVeiculo get type => tipo;
  TipoPropulsao get propulsion => propulsao;
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

  bool get eEletrico => propulsao == TipoPropulsao.eletrico;
  bool get isElectric => eEletrico;
  bool get eHibrido => propulsao == TipoPropulsao.hibrido;
  bool get isHybrid => eHibrido;
  bool get eCombustao => propulsao == TipoPropulsao.combustao;
  bool get isCombustion => eCombustao;
  bool get usaEnergiaEletrica => eEletrico || eHibrido;
  bool get usesElectricPower => usaEnergiaEletrica;

  String get unidadeCapacidade => eEletrico ? 'kWh' : 'Litros';
  String get capacityUnit => unidadeCapacidade;

  String get unidadeConsumoPadrao => eEletrico ? 'km/kWh' : 'km/l';
  String get defaultConsumptionUnit => unidadeConsumoPadrao;

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

  /// Capacidade efetiva do tanque (Litros) ou bateria (kWh nos elétricos).
  double get capacidadeEfetivaTanque {
    if (capacidadeTanque > 0) return capacidadeTanque;
    if (eEletrico) {
      if (eCarro) return 50.0; // 50 kWh padrão carro EV
      if (eCaminhao) return 250.0; // 250 kWh padrão caminhão EV
      return 3.5; // 3.5 kWh padrão moto elétrica
    }
    if (eCarro) return 50.0;
    if (eCaminhao) return 300.0;
    return 14.0; // Moto a combustão
  }

  double get effectiveTankCapacity => capacidadeEfetivaTanque;

  String get carroceriaEfetiva =>
      viagemTipoCarroceria.trim().isNotEmpty ? viagemTipoCarroceria.trim() : tipoCarroceria.trim();

  int? get eixosEfetivos => viagemNumeroEixos ?? numeroEixos;

  String get resumoImplementoCaminhao {
    if (!eCaminhao) return '';
    final partes = <String>[];
    if (carroceriaEfetiva.isNotEmpty) partes.add(carroceriaEfetiva);
    if (eixosEfetivos != null && eixosEfetivos! > 0) partes.add('${eixosEfetivos!} Eixos');
    return partes.join(' • ');
  }

  Map<String, dynamic> toMap() => {
        'type': tipo.name,
        'propulsion': propulsao.name,
        'brand': marca,
        'model': modelo,
        'year': ano,
        'plate': placa,
        'currentKm': kmAtual,
        'transmission': eMoto
            ? ''
            : (eEletrico && transmissao.isEmpty ? 'Redutor Direto (Elétrico)' : transmissao),
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
        if (tipoCarroceria.trim().isNotEmpty) 'tipoCarroceria': tipoCarroceria.trim(),
        if (numeroEixos != null) 'numeroEixos': numeroEixos,
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

    final marcaLida = (d['marca'] ?? d['brand'] ?? '').toString();
    final modeloLido = (d['modelo'] ?? d['model'] ?? '').toString();
    final propStr = (d['propulsao'] ?? d['propulsion'])?.toString().toLowerCase() ?? '';
    TipoPropulsao propResolvida;
    if (propStr == 'eletrico' || propStr == 'electric') {
      propResolvida = TipoPropulsao.eletrico;
    } else if (propStr == 'hibrido' || propStr == 'hybrid') {
      propResolvida = TipoPropulsao.hibrido;
    } else if (propStr == 'combustao' || propStr == 'combustion') {
      propResolvida = TipoPropulsao.combustao;
    } else {
      propResolvida = inferirPropulsao(marcaLida, modeloLido);
    }

    return Veiculo(
      id: doc.id,
      tipo: tipoResolvido,
      propulsao: propResolvida,
      marca: marcaLida,
      modelo: modeloLido,
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
          _converterDataSegura(d['dataVencimentoSeguro'] ?? d['insuranceExpiryDate']),
      ultimoRodizioPneusKm: (d['ultimoRodizioPneusKm'] ?? d['lastTireRotationKm'] as num?)?.toInt(),
      intervaloRodizioPneusKm:
          (d['intervaloRodizioPneusKm'] ?? d['tireRotationIntervalKm'] as num?)?.toInt() ?? 10000,
      tipoCarroceria: (d['tipoCarroceria'] ?? '').toString(),
      numeroEixos: (d['numeroEixos'] as num?)?.toInt(),
      viagemAtiva: d['viagemAtiva'] == true,
      viagemKmInicial: (d['viagemKmInicial'] as num?)?.toInt(),
      viagemTipoCarroceria: (d['viagemTipoCarroceria'] ?? '').toString(),
      viagemNumeroEixos: (d['viagemNumeroEixos'] as num?)?.toInt(),
      viagemPesoCargaTon: (d['viagemPesoCargaTon'] as num?)?.toDouble(),
      viagemNotaFiscalCte: (d['viagemNotaFiscalCte'] ?? '').toString(),
      viagemRota: (d['viagemRota'] ?? '').toString(),
      viagemIniciadaEm: _converterDataSegura(d['viagemIniciadaEm']),
      criadoEm: _converterDataSegura(d['criadoEm'] ?? d['createdAt']),
    );
  }
}

DateTime? _converterDataSegura(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}

/// Alias para manter compatibilidade com o código existente
typedef Vehicle = Veiculo;
