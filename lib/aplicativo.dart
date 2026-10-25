import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/roteador_autenticacao.dart';
import 'screens/tela_erro_firebase.dart';
import 'theme/controlador_tema.dart';
import 'theme/tema_app.dart';
import 'utils/constantes.dart';

class AplicativoCarCare extends StatelessWidget {
  final String? erroFirebase;
  const AplicativoCarCare({
    super.key,
    this.erroFirebase,
  });

  String? get firebaseError => erroFirebase;

  @override
  Widget build(BuildContext context) {
    // Reconstrói o app quando o usuário troca o tema.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controladorTema,
      builder: (context, modo, _) => MaterialApp(
        title: nomeApp,
        debugShowCheckedModeBanner: false,
        theme: TemaApp.claro,
        darkTheme: TemaApp.escuro,
        themeMode: modo,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: erroFirebase == null
            ? const RoteadorAutenticacao()
            : TelaErroFirebase(erro: erroFirebase!),
      ),
    );
  }
}

/// Subclasse para manter compatibilidade
class CarCareApp extends AplicativoCarCare {
  const CarCareApp({super.key, String? firebaseError})
      : super(erroFirebase: firebaseError);
}
