import 'formatadores.dart';

/// Validações usadas nos formulários em português (retornam null quando o valor é válido).
class Validadores {
  Validadores._();

  static String? obrigatorio(String? valor, [String campo = 'Campo']) {
    if (valor == null || valor.trim().isEmpty) return '$campo é obrigatório';
    return null;
  }

  static String? nome(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Informe seu nome';
    if (valor.trim().length < 3) return 'Nome muito curto';
    return null;
  }

  static String? email(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Informe o e-mail';
    final valido = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w.\-]+$').hasMatch(valor.trim());
    return valido ? null : 'E-mail inválido';
  }

  static String? senha(String? valor) {
    if (valor == null || valor.isEmpty) return 'Informe a senha';
    if (valor.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
    return null;
  }

  /// Valida números (aceita vírgula ou ponto como separador decimal).
  static String? numero(String? valor, {String campo = 'Valor', bool obrigatorio = true}) {
    if (valor == null || valor.trim().isEmpty) {
      return obrigatorio ? '$campo é obrigatório' : null;
    }
    final n = converterNumero(valor);
    if (n == null) return 'Número inválido';
    if (n < 0) return 'Não pode ser negativo';
    return null;
  }

  static String? ano(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Ano é obrigatório';
    final y = int.tryParse(valor.trim().split(' ').first);
    if (y == null || y < 1900 || y > DateTime.now().year + 1) return 'Ano inválido';
    return null;
  }

  // Aliases de compatibilidade
  static String? required(String? value, [String field = 'Campo']) => obrigatorio(value, field);
  static String? name(String? value) => nome(value);
  static String? password(String? value) => senha(value);
  static String? number(String? value, {String field = 'Valor', bool required = true}) =>
      numero(value, campo: field, obrigatorio: required);
  static String? year(String? value) => ano(value);
}

/// Alias para manter compatibilidade
typedef Validators = Validadores;
