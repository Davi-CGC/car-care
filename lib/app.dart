import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth_gate.dart';
import 'screens/firebase_error_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/constants.dart';

class CarCareApp extends StatelessWidget {
  final String? firebaseError;
  const CarCareApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    // Reconstrói o app quando o usuário troca o tema.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) => MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: firebaseError == null
            ? const AuthGate()
            : FirebaseErrorScreen(error: firebaseError!),
      ),
    );
  }
}
