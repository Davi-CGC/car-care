import 'package:flutter/material.dart';

import '../widgets/layout.dart';
import '../widgets/logo_app.dart';

/// Mostrada quando o Firebase não foi configurado (falta o firebase_options.dart) em português.
class TelaErroFirebase extends StatelessWidget {
  final String erro;
  const TelaErroFirebase({super.key, required this.erro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CentroResponsivo(
            larguraMaxima: 520,
            filho: Column(
              children: [
                const LogoApp(tamanho: 96),
                const SizedBox(height: 24),
                Text('Firebase não configurado',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                const Text(
                  'Para usar o CarCare é preciso conectar o projeto ao Firebase:\n\n'
                  '1. dart pub global activate flutterfire_cli\n'
                  '2. flutterfire configure\n'
                  '3. Ative "E-mail/senha" no Authentication\n'
                  '4. Crie o Cloud Firestore e publique o firestore.rules\n\n'
                  'Consulte as instruções de configuração do Firebase.',
                ),
                const SizedBox(height: 16),
                Text(erro, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade
class FirebaseErrorScreen extends TelaErroFirebase {
  const FirebaseErrorScreen({super.key, required String error})
      : super(erro: error);
}
