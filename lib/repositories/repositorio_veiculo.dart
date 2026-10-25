import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/veiculo.dart';
import 'referencia_usuario.dart';

/// CRUD de veículos em users/{uid}/vehicles em português.
class RepositorioVeiculo {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      documentoUsuarioAtual().collection('vehicles');

  Stream<List<Veiculo>> observarTodos() => _colecao
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(Veiculo.fromDoc).toList());

  Stream<List<Veiculo>> watchAll() => observarTodos();

  Stream<Veiculo?> observar(String id) => _colecao
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Veiculo.fromDoc(doc) : null);

  Stream<Veiculo?> watch(String id) => observar(id);

  Future<void> adicionar(Veiculo veiculo) => _colecao.add(veiculo.toMap());
  Future<void> add(Veiculo vehicle) => adicionar(vehicle);

  Future<void> atualizar(Veiculo veiculo) =>
      _colecao.doc(veiculo.id).update(veiculo.toMap());
  Future<void> update(Veiculo vehicle) => atualizar(vehicle);

  /// Atualiza a quilometragem apenas se o novo valor for maior.
  Future<void> atualizarKmSeMaior(Veiculo veiculo, int km) async {
    if (km > veiculo.kmAtual) {
      await _colecao.doc(veiculo.id).update({'currentKm': km});
    }
  }

  Future<void> updateKmIfGreater(Veiculo vehicle, int km) =>
      atualizarKmSeMaior(vehicle, km);

  Future<void> definirKm(String id, int km) =>
      _colecao.doc(id).update({'currentKm': km});
  Future<void> setKm(String id, int km) => definirKm(id, km);

  /// Exclui o veículo e também todas as manutenções e abastecimentos dele.
  Future<void> excluir(String id) async {
    final docUsuario = documentoUsuarioAtual();
    final lote = FirebaseFirestore.instance.batch();
    for (final colecao in ['maintenances', 'fuel']) {
      final relacionados =
          await docUsuario.collection(colecao).where('vehicleId', isEqualTo: id).get();
      for (final doc in relacionados.docs) {
        lote.delete(doc.reference);
      }
    }
    lote.delete(_colecao.doc(id));
    await lote.commit();
  }

  Future<void> delete(String id) => excluir(id);
}

/// Alias para manter compatibilidade
typedef VehicleRepository = RepositorioVeiculo;
