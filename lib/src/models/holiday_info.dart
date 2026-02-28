/// Contains holiday information for a given date
class HolidayInfo {
  /// Create a new holiday info
  HolidayInfo({
    required List<String> publicHolidays,
    required List<String> religiousHolidays,
    required List<String> culturalHolidays,
    required List<String> otherHolidays,
    required List<String> myanmarAnniversaryDays,
    required List<String> otherAnniversaryDays,
  }) : publicHolidays = List.unmodifiable(publicHolidays),
       religiousHolidays = List.unmodifiable(religiousHolidays),
       culturalHolidays = List.unmodifiable(culturalHolidays),
       otherHolidays = List.unmodifiable(otherHolidays),
       myanmarAnniversaryDays = List.unmodifiable(myanmarAnniversaryDays),
       otherAnniversaryDays = List.unmodifiable(otherAnniversaryDays);

  /// Public holidays
  final List<String> publicHolidays;

  /// Religious holidays
  final List<String> religiousHolidays;

  /// Cultural holidays
  final List<String> culturalHolidays;

  /// Other holidays
  final List<String> otherHolidays;

  /// Myanmar anniversary days - Others special days (not holidays)
  final List<String> myanmarAnniversaryDays;

  /// Myanmar anniversary days - Others special days (not holidays)
  final List<String> otherAnniversaryDays;

  /// Get all holidays combined
  List<String> get allHolidays => [
    ...publicHolidays,
    ...religiousHolidays,
    ...culturalHolidays,
    ...otherHolidays,
  ];

  /// Check if there are any holidays on this date
  bool get hasHolidays => allHolidays.isNotEmpty;

  /// Get all anniversary days combined
  List<String> get allAnniversaryDays => [
    ...myanmarAnniversaryDays,
    ...otherAnniversaryDays,
  ];

  /// Check if there are any anniversary days on this date
  bool get hasAnniversaryDays => allAnniversaryDays.isNotEmpty;

  @override
  String toString() {
    return 'HolidayInfo(public: $publicHolidays, '
        'religious: $religiousHolidays, '
        'cultural: $culturalHolidays, '
        'other: $otherHolidays, '
        'myanmarAnniversary: $myanmarAnniversaryDays, '
        'otherAnniversary: $otherAnniversaryDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HolidayInfo &&
        _listEquals(other.publicHolidays, publicHolidays) &&
        _listEquals(other.religiousHolidays, religiousHolidays) &&
        _listEquals(other.culturalHolidays, culturalHolidays) &&
        _listEquals(other.otherHolidays, otherHolidays) &&
        _listEquals(other.myanmarAnniversaryDays, myanmarAnniversaryDays) &&
        _listEquals(other.otherAnniversaryDays, otherAnniversaryDays);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(publicHolidays),
    Object.hashAll(religiousHolidays),
    Object.hashAll(culturalHolidays),
    Object.hashAll(otherHolidays),
    Object.hashAll(myanmarAnniversaryDays),
    Object.hashAll(otherAnniversaryDays),
  );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
