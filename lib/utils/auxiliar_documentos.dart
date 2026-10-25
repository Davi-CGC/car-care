import '../models/veiculo.dart';
import 'auxiliar_rodizio.dart';

class InformacaoIpva {
  final int mes;
  final String nomeMes;
  final double valorEstimado;
  final bool estaPago;
  final bool estaAtrasado;

  const InformacaoIpva({
    required this.mes,
    required this.nomeMes,
    required this.valorEstimado,
    required this.estaPago,
    required this.estaAtrasado,
  });

  // Aliases de compatibilidade
  int get month => mes;
  String get monthName => nomeMes;
  double get estimatedValue => valorEstimado;
  bool get isPaid => estaPago;
  bool get isOverdue => estaAtrasado;
}

typedef IpvaInfo = InformacaoIpva;

class InformacaoLicenciamento {
  final int mes;
  final String nomeMes;
  final bool estaPago;
  final bool venceEmBreve;
  final bool estaAtrasado;
  final String descricaoPrazo;

  const InformacaoLicenciamento({
    required this.mes,
    required this.nomeMes,
    required this.estaPago,
    required this.venceEmBreve,
    required this.estaAtrasado,
    required this.descricaoPrazo,
  });

  // Aliases de compatibilidade
  int get month => mes;
  String get monthName => nomeMes;
  bool get isPaid => estaPago;
  bool get isDueSoon => venceEmBreve;
  bool get isOverdue => estaAtrasado;
  String get deadlineDescription => descricaoPrazo;
}

typedef LicensingInfo = InformacaoLicenciamento;

class InformacaoSeguro {
  final String seguradora;
  final String apolice;
  final String telefone;
  final DateTime? dataVencimento;
  final int? diasRestantes;
  final bool estaVencido;
  final bool venceEmBreve;

  const InformacaoSeguro({
    required this.seguradora,
    required this.apolice,
    required this.telefone,
    this.dataVencimento,
    this.diasRestantes,
    required this.estaVencido,
    required this.venceEmBreve,
  });

  // Aliases de compatibilidade
  String get company => seguradora;
  String get policy => apolice;
  String get phone => telefone;
  DateTime? get expiryDate => dataVencimento;
  int? get daysRemaining => diasRestantes;
  bool get isExpired => estaVencido;
  bool get isDueSoon => venceEmBreve;
}

typedef InsuranceInfo = InformacaoSeguro;

class InformacaoRodizioPneus {
  final int? ultimoKm;
  final int intervaloKm;
  final int proximoKm;
  final int kmRestante;
  final double progresso; // 0.0 a 1.0
  final bool precisaFazer;
  final bool fazerEmBreve;

  const InformacaoRodizioPneus({
    required this.ultimoKm,
    required this.intervaloKm,
    required this.proximoKm,
    required this.kmRestante,
    required this.progresso,
    required this.precisaFazer,
    required this.fazerEmBreve,
  });

  // Aliases de compatibilidade
  int? get lastKm => ultimoKm;
  int get intervalKm => intervaloKm;
  int get nextKm => proximoKm;
  int get remainingKm => kmRestante;
  double get progress => progresso;
  bool get isDue => precisaFazer;
  bool get isSoon => fazerEmBreve;
}

typedef TireRotationInfo = InformacaoRodizioPneus;

class AuxiliarDocumentos {
  AuxiliarDocumentos._();

  static const List<String> nomesMeses = [
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

  static const List<String> monthNames = nomesMeses;

  /// Informações e cálculo de IPVA do veículo.
  static InformacaoIpva obterInformacaoIpva(Veiculo v) {
    final digito = AuxiliarRodizio.extrairUltimoDigito(v.placa);
    final agora = DateTime.now();

    // Mês padrão em SP para parcela única ou início: Janeiro/Fevereiro
    int mes = v.mesVencimentoIpva ?? 1;
    if (v.mesVencimentoIpva == null && digito != null) {
      if (digito >= 1 && digito <= 5) {
        mes = 1; // Janeiro
      } else {
        mes = 2; // Fevereiro
      }
    }

    // Estimativa de IPVA baseada na Tabela FIPE
    double estimado = v.valorIpva ?? 0.0;
    if (estimado <= 0 && v.valorFipe.isNotEmpty) {
      final fipeLimpo = v.valorFipe
          .replaceAll(r'R$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final numFipe = double.tryParse(fipeLimpo) ?? 0.0;
      if (numFipe > 0) {
        // Alíquotas comuns: 4% para carros de passeio, 2% para motos, 1.5% para caminhões
        final aliquota = v.eMoto ? 0.02 : (v.eCaminhao ? 0.015 : 0.04);
        estimado = numFipe * aliquota;
      }
    }

    final estaPago = v.ipvaPago;
    final estaAtrasado = !estaPago && (agora.month > mes);

    return InformacaoIpva(
      mes: mes,
      nomeMes: mes >= 1 && mes <= 12 ? nomesMeses[mes] : 'A Definir',
      valorEstimado: estimado,
      estaPago: estaPago,
      estaAtrasado: estaAtrasado,
    );
  }

  static InformacaoIpva getIpvaInfo(Veiculo v) => obterInformacaoIpva(v);

  /// Informações oficiais do Calendário de Licenciamento Detran.
  static InformacaoLicenciamento obterInformacaoLicenciamento(Veiculo v) {
    final digito = AuxiliarRodizio.extrairUltimoDigito(v.placa);
    final agora = DateTime.now();

    int mes = 12;
    if (digito != null) {
      if (v.eCaminhao) {
        // Calendário de Caminhões Detran
        switch (digito) {
          case 1:
          case 2:
            mes = 9; // Setembro
            break;
          case 3:
          case 4:
          case 5:
            mes = 10; // Outubro
            break;
          case 6:
          case 7:
          case 8:
            mes = 11; // Novembro
            break;
          case 9:
          case 0:
            mes = 12; // Dezembro
            break;
        }
      } else {
        // Carros e Motos Detran
        switch (digito) {
          case 1:
          case 2:
            mes = 7; // Julho
            break;
          case 3:
          case 4:
            mes = 8; // Agosto
            break;
          case 5:
          case 6:
            mes = 9; // Setembro
            break;
          case 7:
          case 8:
            mes = 10; // Outubro
            break;
          case 9:
            mes = 11; // Novembro
            break;
          case 0:
            mes = 12; // Dezembro
            break;
        }
      }
    }

    final estaPago = v.licenciamentoPago;
    final venceEmBreve = !estaPago && agora.month == mes;
    final estaAtrasado = !estaPago && agora.month > mes;

    final nomeDoMes = mes >= 1 && mes <= 12 ? nomesMeses[mes] : 'Dezembro';
    final descricaoPrazo = digito != null
        ? 'Final $digito: Vence até o final de $nomeDoMes'
        : 'Informe a placa com número final para ver o mês exato.';

    return InformacaoLicenciamento(
      mes: mes,
      nomeMes: nomeDoMes,
      estaPago: estaPago,
      venceEmBreve: venceEmBreve,
      estaAtrasado: estaAtrasado,
      descricaoPrazo: descricaoPrazo,
    );
  }

  static InformacaoLicenciamento getLicensingInfo(Veiculo v) => obterInformacaoLicenciamento(v);

  /// Informações da apólice e assistência do seguro.
  static InformacaoSeguro obterInformacaoSeguro(Veiculo v) {
    final agora = DateTime.now();
    final vencimento = v.dataVencimentoSeguro;
    int? dias;
    bool vencido = false;
    bool venceEmBreve = false;

    if (vencimento != null) {
      dias = vencimento.difference(agora).inDays;
      if (dias < 0) {
        vencido = true;
      } else if (dias <= 30) {
        venceEmBreve = true;
      }
    }

    return InformacaoSeguro(
      seguradora: v.seguradora,
      apolice: v.apoliceSeguro,
      telefone: v.telefoneSeguro,
      dataVencimento: vencimento,
      diasRestantes: dias,
      estaVencido: vencido,
      venceEmBreve: venceEmBreve,
    );
  }

  static InformacaoSeguro getInsuranceInfo(Veiculo v) => obterInformacaoSeguro(v);

  /// Informações de Rodízio de Pneus (troca periódica de posição).
  static InformacaoRodizioPneus obterInformacaoRodizioPneus(Veiculo v) {
    final intervalo = v.intervaloRodizioPneusKm > 0 ? v.intervaloRodizioPneusKm : 10000;
    final ultimoKm = v.ultimoRodizioPneusKm ?? 0;
    final proximoKm = ultimoKm + intervalo;
    final kmRestante = proximoKm - v.kmAtual;

    final kmDesdeUltimo = v.kmAtual - ultimoKm;
    double progresso = 0.0;
    if (intervalo > 0) {
      progresso = (kmDesdeUltimo / intervalo).clamp(0.0, 1.0);
    }

    final precisaFazer = kmRestante <= 0;
    final fazerEmBreve = kmRestante > 0 && kmRestante <= 1000;

    return InformacaoRodizioPneus(
      ultimoKm: v.ultimoRodizioPneusKm,
      intervaloKm: intervalo,
      proximoKm: proximoKm,
      kmRestante: kmRestante,
      progresso: progresso,
      precisaFazer: precisaFazer,
      fazerEmBreve: fazerEmBreve,
    );
  }

  static InformacaoRodizioPneus getTireRotationInfo(Veiculo v) => obterInformacaoRodizioPneus(v);
}

/// Alias para manter compatibilidade
typedef VehicleDocumentsHelper = AuxiliarDocumentos;
