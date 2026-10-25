import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Referência para o documento do usuário logado: users/{uid} em português.
/// Todos os repositórios salvam os dados dentro dele.
DocumentReference<Map<String, dynamic>> documentoUsuarioAtual() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

// Alias de compatibilidade
DocumentReference<Map<String, dynamic>> currentUserDoc() => documentoUsuarioAtual();
