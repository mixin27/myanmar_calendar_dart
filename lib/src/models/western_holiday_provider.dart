import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';

/// Western calendar date holder for fixed holiday lookup.
class WesternHolidayDate {
  /// Creates a [WesternHolidayDate].
  const WesternHolidayDate({
    required this.month,
    required this.day,
  });

  /// Month number [1..12].
  final int month;

  /// Day number [1..31].
  final int day;

  /// Whether this date matches [month] and [day].
  bool matches(int month, int day) => this.month == month && this.day == day;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WesternHolidayDate &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(month, day);
}

/// Provider contract for western-calendar holiday rules that are not derived
/// from the Myanmar calendar itself.
class WesternHolidayProvider {
  /// Creates a [WesternHolidayProvider].
  const WesternHolidayProvider();

  /// Stable cache key for this provider configuration.
  ///
  /// Custom providers should override this when underlying rule data changes
  /// over time while reusing the same class name.
  String get cacheKey => 'provider_type_${runtimeType.hashCode}';

  /// Returns true when [holidayId] matches [year]-[month]-[day].
  bool matches(HolidayId holidayId, int year, int month, int day) => false;
}

/// Table-driven holiday provider for easy consumer overrides.
class TableWesternHolidayProvider extends WesternHolidayProvider {
  /// Creates a [TableWesternHolidayProvider].
  ///
  /// `singleDayRules` is for holidays with one fixed date per year.
  /// `multiDayRules` is for holidays that may span multiple observed days.
  const TableWesternHolidayProvider({
    this.singleDayRules = const {},
    this.multiDayRules = const {},
  });

  /// Single day rules by holiday and year.
  final Map<HolidayId, Map<int, WesternHolidayDate>> singleDayRules;

  /// Multi day rules by holiday and year.
  final Map<HolidayId, Map<int, List<WesternHolidayDate>>> multiDayRules;

  @override
  String get cacheKey {
    final singleHolidayEntries = singleDayRules.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));
    final singleKey = singleHolidayEntries
        .map((holidayEntry) {
          final yearlyEntries = holidayEntry.value.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          final dates = yearlyEntries
              .map(
                (entry) =>
                    '${entry.key}-${entry.value.month.toString().padLeft(2, '0')}-${entry.value.day.toString().padLeft(2, '0')}',
              )
              .join('.');
          return '${holidayEntry.key.name}:$dates';
        })
        .join('|');

    final multiHolidayEntries = multiDayRules.entries.toList()
      ..sort((a, b) => a.key.name.compareTo(b.key.name));
    final multiKey = multiHolidayEntries
        .map((holidayEntry) {
          final yearlyEntries = holidayEntry.value.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          final yearChunks = yearlyEntries
              .map((entry) {
                final sortedDates = [...entry.value]
                  ..sort((a, b) {
                    final monthCompare = a.month.compareTo(b.month);
                    if (monthCompare != 0) return monthCompare;
                    return a.day.compareTo(b.day);
                  });
                final dates = sortedDates
                    .map(
                      (date) =>
                          '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    )
                    .join(',');
                return '${entry.key}:$dates';
              })
              .join('.');
          return '${holidayEntry.key.name}:$yearChunks';
        })
        .join('|');

    return 'table:s[$singleKey]:m[$multiKey]';
  }

  @override
  bool matches(HolidayId holidayId, int year, int month, int day) {
    final singleByYear = singleDayRules[holidayId];
    if (singleByYear != null) {
      final date = singleByYear[year];
      if (date != null) {
        return date.matches(month, day);
      }
    }

    final multipleByYear = multiDayRules[holidayId];
    if (multipleByYear != null) {
      final dates = multipleByYear[year];
      if (dates != null) {
        for (final date in dates) {
          if (date.matches(month, day)) {
            return true;
          }
        }
      }
    }

    return false;
  }
}

/// Default provider with built-in lookup tables for approximate holidays.
class DefaultWesternHolidayProvider extends TableWesternHolidayProvider {
  /// Creates the default provider.
  const DefaultWesternHolidayProvider()
    : super(
        singleDayRules: _singleDayRules,
        multiDayRules: _multiDayRules,
      );

  @override
  String get cacheKey => 'default_western_holiday_provider:v1';

  static const Map<HolidayId, Map<int, WesternHolidayDate>> _singleDayRules = {
    HolidayId.diwali: _diwaliDates,
    HolidayId.chineseNewYear: _chineseNewYearDates,
  };

  static const Map<HolidayId, Map<int, List<WesternHolidayDate>>>
  _multiDayRules = {
    HolidayId.eidAlFitr: _eidAlFitrDates,
    HolidayId.eidAlAdha: _eidAlAdhaDates,
  };

  static const Map<int, WesternHolidayDate> _diwaliDates = {
    2014: WesternHolidayDate(month: 10, day: 23),
    2015: WesternHolidayDate(month: 11, day: 11),
    2016: WesternHolidayDate(month: 10, day: 30),
    2017: WesternHolidayDate(month: 10, day: 19),
    2018: WesternHolidayDate(month: 11, day: 7),
    2019: WesternHolidayDate(month: 10, day: 27),
    2020: WesternHolidayDate(month: 11, day: 14),
    2021: WesternHolidayDate(month: 11, day: 4),
    2022: WesternHolidayDate(month: 10, day: 24),
    2023: WesternHolidayDate(month: 11, day: 12),
    2024: WesternHolidayDate(month: 11, day: 1),
    2025: WesternHolidayDate(month: 10, day: 20),
    2026: WesternHolidayDate(month: 11, day: 8),
    2027: WesternHolidayDate(month: 10, day: 29),
    2028: WesternHolidayDate(month: 10, day: 17),
    2029: WesternHolidayDate(month: 11, day: 5),
    2030: WesternHolidayDate(month: 10, day: 26),
    2031: WesternHolidayDate(month: 11, day: 14),
    2032: WesternHolidayDate(month: 11, day: 2),
    2033: WesternHolidayDate(month: 10, day: 22),
    2034: WesternHolidayDate(month: 11, day: 10),
    2035: WesternHolidayDate(month: 10, day: 30),
    2036: WesternHolidayDate(month: 10, day: 19),
    2037: WesternHolidayDate(month: 11, day: 7),
    2038: WesternHolidayDate(month: 10, day: 27),
    2039: WesternHolidayDate(month: 10, day: 17),
    2040: WesternHolidayDate(month: 11, day: 4),
    2041: WesternHolidayDate(month: 10, day: 25),
    2042: WesternHolidayDate(month: 11, day: 12),
    2043: WesternHolidayDate(month: 11, day: 1),
  };

  static const Map<int, List<WesternHolidayDate>> _eidAlFitrDates = {
    2014: [
      WesternHolidayDate(month: 7, day: 28),
      WesternHolidayDate(month: 7, day: 29),
    ],
    2015: [
      WesternHolidayDate(month: 7, day: 17),
      WesternHolidayDate(month: 7, day: 18),
    ],
    2016: [
      WesternHolidayDate(month: 7, day: 6),
      WesternHolidayDate(month: 7, day: 7),
    ],
    2017: [
      WesternHolidayDate(month: 6, day: 25),
      WesternHolidayDate(month: 6, day: 26),
    ],
    2018: [
      WesternHolidayDate(month: 6, day: 15),
      WesternHolidayDate(month: 6, day: 16),
    ],
    2019: [
      WesternHolidayDate(month: 6, day: 4),
      WesternHolidayDate(month: 6, day: 5),
    ],
    2020: [
      WesternHolidayDate(month: 5, day: 24),
      WesternHolidayDate(month: 5, day: 25),
    ],
    2021: [
      WesternHolidayDate(month: 5, day: 13),
      WesternHolidayDate(month: 5, day: 14),
    ],
    2022: [
      WesternHolidayDate(month: 5, day: 2),
      WesternHolidayDate(month: 5, day: 3),
    ],
    2023: [
      WesternHolidayDate(month: 4, day: 21),
      WesternHolidayDate(month: 4, day: 22),
    ],
    2024: [
      WesternHolidayDate(month: 4, day: 10),
      WesternHolidayDate(month: 4, day: 11),
    ],
    2025: [
      WesternHolidayDate(month: 3, day: 30),
      WesternHolidayDate(month: 3, day: 31),
    ],
    2026: [
      WesternHolidayDate(month: 3, day: 20),
      WesternHolidayDate(month: 3, day: 21),
    ],
    2027: [
      WesternHolidayDate(month: 3, day: 9),
      WesternHolidayDate(month: 3, day: 10),
    ],
    2028: [
      WesternHolidayDate(month: 2, day: 26),
      WesternHolidayDate(month: 2, day: 27),
    ],
    2029: [
      WesternHolidayDate(month: 2, day: 14),
      WesternHolidayDate(month: 2, day: 15),
    ],
    2030: [
      WesternHolidayDate(month: 2, day: 4),
      WesternHolidayDate(month: 2, day: 5),
    ],
  };

  static const Map<int, List<WesternHolidayDate>> _eidAlAdhaDates = {
    2014: [
      WesternHolidayDate(month: 10, day: 4),
      WesternHolidayDate(month: 10, day: 5),
    ],
    2015: [
      WesternHolidayDate(month: 9, day: 23),
      WesternHolidayDate(month: 9, day: 24),
    ],
    2016: [
      WesternHolidayDate(month: 9, day: 12),
      WesternHolidayDate(month: 9, day: 13),
    ],
    2017: [
      WesternHolidayDate(month: 9, day: 1),
      WesternHolidayDate(month: 9, day: 2),
    ],
    2018: [
      WesternHolidayDate(month: 8, day: 21),
      WesternHolidayDate(month: 8, day: 22),
    ],
    2019: [
      WesternHolidayDate(month: 8, day: 11),
      WesternHolidayDate(month: 8, day: 12),
    ],
    2020: [
      WesternHolidayDate(month: 7, day: 31),
      WesternHolidayDate(month: 8, day: 1),
    ],
    2021: [
      WesternHolidayDate(month: 7, day: 20),
      WesternHolidayDate(month: 7, day: 21),
    ],
    2022: [
      WesternHolidayDate(month: 7, day: 9),
      WesternHolidayDate(month: 7, day: 10),
    ],
    2023: [
      WesternHolidayDate(month: 6, day: 28),
      WesternHolidayDate(month: 6, day: 29),
    ],
    2024: [
      WesternHolidayDate(month: 6, day: 16),
      WesternHolidayDate(month: 6, day: 17),
    ],
    2025: [
      WesternHolidayDate(month: 6, day: 6),
      WesternHolidayDate(month: 6, day: 7),
    ],
    2026: [
      WesternHolidayDate(month: 5, day: 27),
      WesternHolidayDate(month: 5, day: 28),
    ],
    2027: [
      WesternHolidayDate(month: 5, day: 16),
      WesternHolidayDate(month: 5, day: 17),
    ],
    2028: [
      WesternHolidayDate(month: 5, day: 5),
      WesternHolidayDate(month: 5, day: 6),
    ],
    2029: [
      WesternHolidayDate(month: 4, day: 24),
      WesternHolidayDate(month: 4, day: 25),
    ],
    2030: [
      WesternHolidayDate(month: 4, day: 13),
      WesternHolidayDate(month: 4, day: 14),
    ],
  };

  static const Map<int, WesternHolidayDate> _chineseNewYearDates = {
    2014: WesternHolidayDate(month: 1, day: 31),
    2015: WesternHolidayDate(month: 2, day: 19),
    2016: WesternHolidayDate(month: 2, day: 8),
    2017: WesternHolidayDate(month: 1, day: 28),
    2018: WesternHolidayDate(month: 2, day: 16),
    2019: WesternHolidayDate(month: 2, day: 5),
    2020: WesternHolidayDate(month: 1, day: 25),
    2021: WesternHolidayDate(month: 2, day: 12),
    2022: WesternHolidayDate(month: 2, day: 1),
    2023: WesternHolidayDate(month: 1, day: 22),
    2024: WesternHolidayDate(month: 2, day: 10),
    2025: WesternHolidayDate(month: 1, day: 29),
    2026: WesternHolidayDate(month: 2, day: 17),
    2027: WesternHolidayDate(month: 2, day: 6),
    2028: WesternHolidayDate(month: 1, day: 26),
    2029: WesternHolidayDate(month: 2, day: 13),
    2030: WesternHolidayDate(month: 2, day: 3),
    2031: WesternHolidayDate(month: 1, day: 23),
    2032: WesternHolidayDate(month: 2, day: 11),
    2033: WesternHolidayDate(month: 1, day: 31),
    2034: WesternHolidayDate(month: 2, day: 19),
    2035: WesternHolidayDate(month: 2, day: 8),
  };
}
