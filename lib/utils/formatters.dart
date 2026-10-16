import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _number = NumberFormat.decimalPattern('pt_BR');
final _date = DateFormat('dd/MM/yyyy');

String formatMoney(num value) => _money.format(value);

String formatKm(num value) => '${_number.format(value)} km';

String formatNumber(num value, [int decimals = 1]) =>
    NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: decimals)
        .format(value);

String formatDate(DateTime date) => _date.format(date);

/// "outubro/2026"
String formatMonth(DateTime date) => DateFormat('MMM/yy', 'pt_BR').format(date);

/// Converte texto digitado em número. Aceita "45,90" ou "45.90".
double? parseNumber(String text) =>
    double.tryParse(text.trim().replaceAll(' ', '').replaceAll(',', '.'));
