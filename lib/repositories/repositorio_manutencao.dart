import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/manutencao.dart';
import 'referencia_usuario.dart';

/// CRUD de manutenções em users/{uid}/maintenances em português.
class RepositorioManutencao {
  CollectionReference<Map<String, dynamic>> get _colecao =>
      documentoUsuarioAtual().collection('maintenances');

  /// Todas as manutenções, da mais recente para a mais antiga.
  Stream<List<Manutencao>> observarTodas() => _colecao
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Manutencao.fromDoc).toList());

  Stream<List<Manutencao>> watchAll() => observarTodas();

  /// Manutenções de um veículo (ordenadas no app para não exigir índice).
  Stream<List<Manutencao>> observarPorVeiculo(String idVeiculo) => _colecao
      .where('vehicleId', isEqualTo: idVeiculo)
      .snapshots()
      .map((snap) => snap.docs.map(Manutencao.fromDoc).toList()
        ..sort((a, b) => b.data.compareTo(a.data)));

  Stream<List<Manutencao>> watchByVehicle(String vehicleId) =>
      observarPorVeiculo(vehicleId);

  Future<void> adicionar(Manutencao m) => _colecao.add(m.toMap());
  Future<void> add(Manutencao m) => adicionar(m);

  Future<void> atualizar(Manutencao m) => _colecao.doc(m.id).update(m.toMap());
  Future<void> update(Manutencao m) => atualizar(m);

  Future<void> excluir(String id) => _colecao.doc(id).delete();
  Future<void> delete(String id) => excluir(id);
}

/// Alias para manter compatibilidade
typedef MaintenanceRepository = RepositorioManutencao;
