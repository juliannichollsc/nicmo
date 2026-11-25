/// Parser for Colombian street addresses such as
/// "Diagonal 54 # 17-100, Niquía" or "Cra. 43B #1a Sur - 70".
///
/// In this nomenclature the address names the street the place is on
/// (primary), the street it crosses (cross) and the distance in metres from
/// that corner. "Sur" marks streets numbered south of the origin.
class ColombianAddress {
  final String primaryType;
  final String primaryNumber;
  final bool primarySur;
  final String crossNumber;
  final bool crossSur;
  final int? meters;

  /// Words after the address (barrio, municipality) used to disambiguate.
  final List<String> hints;

  const ColombianAddress({
    required this.primaryType,
    required this.primaryNumber,
    required this.primarySur,
    required this.crossNumber,
    required this.crossSur,
    required this.meters,
    required this.hints,
  });

  static const _types = <String, List<String>>{
    'Calle': ['calle', 'clle', 'cll', 'cl', 'call'],
    'Carrera': ['carrera', 'carr', 'cra', 'kra', 'crr', 'cr', 'kr', 'k'],
    'Diagonal': ['diagonal', 'diag', 'dg'],
    'Transversal': ['transversal', 'transv', 'trans', 'trv', 'tv', 'tr'],
    'Circular': ['circular', 'circ', 'cir', 'cq'],
    'Avenida': ['avenida', 'avda', 'av'],
  };

  static const _stopWords = {
    'barrio',
    'sector',
    'urbanizacion',
    'edificio',
    'apto',
    'apartamento',
    'casa',
    'local',
    'interior',
    'piso',
    'torre',
    'del',
    'las',
    'los',
    'antioquia',
    'colombia',
  };

  static final RegExp _pattern = RegExp(
    r'^(?<type>[a-z]+)\.?\s*'
    r'(?<n1>\d{1,3})(?!\d)\s*(?<l1>[a-z](?![a-z]))?\s*(?<b1>bis)?\s*(?<s1>sur|este)?'
    r'\s*(?:#|no\.?|nro\.?|numero)?\s*'
    r'(?<n2>\d{1,3})(?!\d)\s*(?<l2>[a-z](?![a-z]))?\s*(?<b2>bis)?\s*(?<s2>sur|este)?'
    r'\s*-?\s*(?<n3>\d{1,3}(?!\d))?\s*(?<s3>sur|este)?'
    r'\s*[,;]?\s*(?<rest>.*)$',
  );

  /// Returns null when [input] is not a street address.
  static ColombianAddress? tryParse(String input) {
    final text = normalize(input)
        .replaceAll(RegExp(r'n\s*[°º]'), '#')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final type = _canonicalType(match.namedGroup('type')!);
    if (type == null) return null;

    String number(String n, String? letter, String? bis) =>
        '$n${(letter ?? '').toUpperCase()}${bis != null ? ' Bis' : ''}';

    final trailingSur = match.namedGroup('s3') != null;
    final calleLike = type == 'Calle' || type == 'Diagonal';
    return ColombianAddress(
      primaryType: type,
      primaryNumber: number(
        match.namedGroup('n1')!,
        match.namedGroup('l1'),
        match.namedGroup('b1'),
      ),
      // "Calle 10 # 43-20 Sur": a trailing "Sur" belongs to the calle.
      primarySur: match.namedGroup('s1') != null || (trailingSur && calleLike),
      crossNumber: number(
        match.namedGroup('n2')!,
        match.namedGroup('l2'),
        match.namedGroup('b2'),
      ),
      crossSur: match.namedGroup('s2') != null || (trailingSur && !calleLike),
      meters: int.tryParse(match.namedGroup('n3') ?? ''),
      hints: [
        for (final word in (match.namedGroup('rest') ?? '').split(
          RegExp(r'[^a-z0-9]+'),
        ))
          if (word.length >= 3 && !_stopWords.contains(word)) word,
      ],
    );
  }

  static String? _canonicalType(String raw) {
    for (final entry in _types.entries) {
      if (entry.value.contains(raw)) return entry.key;
    }
    return null;
  }

  /// Street name as written in OpenStreetMap, e.g. "Calle 1A Sur".
  String get primaryName =>
      '$primaryType $primaryNumber${primarySur ? ' Sur' : ''}';

  /// Possible names of the crossing street. Calles and diagonales cross
  /// carreras and transversales, and the other way round.
  List<String> get crossNames {
    final suffix = '$crossNumber${crossSur ? ' Sur' : ''}';
    final types = switch (primaryType) {
      'Calle' || 'Diagonal' => ['Carrera', 'Transversal'],
      'Carrera' || 'Transversal' => ['Calle', 'Diagonal'],
      _ => ['Calle', 'Carrera'],
    };
    return [for (final t in types) '$t $suffix'];
  }

  /// Canonical display form: "Carrera 43B # 1A Sur - 70".
  String get label {
    final cross = '$crossNumber${crossSur ? ' Sur' : ''}';
    return '$primaryName # $cross${meters != null ? ' - $meters' : ''}';
  }

  static String normalize(String value) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      final idx = from.indexOf(char);
      buffer.write(idx >= 0 ? to[idx] : char);
    }
    return buffer.toString().toLowerCase();
  }
}
