import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/registro_abastecimento.dart';
import 'referencia_usuario.dart';

/// CRUD de abastecimentos em users/{uid}/fuel em português.
class RepositorioAbastecimento {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      documentoUsuarioAtual().collection('fuel');

  Stream<List<RegistroAbastecimento>> observarTodos() => _colecao
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(RegistroAbastecimento.fromDoc).toList());

  Stream<List<RegistroAbastecimento>> watchAll() => observarTodos();

  Stream<List<RegistroAbastecimento>> observarPorVeiculo(String idVeiculo) => _colecao
      .where('vehicleId', isEqualTo: idVeiculo)
      .snapshots()
      .map((snap) => snap.docs.map(RegistroAbastecimento.fromDoc).toList()
        ..sort((a, b) => b.data.compareTo(a.data)));

  Stream<List<RegistroAbastecimento>> watchByVehicle(String vehicleId) =>
      observarPorVeiculo(vehicleId);

  Future<void> adicionar(RegistroAbastecimento f) => _colecao.add(f.toMap());
  Future<void> add(RegistroAbastecimento f) => adicionar(f);

  Future<void> atualizar(RegistroAbastecimento f) => _colecao.doc(f.id).update(f.toMap());
  Future<void> update(RegistroAbastecimento f) => atualizar(f);

  Future<void> excluir(String id) => _colecao.doc(id).delete();
  Future<void> delete(String id) => excluir(id);
}

/// Alias para manter compatibilidade
typedef FuelRepository = RepositorioAbastecimento;
