import 'package:flutter/material.dart';

import '../models/alerta_manutencao.dart';
import '../models/manutencao.dart';
import '../models/registro_abastecimento.dart';
import '../theme/cores_app.dart';
import '../utils/catalogo_manutencao.dart';
import '../utils/formatadores.dart';
import 'chip_status.dart';

/// Linha de manutenção usada no histórico em português.
class ItemManutencaoTile extends StatelessWidget {
  final Manutencao manutencao;
  final String? nomeVeiculo;
  final VoidCallback? aoTocar;

  const ItemManutencaoTile({
    super.key,
    required this.manutencao,
    this.nomeVeiculo,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final m = manutencao;
    final subtitulo = [
      ?nomeVeiculo,
      formatarData(m.data),
      formatarKm(m.km),
    ].join(' • ');
    return Card(
      child: ListTile(
        onTap: aoTocar,
        leading: _CaixaIcone(CatalogoManutencao.iconeDe(m.categoria)),
        title: Text(m.categoria, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitulo, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(formatarMoeda(m.custo),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class MaintenanceTile extends ItemManutencaoTile {
  const MaintenanceTile({
    super.key,
    required Manutencao maintenance,
    String? vehicleName,
    VoidCallback? onTap,
  }) : super(
         manutencao: maintenance,
         nomeVeiculo: vehicleName,
         aoTocar: onTap,
       );
}

/// Linha de abastecimento em português.
class ItemAbastecimentoTile extends StatelessWidget {
  final RegistroAbastecimento registro;
  final VoidCallback? aoTocar;

  const ItemAbastecimentoTile({
    super.key,
    required this.registro,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final partePosto = r.postoCombustivel.trim().isNotEmpty ? '${r.postoCombustivel} • ' : '';
    final etiquetaTanque = r.eEletrico
        ? (r.tanqueCheio ? 'Carga 100%' : 'Carga Parcial')
        : (r.tanqueCheio ? 'Tanque Cheio' : 'Parcial');

    if (r.possuiDadosViagem) {
      final resKmL = r.resultadoKmPorLitroViagem;
      final resCustoKm = r.resultadoCustoPorKmViagem;
      final kmRodados = r.kmRodadosViagem;
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: CoresApp.amareloPolen.withValues(alpha: 0.45)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _CaixaIcone(Icons.local_shipping),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Viagem Finalizada${r.resumoImplementoViagem.isNotEmpty ? " • ${r.resumoImplementoViagem}" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            r.litros > 0
                                ? '$partePosto${formatarData(r.data)} • ${r.tipoCombustivel} (${formatarNumero(r.litros, 2)} ${r.unidade})'
                                : '$partePosto${formatarData(r.data)} • Viagem sem abastecimento',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      r.precoTotal > 0 ? formatarMoeda(r.precoTotal) : 'Sem Custo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: CoresApp.amareloPolen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (r.kmInicialViagem != null)
                      _BadgeViagem(
                        icone: Icons.route,
                        texto:
                            '${formatarKm(r.kmInicialViagem!)} ➔ ${formatarKm(r.km)} (${formatarKm(kmRodados)} rodados)',
                      ),
                    if (r.pesoCargaTon != null && r.pesoCargaTon! > 0)
                      _BadgeViagem(
                        icone: Icons.scale,
                        texto:
                            'Carga: ${formatarNumero(r.pesoCargaTon!, 1)} t${r.notaFiscalCte.isNotEmpty ? " (NF/CT-e: ${r.notaFiscalCte})" : ""}',
                      ),
                    if (resKmL != null)
                      _BadgeViagem(
                        icone: Icons.speed,
                        texto: 'Resultado 1: ${formatarNumero(resKmL, 2)} ${r.unidadeConsumo}',
                        destaque: true,
                      ),
                    if (resCustoKm != null)
                      _BadgeViagem(
                        icone: Icons.payments_outlined,
                        texto: 'Resultado 2: ${formatarMoeda(resCustoKm)}/km',
                        destaque: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        onTap: aoTocar,
        leading: _CaixaIcone(r.eEletrico ? Icons.ev_station : Icons.local_gas_station),
        title: Text('${r.tipoCombustivel} • ${formatarNumero(r.litros, 2)} ${r.unidade} • ${formatarMoeda(r.precoPorLitro)}/${r.unidade}'),
        subtitle: Text('$partePosto${formatarData(r.data)} • ${formatarKm(r.km)} • $etiquetaTanque'),
        trailing: Text(formatarMoeda(r.precoTotal),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class FuelTile extends ItemAbastecimentoTile {
  const FuelTile({
    super.key,
    required RegistroAbastecimento record,
    VoidCallback? onTap,
  }) : super(
         registro: record,
         aoTocar: onTap,
       );
}

/// Linha de alerta (serviço atrasado ou próximo) em português.
class ItemAlertaTile extends StatelessWidget {
  final AlertaManutencao alerta;
  final VoidCallback? aoTocar;

  const ItemAlertaTile({
    super.key,
    required this.alerta,
    this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final m = alerta.manutencao;
    final cor = ChipStatus.corDe(alerta.status);
    final vencimento = [
      if (m.proximoKm != null) formatarKm(m.proximoKm!),
      if (m.proximaData != null) formatarData(m.proximaData!),
    ].join(' ou ');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cor, width: 1.5),
      ),
      child: ListTile(
        onTap: aoTocar,
        leading: Icon(
          alerta.status == StatusAlerta.vencido ? Icons.error : Icons.schedule,
          color: cor,
        ),
        title: Text(m.categoria, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${alerta.veiculo.nome}\nPróximo: $vencimento',
            maxLines: 3, overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: ChipStatus(alerta.status),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade com chamadas em inglês
class AlertTile extends ItemAlertaTile {
  const AlertTile({
    super.key,
    required AlertaManutencao alert,
    VoidCallback? onTap,
  }) : super(
         alerta: alert,
         aoTocar: onTap,
       );
}

class _CaixaIcone extends StatelessWidget {
  final IconData icone;
  const _CaixaIcone(this.icone);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: CoresApp.amareloPolen.withValues(alpha: 0.18),
      child: Icon(icone, color: Theme.of(context).brightness == Brightness.dark
          ? CoresApp.amareloPolen
          : CoresApp.obsidian),
    );
  }
}

class _BadgeViagem extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool destaque;

  const _BadgeViagem({
    required this.icone,
    required this.texto,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? CoresApp.sucesso : CoresApp.amareloPolen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 11,
                fontWeight: destaque ? FontWeight.bold : FontWeight.w600,
                color: destaque ? cor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
