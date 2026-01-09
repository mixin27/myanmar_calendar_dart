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
  final double startJdn;

  /// End Julian day number.
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

  /// Check if the entry includes a Julian day number.
  bool includesJdn(double jdn) =>
      jdn >= startJdn && (endJdn == null || jdn <= endJdn!);
}

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
