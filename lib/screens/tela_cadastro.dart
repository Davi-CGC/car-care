import 'package:flutter/material.dart';

import '../services/servico_autenticacao.dart';
import '../utils/dialogos.dart';
import '../utils/validadores.dart';
import '../widgets/botao_carregamento.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/logo_app.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    setState(() => _carregando = true);
    try {
      await ServicoAutenticacao().cadastrar(_nome.text, _email.text, _senha.text);
      if (!mounted) return;
      mostrarMensagem(context, 'Conta criada com sucesso! Bem-vindo(a).');
      // Volta para a raiz, onde o RoteadorAutenticacao já está mostrando a TelaPrincipal.
      Navigator.of(context).popUntil((rota) => rota.isFirst);
    } on ExcecaoAutenticacao catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    } catch (e) {
      if (mounted) mostrarMensagem(context, 'Erro ao salvar perfil: $e', erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
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
                key: _chaveFormulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LogoApp(tamanho: 80)),
                    const SizedBox(height: 24),
                    CampoTextoApp(
                      controlador: _nome,
                      rotulo: 'Nome',
                      icone: Icons.person_outline,
                      capitalizacaoTexto: TextCapitalization.words,
                      validador: Validadores.nome,
                    ),
                    const SizedBox(height: 16),
                    CampoTextoApp(
                      controlador: _email,
                      rotulo: 'E-mail',
                      icone: Icons.email_outlined,
                      tipoTeclado: TextInputType.emailAddress,
                      validador: Validadores.email,
                    ),
                    const SizedBox(height: 16),
                    CampoTextoApp(
                      controlador: _senha,
                      rotulo: 'Senha',
                      icone: Icons.lock_outline,
                      ajuda: 'Mínimo de 6 caracteres',
                      eSenha: true,
                      validador: Validadores.senha,
                    ),
                    const SizedBox(height: 16),
                    CampoTextoApp(
                      controlador: _confirmarSenha,
                      rotulo: 'Confirmar senha',
                      icone: Icons.lock_reset,
                      eSenha: true,
                      acaoTeclado: TextInputAction.done,
                      aoSubmeter: _cadastrar,
                      validador: (v) {
                        if (v == null || v.isEmpty) return 'Confirme a senha';
                        if (v != _senha.text) return 'As senhas não conferem';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    BotaoCarregamento(
                      rotulo: 'Cadastrar',
                      carregando: _carregando,
                      aoPressionar: _cadastrar,
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

/// Alias para manter compatibilidade
typedef RegisterScreen = TelaCadastro;
