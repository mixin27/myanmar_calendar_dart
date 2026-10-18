import 'package:myanmar_calendar_dart/src/core/calendar_cache.dart';
import 'package:myanmar_calendar_dart/src/core/calendar_config.dart';
import 'package:myanmar_calendar_dart/src/core/myanmar_date_time.dart';
import 'package:myanmar_calendar_dart/src/exceptions/calendar_exceptions.dart';
import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/models/astro_info.dart';
import 'package:myanmar_calendar_dart/src/models/chronicle_models.dart';
import 'package:myanmar_calendar_dart/src/models/complete_date.dart';
import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_year_info.dart';
import 'package:myanmar_calendar_dart/src/models/shan_date.dart';
import 'package:myanmar_calendar_dart/src/models/validation_result.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_holiday_provider.dart';
import 'package:myanmar_calendar_dart/src/services/chronicle_service.dart';
import 'package:myanmar_calendar_dart/src/services/myanmar_calendar_service.dart';
import 'package:myanmar_calendar_dart/src/utils/astro_details.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_utils.dart';

/// The complete Myanmar calendar API, bound to one [CalendarConfig].
///
/// A client never reads package-global state: everything it returns uses its
/// own [config]. `MyanmarCalendar` is a static convenience over a client for
/// the global configuration, so the two always behave the same.
class MyanmarCalendarClient {
  /// Creates a new calendar client.
  ///
  /// Set [useGlobalCache] to `true` only when you intentionally want cache
  /// sharing with other global/static consumers in the same process.
  MyanmarCalendarClient({
    CalendarConfig? config,
    CacheConfig cacheConfig = const CacheConfig(),
    bool useGlobalCache = false,
  }) : _config = (config ?? const CalendarConfig())..validate(),
       _cacheConfig = cacheConfig,
       _useGlobalCache = useGlobalCache,
       // Never fall back to the global config: a client is isolated.
       _service = useGlobalCache
           ? MyanmarCalendarService.withGlobalCache(
               config: config ?? const CalendarConfig(),
             )
           : MyanmarCalendarService.withIndependentCache(
               config: config ?? const CalendarConfig(),
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

  /// Creates a [MyanmarDateTime] from a (UTC) Julian Day Number.
  MyanmarDateTime fromJulianDay(double julianDayNumber) {
    return MyanmarDateTime.fromJulianDay(julianDayNumber, config: config);
  }

  /// Creates a [MyanmarDateTime] from milliseconds since epoch (an instant).
  MyanmarDateTime fromMillisecondsSinceEpoch(int milliseconds) {
    return MyanmarDateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      config: config,
    );
  }

  /// Creates a [MyanmarDateTime] from seconds since epoch (an instant).
  MyanmarDateTime fromTimestamp(int timestamp) {
    return MyanmarDateTime.fromTimestamp(timestamp, config: config);
  }

  /// Parses a Myanmar date such as `1385/10/1`; throws
  /// [DateParseException].
  MyanmarDateTime parseMyanmar(String dateString) {
    final date = CalendarUtils.parseMyanmarDate(dateString, service: _service);
    return MyanmarDateTime.fromMyanmarDate(date, config: config);
  }

  /// Like [parseMyanmar], but returns null instead of throwing.
  MyanmarDateTime? tryParseMyanmar(String dateString) {
    final date = CalendarUtils.tryParseMyanmarDate(
      dateString,
      service: _service,
    );
    return date == null
        ? null
        : MyanmarDateTime.fromMyanmarDate(date, config: config);
  }

  /// Parses an ISO 8601 Western date; throws [DateParseException].
  MyanmarDateTime parseWestern(String dateString) =>
      MyanmarDateTime.parseWestern(dateString, config: config);

  /// Like [parseWestern], but returns null instead of throwing.
  MyanmarDateTime? tryParseWestern(String dateString) =>
      MyanmarDateTime.tryParseWestern(dateString, config: config);

  /// Converts each of [westernDates].
  List<MyanmarDateTime> convertWesternDates(List<DateTime> westernDates) {
    return [for (final date in westernDates) fromDateTime(date)];
  }

  /// Converts each (year, month, day) of [dates].
  List<MyanmarDateTime> convertMyanmarDates(
    List<(int year, int month, int day)> dates,
  ) {
    return [for (final (y, m, d) in dates) fromMyanmar(y, m, d)];
  }

  /// Returns complete information for [dateTime].
  CompleteDate getCompleteDate(DateTime dateTime, {Language? language}) {
    return _service.getCompleteDate(dateTime, language: language);
  }

  /// Complete information for the calendar day [year]-[month]-[day], with
  /// no time of day or time zone involved.
  CompleteDate getCompleteDateFor(
    int year,
    int month,
    int day, {
    Language? language,
  }) => _service.getCompleteDateFor(year, month, day, language: language);

  /// Returns complete information for each date in [dates].
  List<CompleteDate> getCompleteDates(
    List<DateTime> dates, {
    Language? language,
  }) {
    return [
      for (final date in dates)
        _service.getCompleteDate(date, language: language),
    ];
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
      service: _service,
    );
    return MyanmarDateTime.fromMyanmarDate(myanmarDate, config: config);
  }

  /// Returns typed Myanmar-year metadata.
  MyanmarYearInfo getMyanmarYearInfo(int year) {
    return _service.getMyanmarYearInfo(year);
  }

  /// Whether [myanmarYear] has an intercalary month.
  bool isWatatYear(int myanmarYear) => _service.isWatatYear(myanmarYear);

  /// 0 common, 1 little watat, 2 big watat.
  int getYearType(int myanmarYear) => _service.getYearType(myanmarYear);

  /// Every day of Myanmar [month] in [year]; empty if the year lacks it.
  List<MyanmarDate> getMyanmarMonth(int year, int month) {
    return _service.getMyanmarMonth(year, month);
  }

  /// The Western dates of Myanmar [month] in [year].
  List<DateTime> getWesternDatesForMyanmarMonth(int year, int month) {
    return _service.getWesternDatesForMyanmarMonth(year, month);
  }

  /// Days of Myanmar [month] in [year] that are astrologically auspicious.
  List<CompleteDate> findAuspiciousDays(
    int year,
    int month, {
    Language? language,
  }) {
    return _service.findAuspiciousDays(year, month, language: language);
  }

  /// Days between two dates, always positive.
  int daysBetween(MyanmarDateTime date1, MyanmarDateTime date2) {
    return date1.differenceInDays(date2).abs();
  }

  /// [date] moved by [days], in this client's configuration.
  MyanmarDateTime addDays(MyanmarDateTime date, int days) {
    return fromJulianDay(date.addDays(days).julianDayNumber);
  }

  /// The next day after [startDate] with [moonPhase] (0 waxing, 1 full moon,
  /// 2 waning, 3 new moon).
  MyanmarDateTime findNextMoonPhase(MyanmarDateTime startDate, int moonPhase) {
    final next = CalendarUtils.findNextMoonPhase(
      startDate.myanmarDate,
      moonPhase,
      service: _service,
    );
    return MyanmarDateTime.fromMyanmarDate(next, config: config);
  }

  /// The sabbath days of Myanmar [month] in [year].
  List<MyanmarDateTime> findSabbathDays(int year, int month) {
    return [
      for (final date in CalendarUtils.findSabbathDaysInMonth(
        year,
        month,
        service: _service,
      ))
        MyanmarDateTime.fromMyanmarDate(date, config: config),
    ];
  }

  /// Today in the Shan calendar.
  ShanDate todayInShan() => today().shanDate;

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

  /// Chronicle entries for a Julian Day Number.
  List<ChronicleEntryData> getChronicleForJdn(double jdn) =>
      _chronicles.byJdn(jdn);

  /// The dynasty for a Julian Day Number, if any.
  DynastyData? getDynastyForJdn(double jdn) => _chronicles.dynastyForJdn(jdn);

  /// Chronicle entries for a Myanmar date.
  List<ChronicleEntryData> getChronicleForMyanmar(MyanmarDate date) =>
      _chronicles.byJdn(date.julianDayNumber);

  /// The dynasty for a Myanmar date, if any.
  DynastyData? getDynastyForMyanmar(MyanmarDate date) =>
      _chronicles.dynastyForJdn(date.julianDayNumber);

  /// Chronicle entries of a dynasty.
  List<ChronicleEntryData> getEntriesForDynasty(String dynastyId) =>
      _chronicles.entriesForDynasty(dynastyId);

  /// Chronicle entries intersecting [start]..[end].
  List<ChronicleEntryData> getChroniclesBetween(DateTime start, DateTime end) =>
      _chronicles.betweenJdn(
        WesternDate.fromDateTime(start).julianDayNumber,
        WesternDate.fromDateTime(end).julianDayNumber,
      );

  /// Chronicle entries intersecting [startJdn]..[endJdn].
  List<ChronicleEntryData> getChroniclesBetweenJdn(
    double startJdn,
    double endJdn,
  ) => _chronicles.betweenJdn(startJdn, endJdn);

  /// Every dynasty.
  List<DynastyData> listDynasties() => _chronicles.allDynasties();

  /// The dynasty with [dynastyId], if any.
  DynastyData? getDynastyById(String dynastyId) =>
      _chronicles.dynastyById(dynastyId);

  /// Description of an astrological day.
  String getAstrologicalDayDescription(String dayName) {
    return AstroDetails.getAstrologicalDayDescription(
      dayName,
      language: defaultLanguage,
    );
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
