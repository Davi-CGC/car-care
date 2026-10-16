import 'formatters.dart';

/// Validações usadas nos formulários (retornam null quando o valor é válido).
class Validators {
  Validators._();

  static String? required(String? value, [String field = 'Campo']) {
    if (value == null || value.trim().isEmpty) return '$field é obrigatório';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu nome';
    if (value.trim().length < 3) return 'Nome muito curto';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    final valid = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$').hasMatch(value.trim());
    return valid ? null : 'E-mail inválido';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha';
    if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
    return null;
  }

  /// Valida números (aceita vírgula ou ponto como separador decimal).
  static String? number(String? value, {String field = 'Valor', bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$field é obrigatório' : null;
    }
    final n = parseNumber(value);
    if (n == null) return 'Número inválido';
    if (n < 0) return 'Não pode ser negativo';
    return null;
  }

  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ano é obrigatório';
    final y = int.tryParse(value.trim().split(' ').first);
    if (y == null || y < 1900 || y > DateTime.now().year + 1) return 'Ano inválido';
    return null;
  }
}
