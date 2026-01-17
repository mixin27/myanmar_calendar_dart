import 'package:collection/collection.dart';
import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';

/// Configuration class for the Myanmar Calendar
class CalendarConfig {
  /// Create config with default values
  const CalendarConfig({
    this.sasanaYearType = 0,
    this.calendarType = 0,
    this.gregorianStart = 2361222,
    this.timezoneOffset = 6.5, // Myanmar Time UTC+6:30
    this.defaultLanguage = 'en',
    this.customHolidays = const [],
    this.disabledHolidays = const [],
    this.disabledHolidaysByYear = const {},
  });

  /// Create config with Myanmar Time (UTC+6:30)
  factory CalendarConfig.myanmarTime() {
    return const CalendarConfig(defaultLanguage: 'my');
  }

  /// Create config with Ancient Myanmar Time (UTC+6:24:47)
  factory CalendarConfig.ancientMyanmarTime() {
    return const CalendarConfig(timezoneOffset: 6.41306, defaultLanguage: 'my');
  }

  /// Package-wide global configuration
  static CalendarConfig _global = const CalendarConfig();

  /// Get the package-wide global configuration
  static CalendarConfig get global => _global;

  /// Set the package-wide global configuration
  static set global(CalendarConfig config) => _global = config;

  /// Sasana year type
  ///
  /// 0 = year depends only on the sun, do not take account moon phase for Sasana year
  ///
  /// 1 = Sasana year starts on the first day of Tagu
  ///
  /// 2 = Sasana year starts on Kason full moon day
  final int sasanaYearType;

  /// Calendar type for Julian/Gregorian calculations
  ///
  /// 0 = British (default), 1 = Gregorian, 2 = Julian
  final int calendarType;

  /// Beginning of Gregorian calendar in JDN [default=2361222]
  final int gregorianStart;

  /// Default timezone offset in hours (e.g., 6.5 for Myanmar Time)
  ///
  /// This is used only for display purposes. Internal calculations
  /// are done in UTC to maintain consistency.
  ///
  /// Common Myanmar timezone offsets:
  /// - Yangon/Myanmar Time (MMT): UTC+6:30 (6.5)
  /// - Ancient Myanmar Time: UTC+6:24:47 (6.41306)
  final double timezoneOffset;

  /// Default language for translations
  final String defaultLanguage;

  /// Custom holidays defined by the consumer
  final List<CustomHoliday> customHolidays;

  /// List of built-in holidays to disable globally
  final List<HolidayId> disabledHolidays;

  /// Map of Western year to list of built-in holidays to disable for that specific year
  final Map<int, List<HolidayId>> disabledHolidaysByYear;

  /// Get the current timezone offset in days
  double get timezoneOffsetInDays => timezoneOffset / 24.0;

  /// Convert local time to UTC Julian Day Number
  double localToUtc(double localJdn) => localJdn - timezoneOffsetInDays;

  /// Convert UTC Julian Day Number to local time
  double utcToLocal(double utcJdn) => utcJdn + timezoneOffsetInDays;

  /// Copy with new values
  CalendarConfig copyWith({
    int? sasanaYearType,
    int? calendarType,
    int? gregorianStart,
    double? timezoneOffset,
    String? defaultLanguage,
    List<CustomHoliday>? customHolidays,
    List<HolidayId>? disabledHolidays,
    Map<int, List<HolidayId>>? disabledHolidaysByYear,
  }) {
    return CalendarConfig(
      sasanaYearType: sasanaYearType ?? this.sasanaYearType,
      calendarType: calendarType ?? this.calendarType,
      gregorianStart: gregorianStart ?? this.gregorianStart,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      customHolidays: customHolidays ?? this.customHolidays,
      disabledHolidays: disabledHolidays ?? this.disabledHolidays,
      disabledHolidaysByYear:
          disabledHolidaysByYear ?? this.disabledHolidaysByYear,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalendarConfig &&
        other.sasanaYearType == sasanaYearType &&
        other.calendarType == calendarType &&
        other.gregorianStart == gregorianStart &&
        other.timezoneOffset == timezoneOffset &&
        other.defaultLanguage == defaultLanguage &&
        const ListEquality<CustomHoliday>().equals(
          other.customHolidays,
          customHolidays,
        ) &&
        const ListEquality<HolidayId>().equals(
          other.disabledHolidays,
          disabledHolidays,
        ) &&
        const MapEquality<int, List<HolidayId>>().equals(
          other.disabledHolidaysByYear,
          disabledHolidaysByYear,
        );
  }

  @override
  int get hashCode {
    return sasanaYearType.hashCode ^
        calendarType.hashCode ^
        gregorianStart.hashCode ^
        timezoneOffset.hashCode ^
        defaultLanguage.hashCode ^
        const ListEquality<CustomHoliday>().hash(customHolidays) ^
        const ListEquality<HolidayId>().hash(disabledHolidays) ^
        const MapEquality<int, List<HolidayId>>().hash(disabledHolidaysByYear);
  }
}
