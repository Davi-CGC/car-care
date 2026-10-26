import 'package:carcare/models/registro_abastecimento.dart';
import 'package:carcare/models/veiculo.dart';
import 'package:carcare/utils/auxiliar_documentos.dart';
import 'package:carcare/utils/auxiliar_rodizio.dart';
import 'package:carcare/utils/calculos.dart';
import 'package:carcare/utils/catalogo_manutencao.dart';
import 'package:carcare/utils/formatadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cálculos da Rotina de Abastecimento e Tanque Cheio', () {
    final carro = Veiculo(
      id: 'v1',
      tipo: TipoVeiculo.carro,
      marca: 'Toyota',
      modelo: 'Corolla',
      ano: '2022',
      placa: 'ABC1D23', // final 3 -> terça-feira
      kmAtual: 50000,
      capacidadeTanque: 50.0,
    );

    final abastecimentos = [
      RegistroAbastecimento(
        id: 'f1',
        idVeiculo: 'v1',
        data: DateTime(2026, 1, 1),
        km: 48000,
        litros: 45.0,
        precoTotal: 261.0,
        tanqueCheio: true,
        postoCombustivel: 'Shell Centro',
      ),
      RegistroAbastecimento(
        id: 'f2',
        idVeiculo: 'v1',
        data: DateTime(2026, 1, 12),
        km: 48400,
        litros: 40.0,
        precoTotal: 232.0,
        tanqueCheio: true,
        postoCombustivel: 'Ipiranga Norte',
      ),
      RegistroAbastecimento(
        id: 'f3',
        idVeiculo: 'v1',
        data: DateTime(2026, 1, 24),
        km: 48780,
        litros: 38.0,
        precoTotal: 220.4,
        tanqueCheio: true,
        postoCombustivel: 'Petrobras BR',
      ),
    ];

    test('Calcula estatísticas de rotina de abastecimento corretamente', () {
      final estatisticas = Calculos.rotinaCombustivel(carro, abastecimentos);

      expect(estatisticas.totalAbastecimentos, equals(3));
      expect(estatisticas.quantidadeTanqueCheio, equals(3));
      expect(estatisticas.porcentagemTanqueCheio, equals(100.0));
      expect(estatisticas.distanciaMediaEntreAbastecimentos, closeTo(390.0, 1.0)); // (400 + 380) / 2
      expect(estatisticas.frequenciaMediaDias, closeTo(11.5, 1.0)); // ~11-12 dias
      expect(estatisticas.autonomiaEstimada, greaterThan(450.0));
      expect(estatisticas.projecaoMensal, greaterThan(500.0));
    });

    test('Consumo pelo método do tanque cheio calcula com exatidão', () {
      final mediaTanqueCheio = Calculos.consumoTanqueCheio(abastecimentos);
      expect(mediaTanqueCheio, isNotNull);
      // (48780 - 48000) / (40 + 38) = 780 / 78 = 10.0 km/l
      expect(mediaTanqueCheio!, closeTo(10.0, 0.1));
    });

    test('Média diária de distância', () {
      final kmDiario = Calculos.distanciaMediaDiaria(abastecimentos);
      expect(kmDiario, greaterThan(30.0));
    });
  });

  group('Documentos, Lembretes e Rodízio', () {
    test('Rodízio de carro detecta dia correto pelo final da placa', () {
      final info = AuxiliarRodizio.obterInformacoes('ABC-1233', tipo: TipoVeiculo.carro);
      expect(info.eIsento, isFalse);
      expect(info.ultimoDigito, equals(3));
      expect(info.nomeDia, equals('Terça-feira'));
    });

    test('Motocicleta é isenta de rodízio', () {
      final info = AuxiliarRodizio.obterInformacoes('ABC-1234', tipo: TipoVeiculo.moto);
      expect(info.eIsento, isTrue);
      expect(info.nomeDia, equals('Isento'));
    });

    test('Caminhão possui restrição com horário ZMRC', () {
      final info = AuxiliarRodizio.obterInformacoes('TRK-9871', tipo: TipoVeiculo.caminhao);
      expect(info.eIsento, isFalse);
      expect(info.ultimoDigito, equals(1));
      expect(info.nomeDia, equals('Segunda-feira'));
      expect(info.horarioRestricao, contains('ZMRC'));
    });

    test('Licenciamento calcula mês oficial pelo Detran', () {
      final carro = Veiculo(
        tipo: TipoVeiculo.carro,
        marca: 'VW',
        modelo: 'Gol',
        ano: '2020',
        placa: 'BRA2E19', // final 9 -> Novembro (mês 11)
      );
      final lic = AuxiliarDocumentos.obterInformacaoLicenciamento(carro);
      expect(lic.mes, equals(11));
      expect(lic.nomeMes, equals('Novembro'));
    });

    test('Rodízio de pneus calcula km restante e progresso', () {
      final carro = Veiculo(
        tipo: TipoVeiculo.carro,
        marca: 'VW',
        modelo: 'Gol',
        ano: '2020',
        kmAtual: 47000,
        ultimoRodizioPneusKm: 40000,
        intervaloRodizioPneusKm: 10000,
      );
      final pneu = AuxiliarDocumentos.obterInformacaoRodizioPneus(carro);
      expect(pneu.proximoKm, equals(50000));
      expect(pneu.kmRestante, equals(3000));
      expect(pneu.progresso, closeTo(0.7, 0.05));
      expect(pneu.precisaFazer, isFalse);
    });
  });

  group('Veículos Elétricos e Híbridos (Carros, Motos e Caminhões)', () {
    test('Infere propulsão elétrica e híbrida por marca/modelo', () {
      expect(Veiculo.inferirPropulsao('BYD', 'Dolphin Mini'), equals(TipoPropulsao.eletrico));
      expect(Veiculo.inferirPropulsao('BYD', 'Song Plus Híbrido'), equals(TipoPropulsao.hibrido));
      expect(Veiculo.inferirPropulsao('Voltz', 'EVS'), equals(TipoPropulsao.eletrico));
      expect(Veiculo.inferirPropulsao('VW / MAN', 'e-Delivery 11t Elétrico'), equals(TipoPropulsao.eletrico));
      expect(Veiculo.inferirPropulsao('Volkswagen', 'Gol'), equals(TipoPropulsao.combustao));
    });

    test('Veículo 100% elétrico aceita apenas Eletricidade (kWh)', () {
      final evCar = Veiculo(
        tipo: TipoVeiculo.carro,
        propulsao: TipoPropulsao.eletrico,
        marca: 'BYD',
        modelo: 'Dolphin',
        ano: '2025',
      );
      final fuels = TiposCombustivel.paraVeiculo(evCar);
      expect(fuels, equals([TiposCombustivel.eletricidade]));
      expect(evCar.unidadeCapacidade, equals('kWh'));
      expect(evCar.unidadeConsumoPadrao, equals('km/kWh'));
    });

    test('Catálogo de manutenção EV não exibe óleo de motor nem velas', () {
      final evCar = Veiculo(
        tipo: TipoVeiculo.carro,
        propulsao: TipoPropulsao.eletrico,
        marca: 'BYD',
        modelo: 'Seal',
        ano: '2025',
      );
      final items = CatalogoManutencao.itensPara(evCar).map((i) => i.nome).toList();
      expect(items, isNot(contains('Óleo do motor')));
      expect(items, isNot(contains('Velas de ignição')));
      expect(items, isNot(contains('Correia dentada')));
      expect(items, contains('Diagnóstico da bateria de alta tensão'));
      expect(items, contains('Óleo da caixa redutora (transmissão EV)'));
    });

    test('Veículos elétricos e híbridos possuem isenção ambiental de rodízio', () {
      final rodizioEv = AuxiliarRodizio.obterInformacoes(
        'ABC1D23',
        tipo: TipoVeiculo.carro,
        propulsao: TipoPropulsao.eletrico,
      );
      expect(rodizioEv.eIsento, isTrue);
      expect(rodizioEv.eHoje, isFalse);
      expect(rodizioEv.nomeDia, contains('Isento'));
    });

    test('Avalia consumo em km/kWh para carro, moto e caminhão elétrico', () {
      final avalCarroEv = Calculos.avaliarConsumo(
        7.0,
        tipoVeiculo: TipoVeiculo.carro,
        propulsao: TipoPropulsao.eletrico,
        tipoCombustivel: TiposCombustivel.eletricidade,
      );
      expect(avalCarroEv?.nivel, equals(NivelConsumo.otimo));

      final avalMotoEv = Calculos.avaliarConsumo(
        25.0,
        tipoVeiculo: TipoVeiculo.moto,
        propulsao: TipoPropulsao.eletrico,
        tipoCombustivel: TiposCombustivel.eletricidade,
      );
      expect(avalMotoEv?.nivel, equals(NivelConsumo.otimo));

      final avalCaminhaoEv = Calculos.avaliarConsumo(
        1.2,
        tipoVeiculo: TipoVeiculo.caminhao,
        propulsao: TipoPropulsao.eletrico,
        tipoCombustivel: TiposCombustivel.eletricidade,
      );
      expect(avalCaminhaoEv?.nivel, equals(NivelConsumo.otimo));
    });
  });

  group('Controle de Frota e Viagem de Caminhão', () {
    test('Calcula Resultado 1 (Km/L da viagem) e Resultado 2 (Custo por Km Rodado) com precisão', () {
      final viagemCaminhao = RegistroAbastecimento(
        id: 't1',
        idVeiculo: 'truck1',
        tipoCombustivel: TiposCombustivel.diesel,
        data: DateTime(2026, 2, 10),
        kmInicialViagem: 100000,
        km: 100600, // 600 km rodados
        litros: 200.0, // 200 L abastecidos -> 3.0 km/L
        precoTotal: 1200.0, // R$ 1.200,00 -> R$ 2,00/km
        tipoCarroceria: 'Caçamba',
        numeroEixos: 6,
        pesoCargaTon: 32.5,
        notaFiscalCte: 'CT-e 88920',
      );

      expect(viagemCaminhao.possuiDadosViagem, isTrue);
      expect(viagemCaminhao.kmRodadosViagem, equals(600));
      expect(viagemCaminhao.resumoImplementoViagem, equals('Caçamba • 6 Eixos'));
      // Resultado 1: Km/L da viagem = 600 / 200 = 3.0 km/L
      expect(viagemCaminhao.resultadoKmPorLitroViagem, closeTo(3.0, 0.001));
      // Resultado 2: Custo de Combustível por Km Rodado = 1200.0 / 600 = R$ 2,00/km
      expect(viagemCaminhao.resultadoCustoPorKmViagem, closeTo(2.0, 0.001));
    });

    test('Converte valores numéricos e odômetros com separadores de milhar brasileiros', () {
      // Valores com milhar e vírgula decimal
      expect(converterNumero('1.250,50'), closeTo(1250.50, 0.01));
      expect(parseNumber('R\$ 2.400,00'), closeTo(2400.00, 0.01));
      expect(converterNumero('45,90'), closeTo(45.90, 0.01));
      expect(converterNumero('45.90'), closeTo(45.90, 0.01));

      // Odômetros com ponto de milhar ou puro
      expect(converterKm('105.000'), equals(105000));
      expect(parseKm('105000'), equals(105000));
      expect(parseKm('105.450 km'), equals(105450));
    });
  });
}
