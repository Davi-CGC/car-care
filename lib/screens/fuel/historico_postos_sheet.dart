import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/registro_abastecimento.dart';
import '../../theme/cores_app.dart';
import '../../utils/formatadores.dart';

class _StationStats {
  final String name;
  int visits = 0;
  double totalSpent = 0.0;
  double totalVolume = 0.0;
  DateTime lastVisit = DateTime(2000);
  final Map<String, double> latestPriceByFuel = {};

  _StationStats({required this.name});
}

/// Histórico detalhado dos postos de combustível que o usuário frequentou em português.
class HistoricoPostosSheet extends StatelessWidget {
  final List<RegistroAbastecimento> abastecimentos;

  const HistoricoPostosSheet({
    super.key,
    required this.abastecimentos,
  });

  List<RegistroAbastecimento> get fuels => abastecimentos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filtra registros que possuem posto preenchido
    final withStation = fuels.where((f) => f.gasStation.trim().isNotEmpty).toList();

    // Agrupa dados por posto
    final Map<String, _StationStats> statsMap = {};
    for (final f in withStation) {
      final key = f.gasStation.trim();
      final stat = statsMap.putIfAbsent(key, () => _StationStats(name: key));
      stat.visits += 1;
      stat.totalSpent += f.totalPrice;
      stat.totalVolume += f.liters;
      if (f.date.isAfter(stat.lastVisit)) {
        stat.lastVisit = f.date;
      }
      final p = f.pricePerLiter;
      if (p > 0) {
        stat.latestPriceByFuel[f.fuelType] = p;
      }
    }

    final statsList = statsMap.values.toList()
      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                  Icons.local_gas_station,
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
                      'Histórico de Postos',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${statsList.length} postos visitados com histórico de preços',
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

          if (statsList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined, size: 54, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum posto registrado ainda',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Ao cadastrar um novo abastecimento, informe o nome do posto (ex: Shell, Ipiranga, BR) para salvar o histórico de preços!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: statsList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = statsList[index];

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
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.goldenPollen.withValues(alpha: 0.2),
                                child: const Icon(Icons.storefront, color: AppColors.goldenPollen, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      '${item.visits} ${item.visits == 1 ? 'abastecimento' : 'abastecimentos'} • Última visita: ${formatDate(item.lastVisit)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.directions, color: AppColors.goldenPollen),
                                tooltip: 'Ver rota no Google Maps',
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(item.name)}',
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Gasto: ${formatMoney(item.totalSpent)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Total: ${formatNumber(item.totalVolume, 1)} L/m³/kWh',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          if (item.latestPriceByFuel.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Últimos preços registrados neste local:',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: item.latestPriceByFuel.entries.map((entry) {
                                final unit = entry.key == FuelTypes.eletricidade
                                    ? 'kWh'
                                    : (entry.key == FuelTypes.gnv ? 'm³' : 'L');
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldenPollen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${entry.key}: ${formatMoney(entry.value)}/$unit',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.goldenPollen,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class GasStationsHistorySheet extends HistoricoPostosSheet {
  const GasStationsHistorySheet({
    super.key,
    required List<RegistroAbastecimento> fuels,
  }) : super(abastecimentos: fuels);
}
