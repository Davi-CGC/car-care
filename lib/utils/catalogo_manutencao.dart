import 'package:flutter/material.dart';

import '../models/item_manutencao.dart';
import '../models/veiculo.dart';

/// Plano de manutenção sugerido para cada tipo de veículo em português.
/// Para adicionar/remover itens ou mudar intervalos, edite as listas abaixo.
/// Os intervalos são referências gerais — consulte o manual do fabricante.
class CatalogoManutencao {
  CatalogoManutencao._();

  static const String outroServico = 'Outro serviço';
  static const String other = outroServico;

  static const List<ItemManutencao> carro = [
    ItemManutencao('Troca de óleo e filtro', Icons.oil_barrel, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Revisão', Icons.fact_check, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Troca de pneus', Icons.tire_repair, intervaloKm: 40000, intervaloMeses: 60),
    ItemManutencao('Filtros de ar e combustível', Icons.air, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Sistema de freios', Icons.album, intervaloKm: 20000, intervaloMeses: 12),
    ItemManutencao('Alinhamento e balanceamento', Icons.straighten, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Fluidos e arrefecimento', Icons.water_drop, intervaloKm: 40000, intervaloMeses: 24),
    ItemManutencao('Sistema elétrico e bateria', Icons.battery_charging_full, intervaloMeses: 24),
    ItemManutencao('Suspensão e escapamento', Icons.car_repair, intervaloKm: 40000, intervaloMeses: 24),
    ItemManutencao('Correia dentada e tensores', Icons.settings, intervaloKm: 50000, intervaloMeses: 48),
    ItemManutencao('Velas e cabos de ignição', Icons.bolt, intervaloKm: 30000, intervaloMeses: 24),
    ItemManutencao('Sistema de transmissão', Icons.settings_input_component, intervaloKm: 60000, intervaloMeses: 48),
    ItemManutencao('Embreagem', Icons.sync_alt, intervaloKm: 60000, apenasManual: true),
    ItemManutencao('Palhetas do limpador', Icons.water, intervaloMeses: 12),
  ];

  static const List<ItemManutencao> moto = [
    ItemManutencao('Óleo do motor e filtro', Icons.oil_barrel, intervaloKm: 4000, intervaloMeses: 6),
    ItemManutencao('Sistema de freios', Icons.album, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Pneus e rodas', Icons.tire_repair, intervaloKm: 15000, intervaloMeses: 36),
    ItemManutencao('Kit de transmissão', Icons.link, intervaloKm: 15000, intervaloMeses: 24),
    ItemManutencao('Sistema elétrico e bateria', Icons.battery_charging_full, intervaloMeses: 24),
    ItemManutencao('Filtro de ar e velas de ignição', Icons.air, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Revisão periódica', Icons.fact_check, intervaloKm: 5000, intervaloMeses: 6),
    ItemManutencao('Óleo das bengalas', Icons.opacity, intervaloKm: 20000, intervaloMeses: 24),
    ItemManutencao('Caixa de direção', Icons.explore, intervaloKm: 20000, intervaloMeses: 24),
    ItemManutencao('Balança traseira', Icons.balance, intervaloKm: 20000, intervaloMeses: 24),
    ItemManutencao('Líquido de arrefecimento', Icons.water_drop, intervaloKm: 20000, intervaloMeses: 24),
    ItemManutencao('Radiador e mangueiras', Icons.thermostat, intervaloKm: 20000, intervaloMeses: 24),
    ItemManutencao('Cabos de aço (acelerador e embreagem)', Icons.cable, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Manetes e pedal de câmbio', Icons.pan_tool, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Filtro de combustível', Icons.local_gas_station, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Limpeza do corpo de borboleta (TBI)', Icons.cleaning_services, intervaloKm: 10000, intervaloMeses: 12),
  ];

  // Aliases de compatibilidade
  static const List<ItemManutencao> car = carro;

  /// Itens do plano para um veículo (respeita câmbio manual/automático).
  static List<ItemManutencao> itensPara(Veiculo veiculo) {
    if (!veiculo.eCarro) return moto;
    return carro
        .where((i) => !i.apenasManual || veiculo.transmissao != 'Automático')
        .toList();
  }

  static List<ItemManutencao> itemsFor(Veiculo vehicle) => itensPara(vehicle);

  /// Nomes das categorias para o formulário (inclui "Outro serviço").
  static List<String> categoriasPara(Veiculo veiculo) =>
      [...itensPara(veiculo).map((i) => i.nome), outroServico];

  static List<String> categoriesFor(Veiculo vehicle) => categoriasPara(vehicle);

  static ItemManutencao? buscar(String nome) {
    for (final item in [...carro, ...moto]) {
      if (item.nome == nome) return item;
    }
    return null;
  }

  static ItemManutencao? find(String name) => buscar(name);

  static IconData iconeDe(String categoria) => buscar(categoria)?.icone ?? Icons.build;
  static IconData iconOf(String category) => iconeDe(category);
}

/// Alias para manter compatibilidade
typedef MaintenanceCatalog = CatalogoManutencao;
