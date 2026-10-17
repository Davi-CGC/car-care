import 'package:carcare/models/fuel_record.dart';
import 'package:carcare/models/vehicle.dart';
import 'package:carcare/utils/calculations.dart';
import 'package:carcare/utils/rodizio_helper.dart';
import 'package:carcare/utils/vehicle_documents_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cálculos da Rotina de Abastecimento e Tanque Cheio', () {
    final car = Vehicle(
      id: 'v1',
      type: VehicleType.carro,
      brand: 'Toyota',
      model: 'Corolla',
      year: '2022',
      plate: 'ABC1D23', // final 3 -> terça-feira
      currentKm: 50000,
      tankCapacity: 50.0,
    );

    final fuels = [
      FuelRecord(
        id: 'f1',
        vehicleId: 'v1',
        date: DateTime(2026, 1, 1),
        km: 48000,
        liters: 45.0,
        totalPrice: 261.0,
        isFullTank: true,
        gasStation: 'Shell Centro',
      ),
      FuelRecord(
        id: 'f2',
        vehicleId: 'v1',
        date: DateTime(2026, 1, 12),
        km: 48400,
        liters: 40.0,
        totalPrice: 232.0,
        isFullTank: true,
        gasStation: 'Ipiranga Norte',
      ),
      FuelRecord(
        id: 'f3',
        vehicleId: 'v1',
        date: DateTime(2026, 1, 24),
        km: 48780,
        liters: 38.0,
        totalPrice: 220.4,
        isFullTank: true,
        gasStation: 'Petrobras BR',
      ),
    ];

    test('Calcula estatísticas de rotina de abastecimento corretamente', () {
      final stats = Calculations.fuelRoutine(car, fuels);

      expect(stats.totalFuels, equals(3));
      expect(stats.fullTankCount, equals(3));
      expect(stats.fullTankPercentage, equals(100.0));
      expect(stats.avgDistanceBetweenFuels, closeTo(390.0, 1.0)); // (400 + 380) / 2
      expect(stats.avgFrequencyDays, closeTo(11.5, 1.0)); // ~11-12 dias
      expect(stats.estimatedAutonomy, greaterThan(450.0));
      expect(stats.monthlyProjection, greaterThan(500.0));
    });

    test('Consumo pelo método do tanque cheio calcula com exatidão', () {
      final fullTankAvg = Calculations.fullTankConsumption(fuels);
      expect(fullTankAvg, isNotNull);
      // (48780 - 48000) / (40 + 38) = 780 / 78 = 10.0 km/l
      expect(fullTankAvg!, closeTo(10.0, 0.1));
    });

    test('Média diária de distância', () {
      final dailyKm = Calculations.dailyAverageDistance(fuels);
      expect(dailyKm, greaterThan(30.0));
    });
  });

  group('Documentos, Lembretes e Rodízio', () {
    test('Rodízio de carro detecta dia correto pelo final da placa', () {
      final info = RodizioHelper.getInfo('ABC-1233', type: VehicleType.carro);
      expect(info.isExempt, isFalse);
      expect(info.lastDigit, equals(3));
      expect(info.dayName, equals('Terça-feira'));
    });

    test('Motocicleta é isenta de rodízio', () {
      final info = RodizioHelper.getInfo('ABC-1234', type: VehicleType.moto);
      expect(info.isExempt, isTrue);
      expect(info.dayName, equals('Isento'));
    });

    test('Caminhão possui restrição com horário ZMRC', () {
      final info = RodizioHelper.getInfo('TRK-9871', type: VehicleType.caminhao);
      expect(info.isExempt, isFalse);
      expect(info.lastDigit, equals(1));
      expect(info.dayName, equals('Segunda-feira'));
      expect(info.timeRange, contains('ZMRC'));
    });

    test('Licenciamento calcula mês oficial pelo Detran', () {
      final car = Vehicle(
        type: VehicleType.carro,
        brand: 'VW',
        model: 'Gol',
        year: '2020',
        plate: 'BRA2E19', // final 9 -> Novembro (mês 11)
      );
      final lic = VehicleDocumentsHelper.getLicensingInfo(car);
      expect(lic.month, equals(11));
      expect(lic.monthName, equals('Novembro'));
    });

    test('Rodízio de pneus calcula km restante e progresso', () {
      final car = Vehicle(
        type: VehicleType.carro,
        brand: 'VW',
        model: 'Gol',
        year: '2020',
        currentKm: 47000,
        lastTireRotationKm: 40000,
        tireRotationIntervalKm: 10000,
      );
      final tire = VehicleDocumentsHelper.getTireRotationInfo(car);
      expect(tire.nextKm, equals(50000));
      expect(tire.remainingKm, equals(3000));
      expect(tire.progress, closeTo(0.7, 0.05));
      expect(tire.isDue, isFalse);
    });
  });
}
