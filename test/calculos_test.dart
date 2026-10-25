import 'package:carcare/models/registro_abastecimento.dart';
import 'package:carcare/models/veiculo.dart';
import 'package:carcare/utils/auxiliar_documentos.dart';
import 'package:carcare/utils/auxiliar_rodizio.dart';
import 'package:carcare/utils/calculos.dart';
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
}
