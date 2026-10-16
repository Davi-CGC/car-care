import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Mostra uma mensagem rápida na parte de baixo da tela.
void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : null,
    ));
}

/// Caixa de confirmação. Retorna true se o usuário confirmar.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Excluir',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Abre o seletor de data em português.
Future<DateTime?> pickDate(BuildContext context, DateTime initial,
    {DateTime? first, DateTime? last}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(1990),
    lastDate: last ?? DateTime(2100),
  );
}
