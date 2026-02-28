import 'package:collection/collection.dart';
import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';
import 'package:myanmar_calendar_dart/src/models/western_holiday_provider.dart';

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
    this.disabledHolidaysByDate = const {},
    this.westernHolidayProvider = const DefaultWesternHolidayProvider(),
  }) : assert(
         sasanaYearType >= 0 && sasanaYearType <= 2,
         'sasanaYearType must be between 0 and 2',
       ),
       assert(
         calendarType >= 0 && calendarType <= 2,
         'calendarType must be between 0 and 2',
       ),
       assert(
         timezoneOffset >= -12 && timezoneOffset <= 14,
         'timezoneOffset must be between -12 and 14',
       ),
       assert(gregorianStart > 0, 'gregorianStart must be greater than 0'),
       assert(defaultLanguage != '', 'defaultLanguage must not be empty');

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

  /// Custom holiday rules defined by the consumer.
  ///
  /// This is the preferred naming over [customHolidays].
  List<CustomHoliday> get customHolidayRules => customHolidays;

  /// List of built-in holidays to disable globally
  final List<HolidayId> disabledHolidays;

  /// Map of Western year to list of built-in holidays to disable for that specific year
  final Map<int, List<HolidayId>> disabledHolidaysByYear;

  /// Map of Western date (YYYY-MM-DD) to list of built-in holidays to disable for that specific date
  final Map<String, List<HolidayId>> disabledHolidaysByDate;

  /// Provider for western-calendar holiday rules (e.g., Eid/Diwali/CNY).
  final WesternHolidayProvider westernHolidayProvider;

  /// Get the current timezone offset in days
  double get timezoneOffsetInDays => timezoneOffset / 24.0;

  /// Convert local time to UTC Julian Day Number
  double localToUtc(double localJdn) => localJdn - timezoneOffsetInDays;

  /// Convert UTC Julian Day Number to local time
  double utcToLocal(double utcJdn) => utcJdn + timezoneOffsetInDays;

  /// Cache namespace fingerprint for this configuration.
  ///
  /// This is used to isolate cache entries across different configurations
  /// when sharing a global cache instance.
  String get cacheNamespace {
    final globalDisabled = disabledHolidays.map((e) => e.name).toList()..sort();

    final yearSpecific = disabledHolidaysByYear.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final yearSpecificKey = yearSpecific
        .map((entry) {
          final ids = entry.value.map((e) => e.name).toList()..sort();
          return '${entry.key}:${ids.join('.')}';
        })
        .join('|');

    final dateSpecific = disabledHolidaysByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final dateSpecificKey = dateSpecific
        .map((entry) {
          final ids = entry.value.map((e) => e.name).toList()..sort();
          return '${entry.key}:${ids.join('.')}';
        })
        .join('|');

    final customHolidayKey = customHolidays.map((holiday) {
      return holiday.cacheDescriptor;
    }).toList()..sort();
    final customHolidayFingerprint = customHolidayKey.join('|');

    return 'sy:$sasanaYearType'
        '|ct:$calendarType'
        '|gs:$gregorianStart'
        '|tz:${timezoneOffset.toStringAsFixed(6)}'
        '|lang:$defaultLanguage'
        '|dg:${globalDisabled.join(',')}'
        '|dy:$yearSpecificKey'
        '|dd:$dateSpecificKey'
        '|ch:$customHolidayFingerprint'
        '|whp:${westernHolidayProvider.cacheKey}';
  }

  /// Copy with new values
  CalendarConfig copyWith({
    int? sasanaYearType,
    int? calendarType,
    int? gregorianStart,
    double? timezoneOffset,
    String? defaultLanguage,
    List<CustomHoliday>? customHolidayRules,
    List<HolidayId>? disabledHolidays,
    Map<int, List<HolidayId>>? disabledHolidaysByYear,
    Map<String, List<HolidayId>>? disabledHolidaysByDate,
    WesternHolidayProvider? westernHolidayProvider,
  }) {
    return CalendarConfig(
      sasanaYearType: sasanaYearType ?? this.sasanaYearType,
      calendarType: calendarType ?? this.calendarType,
      gregorianStart: gregorianStart ?? this.gregorianStart,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      customHolidays: customHolidayRules ?? customHolidays,
      disabledHolidays: disabledHolidays ?? this.disabledHolidays,
      disabledHolidaysByYear:
          disabledHolidaysByYear ?? this.disabledHolidaysByYear,
      disabledHolidaysByDate:
          disabledHolidaysByDate ?? this.disabledHolidaysByDate,
      westernHolidayProvider:
          westernHolidayProvider ?? this.westernHolidayProvider,
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
        ) &&
        const MapEquality<String, List<HolidayId>>().equals(
          other.disabledHolidaysByDate,
          disabledHolidaysByDate,
        ) &&
        other.westernHolidayProvider.cacheKey ==
            westernHolidayProvider.cacheKey;
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
        const MapEquality<int, List<HolidayId>>().hash(disabledHolidaysByYear) ^
        const MapEquality<String, List<HolidayId>>().hash(
          disabledHolidaysByDate,
        ) ^
        westernHolidayProvider.cacheKey.hashCode;
  }
}
