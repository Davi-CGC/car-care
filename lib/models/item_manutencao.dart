import 'package:flutter/material.dart';

/// Item do plano de manutenção (ex.: "Troca de óleo e filtro").
/// [intervaloKm] e [intervaloMeses] são sugestões usadas para calcular o
/// próximo serviço. Ficam definidos em utils/catalogo_manutencao.dart.
class ItemManutencao {
  final String nome;
  final IconData icone;
  final int? intervaloKm;
  final int? intervaloMeses;

  /// true = só aparece para carros com câmbio manual (ex.: embreagem).
  final bool apenasManual;

  const ItemManutencao(
    this.nome,
    this.icone, {
    this.intervaloKm,
    this.intervaloMeses,
    this.apenasManual = false,
  });

  String get rotuloIntervalo {
    final partes = <String>[
      if (intervaloKm != null) '$intervaloKm km',
      if (intervaloMeses != null) '$intervaloMeses meses',
    ];
    return partes.isEmpty ? 'Conforme necessidade' : 'A cada ${partes.join(' ou ')}';
  }

  // Aliases de compatibilidade
  String get name => nome;
  IconData get icon => icone;
  int? get intervalKm => intervaloKm;
  int? get intervalMonths => intervaloMeses;
  bool get onlyManual => apenasManual;
  String get intervalLabel => rotuloIntervalo;
}

/// Alias para manter compatibilidade
typedef MaintenanceItem = ItemManutencao;
