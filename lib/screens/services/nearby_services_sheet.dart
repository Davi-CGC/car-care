import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/fuel_record.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Modal para busca de serviços automotivos próximos usando o Google Maps
/// e consulta de preços praticados nos postos de combustível.
class NearbyServicesSheet extends StatefulWidget {
  final List<FuelRecord> fuels;

  const NearbyServicesSheet({super.key, required this.fuels});

  @override
  State<NearbyServicesSheet> createState() => _NearbyServicesSheetState();
}

class _NearbyServicesSheetState extends State<NearbyServicesSheet> {
  final TextEditingController _locationController = TextEditingController();

  Future<void> _openGoogleMaps(String query) async {
    final locationText = _locationController.text.trim();
    final fullQuery = locationText.isNotEmpty
        ? '$query em $locationText'
        : '$query perto de mim';

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fullQuery)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o Google Maps.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Agrupa preços mais recentes registrados pelo usuário nos postos
    final stationFuels = widget.fuels.where((f) => f.gasStation.isNotEmpty).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
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
                    Icons.map,
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
                        'Serviços Próximos',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Localize postos, oficinas e socorro no Google Maps',
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

            // Campo de localização personalizada (opcional)
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Buscar por bairro ou cidade (ex: Centro, Moema)...',
                prefixIcon: const Icon(Icons.my_location),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar no Google Maps',
                  onPressed: () => _openGoogleMaps('posto de combustível'),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Categorias rápidas
            Text(
              'O que você precisa agora?',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ServiceCategoryCard(
                  icon: Icons.local_gas_station,
                  title: 'Postos de Combustível',
                  subtitle: 'Gasolina, Etanol, GNV e Diesel',
                  color: Colors.amber[700]!,
                  onTap: () => _openGoogleMaps('posto de combustivel'),
                ),
                _ServiceCategoryCard(
                  icon: Icons.build,
                  title: 'Oficinas Mecânicas',
                  subtitle: 'Revisão, freios e motor',
                  color: Colors.blue[600]!,
                  onTap: () => _openGoogleMaps('oficina mecanica auto center'),
                ),
                _ServiceCategoryCard(
                  icon: Icons.tire_repair,
                  title: 'Borracharias & Pneus',
                  subtitle: 'Conserto, calibragem e alinhamento',
                  color: Colors.deepOrange[600]!,
                  onTap: () => _openGoogleMaps('borracharia troca de pneus'),
                ),
                _ServiceCategoryCard(
                  icon: Icons.electric_bolt,
                  title: 'Autoelétricas',
                  subtitle: 'Baterias, alternador e motor de arranque',
                  color: Colors.teal[600]!,
                  onTap: () => _openGoogleMaps('auto eletrica automotiva'),
                ),
                _ServiceCategoryCard(
                  icon: Icons.local_car_wash,
                  title: 'Lava-Rápido & Estética',
                  subtitle: 'Lavagem rápida e polimento',
                  color: Colors.indigo[500]!,
                  onTap: () => _openGoogleMaps('lava rapido estetica automotiva'),
                ),
                _ServiceCategoryCard(
                  icon: Icons.support,
                  title: 'Guincho 24 Horas',
                  subtitle: 'Auto socorro mecânico emergencial',
                  color: Colors.red[600]!,
                  onTap: () => _openGoogleMaps('guincho 24 horas auto socorro'),
                ),
              ],
            ),

            if (stationFuels.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preços Registrados nos Postos',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${stationFuels.length} registros',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E24) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey[300]!,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stationFuels.take(5).length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = stationFuels[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.storefront, color: AppColors.goldenPollen),
                      title: Text(
                        item.gasStation,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${item.fuelType} • ${formatDate(item.date)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${formatMoney(item.pricePerLiter)}/${item.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldenPollen,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E24) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
