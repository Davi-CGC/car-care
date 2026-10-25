import 'package:flutter/material.dart';

import '../models/alerta_manutencao.dart';
import '../theme/cores_app.dart';

/// Etiqueta colorida com a situação de um serviço em português.
class ChipStatus extends StatelessWidget {
  final StatusAlerta status;
  const ChipStatus(this.status, {super.key});

  static Color corDe(StatusAlerta status) => switch (status) {
        StatusAlerta.vencido => CoresApp.perigo,
        StatusAlerta.proximo => CoresApp.aviso,
        StatusAlerta.ok => CoresApp.sucesso,
        StatusAlerta.nenhum => Colors.grey,
      };

  static Color colorOf(StatusAlerta status) => corDe(status);

  static String rotuloDe(StatusAlerta status) => switch (status) {
        StatusAlerta.vencido => 'Atrasado',
        StatusAlerta.proximo => 'Em breve',
        StatusAlerta.ok => 'Em dia',
        StatusAlerta.nenhum => 'Sem registro',
      };

  static String labelOf(StatusAlerta status) => rotuloDe(status);

  @override
  Widget build(BuildContext context) {
    final cor = corDe(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rotuloDe(status),
        style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

/// Alias para manter compatibilidade
typedef StatusChip = ChipStatus;
