import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fipe.dart';
import '../models/veiculo.dart';

/// Consulta a Tabela FIPE pela API pública (sem chave) em português:
/// https://deividfortuna.github.io/fipe/
class ServicoFipe {
  static const _urlBase = 'https://parallelum.com.br/fipe/api/v1';

  String _caminho(TipoVeiculo tipo) {
    switch (tipo) {
      case TipoVeiculo.moto:
        return 'motos';
      case TipoVeiculo.caminhao:
        return 'caminhoes';
      case TipoVeiculo.carro:
        return 'carros';
    }
  }

  Future<List<ItemFipe>> marcas(TipoVeiculo tipo) async {
    final dados = await _get('${_caminho(tipo)}/marcas') as List;
    return dados.map(ItemFipe.fromJson).toList();
  }

  Future<List<ItemFipe>> brands(TipoVeiculo type) => marcas(type);

  Future<List<ItemFipe>> modelos(TipoVeiculo tipo, String marca) async {
    final dados = await _get('${_caminho(tipo)}/marcas/$marca/modelos');
    return (dados['modelos'] as List).map(ItemFipe.fromJson).toList();
  }

  Future<List<ItemFipe>> models(TipoVeiculo type, String brand) => modelos(type, brand);

  Future<List<ItemFipe>> anos(TipoVeiculo tipo, String marca, String modelo) async {
    final dados = await _get('${_caminho(tipo)}/marcas/$marca/modelos/$modelo/anos') as List;
    return dados.map(ItemFipe.fromJson).toList();
  }

  Future<List<ItemFipe>> years(TipoVeiculo type, String brand, String model) =>
      anos(type, brand, model);

  Future<ResultadoFipe> preco(
      TipoVeiculo tipo, String marca, String modelo, String ano) async {
    final dados = await _get('${_caminho(tipo)}/marcas/$marca/modelos/$modelo/anos/$ano');
    return ResultadoFipe.fromJson(dados as Map<String, dynamic>);
  }

  Future<ResultadoFipe> price(
          TipoVeiculo type, String brand, String model, String year) =>
      preco(type, brand, model, year);

  Future<dynamic> _get(String caminho) async {
    final resposta = await http
        .get(Uri.parse('$_urlBase/$caminho'))
        .timeout(const Duration(seconds: 20));
    if (resposta.statusCode == 429) {
      throw Exception('Limite de consultas da FIPE atingido. Tente mais tarde.');
    }
    if (resposta.statusCode != 200) {
      throw Exception('Tabela FIPE indisponível (erro ${resposta.statusCode}).');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }
}

/// Alias para manter compatibilidade
typedef FipeService = ServicoFipe;
