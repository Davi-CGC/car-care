import 'manutencao.dart';
import 'veiculo.dart';

enum StatusAlerta { nenhum, ok, proximo, vencido }

// Aliases de compatibilidade
typedef AlertStatus = StatusAlerta;

extension StatusAlertaCompat on StatusAlerta {
  static const StatusAlerta none = StatusAlerta.nenhum;
  static const StatusAlerta ok = StatusAlerta.ok;
  static const StatusAlerta soon = StatusAlerta.proximo;
  static const StatusAlerta overdue = StatusAlerta.vencido;
}

/// Alerta de serviço futuro em português.
class AlertaManutencao {
  final Veiculo veiculo;
  final Manutencao manutencao;
  final StatusAlerta status;

  const AlertaManutencao(this.veiculo, this.manutencao, this.status);

  // Aliases de compatibilidade
  Veiculo get vehicle => veiculo;
  Manutencao get maintenance => manutencao;
}

/// Alias para manter compatibilidade
typedef MaintenanceAlert = AlertaManutencao;
