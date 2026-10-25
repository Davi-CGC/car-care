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
    final partePosto = r.postoCombustivel.trim().isNotEmpty ? ' ${r.postoCombustivel} • ' : '';
    final etiquetaTanque = r.eEletrico
        ? (r.tanqueCheio ? 'Carga 100%' : 'Carga Parcial')
        : (r.tanqueCheio ? 'Tanque Cheio' : 'Parcial');

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
