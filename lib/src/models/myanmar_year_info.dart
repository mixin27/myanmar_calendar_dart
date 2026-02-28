/// Typed metadata for a Myanmar calendar year.
class MyanmarYearInfo {
  /// Creates a [MyanmarYearInfo] instance.
  const MyanmarYearInfo({
    required this.year,
    required this.yearType,
    required this.isWatat,
    required this.firstDayJdn,
    required this.fullMoonJdn,
  });

  /// Creates a [MyanmarYearInfo] from a map representation.
  factory MyanmarYearInfo.fromMap(Map<String, Object?> map) {
    return MyanmarYearInfo(
      year: map['year']! as int,
      yearType: map['yearType']! as int,
      isWatat: map['isWatat']! as bool,
      firstDayJdn: map['firstDayJdn']! as int,
      fullMoonJdn: map['fullMoonJdn']! as int,
    );
  }

  /// Myanmar year value.
  final int year;

  /// Year type (0=common, 1=little watat, 2=big watat).
  final int yearType;

  /// Whether this year is a watat year.
  final bool isWatat;

  /// Julian day number for the first day of the year.
  final int firstDayJdn;

  /// Julian day number for the full moon day in Waso.
  final int fullMoonJdn;

  /// Converts this object to a map representation.
  Map<String, Object> toMap() {
    return {
      'year': year,
      'yearType': yearType,
      'isWatat': isWatat,
      'firstDayJdn': firstDayJdn,
      'fullMoonJdn': fullMoonJdn,
    };
  }

  @override
  String toString() {
    return 'MyanmarYearInfo('
        'year: $year, '
        'yearType: $yearType, '
        'isWatat: $isWatat, '
        'firstDayJdn: $firstDayJdn, '
        'fullMoonJdn: $fullMoonJdn'
        ')';
  }
}
