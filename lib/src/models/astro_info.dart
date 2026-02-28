/// Contains astronomical and astrological information for a Myanmar date
class AstroInfo {
  /// Create a new astro info
  AstroInfo({
    required List<String> astrologicalDays,
    required this.sabbath,
    required this.yatyaza,
    required this.pyathada,
    required this.nagahle,
    required this.mahabote,
    required this.nakhat,
    required this.yearName,
  }) : astrologicalDays = List.unmodifiable(astrologicalDays);

  /// Astrological days
  final List<String> astrologicalDays;

  /// Sabbath
  final String sabbath;

  /// Yatyaza
  final String yatyaza;

  /// Pyathada
  final String pyathada;

  /// Naga head direction
  final String nagahle;

  /// Mahabote
  final String mahabote;

  /// Nakhat
  final String nakhat;

  /// Year name
  final String yearName;

  /// Whether the day is generally considered auspicious
  bool get isAuspicious {
    if (yatyaza.isEmpty) return false;
    if (pyathada.isNotEmpty) return false;

    final badDays = {'thamanyo', 'warameittugyi', 'yatyotema'};
    for (final day in astrologicalDays) {
      if (badDays.contains(day.toLowerCase())) return false;
    }

    return true;
  }

  /// Whether the day is considered highly auspicious (Amyeittasote)
  bool get isHighlyAuspicious {
    return astrologicalDays.any((d) => d.toLowerCase() == 'amyeittasote');
  }

  @override
  String toString() {
    return 'AstroInfo(astrologicalDays: $astrologicalDays, '
        'sabbathInfo: $sabbath, yatyaza: $yatyaza, pyathada: $pyathada, '
        'nagahle: $nagahle, mahabote: $mahabote, nakhat: $nakhat, '
        'yearName: $yearName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AstroInfo &&
        other.sabbath == sabbath &&
        other.yatyaza == yatyaza &&
        other.pyathada == pyathada &&
        other.nagahle == nagahle &&
        other.mahabote == mahabote &&
        other.nakhat == nakhat &&
        other.yearName == yearName &&
        _listEquals(other.astrologicalDays, astrologicalDays);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(astrologicalDays),
    sabbath,
    yatyaza,
    pyathada,
    nagahle,
    mahabote,
    nakhat,
    yearName,
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
