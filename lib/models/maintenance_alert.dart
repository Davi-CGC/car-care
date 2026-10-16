import 'maintenance.dart';
import 'vehicle.dart';

enum AlertStatus { none, ok, soon, overdue }

/// Alerta de serviço futuro, gerado a partir da última manutenção
/// de cada categoria que tenha "próximo km" ou "próxima data".
class MaintenanceAlert {
  final Vehicle vehicle;
  final Maintenance maintenance;
  final AlertStatus status;

  const MaintenanceAlert(this.vehicle, this.maintenance, this.status);
}
