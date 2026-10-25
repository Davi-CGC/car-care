import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Modelo de posto ou eletroposto próximo retornado pela geolocalização + OpenStreetMap.
class PostoProximo {
  final String nome;
  final String endereco;
  final double distanciaKm;
  final bool eEletroposto;

  const PostoProximo({
    required this.nome,
    this.endereco = '',
    this.distanciaKm = 0,
    this.eEletroposto = false,
  });

  /// Distância formatada (ex: "1,2 km")
  String get rotuloDistancia {
    if (distanciaKm <= 0) return 'Próximo';
    return '${distanciaKm.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Rótulo formatado para exibição na lista (ex: "Posto Shell • Av. Brasil (1,2 km)")
  String get rotuloExibicao {
    final partes = <String>[nome];
    if (endereco.isNotEmpty && !nome.toLowerCase().contains(endereco.toLowerCase())) {
      partes.add(endereco);
    }
    final base = partes.join(' - ');
    if (distanciaKm > 0) {
      return '$base ($rotuloDistancia)';
    }
    return base;
  }
}

/// Serviço que busca os postos de combustível e eletropostos reais ao redor do usuário
/// usando geolocalização HTTPS + OpenStreetMap Overpass API (sem exigir chave paga).
class ServicoPostosProximos {
  static List<PostoProximo>? _cacheCombustivel;
  static List<PostoProximo>? _cacheEletrico;
  static String? _cidadeDetectada;

  static String? get cidadeDetectada => _cidadeDetectada;

  /// Retorna uma lista de postos reais próximos à localização atual do usuário.
  Future<List<PostoProximo>> buscarPostosProximos({bool eletrico = false}) async {
    if (eletrico && _cacheEletrico != null && _cacheEletrico!.isNotEmpty) {
      return _cacheEletrico!;
    }
    if (!eletrico && _cacheCombustivel != null && _cacheCombustivel!.isNotEmpty) {
      return _cacheCombustivel!;
    }

    try {
      final coords = await _obterCoordenadasAproximadas();
      if (coords == null) return const [];

      final lat = coords.$1;
      final lon = coords.$2;
      final raioMetros = eletrico ? 15000 : 8000;
      final amenity = eletrico ? 'charging_station' : 'fuel';

      final query = '[out:json][timeout:8];'
          '('
          'node["amenity"="$amenity"](around:$raioMetros,$lat,$lon);'
          'way["amenity"="$amenity"](around:$raioMetros,$lat,$lon);'
          ');'
          'out center 35;';

      final uri = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 7));
      if (resp.statusCode != 200) return const [];

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final elements = (data['elements'] as List?) ?? const [];

      final resultados = <PostoProximo>[];
      final nomesVistos = <String>{};

      for (final el in elements) {
        if (el is! Map<String, dynamic>) continue;
        final tags = (el['tags'] as Map<String, dynamic>?) ?? const {};

        final rawName = (tags['name'] ?? tags['brand'] ?? tags['operator'] ?? '').toString().trim();
        final brand = (tags['brand'] ?? '').toString().trim();
        final street = (tags['addr:street'] ?? tags['addr:suburb'] ?? tags['addr:city'] ?? '').toString().trim();

        String nomeFinal = rawName;
        if (nomeFinal.isEmpty && brand.isNotEmpty) {
          nomeFinal = eletrico ? 'Eletroposto $brand' : 'Posto $brand';
        }
        if (nomeFinal.isEmpty && street.isNotEmpty) {
          nomeFinal = eletrico ? 'Eletroposto ($street)' : 'Posto ($street)';
        }
        if (nomeFinal.isEmpty) continue;

        // Se o nome não começa com "Posto" e é uma bandeira conhecida, deixa claro
        if (!eletrico &&
            !nomeFinal.toLowerCase().contains('posto') &&
            !nomeFinal.toLowerCase().contains('auto')) {
          nomeFinal = 'Posto $nomeFinal';
        }

        double? elLat = (el['lat'] as num?)?.toDouble();
        double? elLon = (el['lon'] as num?)?.toDouble();
        if (elLat == null || elLon == null) {
          final center = el['center'] as Map<String, dynamic>?;
          elLat = (center?['lat'] as num?)?.toDouble();
          elLon = (center?['lon'] as num?)?.toDouble();
        }

        final distKm = (elLat != null && elLon != null)
            ? _calcularDistanciaKm(lat, lon, elLat, elLon)
            : 0.0;

        final chaveUnica = '${nomeFinal.toLowerCase()}|${street.toLowerCase()}';
        if (nomesVistos.add(chaveUnica)) {
          resultados.add(
            PostoProximo(
              nome: nomeFinal,
              endereco: street,
              distanciaKm: distKm,
              eEletroposto: eletrico,
            ),
          );
        }
      }

      resultados.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));

      if (resultados.isNotEmpty) {
        if (eletrico) {
          _cacheEletrico = resultados;
        } else {
          _cacheCombustivel = resultados;
        }
      }
      return resultados;
    } catch (_) {
      return const [];
    }
  }

  Future<(double, double)?> _obterCoordenadasAproximadas() async {
    // 1ª tentativa: geojs.io (HTTPS rápido e com CORS liberado)
    try {
      final r = await http
          .get(Uri.parse('https://get.geojs.io/v1/ip/geo.json'))
          .timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final map = jsonDecode(r.body) as Map<String, dynamic>;
        final lat = double.tryParse((map['latitude'] ?? '').toString());
        final lon = double.tryParse((map['longitude'] ?? '').toString());
        final city = (map['city'] ?? '').toString().trim();
        if (city.isNotEmpty) _cidadeDetectada = city;
        if (lat != null && lon != null) return (lat, lon);
      }
    } catch (_) {}

    // 2ª tentativa: ipwho.is (fallback HTTPS com CORS liberado)
    try {
      final r = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final map = jsonDecode(r.body) as Map<String, dynamic>;
        final lat = (map['latitude'] as num?)?.toDouble();
        final lon = (map['longitude'] as num?)?.toDouble();
        final city = (map['city'] ?? '').toString().trim();
        if (city.isNotEmpty) _cidadeDetectada = city;
        if (lat != null && lon != null) return (lat, lon);
      }
    } catch (_) {}

    return null;
  }

  double _calcularDistanciaKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Raio da Terra em km
    final dLat = _grausParaRadianos(lat2 - lat1);
    final dLon = _grausParaRadianos(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_grausParaRadianos(lat1)) *
            math.cos(_grausParaRadianos(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _grausParaRadianos(double graus) => graus * (math.pi / 180.0);
}

typedef NearbyStationsService = ServicoPostosProximos;
