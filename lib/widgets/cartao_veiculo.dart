import 'package:flutter/material.dart';

import '../models/veiculo.dart';
import '../theme/cores_app.dart';
import '../utils/auxiliar_rodizio.dart';
import '../utils/formatadores.dart';

/// Card de veículo usado na lista de veículos em português.
class CartaoVeiculo extends StatelessWidget {
  final Veiculo veiculo;
  final int quantidadeAlertas;
  final VoidCallback aoTocar;

  const CartaoVeiculo({
    super.key,
    required this.veiculo,
    required this.aoTocar,
    this.quantidadeAlertas = 0,
  });

  IconData get _icone {
    if (veiculo.eCaminhao) return Icons.local_shipping;
    if (veiculo.eCarro) return Icons.directions_car;
    return Icons.two_wheeler;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final detalhes = [
      veiculo.ano,
      if (veiculo.placa.isNotEmpty) veiculo.placa.toUpperCase(),
      formatarKm(veiculo.kmAtual),
    ].where((s) => s.isNotEmpty).join(' • ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CoresApp.obsidian,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _icone,
                  color: CoresApp.amareloPolen,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            veiculo.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (veiculo.usaEnergiaEletrica) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (veiculo.eEletrico ? Colors.green : Colors.teal)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (veiculo.eEletrico ? Colors.green : Colors.teal)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 12,
                                  color: veiculo.eEletrico ? Colors.green[600] : Colors.teal[600],
                                ),
                                Text(
                                  veiculo.propulsao.rotuloCurto,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: veiculo.eEletrico ? Colors.green[600] : Colors.teal[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (veiculo.eCaminhao && veiculo.viagemAtiva) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CoresApp.sucesso.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: CoresApp.sucesso.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_fill, size: 11, color: CoresApp.sucesso),
                                SizedBox(width: 3),
                                Text(
                                  'EM VIAGEM',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: CoresApp.sucesso,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(detalhes, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (veiculo.valorFipe.isNotEmpty)
                      Text('FIPE: ${veiculo.valorFipe}',
                          style: tema.textTheme.bodySmall),
                    if (veiculo.placa.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Builder(builder: (_) {
                        final rodizio = AuxiliarRodizio.obterInformacoes(
                          veiculo.placa,
                          tipo: veiculo.tipo,
                          propulsao: veiculo.propulsao,
                        );
                        if (rodizio.eIsento) {
                          return Text(
                            veiculo.eMoto
                                ? 'Isento de rodízio'
                                : '${rodizio.nomeDia} de rodízio',
                            style: TextStyle(
                              fontSize: 11,
                              color: veiculo.usaEnergiaEletrica ? Colors.green[600] : Colors.grey,
                              fontWeight: veiculo.usaEnergiaEletrica ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rodizio.eHoje
                                ? CoresApp.aviso.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: rodizio.eHoje
                                ? Border.all(color: CoresApp.aviso, width: 1)
                                : null,
                          ),
                          child: Text(
                            rodizio.eHoje
                                ? '⚠️ Rodízio Hoje (${rodizio.nomeDia})'
                                : 'Rodízio: ${rodizio.nomeDia}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: rodizio.eHoje ? FontWeight.bold : FontWeight.normal,
                              color: rodizio.eHoje ? CoresApp.aviso : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              if (quantidadeAlertas > 0)
                Badge(
                  label: Text('$quantidadeAlertas'),
                  backgroundColor: CoresApp.perigo,
                  child: const Icon(Icons.notifications_active),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class VehicleCard extends CartaoVeiculo {
  const VehicleCard({
    super.key,
    required Veiculo vehicle,
    required VoidCallback onTap,
    int alertCount = 0,
  }) : super(
         veiculo: vehicle,
         aoTocar: onTap,
         quantidadeAlertas: alertCount,
       );
}
