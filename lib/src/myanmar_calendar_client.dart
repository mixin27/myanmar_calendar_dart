import 'package:myanmar_calendar_dart/src/core/calendar_cache.dart';
import 'package:myanmar_calendar_dart/src/core/calendar_config.dart';
import 'package:myanmar_calendar_dart/src/core/myanmar_date_time.dart';
import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/models/astro_info.dart';
import 'package:myanmar_calendar_dart/src/models/chronicle_models.dart';
import 'package:myanmar_calendar_dart/src/models/complete_date.dart';
import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_year_info.dart';
import 'package:myanmar_calendar_dart/src/models/validation_result.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_holiday_provider.dart';
import 'package:myanmar_calendar_dart/src/services/chronicle_service.dart';
import 'package:myanmar_calendar_dart/src/services/myanmar_calendar_service.dart';
import 'package:myanmar_calendar_dart/src/utils/astro_details.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_utils.dart';

/// Instance-first Myanmar calendar API without relying on package-global state.
///
/// This class is intended for production apps that need isolated configuration,
/// explicit dependency boundaries, or multi-tenant usage in the same process.
class MyanmarCalendarClient {
  /// Creates a new calendar client.
  ///
  /// Set [useGlobalCache] to `true` only when you intentionally want cache
  /// sharing with other global/static consumers in the same process.
  MyanmarCalendarClient({
    CalendarConfig? config,
    CacheConfig cacheConfig = const CacheConfig(),
    bool useGlobalCache = false,
  }) : _config = config ?? const CalendarConfig(),
       _cacheConfig = cacheConfig,
       _useGlobalCache = useGlobalCache,
       _service = useGlobalCache
           ? MyanmarCalendarService.withGlobalCache(config: config)
           : MyanmarCalendarService.withIndependentCache(
               config: config,
               cacheConfig: cacheConfig,
             ),
       _chronicles = ChronicleService(
         config: config ?? const CalendarConfig(),
         language: Language.fromCode(
           (config ?? const CalendarConfig()).defaultLanguage,
         ),
       );

  final CalendarConfig _config;
  final CacheConfig _cacheConfig;
  final bool _useGlobalCache;
  final MyanmarCalendarService _service;
  final ChronicleService _chronicles;

  /// Client calendar configuration.
  CalendarConfig get config => _config;

  /// Cache profile used by this client (when independent cache is used).
  CacheConfig get cacheConfig => _cacheConfig;

  /// Whether this client uses the package-global shared cache instance.
  bool get useGlobalCache => _useGlobalCache;

  /// Default language resolved from [config].
  Language get defaultLanguage => Language.fromCode(config.defaultLanguage);

  /// Returns a new client with updated configuration and/or cache settings.
  MyanmarCalendarClient copyWith({
    Language? language,
    double? timezoneOffset,
    int? sasanaYearType,
    int? calendarType,
    int? gregorianStart,
    List<CustomHoliday>? customHolidayRules,
    List<HolidayId>? disabledHolidays,
    Map<int, List<HolidayId>>? disabledHolidaysByYear,
    Map<String, List<HolidayId>>? disabledHolidaysByDate,
    WesternHolidayProvider? westernHolidayProvider,
    CacheConfig? cacheConfig,
    bool? useGlobalCache,
  }) {
    final nextConfig = config.copyWith(
      defaultLanguage: language?.code,
      timezoneOffset: timezoneOffset,
      sasanaYearType: sasanaYearType,
      calendarType: calendarType,
      gregorianStart: gregorianStart,
      customHolidayRules: customHolidayRules,
      disabledHolidays: disabledHolidays,
      disabledHolidaysByYear: disabledHolidaysByYear,
      disabledHolidaysByDate: disabledHolidaysByDate,
      westernHolidayProvider: westernHolidayProvider,
    );

    return MyanmarCalendarClient(
      config: nextConfig,
      cacheConfig: cacheConfig ?? _cacheConfig,
      useGlobalCache: useGlobalCache ?? _useGlobalCache,
    );
  }

  /// Returns today's date/time as [MyanmarDateTime] using this client's config.
  MyanmarDateTime today() => MyanmarDateTime.now(config: config);

  /// Alias for [today].
  MyanmarDateTime now() => today();

  /// Creates a [MyanmarDateTime] from Western date components.
  MyanmarDateTime fromWestern(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
    int second = 0,
  }) {
    return MyanmarDateTime.fromWestern(
      year,
      month,
      day,
      hour: hour,
      minute: minute,
      second: second,
      config: config,
    );
  }

  /// Creates a [MyanmarDateTime] from Myanmar date components.
  MyanmarDateTime fromMyanmar(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
    int second = 0,
  }) {
    return MyanmarDateTime.fromMyanmar(
      year,
      month,
      day,
      hour: hour,
      minute: minute,
      second: second,
      config: config,
    );
  }

  /// Creates a [MyanmarDateTime] from a [DateTime].
  MyanmarDateTime fromDateTime(DateTime dateTime) {
    return MyanmarDateTime.fromDateTime(dateTime, config: config);
  }

  /// Returns complete information for [dateTime].
  CompleteDate getCompleteDate(DateTime dateTime, {Language? language}) {
    return _service.getCompleteDate(dateTime, language: language);
  }

  /// Returns complete information for each date in [dates].
  List<CompleteDate> getCompleteDates(
    List<DateTime> dates, {
    Language? language,
  }) {
    return dates
        .map((date) => _service.getCompleteDate(date, language: language))
        .toList();
  }

  /// Returns astrological information for a Myanmar date.
  AstroInfo getAstroInfo(MyanmarDate date) => _service.getAstroInfo(date);

  /// Returns holiday information for a Myanmar date.
  HolidayInfo getHolidayInfo(MyanmarDate date, {Language? language}) {
    return _service.getHolidayInfo(date, language: language);
  }

  /// Formats a Myanmar date with optional [pattern] and [language].
  String formatMyanmar(
    MyanmarDate date, {
    String? pattern,
    Language? language,
  }) {
    return _service.formatMyanmarDate(
      date,
      pattern: pattern,
      language: language,
    );
  }

  /// Formats a Western date with optional [pattern] and [language].
  String formatWestern(
    WesternDate date, {
    String? pattern,
    Language? language,
  }) {
    return _service.formatWesternDate(
      date,
      pattern: pattern,
      language: language,
    );
  }

  /// Formats a [MyanmarDateTime] using this client's default language.
  String format(
    MyanmarDateTime dateTime, {
    String? myanmarPattern,
    String? westernPattern,
    Language? language,
  }) {
    return dateTime.formatComplete(
      myanmarPattern: myanmarPattern,
      westernPattern: westernPattern,
      language: language ?? defaultLanguage,
    );
  }

  /// Adds [months] to a Myanmar date using deterministic month transitions.
  MyanmarDateTime addMonths(MyanmarDateTime date, int months) {
    final myanmarDate = CalendarUtils.addMonthsToMyanmarDate(
      date.myanmarDate,
      months,
    );
    return MyanmarDateTime.fromMyanmarDate(myanmarDate, config: config);
  }

  /// Returns typed Myanmar-year metadata.
  MyanmarYearInfo getMyanmarYearInfo(int year) {
    return _service.getMyanmarYearInfo(year);
  }

  /// Validates Myanmar date components.
  ValidationResult validateMyanmar(int year, int month, int day) {
    return _service.validateMyanmarDate(year, month, day);
  }

  /// Returns whether a Myanmar date is valid.
  bool isValidMyanmar(int year, int month, int day) {
    return validateMyanmar(year, month, day).isValid;
  }

  /// Returns cache statistics map (legacy shape).
  Map<String, dynamic> getCacheStatistics() => _service.getCacheStatistics();

  /// Returns typed cache statistics.
  CalendarCacheStatistics getTypedCacheStatistics() =>
      _service.getTypedCacheStatistics();

  /// Clears all cache entries used by this client.
  void clearCache() => _service.clearCache();

  /// Resets cache hit/miss counters.
  void resetCacheStatistics() => _service.resetCacheStatistics();

  /// Warms up complete-date cache entries for a date range.
  void warmUpCache({
    DateTime? startDate,
    DateTime? endDate,
    Language? language,
  }) {
    _service.warmUpCache(
      startDate: startDate,
      endDate: endDate,
      language: language,
    );
  }

  /// Returns chronicle entries for [dt].
  List<ChronicleEntryData> getChronicleFor(DateTime dt) {
    final jdn = WesternDate.fromDateTime(dt).julianDayNumber;
    return _chronicles.byJdn(jdn);
  }

  /// Returns dynasty for [dt], if any.
  DynastyData? getDynastyFor(DateTime dt) {
    final jdn = WesternDate.fromDateTime(dt).julianDayNumber;
    return _chronicles.dynastyForJdn(jdn);
  }

  /// Returns Nakhat description.
  String getNakhatDescription(String nakhat) {
    return AstroDetails.getNakhatDescription(
      nakhat,
      language: defaultLanguage,
    );
  }

  /// Returns Mahabote characteristics.
  String getMahaboteCharacteristics(String mahabote) {
    return AstroDetails.getMahaboteCharacteristics(
      mahabote,
      language: defaultLanguage,
    );
  }
}
