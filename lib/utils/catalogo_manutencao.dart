import 'package:flutter/material.dart';

import '../models/item_manutencao.dart';
import '../models/veiculo.dart';

/// Plano de manutenção sugerido para cada tipo e motorização de veículo em português.
/// Adapta automaticamente as categorias para veículos a Combustão, Híbridos e 100% Elétricos.
class CatalogoManutencao {
  CatalogoManutencao._();

  static const String outroServico = 'Outro serviço';
  static const String other = outroServico;

  /// Carros a Combustão / Flex
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

  /// Carros 100% Elétricos (EV) — Sem óleo de motor, velas, correia, escapamento ou filtro de combustível
  static const List<ItemManutencao> carroEletrico = [
    ItemManutencao('Diagnóstico da bateria de alta tensão', Icons.battery_charging_full, intervaloKm: 20000, intervaloMeses: 12),
    ItemManutencao('Revisão periódica elétrica (EV)', Icons.fact_check, intervaloKm: 20000, intervaloMeses: 12),
    ItemManutencao('Filtro de ar-condicionado (cabine)', Icons.air, intervaloKm: 15000, intervaloMeses: 12),
    ItemManutencao('Fluido de arrefecimento da bateria e inversor', Icons.ac_unit, intervaloKm: 40000, intervaloMeses: 24),
    ItemManutencao('Óleo da caixa redutora (transmissão EV)', Icons.settings_input_component, intervaloKm: 60000, intervaloMeses: 36),
    ItemManutencao('Motor elétrico e cabos de alta tensão', Icons.electric_bolt, intervaloKm: 30000, intervaloMeses: 12),
    ItemManutencao('Sistema de freios regenerativos e pastilhas', Icons.album, intervaloKm: 30000, intervaloMeses: 24),
    ItemManutencao('Fluido de freio', Icons.water_drop, intervaloKm: 20000, intervaloMeses: 24),
    ItemManutencao('Troca de pneus (alto torque EV)', Icons.tire_repair, intervaloKm: 35000, intervaloMeses: 48),
    ItemManutencao('Alinhamento e balanceamento', Icons.straighten, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Suspensão e amortecedores', Icons.car_repair, intervaloKm: 40000, intervaloMeses: 24),
    ItemManutencao('Bateria auxiliar 12V', Icons.battery_std, intervaloMeses: 24),
    ItemManutencao('Atualização de software e módulos', Icons.system_update_alt, intervaloMeses: 12),
    ItemManutencao('Palhetas do limpador', Icons.water, intervaloMeses: 12),
  ];

  /// Itens adicionais para Híbridos (HEV / PHEV)
  static const List<ItemManutencao> itensExtrasHibrido = [
    ItemManutencao('Diagnóstico da bateria híbrida e inversor', Icons.battery_charging_full, intervaloKm: 20000, intervaloMeses: 12),
    ItemManutencao('Filtro de refrigeração da bateria híbrida', Icons.ac_unit, intervaloKm: 20000, intervaloMeses: 12),
    ItemManutencao('Fluido do sistema híbrido / e-CVT', Icons.settings_input_component, intervaloKm: 40000, intervaloMeses: 24),
  ];

  /// Motos a Combustão
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

  /// Motos 100% Elétricas
  static const List<ItemManutencao> motoEletrica = [
    ItemManutencao('Diagnóstico da bateria e BMS', Icons.battery_charging_full, intervaloKm: 5000, intervaloMeses: 6),
    ItemManutencao('Revisão do motor elétrico (Hub / Central)', Icons.electric_bolt, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Controladora e chicote elétrico', Icons.memory, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Correia / Corrente de transmissão', Icons.link, intervaloKm: 10000, intervaloMeses: 12),
    ItemManutencao('Sistema de freios e fluido', Icons.album, intervaloKm: 8000, intervaloMeses: 12),
    ItemManutencao('Pneus e calibragem', Icons.tire_repair, intervaloKm: 12000, intervaloMeses: 24),
    ItemManutencao('Suspensão e óleo das bengalas', Icons.opacity, intervaloKm: 15000, intervaloMeses: 24),
    ItemManutencao('Caixa de direção e rolamentos', Icons.explore, intervaloKm: 15000, intervaloMeses: 24),
    ItemManutencao('Carregador portátil / Conector de carga', Icons.ev_station, intervaloMeses: 12),
  ];

  /// Caminhões a Diesel / Combustão
  static const List<ItemManutencao> caminhao = [
    ItemManutencao('Óleo do motor diesel e filtros', Icons.oil_barrel, intervaloKm: 20000, intervaloMeses: 6),
    ItemManutencao('Filtro racor (separador de água) e diesel', Icons.filter_alt, intervaloKm: 15000, intervaloMeses: 6),
    ItemManutencao('Sistema de freios a ar, lonas e cuícas', Icons.album, intervaloKm: 25000, intervaloMeses: 6),
    ItemManutencao('Óleo de câmbio e diferencial', Icons.settings_input_component, intervaloKm: 60000, intervaloMeses: 12),
    ItemManutencao('Pneus, recapagem e alinhamento pesado', Icons.tire_repair, intervaloKm: 50000, intervaloMeses: 24),
    ItemManutencao('Suspensão, feixe de molas e bolsas de ar', Icons.local_shipping, intervaloKm: 40000, intervaloMeses: 12),
    ItemManutencao('Sistema Arla 32 / Catalisador SCR', Icons.water_drop, intervaloKm: 30000, intervaloMeses: 12),
    ItemManutencao('Turbina, intercooler e admissão', Icons.air, intervaloKm: 50000, intervaloMeses: 12),
    ItemManutencao('Sistema elétrico 24V e baterias', Icons.battery_charging_full, intervaloMeses: 12),
    ItemManutencao('Embreagem pesada', Icons.sync_alt, intervaloKm: 80000, apenasManual: true),
    ItemManutencao('Aferição de tacógrafo', Icons.speed, intervaloMeses: 24),
  ];

  /// Caminhões Elétricos (e-Delivery, iEV1200T, eT7, etc.)
  static const List<ItemManutencao> caminhaoEletrico = [
    ItemManutencao('Diagnóstico do pack de baterias de tração', Icons.battery_charging_full, intervaloKm: 20000, intervaloMeses: 6),
    ItemManutencao('Arrefecimento térmico das baterias e inversor', Icons.ac_unit, intervaloKm: 30000, intervaloMeses: 12),
    ItemManutencao('Motor elétrico de tração e transmissão', Icons.electric_bolt, intervaloKm: 40000, intervaloMeses: 12),
    ItemManutencao('Compressor de ar elétrico e freios pneumáticos', Icons.album, intervaloKm: 25000, intervaloMeses: 6),
    ItemManutencao('Óleo do diferencial traseiro', Icons.settings_input_component, intervaloKm: 60000, intervaloMeses: 12),
    ItemManutencao('Pneus e alinhamento de eixos', Icons.tire_repair, intervaloKm: 40000, intervaloMeses: 12),
    ItemManutencao('Suspensão e feixe de molas', Icons.local_shipping, intervaloKm: 40000, intervaloMeses: 12),
    ItemManutencao('Sistema auxiliar 24V e ar-condicionado', Icons.air, intervaloKm: 20000, intervaloMeses: 12),
    ItemManutencao('Aferição de tacógrafo', Icons.speed, intervaloMeses: 24),
  ];

  // Aliases de compatibilidade
  static const List<ItemManutencao> car = carro;

  /// Itens do plano para um veículo (respeita tipo Carro/Moto/Caminhão, motorização Elétrico/Híbrido/Combustão e câmbio).
  static List<ItemManutencao> itensPara(Veiculo veiculo) {
    if (veiculo.eMoto) {
      if (veiculo.eEletrico) return motoEletrica;
      if (veiculo.eHibrido) return [...itensExtrasHibrido, ...moto];
      return moto;
    }

    if (veiculo.eCaminhao) {
      if (veiculo.eEletrico) return caminhaoEletrico;
      final baseCaminhao = caminhao
          .where((i) => !i.apenasManual || veiculo.transmissao != 'Automático')
          .toList();
      if (veiculo.eHibrido) return [...itensExtrasHibrido, ...baseCaminhao];
      return baseCaminhao;
    }

    // Carro
    if (veiculo.eEletrico) {
      return carroEletrico;
    }

    final baseCarro = carro
        .where((i) => !i.apenasManual || veiculo.transmissao != 'Automático')
        .toList();

    if (veiculo.eHibrido) {
      return [...itensExtrasHibrido, ...baseCarro];
    }

    return baseCarro;
  }

  static List<ItemManutencao> itemsFor(Veiculo vehicle) => itensPara(vehicle);

  /// Nomes das categorias para o formulário (inclui "Outro serviço").
  static List<String> categoriasPara(Veiculo veiculo) =>
      [...itensPara(veiculo).map((i) => i.nome), outroServico];

  static List<String> categoriesFor(Veiculo vehicle) => categoriasPara(vehicle);

  static ItemManutencao? buscar(String nome) {
    for (final item in [
      ...carro,
      ...carroEletrico,
      ...itensExtrasHibrido,
      ...moto,
      ...motoEletrica,
      ...caminhao,
      ...caminhaoEletrico,
    ]) {
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
