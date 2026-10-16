import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vehicle.dart';
import 'user_ref.dart';

/// CRUD de veículos em users/{uid}/vehicles.
class VehicleRepository {
  CollectionReference<Map<String, dynamic>> get _col =>
      currentUserDoc().collection('vehicles');

  Stream<List<Vehicle>> watchAll() => _col
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(Vehicle.fromDoc).toList());

  Stream<Vehicle?> watch(String id) => _col
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Vehicle.fromDoc(doc) : null);

  Future<void> add(Vehicle vehicle) => _col.add(vehicle.toMap());

  Future<void> update(Vehicle vehicle) =>
      _col.doc(vehicle.id).update(vehicle.toMap());

  /// Atualiza a quilometragem apenas se o novo valor for maior.
  Future<void> updateKmIfGreater(Vehicle vehicle, int km) async {
    if (km > vehicle.currentKm) {
      await _col.doc(vehicle.id).update({'currentKm': km});
    }
  }

  Future<void> setKm(String id, int km) => _col.doc(id).update({'currentKm': km});

  /// Exclui o veículo e também todas as manutenções e abastecimentos dele.
  Future<void> delete(String id) async {
    final userDoc = currentUserDoc();
    final batch = FirebaseFirestore.instance.batch();
    for (final collection in ['maintenances', 'fuel']) {
      final related =
          await userDoc.collection(collection).where('vehicleId', isEqualTo: id).get();
      for (final doc in related.docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(_col.doc(id));
    await batch.commit();
  }
}
