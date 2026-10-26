import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Modelo de posto ou eletroposto próximo retornado pela geolocalização + OpenStreetMap.
class PostoProximo {
  final String nome;
  final String endereco;
  final double distanciaKm;
  final bool eEletroposto;
  final String destaqueCombustivel;

  const PostoProximo({
    required this.nome,
    this.endereco = '',
    this.distanciaKm = 0,
    this.eEletroposto = false,
    this.destaqueCombustivel = '',
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
/// de acordo com o tipo de energia/combustível procurado (Elétrico, GNV, Diesel, Gasolina/Etanol).
class ServicoPostosProximos {
  static final Map<String, List<PostoProximo>> _cachePorTipo = {};
  static (double, double)? _coordenadasCache;
  static String? _cidadeDetectada;

  static String? get cidadeDetectada => _cidadeDetectada;

  static const List<String> _palavrasProibidasPosto = [
    'policial',
    'polícia',
    'policia',
    'militar',
    'guarda',
    'delegacia',
    'prf',
    'bprv',
    'pm ',
    ' pm',
    'saúde',
    'saude',
    'médico',
    'medico',
    'clínic',
    'clinic',
    'hospital',
    'ubs',
    'psf',
    'upas',
    'upa ',
    'fiscal',
    'receita',
    'alfândega',
    'alfandega',
    'pedágio',
    'pedagio',
    'pesagem',
    'balança',
    'balanca',
    'bombeiro',
    'salva-vidas',
    'guarda-vidas',
    'atendimento',
    'bancário',
    'bancario',
    'correio',
    'detran',
    'vistoria',
    'inss',
    'eleitoral',
    'fronteira',
    'rodoviário estadual',
    'rodoviario estadual',
    'polícia rodoviária',
    'policia rodoviaria',
  ];

  static bool _ehNomeDePostoInvalido(String nome) {
    final n = nome.trim().toLowerCase();
    if (n.isEmpty) return true;
    for (final proibida in _palavrasProibidasPosto) {
      if (n.contains(proibida)) return true;
    }
    return false;
  }

  /// Retorna uma lista de postos reais próximos à localização atual do usuário,
  /// filtrados de acordo com o combustível/energia selecionado.
  Future<List<PostoProximo>> buscarPostosProximos({
    bool eletrico = false,
    String tipoCombustivel = '',
    bool forcarAtualizacao = false,
  }) async {
    final combNorm = tipoCombustivel.trim().toLowerCase();
    final isEv = eletrico || combNorm.contains('eletric') || combNorm.contains('kwh');
    final isGnv = !isEv && combNorm.contains('gnv');
    final isDiesel = !isEv && combNorm.contains('diesel');

    final chaveCache = 'v2_${isEv ? 'ev' : (isGnv ? 'gnv' : (isDiesel ? 'diesel' : 'combustivel'))}';
    if (!forcarAtualizacao &&
        _cachePorTipo[chaveCache] != null &&
        _cachePorTipo[chaveCache]!.isNotEmpty) {
      return _cachePorTipo[chaveCache]!;
    }

    try {
      final coords = await _obterCoordenadasAproximadas(forcar: forcarAtualizacao);
      if (coords == null) return const [];

      final lat = coords.$1;
      final lon = coords.$2;

      // 1ª tentativa: Overpass (principal + espelho Kumi) com filtro específico
      var resultados = await _buscarViaOverpass(
        lat: lat,
        lon: lon,
        eletrico: isEv,
        gnv: isGnv,
        diesel: isDiesel,
      );

      // 2ª tentativa (fallback rápido caso Overpass esteja ocupado): Photon / Komoot OpenStreetMap API
      if (resultados.isEmpty) {
        resultados = await _buscarViaPhoton(
          lat: lat,
          lon: lon,
          eletrico: isEv,
          gnv: isGnv,
          diesel: isDiesel,
        );
      }

      if (resultados.isNotEmpty) {
        _cachePorTipo[chaveCache] = resultados;
      }
      return resultados;
    } catch (_) {
      return const [];
    }
  }

  Future<List<PostoProximo>> _buscarViaOverpass({
    required double lat,
    required double lon,
    required bool eletrico,
    required bool gnv,
    required bool diesel,
  }) async {
    final raioMetros = eletrico ? 25000 : 10000;
    final amenity = eletrico ? 'charging_station' : 'fuel';

    final query = '[out:json][timeout:6];'
        '('
        'node["amenity"="$amenity"](around:$raioMetros,$lat,$lon);'
        'way["amenity"="$amenity"](around:$raioMetros,$lat,$lon);'
        ');'
        'out center 45;';

    final endpoints = [
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
      'https://overpass.kumi.systems/api/interpreter?data=${Uri.encodeComponent(query)}',
    ];

    for (final url in endpoints) {
      try {
        final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (resp.statusCode != 200) continue;

        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final elements = (data['elements'] as List?) ?? const [];
        if (elements.isEmpty) continue;

        final resultados = <PostoProximo>[];
        final nomesVistos = <String>{};

        for (final el in elements) {
          if (el is! Map<String, dynamic>) continue;
          final tags = (el['tags'] as Map<String, dynamic>?) ?? const {};

          final rawName =
              (tags['name'] ?? tags['brand'] ?? tags['operator'] ?? '').toString().trim();
          final brand = (tags['brand'] ?? tags['operator'] ?? '').toString().trim();
          final street = (tags['addr:street'] ??
                  tags['addr:suburb'] ??
                  tags['addr:neighbourhood'] ??
                  tags['addr:city'] ??
                  _cidadeDetectada ??
                  '')
              .toString()
              .trim();

          String nomeFinal = rawName;
          if (nomeFinal.isEmpty && brand.isNotEmpty) {
            nomeFinal = eletrico ? 'Eletroposto $brand' : 'Posto $brand';
          }
          if (nomeFinal.isEmpty && street.isNotEmpty) {
            nomeFinal = eletrico ? 'Eletroposto - $street' : 'Posto - $street';
          }
          if (nomeFinal.isEmpty || _ehNomeDePostoInvalido(nomeFinal)) continue;

          if (eletrico) {
            if (!nomeFinal.toLowerCase().contains('eletro') &&
                !nomeFinal.toLowerCase().contains('recharg') &&
                !nomeFinal.toLowerCase().contains('carreg') &&
                !nomeFinal.toLowerCase().contains('estação') &&
                !nomeFinal.toLowerCase().contains('station')) {
              nomeFinal = 'Eletroposto $nomeFinal';
            }
          } else if (!nomeFinal.toLowerCase().contains('posto') &&
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

          final temGnvTag = tags['fuel:cng'] == 'yes' ||
              tags['fuel:lpg'] == 'yes' ||
              nomeFinal.toLowerCase().contains('gnv');
          final temDieselTag = tags['fuel:diesel'] == 'yes' ||
              tags['hgv'] == 'yes' ||
              nomeFinal.toLowerCase().contains('diesel') ||
              nomeFinal.toLowerCase().contains('rodovi');

          String destaque = '';
          if (eletrico) {
            final socket = (tags['socket:type2'] != null || tags['socket:ccs'] != null)
                ? 'Recarga Rápida / Tipo 2'
                : 'Recarga Elétrica (kWh)';
            destaque = socket;
          } else if (gnv && temGnvTag) {
            destaque = 'Abastece GNV';
          } else if (diesel && temDieselTag) {
            destaque = 'Abastece Diesel';
          }

          final chaveUnica = '${nomeFinal.toLowerCase()}|${street.toLowerCase()}';
          if (nomesVistos.add(chaveUnica)) {
            resultados.add(
              PostoProximo(
                nome: nomeFinal,
                endereco: street,
                distanciaKm: distKm,
                eEletroposto: eletrico,
                destaqueCombustivel: destaque,
              ),
            );
          }
        }

        // Ordena priorizando os que têm a tag específica do combustível buscado + menor distância
        resultados.sort((a, b) {
          if (a.destaqueCombustivel.isNotEmpty && b.destaqueCombustivel.isEmpty) return -1;
          if (b.destaqueCombustivel.isNotEmpty && a.destaqueCombustivel.isEmpty) return 1;
          return a.distanciaKm.compareTo(b.distanciaKm);
        });

        if (resultados.isNotEmpty) return resultados;
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  Future<List<PostoProximo>> _buscarViaPhoton({
    required double lat,
    required double lon,
    required bool eletrico,
    required bool gnv,
    required bool diesel,
  }) async {
    try {
      final amenityTag = eletrico ? 'charging_station' : 'fuel';
      final termos = eletrico
          ? ['eletroposto', 'charging', 'posto']
          : (gnv
              ? ['posto gnv', 'auto posto', 'posto shell', 'posto ipiranga', 'posto petrobras']
              : (diesel
                  ? ['posto diesel', 'auto posto', 'posto shell', 'posto ipiranga', 'posto petrobras']
                  : ['auto posto', 'posto shell', 'posto ipiranga', 'posto petrobras', 'posto']));

      final resultados = <PostoProximo>[];
      final nomesVistos = <String>{};

      for (final termo in termos) {
        final uri = Uri.parse(
          'https://photon.komoot.io/api/?q=${Uri.encodeComponent(termo)}&lat=$lat&lon=$lon&osm_tag=amenity:$amenityTag&limit=25',
        );
        final resp = await http.get(uri).timeout(const Duration(seconds: 4));
        if (resp.statusCode != 200) continue;

        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final features = (data['features'] as List?) ?? const [];

        for (final f in features) {
          if (f is! Map<String, dynamic>) continue;
          final props = (f['properties'] as Map<String, dynamic>?) ?? const {};
          final geom = (f['geometry'] as Map<String, dynamic>?) ?? const {};
          final coords = (geom['coordinates'] as List?) ?? const [];

          final osmKey = (props['osm_key'] ?? '').toString().toLowerCase();
          final osmValue = (props['osm_value'] ?? '').toString().toLowerCase();
          // Garante que apenas postos de combustível (fuel) ou eletropostos (charging_station) entrem na lista
          if (osmKey.isNotEmpty && osmValue.isNotEmpty) {
            if (eletrico && osmValue != 'charging_station' && osmValue != 'fuel') continue;
            if (!eletrico && osmValue != 'fuel') continue;
          }

          final rawName = (props['name'] ?? '').toString().trim();
          if (rawName.isEmpty || _ehNomeDePostoInvalido(rawName)) continue;

          final street =
              (props['street'] ?? props['district'] ?? props['city'] ?? '').toString().trim();

          double distKm = 0;
          if (coords.length >= 2) {
            final fLon = (coords[0] as num?)?.toDouble();
            final fLat = (coords[1] as num?)?.toDouble();
            if (fLat != null && fLon != null) {
              distKm = _calcularDistanciaKm(lat, lon, fLat, fLon);
            }
          }
          // Ignora resultados muito distantes (> 50 km)
          if (distKm > 50) continue;

          String nomeFinal = rawName;
          if (eletrico && !nomeFinal.toLowerCase().contains('eletro')) {
            nomeFinal = 'Eletroposto $nomeFinal';
          } else if (!eletrico && !nomeFinal.toLowerCase().contains('posto')) {
            nomeFinal = 'Posto $nomeFinal';
          }

          if (_ehNomeDePostoInvalido(nomeFinal)) continue;

          final chave = '${nomeFinal.toLowerCase()}|${street.toLowerCase()}';
          if (nomesVistos.add(chave)) {
            resultados.add(
              PostoProximo(
                nome: nomeFinal,
                endereco: street,
                distanciaKm: distKm,
                eEletroposto: eletrico,
                destaqueCombustivel: eletrico
                    ? 'Recarga Elétrica (kWh)'
                    : (gnv
                        ? 'Posto Próximo'
                        : (diesel ? 'Posto Próximo (Diesel)' : 'Posto de Combustível')),
              ),
            );
          }
        }
        if (resultados.length >= 10) break;
      }

      resultados.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
      return resultados;
    } catch (_) {
      return const [];
    }
  }

  Future<(double, double)?> _obterCoordenadasAproximadas({bool forcar = false}) async {
    if (!forcar && _coordenadasCache != null) return _coordenadasCache;

    // 1ª tentativa: ipwho.is
    try {
      final r = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final map = jsonDecode(r.body) as Map<String, dynamic>;
        final lat = (map['latitude'] as num?)?.toDouble();
        final lon = (map['longitude'] as num?)?.toDouble();
        final city = (map['city'] ?? '').toString().trim();
        if (city.isNotEmpty) _cidadeDetectada = city;
        if (lat != null && lon != null) {
          _coordenadasCache = (lat, lon);
          return _coordenadasCache;
        }
      }
    } catch (_) {}

    // 2ª tentativa: geojs.io
    try {
      final r = await http
          .get(Uri.parse('https://get.geojs.io/v1/ip/geo.json'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final map = jsonDecode(r.body) as Map<String, dynamic>;
        final lat = double.tryParse((map['latitude'] ?? '').toString());
        final lon = double.tryParse((map['longitude'] ?? '').toString());
        final city = (map['city'] ?? '').toString().trim();
        if (city.isNotEmpty) _cidadeDetectada = city;
        if (lat != null && lon != null) {
          _coordenadasCache = (lat, lon);
          return _coordenadasCache;
        }
      }
    } catch (_) {}

    // 3ª tentativa: freeipapi.com
    try {
      final r = await http
          .get(Uri.parse('https://freeipapi.com/api/json'))
          .timeout(const Duration(seconds: 3));
      if (r.statusCode == 200) {
        final map = jsonDecode(r.body) as Map<String, dynamic>;
        final lat = (map['latitude'] as num?)?.toDouble();
        final lon = (map['longitude'] as num?)?.toDouble();
        final city = (map['cityName'] ?? '').toString().trim();
        if (city.isNotEmpty) _cidadeDetectada = city;
        if (lat != null && lon != null) {
          _coordenadasCache = (lat, lon);
          return _coordenadasCache;
        }
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
