import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';

/// One holiday or anniversary on a date: what it is ([id] or [customId]),
/// its [type] and its display [name] in the requested language.
class Holiday {
  /// Creates a holiday entry.
  const Holiday({
    required this.type,
    required this.name,
    this.id,
    this.customId,
  });

  /// The built-in holiday, or null for a custom one.
  final HolidayId? id;

  /// The `CustomHoliday.id` of a custom holiday, or null for a built-in one.
  final String? customId;

  /// Its category.
  final HolidayType type;

  /// Its name, translated; use [id] or [customId] to tell holidays apart.
  final String name;

  /// Whether it comes from a custom holiday rule.
  bool get isCustom => customId != null;

  @override
  bool operator ==(Object other) =>
      other is Holiday &&
      other.id == id &&
      other.customId == customId &&
      other.type == type &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, customId, type, name);

  @override
  String toString() => 'Holiday(${id?.name ?? customId}, ${type.name}, $name)';
}

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
    List<Holiday> entries = const [],
  }) : entries = List.unmodifiable(entries),
       publicHolidays = List.unmodifiable(publicHolidays),
       religiousHolidays = List.unmodifiable(religiousHolidays),
       culturalHolidays = List.unmodifiable(culturalHolidays),
       otherHolidays = List.unmodifiable(otherHolidays),
       myanmarAnniversaryDays = List.unmodifiable(myanmarAnniversaryDays),
       otherAnniversaryDays = List.unmodifiable(otherAnniversaryDays);

  /// Every holiday and anniversary on the date, with stable IDs. The name
  /// lists below hold the same names, for display.
  final List<Holiday> entries;

  /// Whether the date has the built-in holiday [id], whatever the language.
  bool has(HolidayId id) => entries.any((h) => h.id == id);

  /// Whether the date has the custom holiday with `CustomHoliday.id` [id].
  bool hasCustom(String id) => entries.any((h) => h.customId == id);

  /// Entries of one [type].
  List<Holiday> ofType(HolidayType type) => [
    for (final h in entries)
      if (h.type == type) h,
  ];

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
