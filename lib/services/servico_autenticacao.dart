import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Erro de autenticação com mensagem pronta para mostrar ao usuário em português.
class ExcecaoAutenticacao implements Exception {
  final String mensagem;
  ExcecaoAutenticacao(this.mensagem);

  String get message => mensagem;

  @override
  String toString() => mensagem;
}

typedef AuthException = ExcecaoAutenticacao;

/// Login, cadastro e logout usando o Firebase Authentication em português.
class ServicoAutenticacao {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get mudancasAutenticacao => _auth.authStateChanges();
  Stream<User?> get authChanges => mudancasAutenticacao;

  User? get usuarioAtual => _auth.currentUser;
  User? get currentUser => usuarioAtual;

  Future<void> entrar(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
    } on FirebaseAuthException catch (e) {
      throw ExcecaoAutenticacao(_mensagem(e.code));
    }
  }

  Future<void> signIn(String email, String password) => entrar(email, password);

  /// Cria a conta e salva o perfil em users/{uid}.
  Future<void> cadastrar(String nome, String email, String senha) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final usuario = cred.user!;
      await usuario.updateDisplayName(nome.trim());
      await _db.collection('users').doc(usuario.uid).set({
        'name': nome.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw ExcecaoAutenticacao(_mensagem(e.code));
    }
  }

  Future<void> register(String name, String email, String password) =>
      cadastrar(name, email, password);

  Future<void> redefinirSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw ExcecaoAutenticacao(_mensagem(e.code));
    }
  }

  Future<void> resetPassword(String email) => redefinirSenha(email);

  Future<void> sair() => _auth.signOut();
  Future<void> signOut() => sair();

  /// Traduz os códigos de erro do Firebase.
  static String _mensagem(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha não está ativado no Firebase.';
      default:
        return 'Não foi possível concluir ($codigo).';
    }
  }
}

/// Alias para manter compatibilidade
typedef AuthService = ServicoAutenticacao;
