import 'dart:math' as math;

import '../models/alerta_manutencao.dart';
import '../models/manutencao.dart';
import '../models/registro_abastecimento.dart';
import '../models/veiculo.dart';
import 'constantes.dart';

enum NivelConsumo {
  otimo, // Verde: Muito econômico
  moderado, // Amarelo: Consumo padrão/normal
  alto, // Vermelho: Consumo alto / Gastando muito
}

typedef ConsumptionLevel = NivelConsumo;

class AvaliacaoConsumo {
  final double kmPorLitro;
  final NivelConsumo nivel;
  final String rotulo;
  final String descricao;
  final double pontuacao; // 0.0 a 1.0 para barra de termômetro

  const AvaliacaoConsumo({
    required this.kmPorLitro,
    required this.nivel,
    required this.rotulo,
    required this.descricao,
    required this.pontuacao,
  });

  // Aliases de compatibilidade
  double get kmPerLiter => kmPorLitro;
  NivelConsumo get level => nivel;
  String get label => rotulo;
  String get description => descricao;
  double get score => pontuacao;
}

typedef ConsumptionEvaluation = AvaliacaoConsumo;

/// Estatísticas de Rotina de Abastecimento em português.
class EstatisticasRotinaCombustivel {
  final double distanciaMediaEntreAbastecimentos; // km
  final double frequenciaMediaDias; // Dias
  final double autonomiaEstimada; // km
  final double projecaoMensal; // R$
  final int quantidadeTanqueCheio;
  final int totalAbastecimentos;
  final double porcentagemTanqueCheio; // %
  final double? consumoMedioTanqueCheio; // km/l dos ciclos de tanque cheio

  const EstatisticasRotinaCombustivel({
    required this.distanciaMediaEntreAbastecimentos,
    required this.frequenciaMediaDias,
    required this.autonomiaEstimada,
    required this.projecaoMensal,
    required this.quantidadeTanqueCheio,
    required this.totalAbastecimentos,
    required this.porcentagemTanqueCheio,
    this.consumoMedioTanqueCheio,
  });

  // Aliases de compatibilidade
  double get avgDistanceBetweenFuels => distanciaMediaEntreAbastecimentos;
  double get avgFrequencyDays => frequenciaMediaDias;
  double get estimatedAutonomy => autonomiaEstimada;
  double get monthlyProjection => projecaoMensal;
  int get fullTankCount => quantidadeTanqueCheio;
  int get totalFuels => totalAbastecimentos;
  double get fullTankPercentage => porcentagemTanqueCheio;
  double? get fullTankAverageConsumption => consumoMedioTanqueCheio;
}

typedef FuelRoutineStats = EstatisticasRotinaCombustivel;

/// Cálculos do app: alertas, consumo médio, rotina de abastecimento, termômetro e gastos em português.
class Calculos {
  Calculos._();

  /// Situação de uma manutenção em relação ao próximo serviço.
  static StatusAlerta statusDe(Manutencao m, Veiculo v) {
    if (m.proximoKm == null && m.proximaData == null) return StatusAlerta.nenhum;
    final agora = DateTime.now();
    var status = StatusAlerta.ok;

    if (m.proximoKm != null) {
      final restante = m.proximoKm! - v.kmAtual;
      if (restante <= 0) return StatusAlerta.vencido;
      if (restante <= alertaKmAntecedencia) status = StatusAlerta.proximo;
    }
    if (m.proximaData != null) {
      final dias = m.proximaData!.difference(agora).inDays;
      if (!agora.isBefore(m.proximaData!)) return StatusAlerta.vencido;
      if (dias <= alertaDiasAntecedencia) status = StatusAlerta.proximo;
    }
    return status;
  }

  static StatusAlerta statusOf(Manutencao m, Veiculo v) => statusDe(m, v);

  /// Última manutenção de cada categoria de cada veículo.
  static Map<String, Manutencao> ultimaPorCategoria(List<Manutencao> lista) {
    final mapa = <String, Manutencao>{};
    for (final m in lista) {
      final chave = '${m.idVeiculo}|${m.categoria}';
      final atual = mapa[chave];
      if (atual == null || m.data.isAfter(atual.data)) mapa[chave] = m;
    }
    return mapa;
  }

  static Map<String, Manutencao> latestByCategory(List<Manutencao> list) =>
      ultimaPorCategoria(list);

  /// Alertas (atrasados primeiro, depois os próximos).
  static List<AlertaManutencao> alertas(
      List<Veiculo> veiculos, List<Manutencao> manutencoes) {
    final porId = {for (final v in veiculos) v.id: v};
    final resultado = <AlertaManutencao>[];
    for (final m in ultimaPorCategoria(manutencoes).values) {
      final veiculo = porId[m.idVeiculo];
      if (veiculo == null) continue;
      final status = statusDe(m, veiculo);
      if (status == StatusAlerta.proximo || status == StatusAlerta.vencido) {
        resultado.add(AlertaManutencao(veiculo, m, status));
      }
    }
    resultado.sort((a, b) => b.status.index.compareTo(a.status.index));
    return resultado;
  }

  static List<AlertaManutencao> alerts(
          List<Veiculo> vehicles, List<Manutencao> maintenances) =>
      alertas(vehicles, maintenances);

  /// Consumo médio em km/l ou km/m³.
  /// distância entre o primeiro e o último registro ÷ litros (sem o primeiro).
  static double? consumoMedio(List<RegistroAbastecimento> registros) {
    if (registros.length < 2) return null;
    final ordenados = [...registros]..sort((a, b) => a.km.compareTo(b.km));
    final distancia = ordenados.last.km - ordenados.first.km;
    final volume = ordenados.skip(1).fold<double>(0, (soma, r) => soma + r.litros);
    if (distancia <= 0 || volume <= 0) return null;
    return distancia / volume;
  }

  static double? averageConsumption(List<RegistroAbastecimento> records) =>
      consumoMedio(records);

  /// Método oficial do Tanque Cheio:
  /// Calcula o consumo real medido de um tanque cheio até o próximo.
  static double? consumoTanqueCheio(List<RegistroAbastecimento> registros) {
    if (registros.length < 2) return null;
    final ordenados = [...registros]..sort((a, b) => a.km.compareTo(b.km));

    double distanciaTotal = 0;
    double litrosTotais = 0;

    int indiceUltimoCheio = -1;
    for (int i = 0; i < ordenados.length; i++) {
      if (ordenados[i].tanqueCheio) {
        if (indiceUltimoCheio != -1) {
          final distancia = ordenados[i].km - ordenados[indiceUltimoCheio].km;
          if (distancia > 0) {
            double litrosCiclo = 0;
            for (int j = indiceUltimoCheio + 1; j <= i; j++) {
              litrosCiclo += ordenados[j].litros;
            }
            if (litrosCiclo > 0) {
              distanciaTotal += distancia;
              litrosTotais += litrosCiclo;
            }
          }
        }
        indiceUltimoCheio = i;
      }
    }

    if (distanciaTotal > 0 && litrosTotais > 0) {
      return distanciaTotal / litrosTotais;
    }
    return null;
  }

  static double? fullTankConsumption(List<RegistroAbastecimento> records) =>
      consumoTanqueCheio(records);

  /// Estatísticas completas da Rotina de Abastecimento.
  static EstatisticasRotinaCombustivel rotinaCombustivel(
      Veiculo veiculo, List<RegistroAbastecimento> abastecimentos) {
    if (abastecimentos.isEmpty) {
      return const EstatisticasRotinaCombustivel(
        distanciaMediaEntreAbastecimentos: 0,
        frequenciaMediaDias: 0,
        autonomiaEstimada: 0,
        projecaoMensal: 0,
        quantidadeTanqueCheio: 0,
        totalAbastecimentos: 0,
        porcentagemTanqueCheio: 0,
      );
    }

    final ordenados = [...abastecimentos]..sort((a, b) => a.km.compareTo(b.km));
    final ordenadosPorData = [...abastecimentos]..sort((a, b) => a.data.compareTo(b.data));
    final total = ordenados.length;
    final qtdTanqueCheio = ordenados.where((f) => f.tanqueCheio).length;
    final pctTanqueCheio =
        total > 0 ? (qtdTanqueCheio / total) * 100 : 0.0;

    // Distância entre abastecimentos consecutivos (por odômetro)
    final distancias = <double>[];
    for (int i = 1; i < ordenados.length; i++) {
      final anterior = ordenados[i - 1];
      final atual = ordenados[i];
      final dKm = (atual.km - anterior.km).toDouble();
      if (dKm > 0) distancias.add(dKm);
    }

    // Frequência em dias corridos entre datas distintas de abastecimento
    final datasUnicas = <DateTime>[];
    for (final reg in ordenadosPorData) {
      final dia = DateTime(reg.data.year, reg.data.month, reg.data.day);
      if (datasUnicas.isEmpty || datasUnicas.last != dia) {
        datasUnicas.add(dia);
      }
    }
    final intervalosDias = <double>[];
    for (int i = 1; i < datasUnicas.length; i++) {
      final diffDias = datasUnicas[i].difference(datasUnicas[i - 1]).inDays.toDouble();
      if (diffDias >= 1.0) {
        intervalosDias.add(diffDias);
      }
    }

    final mediaDistancia = distancias.isNotEmpty
        ? distancias.reduce((a, b) => a + b) / distancias.length
        : (ordenados.first.km > 0 ? ordenados.first.km.toDouble() : 0.0);

    final mediaFrequencia = intervalosDias.isNotEmpty
        ? intervalosDias.reduce((a, b) => a + b) / intervalosDias.length
        : (ordenados.length >= 2 ? 1.0 : 0.0);

    // Consumo médio geral e por tanque cheio
    final mediaGeral = consumoMedio(ordenados);
    final mediaTanqueCheio = consumoTanqueCheio(ordenados);
    final mediaEfetiva = mediaTanqueCheio ?? mediaGeral;

    // Autonomia estimada com tanque cheio
    final capTanque = veiculo.capacidadeEfetivaTanque;
    double autonomiaEst = 0.0;
    if (mediaEfetiva != null && mediaEfetiva > 0) {
      autonomiaEst = mediaEfetiva * capTanque;
    } else if (mediaDistancia > 0) {
      autonomiaEst = mediaDistancia * 1.25;
    }

    // Projeção mensal em R$ (evita distorções quando há múltiplos registros no mesmo dia)
    double projecao = 0.0;
    final totalGasto = ordenados.fold<double>(0, (soma, f) => soma + f.precoTotal);
    if (datasUnicas.length >= 2 && mediaFrequencia >= 1.0) {
      final diasTotais = math.max(
        1.0,
        datasUnicas.last.difference(datasUnicas.first).inDays.toDouble(),
      );
      if (diasTotais >= 3.0) {
        projecao = (totalGasto / diasTotais) * 30.0;
      } else {
        final custoMedioPorDia = totalGasto / datasUnicas.length;
        final paradasPorMes = (30.0 / math.max(7.0, mediaFrequencia)).clamp(1.0, 10.0);
        projecao = paradasPorMes * custoMedioPorDia;
      }
    } else if (total > 0) {
      projecao = totalGasto;
    }

    return EstatisticasRotinaCombustivel(
      distanciaMediaEntreAbastecimentos: mediaDistancia,
      frequenciaMediaDias: mediaFrequencia,
      autonomiaEstimada: autonomiaEst,
      projecaoMensal: projecao,
      quantidadeTanqueCheio: qtdTanqueCheio,
      totalAbastecimentos: total,
      porcentagemTanqueCheio: pctTanqueCheio,
      consumoMedioTanqueCheio: mediaEfetiva,
    );
  }

  static EstatisticasRotinaCombustivel fuelRoutine(
          Veiculo vehicle, List<RegistroAbastecimento> fuels) =>
      rotinaCombustivel(vehicle, fuels);

  /// Média diária de distância percorrida (km/dia).
  static double distanciaMediaDiaria(List<RegistroAbastecimento> abastecimentos) {
    if (abastecimentos.length < 2) return 0.0;
    final ordenadosKm = [...abastecimentos]..sort((a, b) => a.km.compareTo(b.km));
    final ordenadosData = [...abastecimentos]..sort((a, b) => a.data.compareTo(b.data));
    final distancia = ordenadosKm.last.km - ordenadosKm.first.km;
    if (distancia <= 0) return 0.0;

    final primeiroDia = DateTime(
      ordenadosData.first.data.year,
      ordenadosData.first.data.month,
      ordenadosData.first.data.day,
    );
    final ultimoDia = DateTime(
      ordenadosData.last.data.year,
      ordenadosData.last.data.month,
      ordenadosData.last.data.day,
    );
    final dias = math.max(1.0, ultimoDia.difference(primeiroDia).inDays.abs().toDouble());
    return distancia / dias;
  }

  static double dailyAverageDistance(List<RegistroAbastecimento> fuels) =>
      distanciaMediaDiaria(fuels);

  /// Avalia a eficiência do consumo (Termômetro: Econômico / Normal / Alto).
  /// Suporta veículos a Combustão, Híbridos e 100% Elétricos (km/kWh).
  static AvaliacaoConsumo? avaliarConsumo(
    double? kmPorUnidade, {
    bool eCarro = true,
    bool eCaminhao = false,
    TipoVeiculo? tipoVeiculo,
    TipoPropulsao? propulsao,
    String tipoCombustivel = TiposCombustivel.gasolina,
    bool? isCar,
    bool? isTruck,
    TipoVeiculo? vehicleType,
    TipoPropulsao? propulsion,
    String? fuelType,
  }) {
    if (kmPorUnidade == null || kmPorUnidade <= 0) return null;

    final carroResolvido = isCar ?? eCarro;
    final caminhaoResolvido = isTruck ?? eCaminhao;
    final tipo = vehicleType ?? tipoVeiculo ??
        (caminhaoResolvido
            ? TipoVeiculo.caminhao
            : (carroResolvido ? TipoVeiculo.carro : TipoVeiculo.moto));
    final propResolvida = propulsion ?? propulsao ?? TipoPropulsao.combustao;
    final combustivel = fuelType ?? tipoCombustivel;

    // 1. Avaliação para Energia Elétrica (km/kWh) — Carros, Motos e Caminhões Elétricos ou Plug-in
    if (combustivel == TiposCombustivel.eletricidade || propResolvida == TipoPropulsao.eletrico) {
      if (tipo == TipoVeiculo.moto) {
        if (kmPorUnidade >= 22.0) {
          return AvaliacaoConsumo(
            kmPorLitro: kmPorUnidade,
            nivel: NivelConsumo.otimo,
            rotulo: 'Muito Eficiente (EV)',
            descricao: 'Excelente eficiência energética na moto elétrica!',
            pontuacao: 0.90,
          );
        } else if (kmPorUnidade >= 14.0) {
          return AvaliacaoConsumo(
            kmPorLitro: kmPorUnidade,
            nivel: NivelConsumo.moderado,
            rotulo: 'Eficiência Normal (EV)',
            descricao: 'Consumo em kWh dentro do padrão para moto elétrica.',
            pontuacao: 0.55,
          );
        } else {
          return AvaliacaoConsumo(
            kmPorLitro: kmPorUnidade,
            nivel: NivelConsumo.alto,
            rotulo: 'Alto Consumo (EV)',
            descricao: 'Gasto elevado de bateria. Verifique calibragem dos pneus e rolamentos.',
            pontuacao: 0.20,
          );
        }
      }

      if (tipo == TipoVeiculo.caminhao) {
        if (kmPorUnidade >= 1.1) {
          return AvaliacaoConsumo(
            kmPorLitro: kmPorUnidade,
            nivel: NivelConsumo.otimo,
            rotulo: 'Excelente Eficiência (EV)',
            descricao: 'Ótimo rendimento energético para caminhão elétrico!',
            pontuacao: 0.90,
          );
        } else if (kmPorUnidade >= 0.7) {
          return AvaliacaoConsumo(
            kmPorLitro: kmPorUnidade,
            nivel: NivelConsumo.moderado,
            rotulo: 'Eficiência Normal (EV)',
            descricao: 'Consumo energético dentro do esperado para transporte.',
            pontuacao: 0.55,
          );
        } else {
          return AvaliacaoConsumo(
            kmPorLitro: kmPorUnidade,
            nivel: NivelConsumo.alto,
            rotulo: 'Alto Consumo (EV)',
            descricao: 'Consumo elevado de kWh. Verifique peso da carga, pneus e regeneração.',
            pontuacao: 0.20,
          );
        }
      }

      // Carro Elétrico (km/kWh)
      if (kmPorUnidade >= 6.2) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Muito Eficiente (EV)',
          descricao: 'Excelente autonomia por kWh! Ótimo aproveitamento da regeneração.',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= 4.5) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Eficiência Normal (EV)',
          descricao: 'Consumo de bateria equilibrado para veículo elétrico.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo (EV)',
          descricao: 'Consumo elevado de bateria. Cheque calibragem, ar-condicionado e condução.',
          pontuacao: 0.20,
        );
      }
    }

    // 2. Motos a Combustão / Híbridas
    if (tipo == TipoVeiculo.moto) {
      if (kmPorUnidade >= 33.0) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Muito Econômico',
          descricao: 'Excelente rendimento para a moto!',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= 24.0) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Normal / Moderado',
          descricao: 'Média de consumo dentro do esperado.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo',
          descricao: 'Consumindo bastante. Verifique velas, filtro e pneus.',
          pontuacao: 0.20,
        );
      }
    }

    // 3. Caminhões a Combustão / Híbridos
    if (tipo == TipoVeiculo.caminhao) {
      if (kmPorUnidade >= 3.5) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Excelente Rendimento',
          descricao: 'Ótima média para caminhão pesado!',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= 2.4) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Normal / Moderado',
          descricao: 'Consumo dentro do padrão para caminhão.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo',
          descricao: 'Consumo elevado. Verifique filtros, bicos e calibragem.',
          pontuacao: 0.20,
        );
      }
    }

    // 4. Carros Híbridos (rodando em Gasolina / Etanol)
    if (propResolvida == TipoPropulsao.hibrido) {
      final limiteOtimo = combustivel == TiposCombustivel.etanol ? 11.5 : 16.0;
      final limiteModerado = combustivel == TiposCombustivel.etanol ? 9.0 : 12.5;
      if (kmPorUnidade >= limiteOtimo) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Excelente (Híbrido)',
          descricao: 'Ótima eficiência combinando motor elétrico e combustão!',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= limiteModerado) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Normal (Híbrido)',
          descricao: 'Média dentro do esperado para um veículo híbrido.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo (Híbrido)',
          descricao: 'Consumo elevado para um híbrido. Verifique bateria híbrida, filtros e pneus.',
          pontuacao: 0.20,
        );
      }
    }

    // 5. Carros a Combustão
    if (combustivel == TiposCombustivel.etanol) {
      if (kmPorUnidade >= 9.5) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Muito Econômico',
          descricao: 'Excelente média rodando no etanol!',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= 7.0) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Normal / Moderado',
          descricao: 'Consumo padrão para combustível vegetal.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo',
          descricao: 'Consumo alto. Atenção ao peso, calibragem e bicos.',
          pontuacao: 0.20,
        );
      }
    } else if (combustivel == TiposCombustivel.gnv) {
      if (kmPorUnidade >= 13.5) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Muito Econômico',
          descricao: 'Ótima autonomia no gás natural!',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= 10.0) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Normal / Moderado',
          descricao: 'Consumo esperado para GNV.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo',
          descricao: 'Rendimento baixo no GNV. Cheque regulagem do kit.',
          pontuacao: 0.20,
        );
      }
    } else {
      // Gasolina / Diesel (Carro)
      if (kmPorUnidade >= 13.0) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.otimo,
          rotulo: 'Muito Econômico',
          descricao: 'Carro muito econômico!',
          pontuacao: 0.90,
        );
      } else if (kmPorUnidade >= 9.0) {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.moderado,
          rotulo: 'Normal / Moderado',
          descricao: 'Consumo equilibrado para o dia a dia.',
          pontuacao: 0.55,
        );
      } else {
        return AvaliacaoConsumo(
          kmPorLitro: kmPorUnidade,
          nivel: NivelConsumo.alto,
          rotulo: 'Alto Consumo',
          descricao: 'Consumindo muito. Verifique alinhamento e filtros.',
          pontuacao: 0.20,
        );
      }
    }
  }

  static AvaliacaoConsumo? evaluateConsumption(
    double? kmPerUnit, {
    bool isCar = true,
    bool isTruck = false,
    TipoVeiculo? vehicleType,
    TipoPropulsao? propulsion,
    String fuelType = TiposCombustivel.gasolina,
  }) =>
      avaliarConsumo(kmPerUnit,
          isCar: isCar,
          isTruck: isTruck,
          vehicleType: vehicleType,
          propulsion: propulsion,
          fuelType: fuelType);

  static double totalManutencoes(Iterable<Manutencao> lista) =>
      lista.fold(0, (soma, m) => soma + m.custo);

  static double maintenanceTotal(Iterable<Manutencao> list) => totalManutencoes(list);

  static double totalCombustivel(Iterable<RegistroAbastecimento> lista) =>
      lista.fold(0, (soma, f) => soma + f.precoTotal);

  static double fuelTotal(Iterable<RegistroAbastecimento> list) => totalCombustivel(list);

  static bool mesmoMes(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool sameMonth(DateTime a, DateTime b) => mesmoMes(a, b);
}

/// Alias para manter compatibilidade
typedef Calculations = Calculos;
