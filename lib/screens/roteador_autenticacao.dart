import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/servico_autenticacao.dart';
import '../widgets/logo_app.dart';
import 'home/tela_principal.dart';
import 'tela_login.dart';

/// Decide qual tela mostrar: Login (deslogado) ou Início (logado) em português.
/// Reage automaticamente quando o usuário entra ou sai.
class RoteadorAutenticacao extends StatelessWidget {
  const RoteadorAutenticacao({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: ServicoAutenticacao().mudancasAutenticacao,
      builder: (context, instantaneo) {
        if (instantaneo.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: LogoApp(tamanho: 120)));
        }
        if (instantaneo.data == null) return const TelaLogin();
        // A key garante que a TelaPrincipal seja recriada ao trocar de usuário.
        return TelaPrincipal(key: ValueKey(instantaneo.data!.uid));
      },
    );
  }
}

/// Alias para manter compatibilidade
typedef AuthGate = RoteadorAutenticacao;
