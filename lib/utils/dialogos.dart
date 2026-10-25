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
