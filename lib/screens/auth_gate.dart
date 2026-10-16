import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import 'home/home_screen.dart';
import 'login_screen.dart';

/// Decide qual tela mostrar: Login (deslogado) ou Home (logado).
/// Reage automaticamente quando o usuário entra ou sai.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: AppLogo(size: 120)));
        }
        if (snapshot.data == null) return const LoginScreen();
        // A key garante que a Home seja recriada ao trocar de usuário.
        return HomeScreen(key: ValueKey(snapshot.data!.uid));
      },
    );
  }
}
