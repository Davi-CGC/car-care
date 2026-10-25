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

/// Converte texto digitado em número. Aceita "45,90" ou "45.90".
double? converterNumero(String texto) =>
    double.tryParse(texto.trim().replaceAll(' ', '').replaceAll(',', '.'));

// Aliases de compatibilidade
String formatMoney(num value) => formatarMoeda(value);
String formatKm(num value) => formatarKm(value);
String formatNumber(num value, [int decimals = 1]) => formatarNumero(value, decimals);
String formatDate(DateTime date) => formatarData(date);
String formatMonth(DateTime date) => formatarMes(date);
double? parseNumber(String text) => converterNumero(text);
