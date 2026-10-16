import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datas e números no padrão brasileiro.
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';

  // Tema salvo (claro/escuro).
  await themeController.load();

  // Firebase. Se não estiver configurado, o app mostra uma tela de ajuda.
  String? firebaseError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(CarCareApp(firebaseError: firebaseError));
}
