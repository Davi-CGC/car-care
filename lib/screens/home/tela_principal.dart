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
    final avgConsumption = Calculations.averageConsumption(fuels);

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
        if (vehicles.any((v) => !v.isMotorcycle && v.plate.isNotEmpty && RodizioHelper.getInfo(v.plate, type: v.type).isToday)) ...[
          const SizedBox(height: 14),
          ...vehicles
              .where((v) => !v.isMotorcycle && v.plate.isNotEmpty && RodizioHelper.getInfo(v.plate, type: v.type).isToday)
              .map((rv) {
            final rInfo = RodizioHelper.getInfo(rv.plate, type: rv.type);
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
            SummaryCard(
              icon: Icons.local_gas_station,
              label: 'Consumo médio',
              value: avgConsumption != null ? '${formatNumber(avgConsumption, 1)} km/l' : '--',
            ),
            Builder(builder: (_) {
              final dailyKm = Calculations.dailyAverageDistance(fuels);
              if (dailyKm <= 0) return const SizedBox.shrink();
              return SummaryCard(
                icon: Icons.route,
                label: 'Média diária',
                value: '${formatNumber(dailyKm, 1)} km/dia',
              );
            }),
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
                      final rodizio = RodizioHelper.getInfo(vehicle.plate, type: vehicle.type);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.calendar_month,
                          color: rodizio.isToday ? AppColors.warning : null,
                        ),
                        title: const Text('Rodízio Municipal'),
                        subtitle: Text(
                          vehicle.isMotorcycle
                              ? 'Isento (Motocicleta)'
                              : '${rodizio.dayName} (${rodizio.timeRange})${rodizio.isToday ? ' • ATIVO HOJE!' : ''}',
                          style: TextStyle(
                            color: rodizio.isToday ? AppColors.warning : null,
                            fontWeight: rodizio.isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                  if (!vehicle.isMotorcycle && vehicle.transmission.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.settings),
                      title: const Text('Câmbio'),
                      subtitle: Text(vehicle.transmission),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.local_gas_station),
                    title: const Text('Capacidade do Tanque'),
                    subtitle: Text('${formatNumber(vehicle.effectiveTankCapacity, 0)} Litros'),
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
                          Text('Abastecimento', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                Text('Combustível: ${f.fuelType}'),
                if (f.gasStation.isNotEmpty) Text('Posto: ${f.gasStation}'),
                Text('Quilometragem: ${formatKm(f.km)}'),
                Text('Volume: ${formatNumber(f.liters, 2)} ${f.unit}'),
                if (f.pricePerLiter > 0)
                  Text('Preço por ${f.unit}: ${formatMoney(f.pricePerLiter)}'),
                Text('Total Pago: ${formatMoney(f.totalPrice)}'),
                Text('Tanque Cheio: ${f.isFullTank ? "Sim" : "Não (Parcial)"}'),
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
                            title: 'Excluir Abastecimento',
                            message: 'Deseja apagar este registro de abastecimento?',
                          );
                          if (confirm) {
                            await _fuelRepo.delete(f.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              showMessage(context, 'Abastecimento excluído.');
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

// ==========================================
// FORMULÁRIO DE VEÍCULO (COM BUSCA DE MARCA E MODELO POR MARCA)
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
  bool _loadingFipeModels = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? VehicleType.carro;
    _brand = TextEditingController(text: e?.brand ?? '');
    _model = TextEditingController(text: e?.model ?? '');
    _year = TextEditingController(text: e?.year ?? '');
    _plate = TextEditingController(text: e?.plate ?? '');
    _km = TextEditingController(text: e != null ? '${e.currentKm}' : '0');
    _tankCapacity = TextEditingController(
      text: (e != null && e.tankCapacity > 0) ? '${e.tankCapacity}' : '',
    );
    _transmission = (e != null && e.transmission.isNotEmpty) ? e.transmission : 'Manual';
    _plate.addListener(() => setState(() {}));
    _brand.addListener(() => setState(() {}));
    _loadFipeBrandsForType(_type, initialBrand: _brand.text);
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

  Future<void> _loadFipeBrandsForType(VehicleType type, {String? initialBrand}) async {
    try {
      final list = await _fipe.brands(type);
      if (!mounted || _type != type) return;
      setState(() => _fipeBrands = list);
      if (initialBrand != null && initialBrand.trim().isNotEmpty) {
        _loadFipeModelsForBrandName(initialBrand.trim());
      }
    } catch (_) {
      // Caso esteja offline, o catálogo local (CatalogoVeiculos) continua funcionando normalmente.
    }
  }

  Future<void> _loadFipeModelsForBrandName(String brandName) async {
    if (brandName.trim().isEmpty || _fipeBrands.isEmpty) {
      setState(() => _fipeModels = []);
      return;
    }
    final clean = brandName.trim().toLowerCase();
    final match = _fipeBrands.cast<FipeItem?>().firstWhere(
          (b) =>
              b != null &&
              (b.name.toLowerCase() == clean ||
                  b.name.toLowerCase().contains(clean) ||
                  clean.contains(b.name.toLowerCase())),
          orElse: () => null,
        );
    if (match == null) {
      setState(() => _fipeModels = []);
      return;
    }
    setState(() => _loadingFipeModels = true);
    try {
      final models = await _fipe.models(_type, match.code);
      if (mounted) {
        setState(() => _fipeModels = models);
      }
    } catch (_) {
      // Ignora falha de rede e mantém catálogo local
    } finally {
      if (mounted) setState(() => _loadingFipeModels = false);
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

  void _selectBrand(String brand) {
    final previousBrand = _brand.text.trim();
    setState(() {
      _brand.text = brand;
      if (previousBrand.toLowerCase() != brand.trim().toLowerCase()) {
        // Ao trocar de marca, limpa o modelo anterior caso não pertença à nova marca
        final modelsOfNewBrand = CatalogoVeiculos.modelosPara(_type, brand);
        if (_model.text.trim().isNotEmpty &&
            !modelsOfNewBrand.any((m) => m.toLowerCase() == _model.text.trim().toLowerCase())) {
          _model.clear();
        }
        _fipeModels = [];
      }
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
          _loadFipeModelsForBrandName(detectedBrand);
        }
      }
    });
  }

  Future<void> _openBrandPickerModal() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SearchableListModal(
        title: 'Selecionar Marca (${_type.label})',
        searchHint: 'Pesquisar marca (ex: Volkswagen, Honda...)',
        items: _availableBrands,
        currentValue: _brand.text.trim(),
        emptyMessage: 'Nenhuma marca encontrada. Você pode usar o nome digitado.',
      ),
    );
    if (selected != null && selected.trim().isNotEmpty) {
      _selectBrand(selected.trim());
    }
  }

  Future<void> _openModelPickerModal() async {
    final brandName = _brand.text.trim();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SearchableListModal(
        title: brandName.isNotEmpty
            ? 'Modelos — $brandName'
            : 'Selecionar Modelo (${_type.label})',
        subtitle: brandName.isEmpty
            ? 'Dica: selecione a marca primeiro para filtrar apenas os modelos dela'
            : null,
        searchHint: brandName.isNotEmpty
            ? 'Buscar modelo da $brandName...'
            : 'Pesquisar modelo (ex: Gol, Onix, CG 160...)',
        items: _availableModelsForCurrentBrand,
        currentValue: _model.text.trim(),
        emptyMessage: 'Modelo não encontrado na lista. Toque abaixo para usar o nome digitado.',
      ),
    );
    if (selected != null && selected.trim().isNotEmpty) {
      _selectModel(selected.trim());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final vehicle = Vehicle(
        id: widget.existing?.id ?? '',
        type: _type,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: _year.text.trim(),
        plate: _plate.text.trim().toUpperCase(),
        currentKm: int.tryParse(_km.text.trim()) ?? 0,
        transmission: _type == VehicleType.moto ? '' : _transmission,
        fipeCode: widget.existing?.fipeCode ?? '',
        fipeValue: widget.existing?.fipeValue ?? '',
        fipeReference: widget.existing?.fipeReference ?? '',
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
        showMessage(context, 'Veículo salvo com sucesso!');
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
    final popularBrands = CatalogoVeiculos.marcasPara(_type).take(8).toList();
    final modelsForBrand = _availableModelsForCurrentBrand;

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
                segments: const [
                  ButtonSegment(value: VehicleType.carro, label: Text('Carro'), icon: Icon(Icons.directions_car)),
                  ButtonSegment(value: VehicleType.moto, label: Text('Moto'), icon: Icon(Icons.two_wheeler)),
                  ButtonSegment(value: VehicleType.caminhao, label: Text('Caminhão'), icon: Icon(Icons.local_shipping)),
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
                  });
                  _loadFipeBrandsForType(nextType);
                },
              ),
              const SizedBox(height: 16),

              // CAMPO DE MARCA COM BOTÃO DE LISTA / BUSCA
              TextFormField(
                controller: _brand,
                decoration: InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: const Icon(Icons.business),
                  hintText: _type == VehicleType.caminhao
                      ? 'Ex: Scania, Mercedes-Benz, Volvo'
                      : (_type == VehicleType.moto ? 'Ex: Honda, Yamaha' : 'Ex: Volkswagen, Chevrolet'),
                  suffixIcon: TextButton.icon(
                    onPressed: _openBrandPickerModal,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Lista'),
                  ),
                ),
                validator: (v) => Validators.required(v, 'Marca'),
                onChanged: (val) {
                  _loadFipeModelsForBrandName(val);
                },
              ),
              const SizedBox(height: 6),
              // Atalhos rápidos das marcas mais comuns
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        avatar: const Icon(Icons.list, size: 16, color: AppColors.goldenPollen),
                        label: const Text('Ver todas as marcas', style: TextStyle(fontSize: 12)),
                        onPressed: _openBrandPickerModal,
                      ),
                    ),
                    ...popularBrands.map((b) {
                      final isSelected = _brand.text.trim().toLowerCase() == b.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(b, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => _selectBrand(b),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CAMPO DE MODELO COM BUSCA POR MARCA
              TextFormField(
                controller: _model,
                decoration: InputDecoration(
                  labelText: _brand.text.trim().isNotEmpty
                      ? 'Modelo (${_brand.text.trim()})'
                      : 'Modelo',
                  prefixIcon: Icon(
                    _type == VehicleType.caminhao
                        ? Icons.local_shipping
                        : (_type == VehicleType.moto ? Icons.two_wheeler : Icons.directions_car_filled),
                  ),
                  hintText: _type == VehicleType.caminhao
                      ? 'Ex: FH 540, Actros'
                      : (_type == VehicleType.moto ? 'Ex: CG 160 Titan, Fazer 250' : 'Ex: Gol, Onix, Corolla'),
                  suffixIcon: TextButton.icon(
                    onPressed: _openModelPickerModal,
                    icon: _loadingFipeModels
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: const Text('Buscar'),
                  ),
                ),
                validator: (v) => Validators.required(v, 'Modelo'),
              ),
              if (modelsForBrand.isNotEmpty) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: const Icon(Icons.manage_search, size: 16, color: AppColors.goldenPollen),
                          label: Text(
                            _brand.text.trim().isNotEmpty
                                ? 'Buscar modelos de ${_brand.text.trim()} (${modelsForBrand.length})'
                                : 'Buscar na lista de modelos',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: _openModelPickerModal,
                        ),
                      ),
                      ...modelsForBrand.take(10).map((m) {
                        final isSelected = _model.text.trim().toLowerCase() == m.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(m, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (_) => _selectModel(m),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _year,
                      label: 'Ano',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: Validators.year,
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
              const SizedBox(height: 12),
              AppTextField(
                controller: _tankCapacity,
                label: 'Capacidade do Tanque (Litros - opcional)',
                icon: Icons.local_gas_station,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: _type == VehicleType.caminhao ? 'Ex: 300' : (_type == VehicleType.moto ? 'Ex: 14' : 'Ex: 50'),
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
                  final rodizio = RodizioHelper.getInfo(_plate.text.trim(), type: _type);
                  if (_type == VehicleType.moto) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        '🏍️ Motocicletas são isentas do rodízio municipal.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
              if (_type != VehicleType.moto) ...[
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

/// Modal reutilizável de busca em lista (para Marcas e Modelos por Marca).
class _SearchableListModal extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String searchHint;
  final List<String> items;
  final String currentValue;
  final String emptyMessage;

  const _SearchableListModal({
    required this.title,
    this.subtitle,
    required this.searchHint,
    required this.items,
    required this.currentValue,
    required this.emptyMessage,
  });

  @override
  State<_SearchableListModal> createState() => _SearchableListModalState();
}

class _SearchableListModalState extends State<_SearchableListModal> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items.where((item) => item.toLowerCase().contains(q)).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _query = val),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.emptyMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (_query.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: Text('Usar "${_query.trim()}"'),
                            onPressed: () => Navigator.pop(context, _query.trim()),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = item.toLowerCase() == widget.currentValue.toLowerCase();
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.goldenPollen : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.goldenPollen)
                            : const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
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
      // Atualiza quilometragem e dados puxados para o novo veículo selecionado
      if (widget.existing == null) {
        _km.text = '${newVehicle.currentKm}';
      }
      if (!newCategories.contains(_category)) {
        _category = newCategories.first;
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
    if (val == null) return;
    setState(() {
      _category = val;
      final item = MaintenanceCatalog.find(val);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final kmVal = int.tryParse(_km.text.trim()) ?? 0;
      final costVal = parseNumber(_cost.text.trim()) ?? 0;
      final nextKmVal = _scheduleNext ? int.tryParse(_nextKm.text.trim()) : null;

      final maintenance = Maintenance(
        id: widget.existing?.id ?? '',
        vehicleId: _selectedVehicleId,
        category: _category,
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
              DropdownButtonFormField<String>(
                key: ValueKey('maint_cat_${_selectedVehicleId}_$effectiveCategory'),
                initialValue: effectiveCategory,
                decoration: const InputDecoration(labelText: 'Serviço / Categoria', prefixIcon: Icon(Icons.build)),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: _onCategoryChanged,
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

  static const List<String> _stationSuggestions = [
    'Posto Shell',
    'Posto Ipiranga',
    'Petrobras BR',
    'Posto Ale',
    'Posto Graal',
    'Posto Rodoil',
    'Auto Posto Central',
  ];

  String _defaultFuelTypeForVehicle(Vehicle v) {
    final lastRecord = widget.fuels.cast<FuelRecord?>().firstWhere(
          (f) => f != null && f.vehicleId == v.id,
          orElse: () => null,
        );
    if (lastRecord != null && FuelTypes.all.contains(lastRecord.fuelType)) {
      return lastRecord.fuelType;
    }
    if (v.isTruck) return FuelTypes.diesel;
    return FuelTypes.gasolina;
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
    setState(() {
      _selectedVehicleId = val;
      if (widget.existing == null) {
        _km.text = '${newVehicle.currentKm}';
        _selectedFuelType = _defaultFuelTypeForVehicle(newVehicle);
        _gasStation.clear();
      }
    });
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
        if (kmUpdated) {
          showMessage(
            context,
            'Abastecimento salvo e odômetro do ${vehicle.name} atualizado para ${formatKm(kmVal)}!',
          );
        } else {
          showMessage(context, 'Abastecimento salvo com sucesso!');
        }
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao salvar abastecimento: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isGnv = _selectedFuelType == FuelTypes.gnv;
    final unitLabel = isGnv ? 'm³' : 'L';
    final volumeLabel = isGnv ? 'Volume (m³)' : 'Volume (L)';
    final volumeName = isGnv ? 'Volume em m³' : 'Litros';

    final vehicle = widget.vehicles.firstWhere(
      (v) => v.id == _selectedVehicleId,
      orElse: () => widget.vehicles.first,
    );
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
                      widget.existing == null ? 'Novo Abastecimento' : 'Editar Abastecimento',
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
                decoration: const InputDecoration(labelText: 'Veículo', prefixIcon: Icon(Icons.directions_car)),
                items: widget.vehicles
                    .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
                    .toList(),
                onChanged: _onVehicleChanged,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('fuel_type_${_selectedVehicleId}_$_selectedFuelType'),
                initialValue: _selectedFuelType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Combustível',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                items: FuelTypes.all
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFuelType = val);
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

              // CHAVE DE TANQUE COMPLETO
              Card(
                elevation: 0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E24)
                    : Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _isFullTank
                        ? AppColors.goldenPollen.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                child: SwitchListTile(
                  value: _isFullTank,
                  activeThumbColor: AppColors.goldenPollen,
                  title: Row(
                    children: [
                      Icon(
                        _isFullTank ? Icons.local_gas_station : Icons.local_gas_station_outlined,
                        color: _isFullTank ? AppColors.goldenPollen : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Tanque Completo (Cheio)?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  subtitle: Text(
                    _isFullTank
                        ? 'Sim — Permite calcular com precisão o consumo real deste trecho.'
                        : 'Não (Parcial) — Litros e km acumulam até o próximo tanque cheio.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onChanged: (val) => setState(() => _isFullTank = val),
                ),
              ),
              const SizedBox(height: 14),

              // CALCULADORA AUTOMÁTICA DE 3 CAMPOS (PREÇO/L, VOLUME, TOTAL R$)
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
                      children: const [
                        Icon(Icons.calculate, size: 18, color: AppColors.goldenPollen),
                        SizedBox(width: 6),
                        Text(
                          'Calculadora Automática',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.goldenPollen),
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

              // CAMPO DE POSTO COM AUTOCOMPLETE
              Autocomplete<String>(
                key: ValueKey('fuel_station_$_selectedVehicleId'),
                initialValue: TextEditingValue(text: _gasStation.text),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _stationSuggestions;
                  }
                  return _stationSuggestions.where((s) =>
                      s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) => _gasStation.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  controller.addListener(() => _gasStation.text = controller.text);
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: const InputDecoration(
                      labelText: 'Posto de Combustível (opcional)',
                      hintText: 'Ex: Shell, Ipiranga, Petrobras BR',
                      prefixIcon: Icon(Icons.storefront),
                    ),
                  );
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
                            'Resumo do Abastecimento',
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
                        '• Rendimento estimado deste abastecimento: ${formatNumber(tripConsumption, 1)} ${isGnv ? 'km/m³' : 'km/l'}',
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
                      label: 'Salvar Abastecimento',
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
// CONSULTA FIPE
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

  bool _loadingBrands = false;
  bool _loadingModels = false;
  bool _loadingYears = false;
  bool _loadingPrice = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loadingBrands = true;
      _error = null;
    });
    try {
      final list = await _fipe.brands(widget.vehicle.type);
      if (mounted) setState(() => _brands = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar marcas FIPE: $e');
    } finally {
      if (mounted) setState(() => _loadingBrands = false);
    }
  }

  Future<void> _loadModels(FipeItem brand) async {
    setState(() {
      _selectedBrand = brand;
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
      if (mounted) setState(() => _models = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar modelos: $e');
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _loadYears(FipeItem model) async {
    if (_selectedBrand == null) return;
    setState(() {
      _selectedModel = model;
      _selectedYear = null;
      _years = [];
      _result = null;
      _loadingYears = true;
      _error = null;
    });
    try {
      final list = await _fipe.years(widget.vehicle.type, _selectedBrand!.code, model.code);
      if (mounted) setState(() => _years = list);
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
      _loadingPrice = true;
      _error = null;
    });
    try {
      final res = await _fipe.price(widget.vehicle.type, _selectedBrand!.code, _selectedModel!.code, year.code);
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
        brand: widget.vehicle.brand,
        model: widget.vehicle.model,
        year: widget.vehicle.year,
        plate: widget.vehicle.plate,
        currentKm: widget.vehicle.currentKm,
        transmission: widget.vehicle.transmission,
        fipeCode: _result!.code,
        fipeValue: _result!.value,
        fipeReference: _result!.reference,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                      Text('Consulta Tabela FIPE', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 16),
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
            if (_loadingBrands)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<FipeItem>(
                initialValue: _selectedBrand,
                decoration: const InputDecoration(labelText: 'Marca FIPE'),
                items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                onChanged: (b) => b != null ? _loadModels(b) : null,
              ),
            const SizedBox(height: 12),
            if (_loadingModels)
              const Center(child: CircularProgressIndicator())
            else if (_models.isNotEmpty)
              DropdownButtonFormField<FipeItem>(
                key: ValueKey('fipe_model_${_selectedBrand?.code}'),
                initialValue: _selectedModel,
                decoration: const InputDecoration(labelText: 'Modelo FIPE'),
                items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (m) => m != null ? _loadYears(m) : null,
              ),
            const SizedBox(height: 12),
            if (_loadingYears)
              const Center(child: CircularProgressIndicator())
            else if (_years.isNotEmpty)
              DropdownButtonFormField<FipeItem>(
                key: ValueKey('fipe_year_${_selectedModel?.code}'),
                initialValue: _selectedYear,
                decoration: const InputDecoration(labelText: 'Ano / Combustível'),
                items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.name))).toList(),
                onChanged: (y) => y != null ? _loadPrice(y) : null,
              ),
            const SizedBox(height: 16),
            if (_loadingPrice) const Center(child: CircularProgressIndicator()),
            if (_result != null) ...[
              Card(
                color: AppColors.goldenPollen.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Valor FIPE Oficial:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        _result!.value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldenPollen,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('Código: ${_result!.code} • Mês: ${_result!.reference}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LoadingButton(
                label: 'Salvar Valor FIPE no Veículo',
                loading: _saving,
                onPressed: _saveFipe,
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
