import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/manutencao.dart';
import '../../models/registro_abastecimento.dart';
import '../../models/veiculo.dart';
import '../../theme/cores_app.dart';
import '../../utils/calculos.dart';
import '../../utils/formatadores.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/layout.dart';

enum PeriodFilter { semana, mes, ano }
enum VehicleTypeFilter { todos, carros, motos, caminhoes }

typedef FiltroPeriodo = PeriodFilter;
typedef FiltroTipoVeiculo = VehicleTypeFilter;

/// Dados de uma coluna do gráfico em português
class _BarData {
  final String label;
  final String fullLabel;
  final double fuelCost;
  final double maintenanceCost;
  final DateTime startDate;
  final DateTime endDate;
  final List<RegistroAbastecimento> fuels;
  final List<Manutencao> maintenances;

  double get total => fuelCost + maintenanceCost;

  const _BarData({
    required this.label,
    required this.fullLabel,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.startDate,
    required this.endDate,
    required this.fuels,
    required this.maintenances,
  });
}

/// Seção de Gráficos de Colunas e Relatórios com detalhamento de gastos e consumo em português.
class AbaRelatorios extends StatefulWidget {
  final List<Veiculo> veiculos;
  final List<Manutencao> manutencoes;
  final List<RegistroAbastecimento> abastecimentos;

  const AbaRelatorios({
    super.key,
    required this.veiculos,
    required this.manutencoes,
    required this.abastecimentos,
  });

  List<Veiculo> get vehicles => veiculos;
  List<Manutencao> get maintenances => manutencoes;
  List<RegistroAbastecimento> get fuels => abastecimentos;

  @override
  State<AbaRelatorios> createState() => _AbaRelatoriosState();
}

class _AbaRelatoriosState extends State<AbaRelatorios> {
  PeriodFilter _period = PeriodFilter.mes;
  VehicleTypeFilter _typeFilter = VehicleTypeFilter.todos;
  String? _selectedVehicleId; // null = Todos juntos; preenchido = Apenas 1 veículo específico
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.vehicles.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'Nenhum veículo cadastrado',
        message: 'Cadastre seus carros ou motos para visualizar gráficos e relatórios detalhados.',
      );
    }

    // Se o veículo selecionado foi excluído, volta para "Todos juntos"
    if (_selectedVehicleId != null &&
        !widget.vehicles.any((v) => v.id == _selectedVehicleId)) {
      _selectedVehicleId = null;
    }

    final Veiculo? singleVehicle = _selectedVehicleId == null
        ? null
        : widget.vehicles.firstWhere((v) => v.id == _selectedVehicleId);

    // Filtrar por veículo individual OU por tipo de veículo (quando "Todos juntos" está ativo)
    final filteredVehicles = singleVehicle != null
        ? <Veiculo>[singleVehicle]
        : widget.vehicles.where((v) {
            if (_typeFilter == VehicleTypeFilter.carros) return v.isCar;
            if (_typeFilter == VehicleTypeFilter.motos) return v.isMotorcycle;
            if (_typeFilter == VehicleTypeFilter.caminhoes) return v.isTruck;
            return true;
          }).toList();

    final allowedVehicleIds = filteredVehicles.map((v) => v.id).toSet();

    final activeMaintenances =
        widget.maintenances.where((m) => allowedVehicleIds.contains(m.vehicleId)).toList();
    final activeFuels = widget.fuels.where((f) => allowedVehicleIds.contains(f.vehicleId)).toList();

    // Monta colunas conforme o período
    final barDataList = _buildBars(activeMaintenances, activeFuels);

    final selectedBar = _selectedBarIndex != null && _selectedBarIndex! < barDataList.length
        ? barDataList[_selectedBarIndex!]
        : (barDataList.isNotEmpty ? barDataList.last : null);

    final totalPeriodSpent = barDataList.fold<double>(0, (sum, b) => sum + b.total);
    final totalFuelSpent = barDataList.fold<double>(0, (sum, b) => sum + b.fuelCost);
    final totalMaintSpent = barDataList.fold<double>(0, (sum, b) => sum + b.maintenanceCost);

    return ListView(
      padding: pagePadding(context),
      children: [
        // Título e Seleção de Período
        Text(
          'Relatório de Gastos e Consumo',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          singleVehicle != null
              ? 'Exibindo gráfico e consumo exclusivo de ${singleVehicle.name}'
              : 'Veja todos os veículos juntos ou selecione um veículo específico abaixo',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Filtros (Semana / Mês / Ano)
        SegmentedButton<PeriodFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: PeriodFilter.semana, label: Text('Semana')),
            ButtonSegment(value: PeriodFilter.mes, label: Text('Mês')),
            ButtonSegment(value: PeriodFilter.ano, label: Text('Ano')),
          ],
          selected: {_period},
          onSelectionChanged: (s) {
            setState(() {
              _period = s.first;
              _selectedBarIndex = null;
            });
          },
        ),
        const SizedBox(height: 12),

        // Seleção: Todos os veículos juntos OU 1 veículo individual
        const Text(
          'Visualizar gráfico de:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: Icon(
                Icons.dashboard_customize,
                size: 16,
                color: _selectedVehicleId == null ? AppColors.obsidian : Colors.grey,
              ),
              label: const Text('Todos juntos'),
              selected: _selectedVehicleId == null,
              onSelected: (_) => setState(() {
                _selectedVehicleId = null;
                _selectedBarIndex = null;
              }),
            ),
            ...widget.vehicles.map((v) {
              final isSelected = _selectedVehicleId == v.id;
              return ChoiceChip(
                avatar: Icon(
                  v.isTruck
                      ? Icons.local_shipping
                      : (v.isMotorcycle ? Icons.two_wheeler : Icons.directions_car),
                  size: 16,
                  color: isSelected ? AppColors.obsidian : Colors.grey,
                ),
                label: Text(v.name),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedVehicleId = isSelected ? null : v.id;
                  _selectedBarIndex = null;
                }),
              );
            }),
          ],
        ),

        // Filtro complementar por categoria apenas quando "Todos juntos" está selecionado e há mais de 1 veículo
        if (_selectedVehicleId == null && widget.vehicles.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text('Categoria:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              ChoiceChip(
                label: const Text('Todos'),
                selected: _typeFilter == VehicleTypeFilter.todos,
                onSelected: (_) => setState(() {
                  _typeFilter = VehicleTypeFilter.todos;
                  _selectedBarIndex = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Carros'),
                selected: _typeFilter == VehicleTypeFilter.carros,
                onSelected: (_) => setState(() {
                  _typeFilter = VehicleTypeFilter.carros;
                  _selectedBarIndex = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Motos'),
                selected: _typeFilter == VehicleTypeFilter.motos,
                onSelected: (_) => setState(() {
                  _typeFilter = VehicleTypeFilter.motos;
                  _selectedBarIndex = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Caminhões'),
                selected: _typeFilter == VehicleTypeFilter.caminhoes,
                onSelected: (_) => setState(() {
                  _typeFilter = VehicleTypeFilter.caminhoes;
                  _selectedBarIndex = null;
                }),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // Resumo do Período
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderStat(
                  label: 'Total Gasto',
                  value: formatMoney(totalPeriodSpent),
                  color: AppColors.goldenPollen,
                ),
                _HeaderStat(
                  label: singleVehicle != null && singleVehicle.isElectric ? 'Recargas' : 'Combustível',
                  value: formatMoney(totalFuelSpent),
                  color: isDark ? Colors.amber[200]! : Colors.orange[800]!,
                ),
                _HeaderStat(
                  label: 'Manutenção',
                  value: formatMoney(totalMaintSpent),
                  color: Colors.blue[400]!,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfico de Colunas Interativo
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gastos por ${_period == PeriodFilter.semana ? 'Dia' : _period == PeriodFilter.mes ? 'Semana' : 'Mês'}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            singleVehicle != null ? singleVehicle.name : 'Todos os veículos selecionados',
                            style: const TextStyle(fontSize: 12, color: AppColors.goldenPollen, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _LegendDot(
                          color: AppColors.goldenPollen,
                          label: singleVehicle != null && singleVehicle.isElectric ? 'Recarga' : 'Combustível',
                        ),
                        const SizedBox(width: 10),
                        const _LegendDot(color: Colors.blue, label: 'Manutenção'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Toque em uma coluna para ver exatamente no que o dinheiro foi gasto.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _ColumnChart(
                  bars: barDataList,
                  selectedIndex: _selectedBarIndex ?? (barDataList.length - 1),
                  onSelectBar: (idx) => setState(() => _selectedBarIndex = idx),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detalhamento do Período Selecionado (Drill-down: "No que eu gastei o dinheiro")
        if (selectedBar != null) ...[
          Card(
            elevation: 0,
            color: AppColors.goldenPollen.withValues(alpha: isDark ? 0.12 : 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.goldenPollen.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, color: AppColors.goldenPollen, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalhamento do período',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedBar.fullLabel,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.goldenPollen.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          formatMoney(selectedBar.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: isDark ? AppColors.goldenPollen : AppColors.obsidian,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (selectedBar.fuels.isEmpty && selectedBar.maintenances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhum gasto registrado neste intervalo.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else ...[
                    // Itens de combustível / recarga
                    ...selectedBar.fuels.map((f) {
                      final v = widget.vehicles.cast<Vehicle?>().firstWhere(
                            (x) => x?.id == f.vehicleId,
                            orElse: () => null,
                          );
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: f.isElectric ? Colors.green[600] : AppColors.goldenPollen,
                          child: Icon(
                            f.isElectric ? Icons.ev_station : Icons.local_gas_station,
                            size: 14,
                            color: f.isElectric ? Colors.white : AppColors.obsidian,
                          ),
                        ),
                        title: Text(
                            '${f.isElectric ? 'Recarga' : 'Abastecimento'} • ${f.fuelType} (${v?.name ?? 'Veículo'})'),
                        subtitle: Text(
                            '${formatDate(f.date)} • ${formatNumber(f.liters, 2)} ${f.unit} • ${formatKm(f.km)}'),
                        trailing: Text(
                          formatMoney(f.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                    // Itens de manutenção
                    ...selectedBar.maintenances.map((m) {
                      final v = widget.vehicles.cast<Vehicle?>().firstWhere(
                            (x) => x?.id == m.vehicleId,
                            orElse: () => null,
                          );
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.build, size: 14, color: Colors.white),
                        ),
                        title: Text('${m.category} (${v?.name ?? 'Veículo'})'),
                        subtitle: Text('${formatDate(m.date)} • ${formatKm(m.km)}'),
                        trailing: Text(
                          formatMoney(m.cost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Tabela / Cards de Consumo de Combustível e Energia dos Veículos
        SectionTitle(
          'Consumo e Eficiência dos Veículos',
          trailing: Text('${filteredVehicles.length} veículo(s)',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        ...filteredVehicles.map((v) {
          final vFuels = activeFuels.where((f) => f.vehicleId == v.id).toList();
          final avg = Calculations.averageConsumption(vFuels);
          final lastFuel = vFuels.isNotEmpty ? vFuels.first : null;
          final totalFuelPrice = Calculations.fuelTotal(vFuels);
          final totalFuelVol = vFuels.fold<double>(0, (sum, f) => sum + f.liters);
          final defaultFuelLabel = v.isElectric ? FuelTypes.eletricidade : 'Gasolina';
          final unitLabel = lastFuel?.unit ?? (v.isElectric ? 'kWh' : 'L');
          final consUnitLabel = lastFuel?.consumptionUnit ?? v.defaultConsumptionUnit;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        v.isTruck ? Icons.local_shipping : (v.isCar ? Icons.directions_car : Icons.two_wheeler),
                        color: AppColors.goldenPollen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          v.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      if (v.usesElectricPower)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (v.isElectric ? Colors.green : Colors.teal).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            v.propulsion.shortLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: v.isElectric ? Colors.green[600] : Colors.teal[600],
                            ),
                          ),
                        ),
                      if (v.plate.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            v.plate.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${v.isElectric ? 'Energia' : 'Combustível'}: ${lastFuel?.fuelType ?? defaultFuelLabel}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Total: ${formatMoney(totalFuelPrice)} (${formatNumber(totalFuelVol, 1)} $unitLabel)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        avg != null
                            ? 'Média: ${formatNumber(avg, 1)} $consUnitLabel'
                            : 'Média: aguarda 2+ registros',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: avg != null ? AppColors.goldenPollen : Colors.grey,
                        ),
                      ),
                      Builder(
                        builder: (_) {
                          final dailyKm = Calculations.dailyAverageDistance(vFuels);
                          if (dailyKm <= 0) return const SizedBox.shrink();
                          return Text(
                            'Média Diária: ${formatNumber(dailyKm, 1)} km/dia',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Gera os dados das colunas com base no período selecionado
  List<_BarData> _buildBars(List<Maintenance> maintenances, List<FuelRecord> fuels) {
    final now = DateTime.now();

    if (_period == PeriodFilter.semana) {
      // 7 dias da semana atual (Segunda a Domingo)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final fullNames = [
        'Segunda-feira',
        'Terça-feira',
        'Quarta-feira',
        'Quinta-feira',
        'Sexta-feira',
        'Sábado',
        'Domingo'
      ];

      return List.generate(7, (i) {
        final day = DateTime(monday.year, monday.month, monday.day).add(Duration(days: i));
        final nextDay = day.add(const Duration(days: 1));

        final dayFuels = fuels.where((f) => !f.date.isBefore(day) && f.date.isBefore(nextDay)).toList();
        final dayMaint = maintenances.where((m) => !m.date.isBefore(day) && m.date.isBefore(nextDay)).toList();

        return _BarData(
          label: dayNames[i],
          fullLabel: '${fullNames[i]} (${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')})',
          fuelCost: Calculations.fuelTotal(dayFuels),
          maintenanceCost: Calculations.maintenanceTotal(dayMaint),
          startDate: day,
          endDate: nextDay,
          fuels: dayFuels,
          maintenances: dayMaint,
        );
      });
    } else if (_period == PeriodFilter.mes) {
      // 4 semanas do mês atual
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      return List.generate(4, (i) {
        final startDay = 1 + (i * 7);
        final endDay = math.min(startDay + 6, daysInMonth);
        final start = DateTime(now.year, now.month, startDay);
        final end = DateTime(now.year, now.month, endDay, 23, 59, 59);

        final weekFuels = fuels.where((f) => !f.date.isBefore(start) && !f.date.isAfter(end)).toList();
        final weekMaint = maintenances.where((m) => !m.date.isBefore(start) && !m.date.isAfter(end)).toList();

        return _BarData(
          label: 'Sem ${i + 1}',
          fullLabel: 'Semana ${i + 1} ($startDay a $endDay/${now.month})',
          fuelCost: Calculations.fuelTotal(weekFuels),
          maintenanceCost: Calculations.maintenanceTotal(weekMaint),
          startDate: start,
          endDate: end,
          fuels: weekFuels,
          maintenances: weekMaint,
        );
      });
    } else {
      // 12 meses do ano atual
      final monthNames = [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez'
      ];
      final monthFullNames = [
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

      return List.generate(12, (i) {
        final month = i + 1;
        final start = DateTime(now.year, month, 1);
        final end = DateTime(now.year, month + 1, 0, 23, 59, 59);

        final mFuels = fuels.where((f) => f.date.year == now.year && f.date.month == month).toList();
        final mMaint = maintenances.where((m) => m.date.year == now.year && m.date.month == month).toList();

        return _BarData(
          label: monthNames[i],
          fullLabel: '${monthFullNames[i]} de ${now.year}',
          fuelCost: Calculations.fuelTotal(mFuels),
          maintenanceCost: Calculations.maintenanceTotal(mMaint),
          startDate: start,
          endDate: end,
          fuels: mFuels,
          maintenances: mMaint,
        );
      });
    }
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

/// Renderizador visual das colunas com proporção, empilhamento e seleção por toque.
class _ColumnChart extends StatelessWidget {
  final List<_BarData> bars;
  final int selectedIndex;
  final ValueChanged<int> onSelectBar;

  const _ColumnChart({
    required this.bars,
    required this.selectedIndex,
    required this.onSelectBar,
  });

  @override
  Widget build(BuildContext context) {
    final maxTotal = bars.fold<double>(0, (max, b) => math.max(max, b.total));
    const double chartHeight = 160;

    return SizedBox(
      height: chartHeight + 50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = math.max(16.0, (constraints.maxWidth / bars.length) - 8);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(bars.length, (index) {
              final bar = bars[index];
              final isSelected = selectedIndex == index;
              final double heightRatio = maxTotal > 0 ? (bar.total / maxTotal).clamp(0.0, 1.0) : 0;

              final totalHeight = chartHeight * heightRatio;

              return InkWell(
                onTap: () => onSelectBar(index),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Valor no topo se selecionado ou tiver gasto
                      if (bar.total > 0)
                        Text(
                          bar.total >= 1000 ? '${(bar.total / 1000).toStringAsFixed(1)}k' : bar.total.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.goldenPollen : Colors.grey,
                          ),
                        )
                      else
                        const SizedBox(height: 12),
                      const SizedBox(height: 4),

                      // Barra
                      Container(
                        width: barWidth,
                        height: math.max(6.0, totalHeight),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.goldenPollen.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: bar.total <= 0
                            ? Container(color: Colors.grey.withValues(alpha: 0.2))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Manutenção (Azul) no topo
                                  if (bar.maintenanceCost > 0)
                                    Expanded(
                                      flex: math.max(1, (bar.maintenanceCost * 100).toInt()),
                                      child: Container(color: Colors.blue[400]),
                                    ),
                                  // Combustível (Dourado) na base
                                  if (bar.fuelCost > 0)
                                    Expanded(
                                      flex: math.max(1, (bar.fuelCost * 100).toInt()),
                                      child: Container(color: AppColors.goldenPollen),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),

                      // Label do período
                      Text(
                        bar.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.goldenPollen : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class ReportsTab extends AbaRelatorios {
  const ReportsTab({
    super.key,
    required List<Veiculo> vehicles,
    required List<Manutencao> maintenances,
    required List<RegistroAbastecimento> fuels,
  }) : super(
         veiculos: vehicles,
         manutencoes: maintenances,
         abastecimentos: fuels,
       );
}
