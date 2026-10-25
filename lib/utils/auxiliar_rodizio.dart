import '../models/veiculo.dart';

/// Utilitário para cálculo e aviso de Rodízio Veicular Municipal em português (padrão São Paulo e capitais).
/// Regra baseada no último dígito da placa do veículo:
/// - Finais 1 e 2: Segunda-feira
/// - Finais 3 e 4: Terça-feira
/// - Finais 5 e 6: Quarta-feira
/// - Finais 7 e 8: Quinta-feira
/// - Finais 9 e 0: Sexta-feira
/// - Sábados e Domingos: Livre
/// - Motocicletas: Isentas de rodízio municipal
/// - Caminhões: Sujeitos ao rodízio de caminhões / ZMRC (05h às 21h em dias úteis)
class InformacaoRodizio {
  final int? ultimoDigito;
  final String nomeDia;
  final int diaSemana; // DateTime.monday .. DateTime.friday
  final bool eHoje;
  final bool eIsento;
  final String descricao;
  final String horarioRestricao;

  const InformacaoRodizio({
    required this.ultimoDigito,
    required this.nomeDia,
    required this.diaSemana,
    required this.eHoje,
    required this.eIsento,
    required this.descricao,
    this.horarioRestricao = '07h às 10h e 17h às 20h',
  });

  // Aliases de compatibilidade
  int? get lastDigit => ultimoDigito;
  String get dayName => nomeDia;
  int get weekday => diaSemana;
  bool get isToday => eHoje;
  bool get isExempt => eIsento;
  String get description => descricao;
  String get timeRange => horarioRestricao;
}

/// Alias para manter compatibilidade
typedef RodizioInfo = InformacaoRodizio;

class AuxiliarRodizio {
  AuxiliarRodizio._();

  /// Extrai o último dígito numérico da placa (válido para placas antigas ABC-1234 e padrão Mercosul ABC1D23).
  static int? extrairUltimoDigito(String placa) {
    final limpo = placa.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpo.isEmpty) return null;
    return int.tryParse(limpo.substring(limpo.length - 1));
  }

  static int? extractLastDigit(String plate) => extrairUltimoDigito(plate);

  /// Retorna as informações de rodízio para um veículo.
  static InformacaoRodizio obterInformacoes(
    String placa, {
    bool eCarro = true,
    bool eCaminhao = false,
    TipoVeiculo? tipo,
    TipoPropulsao? propulsao,
    bool? isCar,
    bool? isTruck,
    TipoVeiculo? type,
    TipoPropulsao? propulsion,
  }) {
    final bool carroResolvido = isCar ?? eCarro;
    final bool caminhaoResolvido = isTruck ?? eCaminhao;
    final tipoEfetivo = tipo ?? type ??
        (caminhaoResolvido
            ? TipoVeiculo.caminhao
            : (carroResolvido ? TipoVeiculo.carro : TipoVeiculo.moto));
    final propEfetiva = propulsao ?? propulsion ?? TipoPropulsao.combustao;

    if (tipoEfetivo == TipoVeiculo.moto) {
      return const InformacaoRodizio(
        ultimoDigito: null,
        nomeDia: 'Isento',
        diaSemana: 0,
        eHoje: false,
        eIsento: true,
        descricao: 'Motocicletas são isentas do rodízio municipal.',
      );
    }

    if (propEfetiva == TipoPropulsao.eletrico || propEfetiva == TipoPropulsao.hibrido) {
      final tipoProp = propEfetiva == TipoPropulsao.eletrico ? 'Elétrico' : 'Híbrido';
      return InformacaoRodizio(
        ultimoDigito: extrairUltimoDigito(placa),
        nomeDia: 'Isento ($tipoProp)',
        diaSemana: 0,
        eHoje: false,
        eIsento: true,
        horarioRestricao: 'Livre (Isenção Ambiental)',
        descricao: 'Veículos elétricos e híbridos possuem isenção do rodízio municipal.',
      );
    }

    final digito = extrairUltimoDigito(placa);
    if (digito == null) {
      return const InformacaoRodizio(
        ultimoDigito: null,
        nomeDia: 'Placa não informada',
        diaSemana: 0,
        eHoje: false,
        eIsento: false,
        descricao: 'Informe a placa com número final para ver o dia do rodízio.',
      );
    }

    final hoje = DateTime.now();
    final diaSemanaAtual = hoje.weekday; // 1 = Segunda, 7 = Domingo
    final horario = tipoEfetivo == TipoVeiculo.caminhao
        ? '05h às 21h (ZMRC)'
        : '07h às 10h e 17h às 20h';

    switch (digito) {
      case 1:
      case 2:
        return InformacaoRodizio(
          ultimoDigito: digito,
          nomeDia: 'Segunda-feira',
          diaSemana: DateTime.monday,
          eHoje: diaSemanaAtual == DateTime.monday,
          eIsento: false,
          horarioRestricao: horario,
          descricao: 'Segunda-feira (finais 1 e 2)',
        );
      case 3:
      case 4:
        return InformacaoRodizio(
          ultimoDigito: digito,
          nomeDia: 'Terça-feira',
          diaSemana: DateTime.tuesday,
          eHoje: diaSemanaAtual == DateTime.tuesday,
          eIsento: false,
          horarioRestricao: horario,
          descricao: 'Terça-feira (finais 3 e 4)',
        );
      case 5:
      case 6:
        return InformacaoRodizio(
          ultimoDigito: digito,
          nomeDia: 'Quarta-feira',
          diaSemana: DateTime.wednesday,
          eHoje: diaSemanaAtual == DateTime.wednesday,
          eIsento: false,
          horarioRestricao: horario,
          descricao: 'Quarta-feira (finais 5 e 6)',
        );
      case 7:
      case 8:
        return InformacaoRodizio(
          ultimoDigito: digito,
          nomeDia: 'Quinta-feira',
          diaSemana: DateTime.thursday,
          eHoje: diaSemanaAtual == DateTime.thursday,
          eIsento: false,
          horarioRestricao: horario,
          descricao: 'Quinta-feira (finais 7 e 8)',
        );
      case 9:
      case 0:
        return InformacaoRodizio(
          ultimoDigito: digito,
          nomeDia: 'Sexta-feira',
          diaSemana: DateTime.friday,
          eHoje: diaSemanaAtual == DateTime.friday,
          eIsento: false,
          horarioRestricao: horario,
          descricao: 'Sexta-feira (finais 9 e 0)',
        );
      default:
        return const InformacaoRodizio(
          ultimoDigito: null,
          nomeDia: 'Inválido',
          diaSemana: 0,
          eHoje: false,
          eIsento: false,
          descricao: 'Placa com formato não identificado.',
        );
    }
  }

  // Aliases de compatibilidade
  static InformacaoRodizio getInfo(
    String plate, {
    bool isCar = true,
    bool isTruck = false,
    TipoVeiculo? type,
    TipoPropulsao? propulsion,
  }) =>
      obterInformacoes(
        plate,
        isCar: isCar,
        isTruck: isTruck,
        type: type,
        propulsion: propulsion,
      );
}

/// Alias para manter compatibilidade
typedef RodizioHelper = AuxiliarRodizio;
