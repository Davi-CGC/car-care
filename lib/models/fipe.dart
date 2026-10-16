/// Item da Tabela FIPE (marca, modelo ou ano).
class FipeItem {
  final String code;
  final String name;

  const FipeItem(this.code, this.name);

  factory FipeItem.fromJson(dynamic json) =>
      FipeItem('${json['codigo']}', '${json['nome']}');
}

/// Resultado final da consulta FIPE (preço do veículo).
class FipeResult {
  final String brand;
  final String model;
  final String year;
  final String fuel;
  final String code;
  final String value;
  final String reference;

  const FipeResult({
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel,
    required this.code,
    required this.value,
    required this.reference,
  });

  factory FipeResult.fromJson(Map<String, dynamic> json) => FipeResult(
        brand: '${json['Marca'] ?? ''}',
        model: '${json['Modelo'] ?? ''}',
        year: '${json['AnoModelo'] ?? ''}',
        fuel: '${json['Combustivel'] ?? ''}',
        code: '${json['CodigoFipe'] ?? ''}',
        value: '${json['Valor'] ?? ''}',
        reference: '${json['MesReferencia'] ?? ''}'.trim(),
      );
}
