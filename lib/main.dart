import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'aplicativo.dart';
import 'firebase_options.dart';
import 'theme/controlador_tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datas e números no padrão brasileiro.
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  // Tema salvo (claro/escuro).
  await controladorTema.carregar();

  // Firebase. Se não estiver configurado, o app mostra uma tela de ajuda.
  String? erroFirebase;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    erroFirebase = e.toString();
  }

  runApp(AplicativoCarCare(erroFirebase: erroFirebase));
}
