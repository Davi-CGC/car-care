import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/veiculo.dart';
import '../../repositories/repositorio_veiculo.dart';
import '../../theme/cores_app.dart';
import '../../utils/auxiliar_documentos.dart';
import '../../utils/dialogos.dart';
import '../../utils/formatadores.dart';

/// Modal para visualização e edição de Lembretes de IPVA, Licenciamento, Seguro e Rodízio de Pneus em português.
class LembretesVeiculoSheet extends StatefulWidget {
  final Veiculo veiculo;
  final RepositorioVeiculo repositorio;

  const LembretesVeiculoSheet({
    super.key,
    required this.veiculo,
    required this.repositorio,
  });

  Veiculo get vehicle => veiculo;
  RepositorioVeiculo get repo => repositorio;

  @override
  State<LembretesVeiculoSheet> createState() => _LembretesVeiculoSheetState();
}

class _LembretesVeiculoSheetState extends State<LembretesVeiculoSheet> {
  late Vehicle _vehicle;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
  }

  Future<void> _updateVehicle(Vehicle updated) async {
    setState(() => _loading = true);
    try {
      await widget.repo.update(updated);
      setState(() => _vehicle = updated);
      if (mounted) {
        showMessage(context, 'Lembretes atualizados com sucesso!');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao atualizar: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editInsurance() async {
    final companyCtrl = TextEditingController(text: _vehicle.insuranceCompany);
    final policyCtrl = TextEditingController(text: _vehicle.insurancePolicy);
    final phoneCtrl = TextEditingController(text: _vehicle.insurancePhone);
    DateTime? selectedDate = _vehicle.insuranceExpiryDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Dados do Seguro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Seguradora',
                    hintText: 'Ex: Porto Seguro, Allianz, Azul',
                    prefixIcon: Icon(Icons.security),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: policyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Número da Apólice',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telefone 24h / Guincho',
                    hintText: 'Ex: 0800 727 0800',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: Text(
                    selectedDate != null
                        ? 'Vencimento: ${formatDate(selectedDate!)}'
                        : 'Definir Vencimento',
                  ),
                  trailing: TextButton(
                    child: const Text('Escolher'),
                    onPressed: () async {
                      final picked = await pickDate(ctx, selectedDate ?? DateTime.now());
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                Navigator.pop(ctx);
                final updated = Vehicle(
                  id: _vehicle.id,
                  type: _vehicle.type,
                  propulsion: _vehicle.propulsion,
                  brand: _vehicle.brand,
                  model: _vehicle.model,
                  year: _vehicle.year,
                  plate: _vehicle.plate,
                  currentKm: _vehicle.currentKm,
                  transmission: _vehicle.transmission,
                  fipeCode: _vehicle.fipeCode,
                  fipeValue: _vehicle.fipeValue,
                  fipeReference: _vehicle.fipeReference,
                  tankCapacity: _vehicle.tankCapacity,
                  ipvaDueMonth: _vehicle.ipvaDueMonth,
                  ipvaPaid: _vehicle.ipvaPaid,
                  ipvaAmount: _vehicle.ipvaAmount,
                  licensingPaid: _vehicle.licensingPaid,
                  insuranceCompany: companyCtrl.text.trim(),
                  insurancePolicy: policyCtrl.text.trim(),
                  insurancePhone: phoneCtrl.text.trim(),
                  insuranceExpiryDate: selectedDate,
                  lastTireRotationKm: _vehicle.lastTireRotationKm,
                  tireRotationIntervalKm: _vehicle.tireRotationIntervalKm,
                  createdAt: _vehicle.createdAt,
                );
                _updateVehicle(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ipva = VehicleDocumentsHelper.getIpvaInfo(_vehicle);
    final licensing = VehicleDocumentsHelper.getLicensingInfo(_vehicle);
    final insurance = VehicleDocumentsHelper.getInsuranceInfo(_vehicle);
    final tires = VehicleDocumentsHelper.getTireRotationInfo(_vehicle);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldenPollen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: AppColors.goldenPollen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lembretes & Documentos',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_vehicle.name} (${_vehicle.propulsion.shortLabel}) • Placa ${_vehicle.plate.isNotEmpty ? _vehicle.plate.toUpperCase() : '--'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                // 1. IPVA CARD
                _DocumentCard(
                  icon: Icons.account_balance,
                  iconColor: Colors.purple[400]!,
                  title: 'IPVA (Imposto sobre Veículos)',
                  subtitle: 'Vencimento em ${ipva.monthName}',
                  statusBadge: _buildBadge(
                    label: ipva.isPaid ? 'PAGO / ISENTO' : (ipva.isOverdue ? 'ATRASADO' : 'PENDENTE'),
                    color: ipva.isPaid
                        ? AppColors.success
                        : (ipva.isOverdue ? AppColors.danger : AppColors.warning),
                  ),
                  bodyContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ipva.estimatedValue > 0)
                        Text(
                          'Valor Estimado: ${formatMoney(ipva.estimatedValue)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      Text(
                        ipva.isPaid
                            ? 'O IPVA deste ano já foi marcado como quitado/isento.'
                            : 'Fique atento ao calendário para evitar juros e multas.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_vehicle.usesElectricPower) ...[
                        const SizedBox(height: 6),
                        Text(
                          '⚡ Dica EV/Híbrido: diversos estados e capitais oferecem isenção total ou restituição de quota-parte do IPVA para veículos elétricos e híbridos.',
                          style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  actionButton: TextButton.icon(
                    icon: Icon(ipva.isPaid ? Icons.undo : Icons.check_circle_outline),
                    label: Text(ipva.isPaid ? 'Desmarcar' : 'Marcar como Pago / Isento'),
                    onPressed: _loading
                        ? null
                        : () {
                            final updated = Vehicle(
                              id: _vehicle.id,
                              type: _vehicle.type,
                              propulsion: _vehicle.propulsion,
                              brand: _vehicle.brand,
                              model: _vehicle.model,
                              year: _vehicle.year,
                              plate: _vehicle.plate,
                              currentKm: _vehicle.currentKm,
                              transmission: _vehicle.transmission,
                              fipeCode: _vehicle.fipeCode,
                              fipeValue: _vehicle.fipeValue,
                              fipeReference: _vehicle.fipeReference,
                              tankCapacity: _vehicle.tankCapacity,
                              ipvaDueMonth: _vehicle.ipvaDueMonth,
                              ipvaPaid: !_vehicle.ipvaPaid,
                              ipvaAmount: _vehicle.ipvaAmount,
                              licensingPaid: _vehicle.licensingPaid,
                              insuranceCompany: _vehicle.insuranceCompany,
                              insurancePolicy: _vehicle.insurancePolicy,
                              insurancePhone: _vehicle.insurancePhone,
                              insuranceExpiryDate: _vehicle.insuranceExpiryDate,
                              lastTireRotationKm: _vehicle.lastTireRotationKm,
                              tireRotationIntervalKm: _vehicle.tireRotationIntervalKm,
                              createdAt: _vehicle.createdAt,
                            );
                            _updateVehicle(updated);
                          },
                  ),
                ),
                const SizedBox(height: 12),

                // 2. LICENCIAMENTO CARD
                _DocumentCard(
                  icon: Icons.badge,
                  iconColor: Colors.blue[500]!,
                  title: 'Licenciamento Anual (Detran)',
                  subtitle: licensing.deadlineDescription,
                  statusBadge: _buildBadge(
                    label: licensing.isPaid
                        ? 'EM DIA'
                        : (licensing.isOverdue
                            ? 'ATRASADO'
                            : (licensing.isDueSoon ? 'VENCE ESTE MÊS' : 'PENDENTE')),
                    color: licensing.isPaid
                        ? AppColors.success
                        : (licensing.isOverdue ? AppColors.danger : AppColors.warning),
                  ),
                  bodyContent: Text(
                    licensing.isPaid
                        ? 'Veículo devidamente licenciado perante o Detran.'
                        : 'O prazo limite para pagamento é até o final de ${licensing.monthName}.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  actionButton: TextButton.icon(
                    icon: Icon(licensing.isPaid ? Icons.undo : Icons.check_circle_outline),
                    label: Text(licensing.isPaid ? 'Desmarcar' : 'Marcar como Pago'),
                    onPressed: _loading
                        ? null
                        : () {
                            final updated = Vehicle(
                              id: _vehicle.id,
                              type: _vehicle.type,
                              propulsion: _vehicle.propulsion,
                              brand: _vehicle.brand,
                              model: _vehicle.model,
                              year: _vehicle.year,
                              plate: _vehicle.plate,
                              currentKm: _vehicle.currentKm,
                              transmission: _vehicle.transmission,
                              fipeCode: _vehicle.fipeCode,
                              fipeValue: _vehicle.fipeValue,
                              fipeReference: _vehicle.fipeReference,
                              tankCapacity: _vehicle.tankCapacity,
                              ipvaDueMonth: _vehicle.ipvaDueMonth,
                              ipvaPaid: _vehicle.ipvaPaid,
                              ipvaAmount: _vehicle.ipvaAmount,
                              licensingPaid: !_vehicle.licensingPaid,
                              insuranceCompany: _vehicle.insuranceCompany,
                              insurancePolicy: _vehicle.insurancePolicy,
                              insurancePhone: _vehicle.insurancePhone,
                              insuranceExpiryDate: _vehicle.insuranceExpiryDate,
                              lastTireRotationKm: _vehicle.lastTireRotationKm,
                              tireRotationIntervalKm: _vehicle.tireRotationIntervalKm,
                              createdAt: _vehicle.createdAt,
                            );
                            _updateVehicle(updated);
                          },
                  ),
                ),
                const SizedBox(height: 12),

                // 3. SEGURO CARD
                _DocumentCard(
                  icon: Icons.shield,
                  iconColor: Colors.green[600]!,
                  title: 'Seguro do Veículo',
                  subtitle: insurance.company.isNotEmpty
                      ? '${insurance.company} • Apólice: ${insurance.policy.isNotEmpty ? insurance.policy : '--'}'
                      : 'Nenhum seguro cadastrado ainda',
                  statusBadge: insurance.expiryDate != null
                      ? _buildBadge(
                          label: insurance.isExpired
                              ? 'VENCIDO'
                              : (insurance.isDueSoon ? 'RENOVAR EM BREVE' : 'VIGENTE'),
                          color: insurance.isExpired
                              ? AppColors.danger
                              : (insurance.isDueSoon ? AppColors.warning : AppColors.success),
                        )
                      : null,
                  bodyContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (insurance.expiryDate != null)
                        Text(
                          'Vencimento: ${formatDate(insurance.expiryDate!)} (${insurance.daysRemaining ?? 0} dias)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      if (insurance.phone.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse('tel:${insurance.phone.replaceAll(RegExp(r'[^0-9]'), '')}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone, size: 16, color: AppColors.goldenPollen),
                              const SizedBox(width: 6),
                              Text(
                                'Assistência 24h: ${insurance.phone} (Toque para discar)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.goldenPollen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  actionButton: TextButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Seguro'),
                    onPressed: _editInsurance,
                  ),
                ),
                const SizedBox(height: 12),

                // 4. RODÍZIO DE PNEUS CARD
                _DocumentCard(
                  icon: Icons.tire_repair,
                  iconColor: Colors.orange[700]!,
                  title: 'Rodízio de Pneus',
                  subtitle: 'Recomendado a cada ${formatKm(tires.intervalKm)}',
                  statusBadge: _buildBadge(
                    label: tires.isDue ? 'FAZER AGORA' : (tires.isSoon ? 'PRÓXIMO' : 'EM DIA'),
                    color: tires.isDue
                        ? AppColors.danger
                        : (tires.isSoon ? AppColors.warning : AppColors.success),
                  ),
                  bodyContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tires.lastKm != null
                                ? 'Último rodízio: ${formatKm(tires.lastKm!)}'
                                : 'Nenhum rodízio registrado',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            tires.remainingKm > 0
                                ? 'Faltam ${formatKm(tires.remainingKm)}'
                                : 'Venceu há ${formatKm(-tires.remainingKm)}!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: tires.isDue ? AppColors.danger : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: tires.progress,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tires.isDue
                                ? AppColors.danger
                                : (tires.isSoon ? AppColors.warning : AppColors.goldenPollen),
                          ),
                        ),
                      ),
                    ],
                  ),
                  actionButton: TextButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Registrar Rodízio Hoje'),
                    onPressed: _loading
                        ? null
                        : () {
                            final updated = Vehicle(
                              id: _vehicle.id,
                              type: _vehicle.type,
                              propulsion: _vehicle.propulsion,
                              brand: _vehicle.brand,
                              model: _vehicle.model,
                              year: _vehicle.year,
                              plate: _vehicle.plate,
                              currentKm: _vehicle.currentKm,
                              transmission: _vehicle.transmission,
                              fipeCode: _vehicle.fipeCode,
                              fipeValue: _vehicle.fipeValue,
                              fipeReference: _vehicle.fipeReference,
                              tankCapacity: _vehicle.tankCapacity,
                              ipvaDueMonth: _vehicle.ipvaDueMonth,
                              ipvaPaid: _vehicle.ipvaPaid,
                              ipvaAmount: _vehicle.ipvaAmount,
                              licensingPaid: _vehicle.licensingPaid,
                              insuranceCompany: _vehicle.insuranceCompany,
                              insurancePolicy: _vehicle.insurancePolicy,
                              insurancePhone: _vehicle.insurancePhone,
                              insuranceExpiryDate: _vehicle.insuranceExpiryDate,
                              lastTireRotationKm: _vehicle.currentKm,
                              tireRotationIntervalKm: _vehicle.tireRotationIntervalKm,
                              createdAt: _vehicle.createdAt,
                            );
                            _updateVehicle(updated);
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? statusBadge;
  final Widget bodyContent;
  final Widget? actionButton;

  const _DocumentCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.statusBadge,
    required this.bodyContent,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E24) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ?statusBadge,
              ],
            ),
            const SizedBox(height: 12),
            bodyContent,
            if (actionButton != null) ...[
              const Divider(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: actionButton,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class VehicleRemindersSheet extends LembretesVeiculoSheet {
  const VehicleRemindersSheet({
    super.key,
    required Veiculo vehicle,
    required RepositorioVeiculo repo,
  }) : super(veiculo: vehicle, repositorio: repo);
}
