import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _numero = NumberFormat.decimalPattern('pt_BR');
final _data = DateFormat('dd/MM/yyyy');

String formatarMoeda(num valor) => _moeda.format(valor);

String formatarKm(num valor) => '${_numero.format(valor)} km';

String formatarNumero(num valor, [int casasDecimais = 1]) =>
    NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: casasDecimais)
        .format(valor);

String formatarData(DateTime data) => _data.format(data);

/// "outubro/2026"
String formatarMes(DateTime data) => DateFormat('MMM/yy', 'pt_BR').format(data);

/// Converte texto digitado em número. Aceita "45,90", "45.90", "1.250,50", "1250.50", "105.000".
double? converterNumero(String? texto) {
  if (texto == null) return null;
  var limpo = texto.trim().replaceAll(' ', '').replaceAll(r'R$', '').replaceAll('km', '').replaceAll('KM', '');
  if (limpo.isEmpty) return null;

  if (limpo.contains('.') && limpo.contains(',')) {
    // Ex: "1.250,50" -> remove o ponto de milhar e troca vírgula por ponto
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  } else if (limpo.contains(',')) {
    // Ex: "1250,50" -> troca vírgula por ponto
    limpo = limpo.replaceAll(',', '.');
  } else if (limpo.contains('.')) {
    final partes = limpo.split('.');
    if (partes.length > 2) {
      // Ex: "1.000.000"
      limpo = limpo.replaceAll('.', '');
    } else if (partes.length == 2 && partes.last.length == 3) {
      // Ex: "1.500" ou "105.000" no padrão brasileiro -> milhar
      limpo = limpo.replaceAll('.', '');
    }
  }
  return double.tryParse(limpo);
}

/// Converte texto de odômetro em número inteiro, aceitando separadores de milhar ("105.000", "105000", "105.450 km").
int? converterKm(String? texto) {
  if (texto == null) return null;
  final limpo = texto.replaceAll('km', '').replaceAll('KM', '').replaceAll(' ', '').trim();
  if (limpo.isEmpty) return null;
  if (limpo.contains('.')) {
    final partes = limpo.split('.');
    if (partes.length > 1 && partes.last.length == 3) {
      return int.tryParse(limpo.replaceAll('.', ''));
    }
  }
  if (limpo.contains(',')) {
    final partes = limpo.split(',');
    if (partes.length > 1 && partes.last.length == 3) {
      return int.tryParse(limpo.replaceAll(',', ''));
    }
  }
  final d = converterNumero(limpo);
  return d?.round();
}

// Aliases de compatibilidade
String formatMoney(num value) => formatarMoeda(value);
String formatKm(num value) => formatarKm(value);
String formatNumber(num value, [int decimals = 1]) => formatarNumero(value, decimals);
String formatDate(DateTime date) => formatarData(date);
String formatMonth(DateTime date) => formatarMes(date);
double? parseNumber(String? text) => converterNumero(text);
int? parseKm(String? text) => converterKm(text);
