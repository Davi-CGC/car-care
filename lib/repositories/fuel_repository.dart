import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fuel_record.dart';
import 'user_ref.dart';

/// CRUD de abastecimentos em users/{uid}/fuel.
class FuelRepository {
  CollectionReference<Map<String, dynamic>> get _col =>
      currentUserDoc().collection('fuel');

  Stream<List<FuelRecord>> watchAll() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(FuelRecord.fromDoc).toList());

  Stream<List<FuelRecord>> watchByVehicle(String vehicleId) => _col
      .where('vehicleId', isEqualTo: vehicleId)
      .snapshots()
      .map((snap) => snap.docs.map(FuelRecord.fromDoc).toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Future<void> add(FuelRecord f) => _col.add(f.toMap());

  Future<void> update(FuelRecord f) => _col.doc(f.id).update(f.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();
}
