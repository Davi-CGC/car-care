import 'package:flutter/material.dart';

import '../models/maintenance_item.dart';
import '../models/vehicle.dart';

/// Plano de manutenção sugerido para cada tipo de veículo.
/// Para adicionar/remover itens ou mudar intervalos, edite as listas abaixo.
/// Os intervalos são referências gerais — consulte o manual do fabricante.
class MaintenanceCatalog {
  MaintenanceCatalog._();

  static const String other = 'Outro serviço';

  static const List<MaintenanceItem> car = [
    MaintenanceItem('Troca de óleo e filtro', Icons.oil_barrel, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Revisão', Icons.fact_check, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Troca de pneus', Icons.tire_repair, intervalKm: 40000, intervalMonths: 60),
    MaintenanceItem('Filtros de ar e combustível', Icons.air, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Sistema de freios', Icons.album, intervalKm: 20000, intervalMonths: 12),
    MaintenanceItem('Alinhamento e balanceamento', Icons.straighten, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Fluidos e arrefecimento', Icons.water_drop, intervalKm: 40000, intervalMonths: 24),
    MaintenanceItem('Sistema elétrico e bateria', Icons.battery_charging_full, intervalMonths: 24),
    MaintenanceItem('Suspensão e escapamento', Icons.car_repair, intervalKm: 40000, intervalMonths: 24),
    MaintenanceItem('Correia dentada e tensores', Icons.settings, intervalKm: 50000, intervalMonths: 48),
    MaintenanceItem('Velas e cabos de ignição', Icons.bolt, intervalKm: 30000, intervalMonths: 24),
    MaintenanceItem('Sistema de transmissão', Icons.settings_input_component, intervalKm: 60000, intervalMonths: 48),
    MaintenanceItem('Embreagem', Icons.sync_alt, intervalKm: 60000, onlyManual: true),
    MaintenanceItem('Palhetas do limpador', Icons.water, intervalMonths: 12),
  ];

  static const List<MaintenanceItem> moto = [
    MaintenanceItem('Óleo do motor e filtro', Icons.oil_barrel, intervalKm: 4000, intervalMonths: 6),
    MaintenanceItem('Sistema de freios', Icons.album, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Pneus e rodas', Icons.tire_repair, intervalKm: 15000, intervalMonths: 36),
    MaintenanceItem('Kit de transmissão', Icons.link, intervalKm: 15000, intervalMonths: 24),
    MaintenanceItem('Sistema elétrico e bateria', Icons.battery_charging_full, intervalMonths: 24),
    MaintenanceItem('Filtro de ar e velas de ignição', Icons.air, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Revisão periódica', Icons.fact_check, intervalKm: 5000, intervalMonths: 6),
    MaintenanceItem('Óleo das bengalas', Icons.opacity, intervalKm: 20000, intervalMonths: 24),
    MaintenanceItem('Caixa de direção', Icons.explore, intervalKm: 20000, intervalMonths: 24),
    MaintenanceItem('Balança traseira', Icons.balance, intervalKm: 20000, intervalMonths: 24),
    MaintenanceItem('Líquido de arrefecimento', Icons.water_drop, intervalKm: 20000, intervalMonths: 24),
    MaintenanceItem('Radiador e mangueiras', Icons.thermostat, intervalKm: 20000, intervalMonths: 24),
    MaintenanceItem('Cabos de aço (acelerador e embreagem)', Icons.cable, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Manetes e pedal de câmbio', Icons.pan_tool, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Filtro de combustível', Icons.local_gas_station, intervalKm: 10000, intervalMonths: 12),
    MaintenanceItem('Limpeza do corpo de borboleta (TBI)', Icons.cleaning_services, intervalKm: 10000, intervalMonths: 12),
  ];

  /// Itens do plano para um veículo (respeita câmbio manual/automático).
  static List<MaintenanceItem> itemsFor(Vehicle vehicle) {
    if (!vehicle.isCar) return moto;
    return car
        .where((i) => !i.onlyManual || vehicle.transmission != 'Automático')
        .toList();
  }

  /// Nomes das categorias para o formulário (inclui "Outro serviço").
  static List<String> categoriesFor(Vehicle vehicle) =>
      [...itemsFor(vehicle).map((i) => i.name), other];

  static MaintenanceItem? find(String name) {
    for (final item in [...car, ...moto]) {
      if (item.name == name) return item;
    }
    return null;
  }

  static IconData iconOf(String category) => find(category)?.icon ?? Icons.build;
}
