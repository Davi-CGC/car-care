import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/dialogs.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';
import '../widgets/loading_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().register(_name.text, _email.text, _password.text);
      if (!mounted) return;
      showMessage(context, 'Conta criada com sucesso! Bem-vindo(a).');
      // Volta para a raiz, onde o AuthGate já está mostrando a Home.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } catch (e) {
      if (mounted) showMessage(context, 'Erro ao salvar perfil: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 80)),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _name,
                      label: 'Nome',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _email,
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _password,
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      helper: 'Mínimo de 6 caracteres',
                      isPassword: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirmar senha',
                      icon: Icons.lock_reset,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _register,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirme a senha';
                        if (v != _password.text) return 'As senhas não conferem';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    LoadingButton(
                      label: 'Cadastrar',
                      loading: _loading,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Já tenho conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
