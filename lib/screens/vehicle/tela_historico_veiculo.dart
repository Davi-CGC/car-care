import 'package:flutter/material.dart';

import '../../models/manutencao.dart';
import '../../models/registro_abastecimento.dart';
import '../../models/veiculo.dart';
import '../../repositories/repositorio_abastecimento.dart';
import '../../repositories/repositorio_manutencao.dart';
import '../../repositories/repositorio_veiculo.dart';
import '../../theme/cores_app.dart';
import '../../utils/auxiliar_rodizio.dart';
import '../../utils/calculos.dart';
import '../../utils/catalogo_manutencao.dart';
import '../../utils/formatadores.dart';
import '../../widgets/cartao_rotina_combustivel.dart';
import '../../widgets/layout.dart';
import '../../widgets/termometro_consumo.dart';
import 'lembretes_veiculo_sheet.dart';

enum _LogFilter { todos, manutencoes, abastecimentos }

class _LogEntry {
  final DateTime date;
  final int km;
  final bool isFuel;
  final RegistroAbastecimento? fuel;
  final Manutencao? maintenance;

  const _LogEntry({
    required this.date,
    required this.km,
    required this.isFuel,
    this.fuel,
    this.maintenance,
  });
}

/// Diário de Bordo / Log Unificado do Veículo em português.
/// Exibe todo o histórico de manutenções, abastecimentos, gastos e consumo
/// em uma linha do tempo cronológica com estatísticas acumuladas.
class TelaHistoricoVeiculo extends StatefulWidget {
  final Veiculo veiculo;

  const TelaHistoricoVeiculo({
    super.key,
    required this.veiculo,
  });

  Veiculo get vehicle => veiculo;

  @override
  State<TelaHistoricoVeiculo> createState() => _TelaHistoricoVeiculoState();
}

class _TelaHistoricoVeiculoState extends State<TelaHistoricoVeiculo> {
  final _fuelRepo = RepositorioAbastecimento();
  final _maintenanceRepo = RepositorioManutencao();
  final _vehicleRepo = RepositorioVeiculo();

  _LogFilter _filter = _LogFilter.todos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final v = widget.vehicle;
    final rodizio = RodizioHelper.getInfo(
      v.plate,
      type: v.type,
      propulsion: v.propulsion,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Diário de Bordo - ${v.name}'),
      ),
      body: StreamBuilder<List<FuelRecord>>(
        stream: _fuelRepo.watchAll(),
        builder: (context, fSnap) {
          final allFuels = fSnap.data ?? [];
          final vehicleFuels = allFuels.where((f) => f.vehicleId == v.id).toList();

          return StreamBuilder<List<Maintenance>>(
            stream: _maintenanceRepo.watchAll(),
            builder: (context, mSnap) {
              final allMaintenances = mSnap.data ?? [];
              final vehicleMaintenances =
                  allMaintenances.where((m) => m.vehicleId == v.id).toList();

              final totalFuelCost = Calculations.fuelTotal(vehicleFuels);
              final totalMaintCost = Calculations.maintenanceTotal(vehicleMaintenances);
              final totalSpent = totalFuelCost + totalMaintCost;

              final avgConsumption = Calculations.averageConsumption(vehicleFuels);
              final dailyKm = Calculations.dailyAverageDistance(vehicleFuels);

              // Unifica registros na linha do tempo
              final entries = <_LogEntry>[];
              if (_filter == _LogFilter.todos || _filter == _LogFilter.abastecimentos) {
                for (final f in vehicleFuels) {
                  entries.add(_LogEntry(date: f.date, km: f.km, isFuel: true, fuel: f));
                }
              }
              if (_filter == _LogFilter.todos || _filter == _LogFilter.manutencoes) {
                for (final m in vehicleMaintenances) {
                  entries.add(_LogEntry(date: m.date, km: m.km, isFuel: false, maintenance: m));
                }
              }
              entries.sort((a, b) => b.date.compareTo(a.date));

              return ResponsiveCenter(
                child: ListView(
                  padding: pagePadding(context),
                  children: [
                    // Card do Veículo e Rodízio
                    Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: rodizio.isToday ? AppColors.warning : AppColors.goldenPollen.withValues(alpha: 0.3),
                          width: rodizio.isToday ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.goldenPollen.withValues(alpha: 0.2),
                                  child: Icon(
                                    v.isTruck
                                        ? Icons.local_shipping
                                        : (v.isCar ? Icons.directions_car : Icons.two_wheeler),
                                    color: AppColors.goldenPollen,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              v.name,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          if (v.usesElectricPower) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (v.isElectric ? Colors.green : Colors.teal).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
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
                                          ],
                                        ],
                                      ),
                                      Text(
                                        'Placa: ${v.plate.isNotEmpty ? v.plate.toUpperCase() : 'Não informada'} • Ano: ${v.year.isNotEmpty ? v.year : '--'} • ${v.propulsion.label}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                      ),
                                      Text(
                                        'Odômetro Atual: ${formatKm(v.currentKm)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            // Alerta de Rodízio
                            Row(
                              children: [
                                Icon(
                                  rodizio.isExempt ? Icons.verified_outlined : Icons.calendar_month,
                                  size: 18,
                                  color: rodizio.isToday
                                      ? AppColors.warning
                                      : (rodizio.isExempt && v.usesElectricPower ? Colors.green[600] : Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    v.isMotorcycle
                                        ? 'Rodízio: Isento (Motocicleta)'
                                        : (rodizio.isExempt
                                            ? 'Rodízio: ${rodizio.dayName} — ${rodizio.timeRange}'
                                            : 'Dia de Rodízio: ${rodizio.dayName} (${rodizio.timeRange})'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: rodizio.isToday ? FontWeight.bold : FontWeight.normal,
                                      color: rodizio.isToday ? AppColors.warning : null,
                                    ),
                                  ),
                                ),
                                if (rodizio.isToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'HOJE',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.assignment_outlined, size: 18),
                                label: const Text('Lembretes: IPVA, Licenciamento, Seguro & Pneus'),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (_) => VehicleRemindersSheet(vehicle: v, repo: _vehicleRepo),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resumo Financeiro
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Total Gasto',
                            value: formatMoney(totalSpent),
                            icon: Icons.account_balance_wallet,
                            color: AppColors.goldenPollen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatMiniCard(
                            label: v.isElectric ? 'Recargas (kWh)' : 'Combustível',
                            value: formatMoney(totalFuelCost),
                            icon: v.isElectric ? Icons.ev_station : Icons.local_gas_station,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Manutenções',
                            value: formatMoney(totalMaintCost),
                            icon: Icons.build,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Consumo Médio e Média Diária (exclusivos por veículo no Log)
                    Builder(
                      builder: (_) {
                        final lastFuel = vehicleFuels.isNotEmpty ? vehicleFuels.first : null;
                        final consUnit = lastFuel?.consumptionUnit ?? v.defaultConsumptionUnit;
                        return Row(
                          children: [
                            Expanded(
                              child: _StatMiniCard(
                                label: 'Consumo médio',
                                value: avgConsumption != null
                                    ? '${formatNumber(avgConsumption, 1)} $consUnit'
                                    : '--',
                                icon: v.isElectric ? Icons.ev_station : Icons.local_gas_station,
                                color: AppColors.goldenPollen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatMiniCard(
                                label: 'Média diária',
                                value: dailyKm > 0
                                    ? '${formatNumber(dailyKm, 1)} km/dia'
                                    : '--',
                                icon: Icons.route,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Card de Rotina de Abastecimento / Recarga
                    if (vehicleFuels.isNotEmpty) ...[
                      FuelRoutineCard(vehicle: v, fuels: vehicleFuels),
                      const SizedBox(height: 16),
                    ],

                    // Termômetro de Consumo exclusivo deste veículo
                    if (avgConsumption != null) ...[
                      Builder(
                        builder: (_) {
                          final lastFuel = vehicleFuels.isNotEmpty ? vehicleFuels.first : null;
                          final effectiveFuelType = lastFuel?.fuelType ??
                              (v.isElectric ? FuelTypes.eletricidade : FuelTypes.gasolina);
                          final effectivePropulsion =
                              (lastFuel != null && !lastFuel.isElectric && v.isElectric)
                                  ? VehiclePropulsion.combustao
                                  : v.propulsion;
                          final eval = Calculations.evaluateConsumption(
                            avgConsumption,
                            vehicleType: v.type,
                            propulsion: effectivePropulsion,
                            fuelType: effectiveFuelType,
                          );
                          if (eval == null) return const SizedBox.shrink();
                          return ConsumptionThermometer(
                            evaluation: eval,
                            unit: lastFuel?.consumptionUnit ?? v.defaultConsumptionUnit,
                            vehicleName: v.name,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Card(
                        elevation: 0,
                        color: isDark ? const Color(0xFF1E1E24) : Colors.grey.withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.goldenPollen.withValues(alpha: 0.15),
                                child: const Icon(Icons.thermostat, color: AppColors.goldenPollen),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Termômetro de Consumo • ${v.name}',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.isElectric
                                          ? 'Registre pelo menos 2 recargas elétricas neste veículo para calcular a eficiência (${v.defaultConsumptionUnit}) e ativar o termômetro.'
                                          : 'Registre pelo menos 2 abastecimentos neste veículo para calcular a média (${v.defaultConsumptionUnit}) e ativar o termômetro de consumo.',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Filtros da Linha do Tempo (empilhados para nunca espremer em celulares)
                    Text(
                      'Histórico de Eventos (${entries.length})',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_LogFilter>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: [
                          const ButtonSegment(
                            value: _LogFilter.todos,
                            label: Text('Tudo', maxLines: 1, softWrap: false),
                          ),
                          const ButtonSegment(
                            value: _LogFilter.manutencoes,
                            label: Text('Serviços', maxLines: 1, softWrap: false),
                          ),
                          ButtonSegment(
                            value: _LogFilter.abastecimentos,
                            label: Text(
                              v.isElectric ? 'Recargas' : 'Abastecimentos',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (s) => setState(() => _filter = s.first),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Timeline Entries
                    if (entries.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: const [
                              Icon(Icons.history, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Nenhum registro encontrado para este veículo.',
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...entries.map((entry) {
                        return _TimelineTile(entry: entry);
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color ?? Colors.grey),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _LogEntry entry;

  const _TimelineTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (entry.isFuel && entry.fuel != null) {
      final f = entry.fuel!;
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: (f.isElectric ? Colors.green : AppColors.goldenPollen)
                    .withValues(alpha: 0.15),
                child: Icon(
                  f.isElectric ? Icons.ev_station : Icons.local_gas_station,
                  color: f.isElectric ? Colors.green[600] : AppColors.goldenPollen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.isElectric
                                ? 'Recarga Elétrica • ${f.fuelType}'
                                : 'Abastecimento • ${f.fuelType}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Text(
                          formatMoney(f.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldenPollen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDate(f.date)} • Odômetro: ${formatKm(f.km)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '${f.isElectric ? 'Carga' : 'Volume'}: ${formatNumber(f.liters, 2)} ${f.unit} • ${formatMoney(f.pricePerLiter)}/${f.unit}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (!entry.isFuel && entry.maintenance != null) {
      final m = entry.maintenance!;
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                child: Icon(MaintenanceCatalog.iconOf(m.category), color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.category,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Text(
                          formatMoney(m.cost),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDate(m.date)} • Odômetro: ${formatKm(m.km)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    if (m.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Obs: ${m.notes}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    if (m.nextKm != null || m.nextDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Próximo: ${[if (m.nextKm != null) formatKm(m.nextKm!), if (m.nextDate != null) formatDate(m.nextDate!)].join(' ou ')}',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.amber[300] : Colors.amber[900]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class VehicleLogScreen extends TelaHistoricoVeiculo {
  const VehicleLogScreen({
    super.key,
    required Veiculo vehicle,
  }) : super(veiculo: vehicle);
}
