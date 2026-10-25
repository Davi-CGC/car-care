/// Item da Tabela FIPE (marca, modelo ou ano) em português.
class ItemFipe {
  final String codigo;
  final String nome;

  const ItemFipe(this.codigo, this.nome);

  String get code => codigo;
  String get name => nome;

  factory ItemFipe.fromJson(dynamic json) =>
      ItemFipe('${json['codigo']}', '${json['nome']}');
}

/// Alias para manter compatibilidade
typedef FipeItem = ItemFipe;

/// Resultado final da consulta FIPE (preço do veículo) em português.
class ResultadoFipe {
  final String marca;
  final String modelo;
  final String ano;
  final String combustivel;
  final String codigo;
  final String valor;
  final String referencia;

  const ResultadoFipe({
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.combustivel,
    required this.codigo,
    required this.valor,
    required this.referencia,
  });

  // Aliases de compatibilidade
  String get brand => marca;
  String get model => modelo;
  String get year => ano;
  String get fuel => combustivel;
  String get code => codigo;
  String get value => valor;
  String get reference => referencia;

  factory ResultadoFipe.fromJson(Map<String, dynamic> json) => ResultadoFipe(
        marca: '${json['Marca'] ?? ''}',
        modelo: '${json['Modelo'] ?? ''}',
        ano: '${json['AnoModelo'] ?? ''}',
        combustivel: '${json['Combustivel'] ?? ''}',
        codigo: '${json['CodigoFipe'] ?? ''}',
        valor: '${json['Valor'] ?? ''}',
        referencia: '${json['MesReferencia'] ?? ''}'.trim(),
      );
}

/// Alias para manter compatibilidade
typedef FipeResult = ResultadoFipe;
