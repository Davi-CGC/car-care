import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/maintenance.dart';
import 'user_ref.dart';

/// CRUD de manutenções em users/{uid}/maintenances.
class MaintenanceRepository {
  CollectionReference<Map<String, dynamic>> get _col =>
      currentUserDoc().collection('maintenances');

  /// Todas as manutenções, da mais recente para a mais antiga.
  Stream<List<Maintenance>> watchAll() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Maintenance.fromDoc).toList());

  /// Manutenções de um veículo (ordenadas no app para não exigir índice).
  Stream<List<Maintenance>> watchByVehicle(String vehicleId) => _col
      .where('vehicleId', isEqualTo: vehicleId)
      .snapshots()
      .map((snap) => snap.docs.map(Maintenance.fromDoc).toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Future<void> add(Maintenance m) => _col.add(m.toMap());

  Future<void> update(Maintenance m) => _col.doc(m.id).update(m.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();
}
