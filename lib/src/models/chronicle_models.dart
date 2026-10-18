/// Chronicle entry data.
class ChronicleEntryData {
  /// Create a new Chronicle entry data.
  const ChronicleEntryData({
    required this.id,
    required this.startJdn,
    required this.title,
    this.endJdn,
    this.summary,
    this.tags = const [],
    this.dynastyId,
    this.rulerId,
  });

  ///
  final String id;

  /// Start Julian day number.
  ///
  /// Any time on the day works; the built-in entries use the whole
  /// (noon-based) day number, like `MyanmarDate.julianDayNumber`.
  final double startJdn;

  /// End Julian day number, inclusive. Null for a one-day event.
  final double? endJdn;

  /// Title.
  final Map<String, String> title; // 'my', 'en', etc.
  /// Summary.
  final Map<String, String>? summary;

  /// Tags.
  final List<String> tags;

  /// Dynasty ID.
  final String? dynastyId;

  /// Ruler ID.
  final String? rulerId;

  /// Day number of the first day of the entry.
  int get startDay => _dayOf(startJdn);

  /// Day number of the last day of the entry (the first day when [endJdn]
  /// is null).
  int get endDay => _dayOf(endJdn ?? startJdn);

  /// Whether the entry covers the day of [jdn].
  ///
  /// An entry without [endJdn] is a one-day event.
  bool includesJdn(double jdn) {
    final day = _dayOf(jdn);
    return day >= startDay && day <= endDay;
  }

  /// Whether the entry covers any day from [startJdn] to [endJdn].
  bool overlapsJdn(double startJdn, double endJdn) {
    final a = _dayOf(startJdn <= endJdn ? startJdn : endJdn);
    final b = _dayOf(startJdn <= endJdn ? endJdn : startJdn);
    return startDay <= b && endDay >= a;
  }
}

/// The whole day number (noon-based) of the local day containing [jdn].
///
/// Times from midnight (`n - 0.5`) up to the next midnight belong to day `n`,
/// matching `MyanmarDate.julianDayNumber`.
int _dayOf(double jdn) => (jdn + 0.5).floor();

/// Dynasty data.
class DynastyData {
  /// Create a new Dynasty data.
  const DynastyData({
    required this.id,
    required this.name,
    required this.startJdn,
    required this.endJdn,
  });

  ///
  final String id;

  /// Name.
  final Map<String, String> name;

  /// Start Julian day number.
  final double startJdn;

  /// End Julian day number.
  final double endJdn;
}

/// Ruler data.
class RulerData {
  /// Create a new Ruler data.
  const RulerData({
    required this.id,
    required this.dynastyId,
    required this.name,
    required this.startJdn,
    required this.endJdn,
  });

  /// ID
  final String id;

  /// Dynasty ID.
  final String dynastyId;

  /// Name.
  final Map<String, String> name;

  /// Start Julian day number.
  final double startJdn;

  /// End Julian day number.
  final double endJdn;
}
