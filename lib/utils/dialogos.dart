import 'package:flutter/material.dart';

import '../theme/cores_app.dart';

/// Mostra uma mensagem rápida na parte de baixo da tela.
void mostrarMensagem(BuildContext context, String mensagem, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? CoresApp.perigo : null,
    ));
}

/// Caixa de confirmação. Retorna true se o usuário confirmar.
Future<bool> dialogoConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Excluir',
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: CoresApp.perigo),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return resultado ?? false;
}

/// Abre o seletor de data em português.
Future<DateTime?> selecionarData(BuildContext context, DateTime dataInicial,
    {DateTime? primeiro, DateTime? ultimo}) {
  return showDatePicker(
    context: context,
    initialDate: dataInicial,
    firstDate: primeiro ?? DateTime(1990),
    lastDate: ultimo ?? DateTime(2100),
  );
}

/// Abre o modal com os Termos e Condições de Uso da Empresa.
void exibirModalTermosECondicoes(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.gavel, color: CoresApp.amareloPolen),
          SizedBox(width: 8),
          Expanded(child: Text('Termos e Condições')),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Termos de Uso e Política de Privacidade da Empresa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text(
              '1. Aceitação dos Termos\n'
              'Ao utilizar este aplicativo, você declara ter lido, compreendido e concordado integralmente com as regras, termos e políticas da nossa empresa.\n\n'
              '2. Finalidade da Plataforma\n'
              'O aplicativo destina-se ao gerenciamento de veículos, despesas, manutenções, rotinas de abastecimento e controle de frota/viagens de caminhão.\n\n'
              '3. Veracidade dos Dados\n'
              'O usuário é o único responsável pela veracidade e exatidão das informações inseridas (odômetro, notas fiscais, CT-e, valores de combustível e despesas).\n\n'
              '4. Privacidade e Segurança\n'
              'Seus dados veiculares e permissões (como localização para busca de postos próximos) são utilizados exclusivamente para o funcionamento dos serviços e protegidos com segurança.\n\n'
              '5. Obrigatoriedade de Aceite\n'
              'O aceite destes termos é requisito obrigatório para a criação de conta, login e permanência no aplicativo.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: CoresApp.amareloPolen,
            foregroundColor: CoresApp.obsidiana,
          ),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

// Aliases de compatibilidade
void showMessage(BuildContext context, String message, {bool error = false}) =>
    mostrarMensagem(context, message, erro: error);

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Excluir',
}) =>
    dialogoConfirmacao(context, titulo: title, mensagem: message, textoConfirmar: confirmText);

Future<DateTime?> pickDate(BuildContext context, DateTime initial,
        {DateTime? first, DateTime? last}) =>
    selecionarData(context, initial, primeiro: first, ultimo: last);
