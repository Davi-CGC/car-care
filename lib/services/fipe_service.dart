import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fipe.dart';
import '../models/vehicle.dart';

/// Consulta a Tabela FIPE pela API pública (sem chave):
/// https://deividfortuna.github.io/fipe/
class FipeService {
  static const _baseUrl = 'https://parallelum.com.br/fipe/api/v1';

  String _path(VehicleType type) => type == VehicleType.moto ? 'motos' : 'carros';

  Future<List<FipeItem>> brands(VehicleType type) async {
    final data = await _get('${_path(type)}/marcas') as List;
    return data.map(FipeItem.fromJson).toList();
  }

  Future<List<FipeItem>> models(VehicleType type, String brand) async {
    final data = await _get('${_path(type)}/marcas/$brand/modelos');
    return (data['modelos'] as List).map(FipeItem.fromJson).toList();
  }

  Future<List<FipeItem>> years(VehicleType type, String brand, String model) async {
    final data = await _get('${_path(type)}/marcas/$brand/modelos/$model/anos') as List;
    return data.map(FipeItem.fromJson).toList();
  }

  Future<FipeResult> price(
      VehicleType type, String brand, String model, String year) async {
    final data = await _get('${_path(type)}/marcas/$brand/modelos/$model/anos/$year');
    return FipeResult.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _get(String path) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/$path'))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 429) {
      throw Exception('Limite de consultas da FIPE atingido. Tente mais tarde.');
    }
    if (response.statusCode != 200) {
      throw Exception('Tabela FIPE indisponível (erro ${response.statusCode}).');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
