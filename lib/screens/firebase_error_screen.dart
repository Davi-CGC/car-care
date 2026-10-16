import 'package:flutter/material.dart';

import '../widgets/app_logo.dart';
import '../widgets/layout.dart';

/// Mostrada quando o Firebase não foi configurado (falta o firebase_options.dart).
class FirebaseErrorScreen extends StatelessWidget {
  final String error;
  const FirebaseErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ResponsiveCenter(
            maxWidth: 520,
            child: Column(
              children: [
                const AppLogo(size: 96),
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
                  'Veja o passo a passo completo em manual/index.html.',
                ),
                const SizedBox(height: 16),
                Text(error, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
