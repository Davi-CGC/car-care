import 'package:flutter/material.dart';

import '../../models/alerta_manutencao.dart';
import '../../models/fipe.dart';
import '../../models/manutencao.dart';
import '../../models/registro_abastecimento.dart';
import '../../models/veiculo.dart';
import '../../repositories/repositorio_abastecimento.dart';
import '../../repositories/repositorio_manutencao.dart';
import '../../repositories/repositorio_veiculo.dart';
import '../../services/servico_autenticacao.dart';
import '../../services/servico_fipe.dart';
import '../../services/servico_postos_proximos.dart';
import '../../theme/controlador_tema.dart';
import '../../theme/cores_app.dart';
import '../../utils/auxiliar_rodizio.dart';
import '../../utils/calculos.dart';
import '../../utils/catalogo_manutencao.dart';
import '../../utils/catalogo_veiculos.dart';
import '../../utils/constantes.dart';
import '../../utils/dialogos.dart';
import '../../utils/formatadores.dart';
import '../../utils/validadores.dart';
import '../../widgets/botao_carregamento.dart';
import '../../widgets/campo_texto_app.dart';
import '../../widgets/cartao_resumo.dart';
import '../../widgets/cartao_rotina_combustivel.dart';
import '../../widgets/cartao_veiculo.dart';
import '../../widgets/estado_vazio.dart';
import '../../widgets/itens_registro.dart';
import '../../widgets/layout.dart';
import '../../widgets/logo_app.dart';
import '../fuel/historico_postos_sheet.dart';
import '../manual/tela_manual.dart';
import '../reports/aba_relatorios.dart';
import '../services/servicos_proximos_sheet.dart';
import '../vehicle/lembretes_veiculo_sheet.dart';
import '../vehicle/tela_historico_veiculo.dart';

/// Tela principal do CarCare com 5 abas integradas em português.
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

/// Alias para manter compatibilidade
typedef HomeScreen = TelaPrincipal;

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _currentIndex = 0;

  final _vehicleRepo = VehicleRepository();
  final _maintenanceRepo = MaintenanceRepository();
  final _fuelRepo = FuelRepository();
  final _auth = AuthService();

  String? _selectedVehicleFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _auth.currentUser;

    return StreamBuilder<List<Vehicle>>(
      stream: _vehicleRepo.watchAll(),
      builder: (context, vSnap) {
        final vehicles = vSnap.data ?? [];

        return StreamBuilder<List<Maintenance>>(
          stream: _maintenanceRepo.watchAll(),
          builder: (context, mSnap) {
            final maintenances = mSnap.data ?? [];

            return StreamBuilder<List<FuelRecord>>(
              stream: _fuelRepo.watchAll(),
              builder: (context, fSnap) {
                final fuels = fSnap.data ?? [];
                final alerts = Calculations.alerts(vehicles, maintenances);

                return Scaffold(
                  appBar: AppBar(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(size: 32),
                        const SizedBox(width: 8),
                        Text(
                          appName,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.explore_outlined),
                        tooltip: 'Serviços Próximos (Google Maps)',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => NearbyServicesSheet(fuels: fuels),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          themeController.isDark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        tooltip: 'Alternar Tema',
                        onPressed: () => setState(() => themeController.toggle()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Sair',
                        onPressed: () async {
                          final confirm = await confirmDialog(
                            context,
                            title: 'Sair da conta',
                            message: 'Deseja realmente sair do aplicativo?',
                            confirmText: 'Sair',
                          );
                          if (confirm) await _auth.signOut();
                        },
                      ),
                    ],
                  ),
                  body: IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildOverviewTab(user?.displayName, vehicles, maintenances, fuels, alerts),
                      _buildVehiclesTab(vehicles, alerts),
                      _buildMaintenancesTab(vehicles, maintenances),
                      _buildFuelTab(vehicles, fuels),
                      ReportsTab(vehicles: vehicles, maintenances: maintenances, fuels: fuels),
                    ],
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (i) => setState(() => _currentIndex = i),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: [
                      NavigationDestination(
                        icon: Badge(
                          isLabelVisible: alerts.isNotEmpty,
                          label: Text('${alerts.length}'),
                          child: const Icon(Icons.home_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: alerts.isNotEmpty,
                          label: Text('${alerts.length}'),
                          child: const Icon(Icons.home),
                        ),
                        label: 'Início',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.directions_car_outlined),
                        selectedIcon: const Icon(Icons.directions_car),
                        label: 'Veículos',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.build_outlined),
                        selectedIcon: const Icon(Icons.build),
                        label: 'Serviços',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.local_gas_station_outlined),
                        selectedIcon: const Icon(Icons.local_gas_station),
                        label: 'Abastecer',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.bar_chart_outlined),
                        selectedIcon: const Icon(Icons.bar_chart),
                        label: 'Relatórios',
                      ),
                    ],
                  ),
                  floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
                  floatingActionButton: _buildFloatingActions(vehicles, fuels),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFloatingActions(List<Vehicle> vehicles, List<FuelRecord> fuels) {
    final rightFab = _buildFab(vehicles, fuels);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'help_manual_fab',
            backgroundColor: AppColors.goldenPollen,
            foregroundColor: AppColors.obsidian,
            tooltip: 'Dúvidas Frequentes (FAQ)',
            elevation: 4,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualScreen()),
              );
            },
            child: const Icon(
              Icons.question_mark,
              color: AppColors.obsidian,
              size: 26,
              weight: 700,
            ),
          ),
          if (rightFab != null) rightFab else const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget? _buildFab(List<Vehicle> vehicles, List<FuelRecord> fuels) {
    switch (_currentIndex) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _showVehicleDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Veículo'),
        );
      case 2:
        return vehicles.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showMaintenanceDialog(context, vehicles),
                icon: const Icon(Icons.add),
                label: const Text('Manutenção'),
              );
      case 3:
        return vehicles.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showFuelDialog(context, vehicles, null, fuels),
                icon: const Icon(Icons.add),
                label: const Text('Abastecer'),
              );
      default:
        return vehicles.isEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _showVehicleDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Veículo'),
              )
            : null;
    }
  }

  // --- TAB 0: VISÃO GERAL ---
  Widget _buildOverviewTab(
    String? name,
    List<Vehicle> vehicles,
    List<Maintenance> maintenances,
    List<FuelRecord> fuels,
    List<MaintenanceAlert> alerts,
  ) {
    final now = DateTime.now();
    final monthMaintenances = maintenances.where((m) => Calculations.sameMonth(m.date, now));
    final monthFuels = fuels.where((f) => Calculations.sameMonth(f.date, now));

    final totalSpentMonth =
        Calculations.maintenanceTotal(monthMaintenances) + Calculations.fuelTotal(monthFuels);

    return ListView(
      padding: pagePadding(context),
      children: [
        Text(
          'Olá, ${name ?? 'Motorista'}!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          appSlogan,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        if (vehicles.any((v) => !v.isMotorcycle && v.plate.isNotEmpty && RodizioHelper.getInfo(v.plate, type: v.type, propulsion: v.propulsion).isToday)) ...[
          const SizedBox(height: 14),
          ...vehicles
              .where((v) => !v.isMotorcycle && v.plate.isNotEmpty && RodizioHelper.getInfo(v.plate, type: v.type, propulsion: v.propulsion).isToday)
              .map((rv) {
            final rInfo = RodizioHelper.getInfo(rv.plate, type: rv.type, propulsion: rv.propulsion);
            return Card(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.warning, width: 1.5),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.warning,
                  child: Icon(Icons.warning_amber_rounded, color: Colors.black87),
                ),
                title: Text(
                  'Atenção ao Rodízio Hoje: ${rv.name} (${rv.plate.toUpperCase()})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Restrição ativa hoje (${rInfo.dayName}) das ${rInfo.timeRange}.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
        SummaryGrid(
          children: [
            SummaryCard(
              icon: Icons.directions_car,
              label: 'Veículos',
              value: '${vehicles.length}',
            ),
            SummaryCard(
              icon: Icons.attach_money,
              label: 'Gastos este mês',
              value: formatMoney(totalSpentMonth),
              color: AppColors.goldenPollen,
            ),
            SummaryCard(
              icon: Icons.notifications_active,
              label: 'Alertas ativos',
              value: '${alerts.length}',
              color: alerts.isNotEmpty ? AppColors.danger : AppColors.success,
            ),
          ],
        ),
        SectionTitle(
          'Alertas de Serviços',
          trailing: alerts.isEmpty
              ? null
              : TextButton(
                  onPressed: () => setState(() => _currentIndex = 2),
                  child: const Text('Ver todos'),
                ),
        ),
        if (alerts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Tudo em dia!', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Nenhuma manutenção pendente ou atrasada.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...alerts.take(3).map((a) => AlertTile(
                alert: a,
                onTap: () => setState(() => _currentIndex = 2),
              )),
        const SectionTitle('Últimas Manutenções'),
        if (maintenances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhuma manutenção registrada ainda.'),
          )
        else
          ...maintenances.take(3).map((m) {
            final v = vehicles.cast<Vehicle?>().firstWhere((v) => v?.id == m.vehicleId, orElse: () => null);
            return MaintenanceTile(
              maintenance: m,
              vehicleName: v?.name,
              onTap: () => _showMaintenanceDetailsModal(context, vehicles, m, v),
            );
          }),
        const SectionTitle('Últimos Abastecimentos'),
        if (fuels.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum abastecimento registrado ainda.'),
          )
        else
          ...fuels.take(3).map((f) => FuelTile(
                record: f,
                onTap: () => _showFuelDetailsModal(context, vehicles, f),
              )),
      ],
    );
  }

  // --- TAB 1: VEÍCULOS ---
  Widget _buildVehiclesTab(List<Vehicle> vehicles, List<MaintenanceAlert> alerts) {
    if (vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_car_outlined,
        title: 'Nenhum veículo cadastrado',
        message: 'Cadastre seu carro ou moto para gerenciar manutenções, abastecimentos e tabela FIPE.',
        actionLabel: 'Cadastrar Veículo',
        onAction: () => _showVehicleDialog(context),
      );
    }

    return ListView(
      padding: pagePadding(context),
      children: [
        const SectionTitle('Meus Veículos'),
        ...vehicles.map((v) {
          final count = alerts.where((a) => a.vehicle.id == v.id).length;
          return VehicleCard(
            vehicle: v,
            alertCount: count,
            onTap: () => _showVehicleDetailsModal(context, v),
          );
        }),
      ],
    );
  }

  // --- TAB 2: MANUTENÇÕES ---
  Widget _buildMaintenancesTab(List<Vehicle> vehicles, List<Maintenance> maintenances) {
    if (vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_car,
        title: 'Cadastre um veículo primeiro',
        message: 'Para registrar manutenções você precisa ter pelo menos um veículo cadastrado.',
        actionLabel: 'Cadastrar Veículo',
        onAction: () => _showVehicleDialog(context),
      );
    }

    final filtered = _selectedVehicleFilter == null
        ? maintenances
        : maintenances.where((m) => m.vehicleId == _selectedVehicleFilter).toList();

    return ListView(
      padding: pagePadding(context),
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle('Histórico de Manutenções')),
            if (vehicles.length > 1)
              DropdownButton<String?>(
                value: _selectedVehicleFilter,
                hint: const Text('Todos'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos os veículos')),
                  ...vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))),
                ],
                onChanged: (val) => setState(() => _selectedVehicleFilter = val),
              ),
          ],
        ),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.build_outlined,
            title: 'Nenhuma manutenção',
            message: 'Toque no botão + para registrar uma nova manutenção.',
          )
        else
          ...filtered.map((m) {
            final v = vehicles.cast<Vehicle?>().firstWhere((x) => x?.id == m.vehicleId, orElse: () => null);
            return MaintenanceTile(
              maintenance: m,
              vehicleName: v?.name,
              onTap: () => _showMaintenanceDetailsModal(context, vehicles, m, v),
            );
          }),
      ],
    );
  }

  // --- TAB 3: ABASTECIMENTOS ---
  Widget _buildFuelTab(List<Vehicle> vehicles, List<FuelRecord> fuels) {
    if (vehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_car,
        title: 'Cadastre um veículo primeiro',
        message: 'Para registrar abastecimentos você precisa ter pelo menos um veículo cadastrado.',
        actionLabel: 'Cadastrar Veículo',
        onAction: () => _showVehicleDialog(context),
      );
    }

    final filtered = _selectedVehicleFilter == null
        ? fuels
        : fuels.where((f) => f.vehicleId == _selectedVehicleFilter).toList();

    return ListView(
      padding: pagePadding(context),
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle('Histórico de Abastecimentos')),
            if (vehicles.length > 1)
              DropdownButton<String?>(
                value: _selectedVehicleFilter,
                hint: const Text('Todos'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos os veículos')),
                  ...vehicles.map((v) => DropdownMenuItem(value: v.id, child: Text(v.name))),
                ],
                onChanged: (val) => setState(() => _selectedVehicleFilter = val),
              ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.storefront, size: 18),
            label: const Text('Histórico de Postos Frequentados'),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => GasStationsHistorySheet(fuels: fuels),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.local_gas_station_outlined,
            title: 'Nenhum abastecimento',
            message: 'Toque no botão + para registrar um novo abastecimento.',
          )
        else ...[
          Builder(
            builder: (_) {
              final vObj = _selectedVehicleFilter != null
                  ? vehicles.firstWhere((x) => x.id == _selectedVehicleFilter, orElse: () => vehicles.first)
                  : vehicles.firstWhere((x) => x.id == filtered.first.vehicleId, orElse: () => vehicles.first);
              final vFuels = _selectedVehicleFilter != null
                  ? filtered
                  : filtered.where((f) => f.vehicleId == vObj.id).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FuelRoutineCard(vehicle: vObj, fuels: vFuels),
              );
            },
          ),
          ...filtered.map((f) => FuelTile(
                record: f,
                onTap: () => _showFuelDetailsModal(context, vehicles, f, fuels),
              )),
        ],
      ],
    );
  }

  // ==========================================
  // MODAIS E DIÁLOGOS DE CADASTRO
  // ==========================================

  // --- Novo Veículo / Editar Veículo ---
  void _showVehicleDialog(BuildContext context, [Vehicle? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _VehicleFormSheet(existing: existing, repo: _vehicleRepo),
    );
  }

  // --- Detalhes do Veículo ---
  void _showVehicleDetailsModal(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        vehicle.isTruck
                            ? Icons.local_shipping
                            : (vehicle.isCar ? Icons.directions_car : Icons.two_wheeler),
                        color: AppColors.goldenPollen,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          vehicle.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      vehicle.usesElectricPower ? Icons.bolt : Icons.local_gas_station,
                      color: vehicle.usesElectricPower ? AppColors.success : null,
                    ),
                    title: const Text('Motorização'),
                    subtitle: Text(vehicle.propulsion.label),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.speed),
                    title: const Text('Quilometragem atual'),
                    subtitle: Text(formatKm(vehicle.currentKm)),
                    trailing: TextButton(
                      child: const Text('Atualizar'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showUpdateKmDialog(context, vehicle);
                      },
                    ),
                  ),
                  if (vehicle.plate.isNotEmpty) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Placa'),
                      subtitle: Text(vehicle.plate.toUpperCase()),
                    ),
                    Builder(builder: (_) {
                      final rodizio = RodizioHelper.getInfo(
                        vehicle.plate,
                        type: vehicle.type,
                        propulsion: vehicle.propulsion,
                      );
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.calendar_month,
                          color: rodizio.isToday
                              ? AppColors.warning
                              : (vehicle.usesElectricPower ? AppColors.success : null),
                        ),
                        title: const Text('Rodízio Municipal'),
                        subtitle: Text(
                          vehicle.isMotorcycle
                              ? 'Isento (Motocicleta)'
                              : '${rodizio.dayName} (${rodizio.timeRange})${rodizio.isToday ? ' • ATIVO HOJE!' : ''}',
                          style: TextStyle(
                            color: rodizio.isToday
                                ? AppColors.warning
                                : (vehicle.usesElectricPower ? AppColors.success : null),
                            fontWeight: (rodizio.isToday || vehicle.usesElectricPower)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                  if (!vehicle.isMotorcycle && vehicle.transmission.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings),
                      title: const Text('Câmbio / Transmissão'),
                      subtitle: Text(vehicle.transmission),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(vehicle.isElectric ? Icons.battery_charging_full : Icons.local_gas_station),
                    title: Text(vehicle.isElectric ? 'Capacidade da Bateria' : 'Capacidade do Tanque'),
                    subtitle: Text(
                      '${formatNumber(vehicle.effectiveTankCapacity, vehicle.isElectric ? 1 : 0)} ${vehicle.capacityUnit}',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.request_quote),
                    title: const Text('Tabela FIPE'),
                    subtitle: Text(
                      vehicle.fipeValue.isNotEmpty
                          ? '${vehicle.fipeValue} (${vehicle.fipeReference})'
                          : 'Não consultada',
                    ),
                    trailing: TextButton(
                      child: const Text('Consultar'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showFipeLookupDialog(context, vehicle);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.assignment),
                    label: const Text('Lembretes: IPVA, Licenciamento, Seguro & Pneus'),
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => VehicleRemindersSheet(vehicle: vehicle, repo: _vehicleRepo),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.goldenPollen,
                      foregroundColor: AppColors.obsidian,
                    ),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Diário de Bordo & Termômetro (Log)'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VehicleLogScreen(vehicle: vehicle),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showVehicleDialog(context, vehicle);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                          icon: const Icon(Icons.delete),
                          label: const Text('Excluir'),
                          onPressed: () async {
                            final confirm = await confirmDialog(
                              context,
                              title: 'Excluir veículo',
                              message:
                                  'Deseja excluir "${vehicle.name}"? Todas as manutenções e abastecimentos também serão apagados.',
                            );
                            if (confirm) {
                              await _vehicleRepo.delete(vehicle.id);
                              if (context.mounted) {
                                Navigator.pop(context);
                                showMessage(context, 'Veículo excluído com sucesso.');
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Atualizar Quilometragem ---
  void _showUpdateKmDialog(BuildContext context, Vehicle vehicle) {
    final controller = TextEditingController(text: '${vehicle.currentKm}');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atualizar Quilometragem'),
        content: Form(
          key: formKey,
          child: AppTextField(
            controller: controller,
            label: 'Nova Quilometragem (km)',
            icon: Icons.speed,
            keyboardType: TextInputType.number,
            validator: (v) => Validators.number(v, field: 'Quilometragem'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final km = int.tryParse(controller.text) ?? 0;
              await _vehicleRepo.setKm(vehicle.id, km);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                showMessage(context, 'Quilometragem atualizada para ${formatKm(km)}.');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // --- Consulta FIPE ---
  void _showFipeLookupDialog(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FipeLookupSheet(vehicle: vehicle, repo: _vehicleRepo),
    );
  }

  // --- Nova Manutenção ---
  void _showMaintenanceDialog(BuildContext context, List<Vehicle> vehicles, [Maintenance? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MaintenanceFormSheet(
        vehicles: vehicles,
        existing: existing,
        initialVehicleId: _selectedVehicleFilter,
        mRepo: _maintenanceRepo,
        vRepo: _vehicleRepo,
      ),
    );
  }

  void _showMaintenanceDetailsModal(
      BuildContext context, List<Vehicle> vehicles, Maintenance m, Vehicle? v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.category, style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text(v?.name ?? 'Veículo', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Data: ${formatDate(m.date)}'),
                Text('Quilometragem: ${formatKm(m.km)}'),
                Text('Valor: ${formatMoney(m.cost)}'),
                if (m.notes.isNotEmpty) Text('Observações: ${m.notes}'),
                if (m.nextKm != null || m.nextDate != null) ...[
                  const SizedBox(height: 8),
                  const Text('Próximo Serviço:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (m.nextKm != null) Text('• Com: ${formatKm(m.nextKm!)}'),
                  if (m.nextDate != null) Text('• Em: ${formatDate(m.nextDate!)}'),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showMaintenanceDialog(context, vehicles, m);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        onPressed: () async {
                          final confirm = await confirmDialog(
                            sheetContext,
                            title: 'Excluir Manutenção',
                            message: 'Deseja apagar este registro de manutenção?',
                          );
                          if (confirm) {
                            await _maintenanceRepo.delete(m.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              showMessage(context, 'Manutenção excluída.');
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Novo Abastecimento ---
  void _showFuelDialog(
    BuildContext context,
    List<Vehicle> vehicles, [
    FuelRecord? existing,
    List<FuelRecord> fuels = const [],
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FuelFormSheet(
        vehicles: vehicles,
        existing: existing,
        initialVehicleId: _selectedVehicleFilter,
        fuels: fuels,
        fRepo: _fuelRepo,
        vRepo: _vehicleRepo,
      ),
    );
  }

  void _showFuelDetailsModal(
    BuildContext context,
    List<Vehicle> vehicles,
    FuelRecord f, [
    List<FuelRecord> fuels = const [],
  ]) {
    final v = vehicles.cast<Vehicle?>().firstWhere((x) => x?.id == f.vehicleId, orElse: () => null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.isElectric ? 'Recarga Elétrica' : 'Abastecimento',
                            style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (v != null) Text(v.name, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Data: ${formatDate(f.date)}'),
                Text('${f.isElectric ? "Fonte de Energia" : "Combustível"}: ${f.fuelType}'),
                if (f.gasStation.isNotEmpty)
                  Text('${f.isElectric ? "Eletroposto / Local" : "Posto"}: ${f.gasStation}'),
                Text('Quilometragem: ${formatKm(f.km)}'),
                Text('${f.isElectric ? "Energia Recarregada" : "Volume"}: ${formatNumber(f.liters, 2)} ${f.unit}'),
                if (f.pricePerLiter > 0)
                  Text('Preço por ${f.unit}: ${formatMoney(f.pricePerLiter)}'),
                Text('Total Pago: ${formatMoney(f.totalPrice)}'),
                Text(
                  f.isElectric
                      ? 'Carga 100% Completa: ${f.isFullTank ? "Sim" : "Não (Parcial)"}'
                      : 'Tanque Cheio: ${f.isFullTank ? "Sim" : "Não (Parcial)"}',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showFuelDialog(context, vehicles, f, fuels);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        onPressed: () async {
                          final confirm = await confirmDialog(
                            sheetContext,
                            title: f.isElectric ? 'Excluir Recarga' : 'Excluir Abastecimento',
                            message: f.isElectric
                                ? 'Deseja apagar este registro de recarga elétrica?'
                                : 'Deseja apagar este registro de abastecimento?',
                          );
                          if (confirm) {
                            await _fuelRepo.delete(f.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              showMessage(context, f.isElectric ? 'Recarga excluída.' : 'Abastecimento excluído.');
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloquinho rolável inline que exibe até 5 opções por vez embaixo do campo
/// e filtra automaticamente conforme a pessoa digita ou rola a lista.
class _CaixaOpcoesRolavel extends StatefulWidget {
  final List<String> opcoes;
  final String valorSelecionado;
  final String filtroTexto;
  final ValueChanged<String> aoSelecionar;
  final String Function(String)? subtituloOpcao;
  final IconData Function(String)? iconeOpcao;
  final String? rotuloCabecalho;

  const _CaixaOpcoesRolavel({
    required this.opcoes,
    required this.valorSelecionado,
    required this.filtroTexto,
    required this.aoSelecionar,
    this.subtituloOpcao,
    this.iconeOpcao,
    this.rotuloCabecalho,
  });

  @override
  State<_CaixaOpcoesRolavel> createState() => _CaixaOpcoesRolavelState();
}

class _CaixaOpcoesRolavelState extends State<_CaixaOpcoesRolavel> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final eEscuro = tema.brightness == Brightness.dark;
    final q = widget.filtroTexto.trim().toLowerCase();

    // Se o texto digitado for exatamente igual ao selecionado, mostra todas as opções
    // para que a pessoa possa rolar o bloquinho livremente se quiser trocar.
    final mostrarTodas = q.isEmpty ||
        (widget.valorSelecionado.trim().isNotEmpty &&
            q == widget.valorSelecionado.trim().toLowerCase());

    final filtradas = mostrarTodas
        ? widget.opcoes
        : widget.opcoes.where((item) => item.toLowerCase().contains(q)).toList();

    if (filtradas.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: eEscuro ? const Color(0xFF1A1A20) : const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: const Text(
          'Nenhuma opção encontrada.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    // Altura de ~42px por linha -> 5 opções visíveis por vez (~210px)
    final double alturaItem = widget.subtituloOpcao != null ? 50.0 : 42.0;
    final int qtdVisivel = filtradas.length < 5 ? filtradas.length : 5;
    final double alturaCaixa = qtdVisivel * alturaItem;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: eEscuro ? const Color(0xFF1A1A20) : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldenPollen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.rotuloCabecalho != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.goldenPollen.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swipe_vertical, size: 13, color: AppColors.goldenPollen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.rotuloCabecalho!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Text(
                    '${filtradas.length} opções',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: alturaCaixa,
            child: Scrollbar(
              controller: _scrollCtrl,
              thumbVisibility: filtradas.length > 5,
              child: ListView.separated(
                controller: _scrollCtrl,
                padding: EdgeInsets.zero,
                itemCount: filtradas.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  final item = filtradas[index];
                  final selecionado =
                      item.toLowerCase() == widget.valorSelecionado.trim().toLowerCase();
                  final subtitulo = widget.subtituloOpcao?.call(item);
                  final icone = widget.iconeOpcao?.call(item);

                  return InkWell(
                    onTap: () => widget.aoSelecionar(item),
                    child: Container(
                      height: alturaItem,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: selecionado
                          ? AppColors.goldenPollen.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          if (icone != null) ...[
                            Icon(
                              icone,
                              size: 17,
                              color: selecionado ? AppColors.goldenPollen : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: subtitulo != null && subtitulo.isNotEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              selecionado ? FontWeight.bold : FontWeight.w500,
                                          color: selecionado ? AppColors.goldenPollen : null,
                                        ),
                                      ),
                                      Text(
                                        subtitulo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  )
                                : Text(
                                    item,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          selecionado ? FontWeight.bold : FontWeight.normal,
                                      color: selecionado ? AppColors.goldenPollen : null,
                                    ),
                                  ),
                          ),
                          if (selecionado)
                            const Icon(Icons.check_circle, size: 17, color: AppColors.goldenPollen),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FORMULÁRIO DE VEÍCULO (COM BLOQUINHO DE 5 OPÇÕES E FIPE AUTOMÁTICA)
// ==========================================
class _VehicleFormSheet extends StatefulWidget {
  final Vehicle? existing;
  final VehicleRepository repo;

  const _VehicleFormSheet({this.existing, required this.repo});

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fipe = FipeService();

  late VehicleType _type;
  late VehiclePropulsion _propulsion;
  bool _manualPropulsionOverride = false;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _plate;
  late final TextEditingController _km;
  late final TextEditingController _tankCapacity;
  String _transmission = 'Manual';
  bool _loading = false;

  List<FipeItem> _fipeBrands = [];
  List<FipeItem> _fipeModels = [];
  List<FipeItem> _fipeYears = [];
  FipeItem? _matchedFipeBrand;
  FipeItem? _matchedFipeModel;
  FipeResult? _autoFipeResult;
  bool _loadingFipeModels = false;
  bool _loadingFipePrice = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? VehicleType.carro;
    _propulsion = e?.propulsion ?? VehiclePropulsion.combustao;
    _brand = TextEditingController(text: e?.brand ?? '');
    _model = TextEditingController(text: e?.model ?? '');
    _year = TextEditingController(text: e?.year ?? '');
    _plate = TextEditingController(text: e?.plate ?? '');
    _km = TextEditingController(text: e != null ? '${e.currentKm}' : '0');
    _tankCapacity = TextEditingController(
      text: (e != null && e.tankCapacity > 0) ? '${e.tankCapacity}' : '',
    );
    _transmission = (e != null && e.transmission.isNotEmpty)
        ? (e.transmission == 'Manual' || e.transmission == 'Automático'
            ? e.transmission
            : 'Automático')
        : 'Manual';
    _plate.addListener(() => setState(() {}));
    _loadFipeBrandsForType(_type, initialBrand: _brand.text, initialModel: _model.text);
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    _km.dispose();
    _tankCapacity.dispose();
    super.dispose();
  }

  FipeItem? _findBestFipeMatch(List<FipeItem> list, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty || list.isEmpty) return null;
    for (final item in list) {
      if (item.name.toLowerCase() == clean) return item;
    }
    for (final item in list) {
      if (item.name.toLowerCase().startsWith(clean) ||
          clean.startsWith(item.name.toLowerCase())) {
        return item;
      }
    }
    for (final item in list) {
      if (item.name.toLowerCase().contains(clean) ||
          clean.contains(item.name.toLowerCase())) {
        return item;
      }
    }
    return null;
  }

  Future<void> _loadFipeBrandsForType(
    VehicleType type, {
    String? initialBrand,
    String? initialModel,
  }) async {
    try {
      final list = await _fipe.brands(type);
      if (!mounted || _type != type) return;
      setState(() => _fipeBrands = list);
      if (initialBrand != null && initialBrand.trim().isNotEmpty) {
        await _loadFipeModelsForBrandName(initialBrand.trim(), initialModel: initialModel);
      }
    } catch (_) {
      // Caso esteja offline, o catálogo local (CatalogoVeiculos) continua funcionando normalmente.
    }
  }

  Future<void> _loadFipeModelsForBrandName(String brandName, {String? initialModel}) async {
    if (brandName.trim().isEmpty || _fipeBrands.isEmpty) {
      setState(() {
        _matchedFipeBrand = null;
        _fipeModels = [];
      });
      return;
    }
    final match = _findBestFipeMatch(_fipeBrands, brandName);
    if (match == null) {
      setState(() {
        _matchedFipeBrand = null;
        _fipeModels = [];
      });
      return;
    }
    _matchedFipeBrand = match;
    setState(() => _loadingFipeModels = true);
    try {
      final models = await _fipe.models(_type, match.code);
      if (mounted) {
        setState(() => _fipeModels = models);
        final modelToLookup = initialModel ?? _model.text.trim();
        if (modelToLookup.isNotEmpty) {
          await _tryAutoLookupFipe(modelToLookup);
        }
      }
    } catch (_) {
      // Ignora falha de rede e mantém catálogo local
    } finally {
      if (mounted) setState(() => _loadingFipeModels = false);
    }
  }

  /// Quando o usuário escolhe ou digita o modelo, busca automaticamente os anos e o preço na Tabela FIPE!
  Future<void> _tryAutoLookupFipe(String modelName) async {
    final brandItem = _matchedFipeBrand ?? _findBestFipeMatch(_fipeBrands, _brand.text);
    if (brandItem == null || _fipeModels.isEmpty || modelName.trim().isEmpty) return;

    final modelItem = _findBestFipeMatch(_fipeModels, modelName);
    if (modelItem == null) return;

    _matchedFipeModel = modelItem;
    setState(() => _loadingFipePrice = true);
    try {
      final years = await _fipe.years(_type, brandItem.code, modelItem.code);
      if (!mounted) return;
      setState(() => _fipeYears = years);
      if (years.isEmpty) return;

      final typedYear = _year.text.trim();
      FipeItem selectedYear = years.first;
      if (typedYear.isNotEmpty) {
        final found = years.cast<FipeItem?>().firstWhere(
              (y) => y != null && y.name.contains(typedYear),
              orElse: () => null,
            );
        if (found != null) selectedYear = found;
      } else {
        // Preenche automaticamente o ano com o ano do modelo FIPE se estiver em branco
        final matchDigits = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(selectedYear.name);
        if (matchDigits != null) {
          _year.text = matchDigits.group(0)!;
        }
      }

      final price = await _fipe.price(_type, brandItem.code, modelItem.code, selectedYear.code);
      if (mounted) {
        setState(() => _autoFipeResult = price);
      }
    } catch (_) {
      // Ignora silenciosamente falhas de rede na consulta automática
    } finally {
      if (mounted) setState(() => _loadingFipePrice = false);
    }
  }

  Future<void> _onYearSelectedOrChanged(String yearText) async {
    final brandItem = _matchedFipeBrand ?? _findBestFipeMatch(_fipeBrands, _brand.text);
    final modelItem = _matchedFipeModel ?? _findBestFipeMatch(_fipeModels, _model.text);
    if (brandItem == null || modelItem == null || _fipeYears.isEmpty) return;

    final foundYear = _fipeYears.cast<FipeItem?>().firstWhere(
          (y) => y != null && y.name.toLowerCase().contains(yearText.trim().toLowerCase()),
          orElse: () => null,
        );
    if (foundYear == null) return;

    setState(() => _loadingFipePrice = true);
    try {
      final price = await _fipe.price(_type, brandItem.code, modelItem.code, foundYear.code);
      if (mounted) {
        setState(() => _autoFipeResult = price);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingFipePrice = false);
    }
  }

  List<String> get _availableBrands {
    final local = CatalogoVeiculos.marcasPara(_type);
    final set = <String>{...local};
    for (final b in _fipeBrands) {
      if (!set.any((x) => x.toLowerCase() == b.name.toLowerCase())) {
        set.add(b.name);
      }
    }
    return set.toList();
  }

  List<String> get _availableModelsForCurrentBrand {
    final brandText = _brand.text.trim();
    final local = CatalogoVeiculos.modelosPara(_type, brandText);
    final set = <String>{...local};
    for (final m in _fipeModels) {
      if (!set.any((x) => x.toLowerCase() == m.name.toLowerCase())) {
        set.add(m.name);
      }
    }
    return set.toList();
  }

  void _autoDetectPropulsion(String brand, String model) {
    final inferred = Vehicle.inferirPropulsao(brand, model);
    if (!_manualPropulsionOverride || inferred != VehiclePropulsion.combustao) {
      _propulsion = inferred;
      if (inferred != VehiclePropulsion.combustao) {
        _transmission = 'Automático';
      }
    }
  }

  void _selectBrand(String brand) {
    final previousBrand = _brand.text.trim();
    setState(() {
      _brand.text = brand;
      if (previousBrand.toLowerCase() != brand.trim().toLowerCase()) {
        final modelsOfNewBrand = CatalogoVeiculos.modelosPara(_type, brand);
        if (_model.text.trim().isNotEmpty &&
            !modelsOfNewBrand.any((m) => m.toLowerCase() == _model.text.trim().toLowerCase())) {
          _model.clear();
        }
        _fipeModels = [];
        _fipeYears = [];
        _autoFipeResult = null;
      }
      _autoDetectPropulsion(brand, _model.text);
    });
    _loadFipeModelsForBrandName(brand);
  }

  void _selectModel(String model) {
    setState(() {
      _model.text = model;
      if (_brand.text.trim().isEmpty) {
        final detectedBrand = CatalogoVeiculos.encontrarMarcaDoModelo(_type, model);
        if (detectedBrand != null) {
          _brand.text = detectedBrand;
          _loadFipeModelsForBrandName(detectedBrand, initialModel: model);
        }
      }
      _autoDetectPropulsion(_brand.text, model);
    });
    _tryAutoLookupFipe(model);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final String resolvedTransmission;
      if (_type == VehicleType.moto) {
        resolvedTransmission = '';
      } else if (_propulsion == VehiclePropulsion.eletrico) {
        resolvedTransmission = 'Redutor Direto (Elétrico)';
      } else {
        resolvedTransmission = _transmission;
      }

      final fipeCode = _autoFipeResult?.code ?? widget.existing?.fipeCode ?? '';
      final fipeValue = _autoFipeResult?.value ?? widget.existing?.fipeValue ?? '';
      final fipeReference = _autoFipeResult?.reference ?? widget.existing?.fipeReference ?? '';

      final vehicle = Vehicle(
        id: widget.existing?.id ?? '',
        type: _type,
        propulsion: _propulsion,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: _year.text.trim(),
        plate: _plate.text.trim().toUpperCase(),
        currentKm: int.tryParse(_km.text.trim()) ?? 0,
        transmission: resolvedTransmission,
        fipeCode: fipeCode,
        fipeValue: fipeValue,
        fipeReference: fipeReference,
        tankCapacity: parseNumber(_tankCapacity.text.trim()) ?? 0.0,
        ipvaDueMonth: widget.existing?.ipvaDueMonth,
        ipvaPaid: widget.existing?.ipvaPaid ?? false,
        ipvaAmount: widget.existing?.ipvaAmount,
        licensingPaid: widget.existing?.licensingPaid ?? false,
        insuranceCompany: widget.existing?.insuranceCompany ?? '',
        insurancePolicy: widget.existing?.insurancePolicy ?? '',
        insurancePhone: widget.existing?.insurancePhone ?? '',
        insuranceExpiryDate: widget.existing?.insuranceExpiryDate,
        lastTireRotationKm: widget.existing?.lastTireRotationKm,
        tireRotationIntervalKm: widget.existing?.tireRotationIntervalKm ?? 10000,
      );

      if (widget.existing == null) {
        await widget.repo.add(vehicle);
      } else {
        await widget.repo.update(vehicle);
      }

      if (mounted) {
        Navigator.pop(context);
        showMessage(
          context,
          _autoFipeResult != null
              ? 'Veículo e valor Tabela FIPE (${_autoFipeResult!.value}) salvos com sucesso!'
              : 'Veículo salvo com sucesso!',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao salvar veículo: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final brandsList = _availableBrands;
    final modelsForBrand = _availableModelsForCurrentBrand;
    final isElectric = _propulsion == VehiclePropulsion.eletrico;
    final isHybrid = _propulsion == VehiclePropulsion.hibrido;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador visual de arraste no topo
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'Cadastrar Veículo' : 'Editar Veículo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<VehicleType>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(
                    value: VehicleType.carro,
                    label: Text('Carro', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.directions_car, size: 18),
                  ),
                  ButtonSegment(
                    value: VehicleType.moto,
                    label: Text('Moto', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.two_wheeler, size: 18),
                  ),
                  ButtonSegment(
                    value: VehicleType.caminhao,
                    label: Text('Caminhão', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.local_shipping, size: 18),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  final nextType = set.first;
                  if (nextType == _type) return;
                  setState(() {
                    _type = nextType;
                    if (widget.existing == null) {
                      _brand.clear();
                      _model.clear();
                    }
                    _fipeBrands = [];
                    _fipeModels = [];
                    _fipeYears = [];
                    _autoFipeResult = null;
                  });
                  _loadFipeBrandsForType(nextType);
                },
              ),
              const SizedBox(height: 12),

              // SELETOR DE MOTORIZAÇÃO (COMBUSTÃO / HÍBRIDO / ELÉTRICO) SEM QUEBRA DE TEXTO
              const Text(
                'Motorização / Energia:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              SegmentedButton<VehiclePropulsion>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(
                    value: VehiclePropulsion.combustao,
                    label: Text('Combustão', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.local_gas_station, size: 16),
                  ),
                  ButtonSegment(
                    value: VehiclePropulsion.hibrido,
                    label: Text('Híbrido', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.electric_car, size: 16),
                  ),
                  ButtonSegment(
                    value: VehiclePropulsion.eletrico,
                    label: Text('Elétrico', maxLines: 1, softWrap: false),
                    icon: Icon(Icons.ev_station, size: 16),
                  ),
                ],
                selected: {_propulsion},
                onSelectionChanged: (set) {
                  setState(() {
                    _manualPropulsionOverride = true;
                    _propulsion = set.first;
                    if (_propulsion != VehiclePropulsion.combustao) {
                      _transmission = 'Automático';
                    }
                  });
                },
              ),
              if (isElectric || isHybrid) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.ev_station, color: AppColors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isElectric
                              ? 'Modo 100% Elétrico ativo: recargas em kWh, eficiência em km/kWh, catálogo de manutenção EV e isenção de rodízio.'
                              : 'Modo Híbrido ativo: suporta Combustível (L) e Recarga Elétrica (kWh), alertas do sistema híbrido e isenção de rodízio.',
                          style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // CAMPO DE MARCA + BLOQUINHO DE 5 OPÇÕES ROLÁVEL E FILTRÁVEL
              TextFormField(
                controller: _brand,
                decoration: InputDecoration(
                  labelText: 'Marca (digite para filtrar ou escolha abaixo)',
                  prefixIcon: const Icon(Icons.business),
                  hintText: _type == VehicleType.caminhao
                      ? 'Ex: Scania, Volvo, Volkswagen, BYD'
                      : (_type == VehicleType.moto
                          ? 'Ex: Honda, Yamaha, Voltz, Watts'
                          : 'Ex: Volkswagen, BYD, GWM, Toyota'),
                  suffixIcon: _brand.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Limpar marca',
                          onPressed: () {
                            setState(() {
                              _brand.clear();
                              _model.clear();
                              _fipeModels = [];
                              _fipeYears = [];
                              _autoFipeResult = null;
                            });
                          },
                        )
                      : null,
                ),
                validator: (v) => Validators.required(v, 'Marca'),
                onChanged: (val) {
                  _loadFipeModelsForBrandName(val);
                  setState(() => _autoDetectPropulsion(val, _model.text));
                },
              ),
              _CaixaOpcoesRolavel(
                opcoes: brandsList,
                valorSelecionado: _brand.text,
                filtroTexto: _brand.text,
                rotuloCabecalho: 'Role para escolher a Marca (5 por vez)',
                aoSelecionar: _selectBrand,
              ),
              const SizedBox(height: 14),

              // CAMPO DE MODELO + BLOQUINHO DE 5 OPÇÕES ROLÁVEL E FILTRÁVEL
              TextFormField(
                controller: _model,
                decoration: InputDecoration(
                  labelText: _brand.text.trim().isNotEmpty
                      ? 'Modelo — ${_brand.text.trim()} (digite ou role abaixo)'
                      : 'Modelo (digite para filtrar ou role abaixo)',
                  prefixIcon: Icon(
                    _type == VehicleType.caminhao
                        ? Icons.local_shipping
                        : (_type == VehicleType.moto ? Icons.two_wheeler : Icons.directions_car_filled),
                  ),
                  hintText: _type == VehicleType.caminhao
                      ? 'Ex: FH 540, e-Delivery, Actros'
                      : (_type == VehicleType.moto
                          ? 'Ex: CG 160 Titan, EVS, Fazer 250'
                          : 'Ex: Gol, Dolphin, Corolla Hybrid'),
                  suffixIcon: _loadingFipeModels
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_model.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Limpar modelo',
                              onPressed: () {
                                setState(() {
                                  _model.clear();
                                  _fipeYears = [];
                                  _autoFipeResult = null;
                                });
                              },
                            )
                          : null),
                ),
                validator: (v) => Validators.required(v, 'Modelo'),
                onChanged: (val) {
                  setState(() => _autoDetectPropulsion(_brand.text, val));
                  _tryAutoLookupFipe(val);
                },
              ),
              if (modelsForBrand.isNotEmpty)
                _CaixaOpcoesRolavel(
                  opcoes: modelsForBrand,
                  valorSelecionado: _model.text,
                  filtroTexto: _model.text,
                  rotuloCabecalho: _brand.text.trim().isNotEmpty
                      ? 'Modelos de ${_brand.text.trim()} (role ou digite)'
                      : 'Modelos disponíveis (role ou digite)',
                  aoSelecionar: _selectModel,
                ),

              // CARD AUTOMÁTICO DA TABELA FIPE ASSIM QUE ESCOLHE O MODELO
              if (_loadingFipePrice) ...[
                const SizedBox(height: 10),
                Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Buscando valor automático na Tabela FIPE...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ] else if (_autoFipeResult != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.goldenPollen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.goldenPollen.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.request_quote, color: AppColors.goldenPollen, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tabela FIPE vinculada automaticamente: ${_autoFipeResult!.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Código ${_autoFipeResult!.code} • Ref: ${_autoFipeResult!.reference}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _year,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.year,
                      onChanged: (val) {
                        if (val.trim().length == 4) {
                          _onYearSelectedOrChanged(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _km,
                      label: 'Km Atual',
                      icon: Icons.speed,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.number(v, field: 'Quilometragem'),
                    ),
                  ),
                ],
              ),
              if (_fipeYears.isNotEmpty) ...[
                _CaixaOpcoesRolavel(
                  opcoes: _fipeYears.map((y) => y.name).toList(),
                  valorSelecionado: _year.text,
                  filtroTexto: '',
                  rotuloCabecalho: 'Anos / Versões na Tabela FIPE (toque para atualizar o preço)',
                  aoSelecionar: (yearLabel) {
                    final matchDigits = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(yearLabel);
                    setState(() {
                      _year.text = matchDigits != null ? matchDigits.group(0)! : yearLabel.split(' ').first;
                    });
                    _onYearSelectedOrChanged(yearLabel);
                  },
                ),
              ],
              const SizedBox(height: 12),
              AppTextField(
                controller: _tankCapacity,
                label: isElectric
                    ? 'Capacidade da Bateria (kWh - opcional)'
                    : 'Capacidade do Tanque (Litros - opcional)',
                icon: isElectric ? Icons.battery_charging_full : Icons.local_gas_station,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: isElectric
                    ? (_type == VehicleType.caminhao
                        ? 'Ex: 250 (kWh)'
                        : (_type == VehicleType.moto ? 'Ex: 3.5 (kWh)' : 'Ex: 44.9 ou 60.5 (kWh)'))
                    : (_type == VehicleType.caminhao
                        ? 'Ex: 300'
                        : (_type == VehicleType.moto ? 'Ex: 14' : 'Ex: 50')),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _plate,
                label: 'Placa (opcional)',
                icon: Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
              ),
              if (_plate.text.trim().isNotEmpty) ...[
                Builder(builder: (_) {
                  final rodizio = RodizioHelper.getInfo(
                    _plate.text.trim(),
                    type: _type,
                    propulsion: _propulsion,
                  );
                  if (_type == VehicleType.moto) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Motocicletas são isentas do rodízio municipal.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }
                  if (isElectric || isHybrid) {
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.eco, size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rodízio Municipal: ${rodizio.dayName} — ${rodizio.timeRange}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (rodizio.lastDigit == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Digite os números da placa para ver o dia do rodízio.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.goldenPollen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.goldenPollen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: AppColors.goldenPollen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dia de Rodízio: ${rodizio.dayName} (${rodizio.timeRange})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (_type != VehicleType.moto && !isElectric) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _transmission,
                  decoration: const InputDecoration(
                    labelText: 'Câmbio',
                    prefixIcon: Icon(Icons.settings),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Manual', child: Text('Manual')),
                    DropdownMenuItem(value: 'Automático', child: Text('Automático')),
                  ],
                  onChanged: (val) => setState(() => _transmission = val!),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      label: 'Salvar Veículo',
                      loading: _loading,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// FORMULÁRIO DE MANUTENÇÃO
// ==========================================
class _MaintenanceFormSheet extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Maintenance? existing;
  final String? initialVehicleId;
  final MaintenanceRepository mRepo;
  final VehicleRepository vRepo;

  const _MaintenanceFormSheet({
    required this.vehicles,
    this.existing,
    this.initialVehicleId,
    required this.mRepo,
    required this.vRepo,
  });

  @override
  State<_MaintenanceFormSheet> createState() => _MaintenanceFormSheetState();
}

class _MaintenanceFormSheetState extends State<_MaintenanceFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedVehicleId;
  late String _category;
  late final TextEditingController _categoryFilterCtrl;
  late DateTime _date;
  late final TextEditingController _km;
  late final TextEditingController _cost;
  late final TextEditingController _notes;

  bool _scheduleNext = false;
  late final TextEditingController _nextKm;
  DateTime? _nextDate;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final defaultVehicleId = (widget.initialVehicleId != null &&
            widget.vehicles.any((v) => v.id == widget.initialVehicleId))
        ? widget.initialVehicleId!
        : widget.vehicles.first.id;
    _selectedVehicleId = e?.vehicleId ?? defaultVehicleId;

    final vehicle = widget.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => widget.vehicles.first,
    );
    final categories = MaintenanceCatalog.categoriesFor(vehicle);

    _category = (e != null && categories.contains(e.category)) ? e.category : categories.first;
    _categoryFilterCtrl = TextEditingController(text: _category);
    _date = e?.date ?? DateTime.now();
    _km = TextEditingController(text: '${e?.km ?? vehicle.currentKm}');
    _cost = TextEditingController(text: e != null ? '${e.cost}' : '');
    _notes = TextEditingController(text: e?.notes ?? '');

    _scheduleNext = (e?.nextKm != null || e?.nextDate != null);
    _nextKm = TextEditingController(text: e?.nextKm != null ? '${e!.nextKm}' : '');
    _nextDate = e?.nextDate;
  }

  @override
  void dispose() {
    _categoryFilterCtrl.dispose();
    _km.dispose();
    _cost.dispose();
    _notes.dispose();
    _nextKm.dispose();
    super.dispose();
  }

  void _onVehicleChanged(String? val) {
    if (val == null || val == _selectedVehicleId) return;
    final newVehicle = widget.vehicles.firstWhere(
      (v) => v.id == val,
      orElse: () => widget.vehicles.first,
    );
    final newCategories = MaintenanceCatalog.categoriesFor(newVehicle);

    setState(() {
      _selectedVehicleId = val;
      if (widget.existing == null) {
        _km.text = '${newVehicle.currentKm}';
      }
      if (!newCategories.contains(_category)) {
        _category = newCategories.first;
        _categoryFilterCtrl.text = _category;
      }
      if (_scheduleNext) {
        final item = MaintenanceCatalog.find(_category);
        if (item != null && item.intervalKm != null) {
          _nextKm.text = '${newVehicle.currentKm + item.intervalKm!}';
        } else if (widget.existing == null) {
          _nextKm.clear();
        }
      }
    });
  }

  void _onCategoryChanged(String? val) {
    if (val == null || val.trim().isEmpty) return;
    setState(() {
      _category = val.trim();
      _categoryFilterCtrl.text = _category;
      final item = MaintenanceCatalog.find(_category);
      if (item != null) {
        final currentKm = int.tryParse(_km.text) ?? 0;
        if (item.intervalKm != null) {
          _nextKm.text = '${currentKm + item.intervalKm!}';
          _scheduleNext = true;
        }
        if (item.intervalMonths != null) {
          _nextDate = DateTime(_date.year, _date.month + item.intervalMonths!, _date.day);
          _scheduleNext = true;
        }
      }
    });
  }

  String _categorySubtitle(String catName) {
    final item = MaintenanceCatalog.find(catName);
    if (item == null) return '';
    final parts = <String>[];
    if (item.intervalKm != null) parts.add('A cada ${formatKm(item.intervalKm!)}');
    if (item.intervalMonths != null) parts.add('A cada ${item.intervalMonths} meses');
    return parts.join(' • ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final kmVal = int.tryParse(_km.text.trim()) ?? 0;
      final costVal = parseNumber(_cost.text.trim()) ?? 0;
      final nextKmVal = _scheduleNext ? int.tryParse(_nextKm.text.trim()) : null;
      final chosenCategory = _categoryFilterCtrl.text.trim().isNotEmpty
          ? _categoryFilterCtrl.text.trim()
          : _category;

      final maintenance = Maintenance(
        id: widget.existing?.id ?? '',
        vehicleId: _selectedVehicleId,
        category: chosenCategory,
        date: _date,
        km: kmVal,
        cost: costVal,
        notes: _notes.text.trim(),
        nextKm: nextKmVal,
        nextDate: _scheduleNext ? _nextDate : null,
      );

      if (widget.existing == null) {
        await widget.mRepo.add(maintenance);
      } else {
        await widget.mRepo.update(maintenance);
      }

      final vehicle = widget.vehicles.firstWhere((v) => v.id == _selectedVehicleId);
      await widget.vRepo.updateKmIfGreater(vehicle, kmVal);

      if (mounted) {
        Navigator.pop(context);
        showMessage(context, 'Manutenção salva com sucesso!');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao salvar manutenção: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final vehicle = widget.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => widget.vehicles.first,
    );
    final categories = MaintenanceCatalog.categoriesFor(vehicle);
    final effectiveCategory = categories.contains(_category) ? _category : categories.first;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'Nova Manutenção' : 'Editar Manutenção',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('maint_vehicle_$_selectedVehicleId'),
                initialValue: _selectedVehicleId,
                decoration: const InputDecoration(labelText: 'Veículo', prefixIcon: Icon(Icons.directions_car)),
                items: widget.vehicles
                    .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                    .toList(),
                onChanged: _onVehicleChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryFilterCtrl,
                decoration: InputDecoration(
                  labelText: 'Serviço / Categoria (digite ou role abaixo)',
                  hintText: 'Ex: Troca de óleo, Pneus, Freio...',
                  prefixIcon: Icon(MaintenanceCatalog.find(effectiveCategory)?.icon ?? Icons.build),
                  suffixIcon: _categoryFilterCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Limpar filtro para ver todos',
                          onPressed: () => setState(() => _categoryFilterCtrl.clear()),
                        )
                      : null,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Selecione ou digite um serviço' : null,
                onChanged: (val) => setState(() {}),
              ),
              _CaixaOpcoesRolavel(
                opcoes: categories,
                valorSelecionado: effectiveCategory,
                filtroTexto: _categoryFilterCtrl.text,
                rotuloCabecalho: 'Serviços compatíveis (role 5 por vez ou digite acima)',
                iconeOpcao: (cat) => MaintenanceCatalog.find(cat)?.icon ?? Icons.build,
                subtituloOpcao: _categorySubtitle,
                aoSelecionar: _onCategoryChanged,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.goldenPollen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldenPollen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speed, color: AppColors.goldenPollen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Último odômetro de ${vehicle.name}:',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(formatKm(vehicle.currentKm), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _km.text = '${vehicle.currentKm}'),
                      child: const Text('Usar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _km,
                      label: 'Km Realizado',
                      icon: Icons.speed,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.number(v, field: 'Quilometragem'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _cost,
                      label: r'Valor (R$)',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => Validators.number(v, field: 'Valor'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text('Data: ${formatDate(_date)}'),
                trailing: TextButton(
                  child: const Text('Alterar'),
                  onPressed: () async {
                    final picked = await pickDate(context, _date);
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
              AppTextField(
                controller: _notes,
                label: 'Observações (opcional)',
                icon: Icons.notes,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Agendar próximo serviço'),
                value: _scheduleNext,
                onChanged: (val) => setState(() => _scheduleNext = val),
              ),
              if (_scheduleNext) ...[
                AppTextField(
                  controller: _nextKm,
                  label: 'Próximo Km (opcional)',
                  icon: Icons.add_road,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(_nextDate != null ? 'Próxima Data: ${formatDate(_nextDate!)}' : 'Selecionar Próxima Data'),
                  trailing: TextButton(
                    child: const Text('Escolher Data'),
                    onPressed: () async {
                      final picked = await pickDate(context, _nextDate ?? DateTime.now().add(const Duration(days: 180)));
                      if (picked != null) setState(() => _nextDate = picked);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      label: 'Salvar Manutenção',
                      loading: _loading,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// FORMULÁRIO DE ABASTECIMENTO
// ==========================================
class _FuelFormSheet extends StatefulWidget {
  final List<Vehicle> vehicles;
  final FuelRecord? existing;
  final String? initialVehicleId;
  final List<FuelRecord> fuels;
  final FuelRepository fRepo;
  final VehicleRepository vRepo;

  const _FuelFormSheet({
    required this.vehicles,
    this.existing,
    this.initialVehicleId,
    this.fuels = const [],
    required this.fRepo,
    required this.vRepo,
  });

  @override
  State<_FuelFormSheet> createState() => _FuelFormSheetState();
}

class _FuelFormSheetState extends State<_FuelFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nearbyService = ServicoPostosProximos();

  late String _selectedVehicleId;
  late String _selectedFuelType;
  late DateTime _date;
  late final TextEditingController _km;
  late final TextEditingController _pricePerUnit;
  late final TextEditingController _liters;
  late final TextEditingController _price;
  late final TextEditingController _gasStation;

  bool _isFullTank = true;
  bool _isCalculating = false;
  bool _loading = false;

  List<PostoProximo> _nearbyStations = [];
  bool _loadingNearbyStations = false;

  static const List<String> _stationSuggestions = [
    'Posto Shell',
    'Posto Ipiranga',
    'Petrobras BR',
    'Posto Ale',
    'Posto Graal',
    'Posto Rodoil',
    'Auto Posto Central',
  ];

  static const List<String> _evStationSuggestions = [
    'Wallbox Residencial',
    'Tupinambá',
    'Shell Recharge',
    'Zletric',
    'WeCharge',
    'Volvo Recharge',
    'Eletroposto Shopping',
    'Carregador Portátil',
  ];

  String _defaultFuelTypeForVehicle(Vehicle v) {
    final allowed = FuelTypes.forVehicle(v);
    if (v.isElectric) return FuelTypes.eletricidade;
    final lastRecord = widget.fuels.cast<FuelRecord?>().firstWhere(
          (f) => f != null && f.vehicleId == v.id,
          orElse: () => null,
        );
    if (lastRecord != null && allowed.contains(lastRecord.fuelType)) {
      return lastRecord.fuelType;
    }
    if (v.isTruck) {
      return allowed.contains(FuelTypes.diesel) ? FuelTypes.diesel : allowed.first;
    }
    return allowed.first;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final defaultVehicleId = (widget.initialVehicleId != null &&
            widget.vehicles.any((v) => v.id == widget.initialVehicleId))
        ? widget.initialVehicleId!
        : widget.vehicles.first.id;
    _selectedVehicleId = e?.vehicleId ?? defaultVehicleId;

    final vehicle = widget.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => widget.vehicles.first,
    );

    _selectedFuelType = e?.fuelType ?? _defaultFuelTypeForVehicle(vehicle);
    _date = e?.date ?? DateTime.now();
    _km = TextEditingController(text: '${e?.km ?? vehicle.currentKm}');
    _liters = TextEditingController(text: e != null ? '${e.liters}' : '');
    _price = TextEditingController(text: e != null ? '${e.totalPrice}' : '');

    final initialPpu = (e != null && e.liters > 0)
        ? (e.totalPrice / e.liters).toStringAsFixed(2)
        : '';
    _pricePerUnit = TextEditingController(text: initialPpu);
    _gasStation = TextEditingController(text: e?.gasStation ?? '');
    _isFullTank = e?.isFullTank ?? true;

    _km.addListener(() => setState(() {}));
    _gasStation.addListener(() => setState(() {}));
    _fetchNearbyStations();
  }

  Future<void> _fetchNearbyStations() async {
    final isEv = _selectedFuelType == FuelTypes.eletricidade;
    setState(() => _loadingNearbyStations = true);
    try {
      final list = await _nearbyService.buscarPostosProximos(eletrico: isEv);
      if (mounted) {
        setState(() => _nearbyStations = list);
      }
    } catch (_) {
      // Silencioso: mantém sugestões locais e histórico
    } finally {
      if (mounted) {
        setState(() => _loadingNearbyStations = false);
      }
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _pricePerUnit.dispose();
    _liters.dispose();
    _price.dispose();
    _gasStation.dispose();
    super.dispose();
  }

  void _onVehicleChanged(String? val) {
    if (val == null || val == _selectedVehicleId) return;
    final newVehicle = widget.vehicles.firstWhere(
      (x) => x.id == val,
      orElse: () => widget.vehicles.first,
    );
    final oldWasEv = _selectedFuelType == FuelTypes.eletricidade;
    setState(() {
      _selectedVehicleId = val;
      if (widget.existing == null) {
        _km.text = '${newVehicle.currentKm}';
        _selectedFuelType = _defaultFuelTypeForVehicle(newVehicle);
        _gasStation.clear();
      } else {
        final allowed = FuelTypes.forVehicle(newVehicle);
        if (!allowed.contains(_selectedFuelType)) {
          _selectedFuelType = _defaultFuelTypeForVehicle(newVehicle);
        }
      }
    });
    final newIsEv = _selectedFuelType == FuelTypes.eletricidade;
    if (oldWasEv != newIsEv) {
      _fetchNearbyStations();
    }
  }

  void _onPricePerUnitChanged(String val) {
    if (_isCalculating) return;
    final ppu = parseNumber(val);
    final total = parseNumber(_price.text.trim());
    final lts = parseNumber(_liters.text.trim());

    if (ppu != null && ppu > 0) {
      if (total != null && total > 0) {
        _isCalculating = true;
        _liters.text = (total / ppu).toStringAsFixed(2);
        _isCalculating = false;
      } else if (lts != null && lts > 0) {
        _isCalculating = true;
        _price.text = (ppu * lts).toStringAsFixed(2);
        _isCalculating = false;
      }
    }
    setState(() {});
  }

  void _onLitersChanged(String val) {
    if (_isCalculating) return;
    final lts = parseNumber(val);
    final ppu = parseNumber(_pricePerUnit.text.trim());
    final total = parseNumber(_price.text.trim());

    if (lts != null && lts > 0) {
      if (ppu != null && ppu > 0) {
        _isCalculating = true;
        _price.text = (ppu * lts).toStringAsFixed(2);
        _isCalculating = false;
      } else if (total != null && total > 0) {
        _isCalculating = true;
        _pricePerUnit.text = (total / lts).toStringAsFixed(2);
        _isCalculating = false;
      }
    }
    setState(() {});
  }

  void _onTotalPriceChanged(String val) {
    if (_isCalculating) return;
    final total = parseNumber(val);
    final ppu = parseNumber(_pricePerUnit.text.trim());
    final lts = parseNumber(_liters.text.trim());

    if (total != null && total > 0) {
      if (ppu != null && ppu > 0) {
        _isCalculating = true;
        _liters.text = (total / ppu).toStringAsFixed(2);
        _isCalculating = false;
      } else if (lts != null && lts > 0) {
        _isCalculating = true;
        _pricePerUnit.text = (total / lts).toStringAsFixed(2);
        _isCalculating = false;
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final kmVal = int.tryParse(_km.text.trim()) ?? 0;
      final litersVal = parseNumber(_liters.text.trim()) ?? 0;
      final priceVal = parseNumber(_price.text.trim()) ?? 0;
      final isEv = _selectedFuelType == FuelTypes.eletricidade;

      final record = FuelRecord(
        id: widget.existing?.id ?? '',
        vehicleId: _selectedVehicleId,
        fuelType: _selectedFuelType,
        date: _date,
        km: kmVal,
        liters: litersVal,
        totalPrice: priceVal,
        isFullTank: _isFullTank,
        gasStation: _gasStation.text.trim(),
      );

      if (widget.existing == null) {
        await widget.fRepo.add(record);
      } else {
        await widget.fRepo.update(record);
      }

      final vehicle = widget.vehicles.firstWhere((v) => v.id == _selectedVehicleId);
      final kmUpdated = kmVal > vehicle.currentKm;
      await widget.vRepo.updateKmIfGreater(vehicle, kmVal);

      if (mounted) {
        Navigator.pop(context);
        final actionWord = isEv ? 'Recarga elétrica salva' : 'Abastecimento salvo';
        if (kmUpdated) {
          showMessage(
            context,
            '$actionWord e odômetro do ${vehicle.name} atualizado para ${formatKm(kmVal)}!',
          );
        } else {
          showMessage(context, '$actionWord com sucesso!');
        }
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao salvar registro: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final vehicle = widget.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => widget.vehicles.first,
    );

    final allowedFuels = <String>{
      ...FuelTypes.forVehicle(vehicle),
      if (widget.existing != null) widget.existing!.fuelType,
    }.toList();
    if (!allowedFuels.contains(_selectedFuelType)) {
      _selectedFuelType = allowedFuels.first;
    }

    final isElectricFuel = _selectedFuelType == FuelTypes.eletricidade;
    final isGnv = _selectedFuelType == FuelTypes.gnv;
    final unitLabel = isElectricFuel ? 'kWh' : (isGnv ? 'm³' : 'L');
    final volumeLabel = isElectricFuel ? 'Carga (kWh)' : (isGnv ? 'Volume (m³)' : 'Volume (L)');
    final volumeName = isElectricFuel ? 'Energia em kWh' : (isGnv ? 'Volume em m³' : 'Litros');
    final consumptionUnitLabel = isElectricFuel ? 'km/kWh' : (isGnv ? 'km/m³' : 'km/l');

    // Monta lista de postos: 1) Postos próximos da localização, 2) Postos já visitados pelo usuário, 3) Sugestões padrão
    final visitedStations = <String>[];
    final visitedPriceMap = <String, String>{};
    for (final f in widget.fuels) {
      final st = f.gasStation.trim();
      if (st.isEmpty) continue;
      final fIsEv = f.fuelType == FuelTypes.eletricidade;
      if (fIsEv != isElectricFuel) continue;
      if (!visitedStations.any((x) => x.toLowerCase() == st.toLowerCase())) {
        visitedStations.add(st);
        if (f.liters > 0) {
          final ppu = f.totalPrice / f.liters;
          visitedPriceMap[st.toLowerCase()] =
              'Já visitado • Último: ${formatMoney(ppu)}/$unitLabel (${f.fuelType})';
        } else {
          visitedPriceMap[st.toLowerCase()] = 'Já visitado por você';
        }
      }
    }

    final nearbyMap = <String, PostoProximo>{};
    final combinedStationNames = <String>[];

    for (final p in _nearbyStations) {
      final n = p.nome.trim();
      if (n.isEmpty) continue;
      if (!combinedStationNames.any((x) => x.toLowerCase() == n.toLowerCase())) {
        combinedStationNames.add(n);
        nearbyMap[n.toLowerCase()] = p;
      }
    }
    for (final vSt in visitedStations) {
      if (!combinedStationNames.any((x) => x.toLowerCase() == vSt.toLowerCase())) {
        combinedStationNames.add(vSt);
      }
    }
    final fallbackSuggestions = isElectricFuel ? _evStationSuggestions : _stationSuggestions;
    for (final s in fallbackSuggestions) {
      if (!combinedStationNames.any((x) => x.toLowerCase() == s.toLowerCase())) {
        combinedStationNames.add(s);
      }
    }

    final currentVehicleKm = vehicle.currentKm;
    final enteredKm = int.tryParse(_km.text.trim()) ?? 0;
    final enteredVolume = parseNumber(_liters.text.trim()) ?? 0.0;
    final diffKm = enteredKm - currentVehicleKm;
    final bool showCalc = diffKm > 0 && enteredVolume > 0;
    final double? tripConsumption = showCalc ? diffKm / enteredVolume : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? (isElectricFuel ? 'Nova Recarga Elétrica' : 'Novo Abastecimento')
                          : (isElectricFuel ? 'Editar Recarga Elétrica' : 'Editar Abastecimento'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('fuel_vehicle_$_selectedVehicleId'),
                initialValue: _selectedVehicleId,
                decoration: InputDecoration(
                  labelText: 'Veículo',
                  prefixIcon: Icon(
                    vehicle.isTruck
                        ? Icons.local_shipping
                        : (vehicle.isMotorcycle ? Icons.two_wheeler : Icons.directions_car),
                  ),
                ),
                items: widget.vehicles
                    .map((v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            '${v.name}${v.isElectric ? " (Elétrico)" : (v.isHybrid ? " (Híbrido)" : "")}',
                          ),
                        ))
                    .toList(),
                onChanged: _onVehicleChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('fuel_type_${_selectedVehicleId}_$_selectedFuelType'),
                initialValue: _selectedFuelType,
                decoration: InputDecoration(
                  labelText: vehicle.isElectric
                      ? 'Fonte de Energia (Veículo 100% Elétrico)'
                      : (vehicle.isHybrid ? 'Energia / Combustível (Híbrido)' : 'Tipo de Combustível'),
                  prefixIcon: Icon(isElectricFuel ? Icons.ev_station : Icons.local_gas_station),
                ),
                items: allowedFuels
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t == FuelTypes.eletricidade ? 'Eletricidade (kWh)' : t),
                        ))
                    .toList(),
                onChanged: allowedFuels.length <= 1
                    ? null
                    : (val) {
                        if (val != null) {
                          final oldEv = _selectedFuelType == FuelTypes.eletricidade;
                          setState(() => _selectedFuelType = val);
                          final newEv = _selectedFuelType == FuelTypes.eletricidade;
                          if (oldEv != newEv) _fetchNearbyStations();
                        }
                      },
              ),
              const SizedBox(height: 14),

              // CARD DE ÚLTIMO ODÔMETRO REGISTRADO
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.goldenPollen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldenPollen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speed, color: AppColors.goldenPollen, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Último odômetro de ${vehicle.name}:',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(formatKm(currentVehicleKm), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    if (diffKm > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Text(
                          '+${formatKm(diffKm)} rodados',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() => _km.text = '$currentVehicleKm'),
                        child: const Text('Usar'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _km,
                label: 'Km Atual do Veículo',
                icon: Icons.speed,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.number(v, field: 'Quilometragem'),
              ),
              if (enteredKm <= currentVehicleKm && enteredKm > 0 && widget.existing == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Odômetro registrado: ${formatKm(currentVehicleKm)}. Digite a quilometragem atual.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 14),

              // CHAVE DE TANQUE COMPLETO / CARGA 100% DA BATERIA
              Card(
                elevation: 0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E24)
                    : Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _isFullTank
                        ? (isElectricFuel ? AppColors.success : AppColors.goldenPollen).withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                child: SwitchListTile(
                  value: _isFullTank,
                  activeThumbColor: isElectricFuel ? AppColors.success : AppColors.goldenPollen,
                  title: Row(
                    children: [
                      Icon(
                        isElectricFuel
                            ? (_isFullTank ? Icons.battery_charging_full : Icons.battery_4_bar)
                            : (_isFullTank ? Icons.local_gas_station : Icons.local_gas_station_outlined),
                        color: _isFullTank
                            ? (isElectricFuel ? AppColors.success : AppColors.goldenPollen)
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isElectricFuel ? 'Carga Completa (100% da Bateria)?' : 'Tanque Completo (Cheio)?',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    isElectricFuel
                        ? (_isFullTank
                            ? 'Sim — Permite calcular com precisão a eficiência real (km/kWh) deste trecho.'
                            : 'Não (Carga Parcial) — Os kWh e km acumulam até a próxima recarga de 100%.')
                        : (_isFullTank
                            ? 'Sim — Permite calcular com precisão o consumo real deste trecho.'
                            : 'Não (Parcial) — Litros e km acumulam até o próximo tanque cheio.'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onChanged: (val) => setState(() => _isFullTank = val),
                ),
              ),
              const SizedBox(height: 14),

              // CALCULADORA AUTOMÁTICA DE 3 CAMPOS (PREÇO/UNIDADE, VOLUME/CARGA, TOTAL R$)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldenPollen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldenPollen.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate, size: 18, color: AppColors.goldenPollen),
                        const SizedBox(width: 6),
                        Text(
                          isElectricFuel ? 'Calculadora de Recarga (kWh)' : 'Calculadora Automática',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.goldenPollen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Preencha 2 campos quaisquer e o 3º calcula na hora:',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pricePerUnit,
                            decoration: InputDecoration(
                              labelText: 'Preço/$unitLabel',
                              hintText: '0,00',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: _onPricePerUnitChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _liters,
                            decoration: InputDecoration(
                              labelText: volumeLabel,
                              hintText: '0,0',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => Validators.number(v, field: volumeName),
                            onChanged: _onLitersChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _price,
                            decoration: const InputDecoration(
                              labelText: r'Total (R$)',
                              hintText: '0,00',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => Validators.number(v, field: 'Valor'),
                            onChanged: _onTotalPriceChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CAMPO DE POSTO / ELETROPOSTO COM BLOQUINHO ROLÁVEL DE 5 OPÇÕES (POSTOS PRÓXIMOS + VISITADOS)
              TextFormField(
                controller: _gasStation,
                decoration: InputDecoration(
                  labelText: isElectricFuel
                      ? 'Eletroposto / Local de Recarga (opcional)'
                      : 'Posto de Combustível (opcional)',
                  hintText: isElectricFuel
                      ? 'Digite para filtrar ou escolha um eletroposto abaixo'
                      : 'Digite para filtrar ou escolha um posto próximo abaixo',
                  prefixIcon: Icon(isElectricFuel ? Icons.ev_station : Icons.storefront),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_gasStation.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Limpar campo',
                          onPressed: () => setState(() => _gasStation.clear()),
                        ),
                      IconButton(
                        icon: _loadingNearbyStations
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 18),
                        tooltip: 'Buscar postos perto de mim',
                        onPressed: _loadingNearbyStations ? null : _fetchNearbyStations,
                      ),
                    ],
                  ),
                ),
              ),
              _CaixaOpcoesRolavel(
                opcoes: combinedStationNames,
                valorSelecionado: _gasStation.text,
                filtroTexto: _gasStation.text,
                rotuloCabecalho: _loadingNearbyStations
                    ? 'Localizando postos próximos de você...'
                    : (_nearbyStations.isNotEmpty
                        ? 'Postos perto de você e visitados (role 5 por vez)'
                        : 'Postos visitados e sugeridos (role 5 por vez)'),
                iconeOpcao: (st) {
                  final key = st.toLowerCase();
                  if (nearbyMap.containsKey(key)) return Icons.near_me;
                  if (visitedPriceMap.containsKey(key)) return Icons.history;
                  return isElectricFuel ? Icons.ev_station : Icons.local_gas_station;
                },
                subtituloOpcao: (st) {
                  final key = st.toLowerCase();
                  final near = nearbyMap[key];
                  final visitedInfo = visitedPriceMap[key];
                  if (near != null && visitedInfo != null) {
                    return 'A ${near.rotuloDistancia} de você • $visitedInfo';
                  }
                  if (near != null) {
                    return 'Perto de você (${near.rotuloDistancia})${near.endereco.isNotEmpty ? " • ${near.endereco}" : ""}';
                  }
                  if (visitedInfo != null) {
                    return visitedInfo;
                  }
                  return '';
                },
                aoSelecionar: (selection) {
                  setState(() {
                    _gasStation.text = selection;
                  });
                },
              ),
              const SizedBox(height: 12),

              if (showCalc && tripConsumption != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldenPollen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.goldenPollen.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 18, color: AppColors.goldenPollen),
                          const SizedBox(width: 8),
                          Text(
                            isElectricFuel ? 'Resumo da Recarga Elétrica' : 'Resumo do Abastecimento',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.goldenPollen
                                  : AppColors.obsidian,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Odômetro anterior: ${formatKm(currentVehicleKm)} ➔ Novo: ${formatKm(enteredKm)} (+${formatKm(diffKm)})',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        '• ${isElectricFuel ? "Eficiência estimada desta recarga" : "Rendimento estimado deste abastecimento"}: ${formatNumber(tripConsumption, 1)} $consumptionUnitLabel',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '• A quilometragem do veículo será atualizada automaticamente.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text('Data: ${formatDate(_date)}'),
                trailing: TextButton(
                  child: const Text('Alterar'),
                  onPressed: () async {
                    final picked = await pickDate(context, _date);
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: LoadingButton(
                      label: isElectricFuel ? 'Salvar Recarga' : 'Salvar Abastecimento',
                      loading: _loading,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CONSULTA FIPE (COM AUTO-SELEÇÃO DO VEÍCULO E BLOQUINHO DE 5 OPÇÕES)
// ==========================================
class _FipeLookupSheet extends StatefulWidget {
  final Vehicle vehicle;
  final VehicleRepository repo;

  const _FipeLookupSheet({required this.vehicle, required this.repo});

  @override
  State<_FipeLookupSheet> createState() => _FipeLookupSheetState();
}

class _FipeLookupSheetState extends State<_FipeLookupSheet> {
  final _fipe = FipeService();

  List<FipeItem> _brands = [];
  List<FipeItem> _models = [];
  List<FipeItem> _years = [];

  FipeItem? _selectedBrand;
  FipeItem? _selectedModel;
  FipeItem? _selectedYear;
  FipeResult? _result;

  late final TextEditingController _brandFilterCtrl;
  late final TextEditingController _modelFilterCtrl;
  late final TextEditingController _yearFilterCtrl;

  bool _loadingBrands = false;
  bool _loadingModels = false;
  bool _loadingYears = false;
  bool _loadingPrice = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _brandFilterCtrl = TextEditingController(text: widget.vehicle.brand);
    _modelFilterCtrl = TextEditingController(text: widget.vehicle.model);
    _yearFilterCtrl = TextEditingController(text: widget.vehicle.year);
    _loadBrands(autoMatch: true);
  }

  @override
  void dispose() {
    _brandFilterCtrl.dispose();
    _modelFilterCtrl.dispose();
    _yearFilterCtrl.dispose();
    super.dispose();
  }

  FipeItem? _findBestMatch(List<FipeItem> items, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty || items.isEmpty) return null;
    for (final item in items) {
      if (item.name.toLowerCase() == q) return item;
    }
    for (final item in items) {
      if (item.name.toLowerCase().startsWith(q) || q.startsWith(item.name.toLowerCase())) {
        return item;
      }
    }
    for (final item in items) {
      if (item.name.toLowerCase().contains(q) || q.contains(item.name.toLowerCase())) {
        return item;
      }
    }
    final firstWord = q.split(RegExp(r'\s+')).first;
    if (firstWord.length >= 2) {
      for (final item in items) {
        if (item.name.toLowerCase().contains(firstWord)) return item;
      }
    }
    return null;
  }

  Future<void> _loadBrands({bool autoMatch = false}) async {
    setState(() {
      _loadingBrands = true;
      _error = null;
    });
    try {
      final list = await _fipe.brands(widget.vehicle.type);
      if (!mounted) return;
      setState(() => _brands = list);

      if (autoMatch) {
        final matchedBrand = _findBestMatch(list, widget.vehicle.brand);
        if (matchedBrand != null) {
          _brandFilterCtrl.text = matchedBrand.name;
          await _loadModels(matchedBrand, autoMatch: true);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar marcas FIPE: $e');
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _loadModels(FipeItem brand, {bool autoMatch = false}) async {
    setState(() {
      _selectedBrand = brand;
      _brandFilterCtrl.text = brand.name;
      _selectedModel = null;
      _selectedYear = null;
      _models = [];
      _years = [];
      _result = null;
      _loadingModels = true;
      _error = null;
    });
    try {
      final list = await _fipe.models(widget.vehicle.type, brand.code);
      if (!mounted) return;
      setState(() => _models = list);

      if (autoMatch) {
        final matchedModel = _findBestMatch(list, widget.vehicle.model);
        if (matchedModel != null) {
          _modelFilterCtrl.text = matchedModel.name;
          await _loadYears(matchedModel, autoMatch: true);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar modelos: $e');
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _loadYears(FipeItem model, {bool autoMatch = false}) async {
    if (_selectedBrand == null) return;
    setState(() {
      _selectedModel = model;
      _modelFilterCtrl.text = model.name;
      _selectedYear = null;
      _years = [];
      _result = null;
      _loadingYears = true;
      _error = null;
    });
    try {
      final list = await _fipe.years(widget.vehicle.type, _selectedBrand!.code, model.code);
      if (!mounted) return;
      setState(() => _years = list);

      if (list.isNotEmpty) {
        final matchedYear = _findBestMatch(list, widget.vehicle.year) ?? list.first;
        _yearFilterCtrl.text = matchedYear.name;
        await _loadPrice(matchedYear);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar anos: $e');
    } finally {
      if (mounted) setState(() => _loadingYears = false);
    }
  }

  Future<void> _loadPrice(FipeItem year) async {
    if (_selectedBrand == null || _selectedModel == null) return;
    setState(() {
      _selectedYear = year;
      _yearFilterCtrl.text = year.name;
      _loadingPrice = true;
      _error = null;
    });
    try {
      final res = await _fipe.price(
        widget.vehicle.type,
        _selectedBrand!.code,
        _selectedModel!.code,
        year.code,
      );
      if (mounted) setState(() => _result = res);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao obter preço FIPE: $e');
    } finally {
      if (mounted) setState(() => _loadingPrice = false);
    }
  }

  Future<void> _saveFipe() async {
    if (_result == null) return;
    setState(() => _saving = true);
    try {
      final updated = Vehicle(
        id: widget.vehicle.id,
        type: widget.vehicle.type,
        propulsion: widget.vehicle.propulsion,
        brand: widget.vehicle.brand,
        model: widget.vehicle.model,
        year: widget.vehicle.year,
        plate: widget.vehicle.plate,
        currentKm: widget.vehicle.currentKm,
        tankCapacity: widget.vehicle.tankCapacity,
        transmission: widget.vehicle.transmission,
        fipeCode: _result!.code,
        fipeValue: _result!.value,
        fipeReference: _result!.reference,
        ipvaDueMonth: widget.vehicle.ipvaDueMonth,
        ipvaPaid: widget.vehicle.ipvaPaid,
        ipvaAmount: widget.vehicle.ipvaAmount,
        licensingPaid: widget.vehicle.licensingPaid,
        insuranceCompany: widget.vehicle.insuranceCompany,
        insurancePolicy: widget.vehicle.insurancePolicy,
        insurancePhone: widget.vehicle.insurancePhone,
        insuranceExpiryDate: widget.vehicle.insuranceExpiryDate,
        lastTireRotationKm: widget.vehicle.lastTireRotationKm,
        tireRotationIntervalKm: widget.vehicle.tireRotationIntervalKm,
      );
      await widget.repo.update(updated);
      if (mounted) {
        Navigator.pop(context);
        showMessage(context, 'Dados FIPE salvos no veículo!');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao salvar dados FIPE: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consulta Tabela FIPE',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.vehicle.name, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),

            // RESULTADO FIPE EM DESTAQUE NO TOPO ASSIM QUE IDENTIFICADO AUTOMATICAMENTE
            if (_loadingPrice)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_result != null) ...[
              Card(
                color: AppColors.goldenPollen.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Valor FIPE Oficial Identificado:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        _result!.value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldenPollen,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedBrand?.name ?? widget.vehicle.brand} • ${_selectedModel?.name ?? widget.vehicle.model} (${_selectedYear?.name ?? widget.vehicle.year})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Código: ${_result!.code} • Ref: ${_result!.reference}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LoadingButton(
                label: 'Salvar Valor FIPE no Veículo',
                loading: _saving,
                onPressed: _saveFipe,
              ),
              const SizedBox(height: 16),
            ],

            // MARCA FIPE COM BLOQUINHO DE 5 OPÇÕES
            if (_loadingBrands)
              const Center(child: CircularProgressIndicator())
            else if (_brands.isNotEmpty) ...[
              TextFormField(
                controller: _brandFilterCtrl,
                decoration: InputDecoration(
                  labelText: 'Marca FIPE (digite ou role abaixo)',
                  prefixIcon: const Icon(Icons.business),
                  suffixIcon: _brandFilterCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _brandFilterCtrl.clear()),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              _CaixaOpcoesRolavel(
                opcoes: _brands.map((b) => b.name).toList(),
                valorSelecionado: _selectedBrand?.name ?? '',
                filtroTexto: _brandFilterCtrl.text,
                rotuloCabecalho: 'Marcas FIPE (role 5 por vez)',
                aoSelecionar: (nome) {
                  final b = _brands.firstWhere((x) => x.name == nome);
                  _loadModels(b);
                },
              ),
            ],
            const SizedBox(height: 12),

            // MODELO FIPE COM BLOQUINHO DE 5 OPÇÕES
            if (_loadingModels)
              const Center(child: CircularProgressIndicator())
            else if (_models.isNotEmpty) ...[
              TextFormField(
                controller: _modelFilterCtrl,
                decoration: InputDecoration(
                  labelText: 'Modelo FIPE (digite ou role abaixo)',
                  prefixIcon: const Icon(Icons.directions_car),
                  suffixIcon: _modelFilterCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _modelFilterCtrl.clear()),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              _CaixaOpcoesRolavel(
                opcoes: _models.map((m) => m.name).toList(),
                valorSelecionado: _selectedModel?.name ?? '',
                filtroTexto: _modelFilterCtrl.text,
                rotuloCabecalho: 'Modelos FIPE (role 5 por vez)',
                aoSelecionar: (nome) {
                  final m = _models.firstWhere((x) => x.name == nome);
                  _loadYears(m);
                },
              ),
            ],
            const SizedBox(height: 12),

            // ANO / VERSÃO FIPE COM BLOQUINHO DE 5 OPÇÕES
            if (_loadingYears)
              const Center(child: CircularProgressIndicator())
            else if (_years.isNotEmpty) ...[
              TextFormField(
                controller: _yearFilterCtrl,
                decoration: InputDecoration(
                  labelText: 'Ano / Versão FIPE (digite ou role abaixo)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _yearFilterCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _yearFilterCtrl.clear()),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              _CaixaOpcoesRolavel(
                opcoes: _years.map((y) => y.name).toList(),
                valorSelecionado: _selectedYear?.name ?? '',
                filtroTexto: _yearFilterCtrl.text,
                rotuloCabecalho: 'Anos / Versões FIPE (role 5 por vez)',
                aoSelecionar: (nome) {
                  final y = _years.firstWhere((x) => x.name == nome);
                  _loadPrice(y);
                },
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}
