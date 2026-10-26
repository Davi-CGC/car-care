import 'package:flutter/material.dart';

import '../services/servico_autenticacao.dart';
import '../theme/cores_app.dart';
import '../utils/constantes.dart';
import '../utils/dialogos.dart';
import '../utils/validadores.dart';
import '../widgets/bloco_termos_condicoes.dart';
import '../widgets/botao_carregamento.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/logo_app.dart';
import 'tela_cadastro.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _servicoAutenticacao = ServicoAutenticacao();
  bool _carregando = false;
  bool _aceitouTermos = false;
  bool _tentouEntrarSemTermos = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() => _erro = null);
    if (!_chaveFormulario.currentState!.validate()) return;
    if (!_aceitouTermos) {
      setState(() {
        _tentouEntrarSemTermos = true;
        _erro = 'Você deve aceitar os Termos e Condições para entrar no aplicativo.';
      });
      return;
    }
    setState(() => _carregando = true);
    try {
      await _servicoAutenticacao.entrar(_email.text, _senha.text);
      // O RoteadorAutenticacao abre a TelaPrincipal automaticamente.
    } on ExcecaoAutenticacao catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _esqueciSenha() async {
    final erroEmail = Validadores.email(_email.text);
    if (erroEmail != null) {
      mostrarMensagem(context, 'Digite seu e-mail no campo acima primeiro.', erro: true);
      return;
    }
    try {
      await _servicoAutenticacao.redefinirSenha(_email.text);
      if (mounted) mostrarMensagem(context, 'Enviamos um link de redefinição para o seu e-mail.');
    } on ExcecaoAutenticacao catch (e) {
      if (mounted) mostrarMensagem(context, e.mensagem, erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
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
                    const Center(child: LogoApp(tamanho: 110)),
                    const SizedBox(height: 16),
                    Text(nomeApp,
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    Text(sloganApp,
                        textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
                    const SizedBox(height: 32),
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
                      eSenha: true,
                      acaoTeclado: TextInputAction.done,
                      aoSubmeter: _entrar,
                      validador: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _esqueciSenha,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    BlocoTermosCondicoes(
                      aceitou: _aceitouTermos,
                      aoAlterar: (v) => setState(() {
                        _aceitouTermos = v;
                        if (v) {
                          _tentouEntrarSemTermos = false;
                          _erro = null;
                        }
                      }),
                      exibirErro: _tentouEntrarSemTermos && !_aceitouTermos,
                    ),
                    const SizedBox(height: 16),
                    if (_erro != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CoresApp.perigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: CoresApp.perigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_erro!,
                                  style: const TextStyle(color: CoresApp.perigo)),
                            ),
                          ],
                        ),
                      ),
                    BotaoCarregamento(rotulo: 'Entrar', carregando: _carregando, aoPressionar: _entrar),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Não tem conta?'),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TelaCadastro()),
                          ),
                          child: const Text('Criar conta',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
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
typedef LoginScreen = TelaLogin;
