import 'package:myanmar_calendar_dart/src/core/calendar_cache.dart';
import 'package:myanmar_calendar_dart/src/core/calendar_config.dart';
import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/models/astro_info.dart';
import 'package:myanmar_calendar_dart/src/models/complete_date.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_year_info.dart';
import 'package:myanmar_calendar_dart/src/models/shan_date.dart';
import 'package:myanmar_calendar_dart/src/models/validation_result.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/services/astro_calculator.dart';
import 'package:myanmar_calendar_dart/src/services/date_converter.dart';
import 'package:myanmar_calendar_dart/src/services/format_service.dart';
import 'package:myanmar_calendar_dart/src/services/holiday_calculator.dart';

/// Main service class for Myanmar Calendar operations
///
/// This service provides:
/// - Date conversions between Myanmar and Western calendars
/// - Formatting services with localization support
/// - Holiday calculations
/// - Astrological information
/// - Configuration management
class MyanmarCalendarService {
  /// Legacy constructor - uses global cache by default
  factory MyanmarCalendarService({
    CalendarConfig? config,
    Language? defaultLanguage,
  }) {
    return MyanmarCalendarService.withGlobalCache(
      config: config,
      defaultLanguage: defaultLanguage,
    );
  }

  /// Create service with independent cache
  /// Use this for testing or when isolation is needed
  MyanmarCalendarService.withIndependentCache({
    CalendarConfig? config,
    CacheConfig? cacheConfig,
    Language? defaultLanguage,
  }) : _config = config ?? CalendarConfig.global,
       _cacheNamespace = (config ?? CalendarConfig.global).cacheNamespace,
       _cache = CalendarCache.independent(
         config: cacheConfig ?? const CacheConfig(),
       ),
       _formatService = FormatService(),
       _defaultLanguage =
           defaultLanguage ??
           Language.fromCode(
             (config ?? CalendarConfig.global).defaultLanguage,
           ) {
    _initializeServices();
  }

  /// Create service that uses the global shared cache
  /// This is the default and recommended for most use cases
  MyanmarCalendarService.withGlobalCache({
    CalendarConfig? config,
    Language? defaultLanguage,
  }) : _config = config ?? CalendarConfig.global,
       _cacheNamespace = (config ?? CalendarConfig.global).cacheNamespace,
       _cache = CalendarCache.global(), // Use global cache
       _formatService = FormatService(),
       _defaultLanguage =
           defaultLanguage ??
           Language.fromCode(
             (config ?? CalendarConfig.global).defaultLanguage,
           ) {
    _initializeServices();
  }

  final CalendarConfig _config;
  final String _cacheNamespace;
  final CalendarCache _cache;
  late final DateConverter _dateConverter;
  late final AstroCalculator _astroCalculator;
  late final HolidayCalculator _holidayCalculator;
  final FormatService _formatService;
  final Language _defaultLanguage;

  void _initializeServices() {
    _dateConverter = DateConverter(
      _config,
      cache: _cache,
      cacheNamespace: 'date_converter|$_cacheNamespace',
    );
    _astroCalculator = AstroCalculator(cache: _cache);
    _holidayCalculator = HolidayCalculator(cache: _cache, config: _config);
  }

  /// Get calendar configuration
  CalendarConfig get config => _config;

  /// Get [DateConverter] instance.
  DateConverter get dateConverter => _dateConverter;

  /// Get [AstroCalculator] instance.
  AstroCalculator get astroCalculator => _astroCalculator;

  /// Get [HolidayCalculator] instance.
  HolidayCalculator get holidayCalculator => _holidayCalculator;

  /// Get [FormatService] instance.
  FormatService get formatService => _formatService;

  /// Convert Western date to Myanmar date
  MyanmarDate westernToMyanmar(DateTime dateTime) {
    final westernDate = WesternDate.fromDateTime(dateTime);
    return _dateConverter.julianToMyanmar(westernDate.julianDayNumber);
  }

  /// Convert julian day number to Western date.
  WesternDate julianToWestern(double julianDayNumber) {
    return _dateConverter.julianToWestern(julianDayNumber);
  }

  /// Convert Myanmar date to Western date
  DateTime myanmarToWestern(
    int year,
    int month,
    int day, [
    int hour = 12,
    int minute = 0,
    int second = 0,
  ]) {
    final jdn = _dateConverter.myanmarToJulian(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
    final westernDate = _dateConverter.julianToWestern(jdn);
    return westernDate.toDateTime();
  }

  /// Convert Myanmar date to WesternDate object
  WesternDate myanmarToWesternDate(
    int year,
    int month,
    int day, [
    int hour = 12,
    int minute = 0,
    int second = 0,
  ]) {
    final jdn = _dateConverter.myanmarToJulian(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
    return _dateConverter.julianToWestern(jdn);
  }

  /// Get today's Myanmar date
  MyanmarDate get today {
    return westernToMyanmar(DateTime.now());
  }

  /// Get Myanmar date for a specific Julian Day Number
  MyanmarDate julianToMyanmar(double julianDayNumber) {
    return _dateConverter.julianToMyanmar(julianDayNumber);
  }

  /// Get Julian Day Number for a Myanmar date
  double myanmarToJulian(
    int year,
    int month,
    int day, [
    int hour = 12,
    int minute = 0,
    int second = 0,
  ]) {
    return _dateConverter.myanmarToJulian(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  /// Get astronomical information for a Myanmar date
  AstroInfo getAstroInfo(MyanmarDate date) {
    return _astroCalculator.calculate(date);
  }

  /// Get holiday information for a Myanmar date
  HolidayInfo getHolidayInfo(MyanmarDate date, {Language? language}) {
    final resolvedLanguage = language ?? _defaultLanguage;
    return _holidayCalculator.getHolidays(
      date,
      customHolidays: _config.customHolidayRules,
      language: resolvedLanguage,
    );
  }

  /// Format Myanmar date as string
  String formatMyanmarDate(
    MyanmarDate date, {
    String? pattern,
    Language? language,
  }) {
    final resolvedLanguage = language ?? _defaultLanguage;
    return _formatService.formatMyanmarDate(
      date,
      pattern: pattern,
      language: resolvedLanguage,
    );
  }

  /// Format Western date as string
  String formatWesternDate(
    WesternDate date, {
    String? pattern,
    Language? language,
  }) {
    final resolvedLanguage = language ?? _defaultLanguage;
    return _formatService.formatWesternDate(
      date,
      pattern: pattern,
      language: resolvedLanguage,
    );
  }

  /// Get complete information for a date (Myanmar + Western + Astro + Holidays)
  CompleteDate getCompleteDate(DateTime dateTime, {Language? language}) {
    final resolvedLanguage = language ?? _defaultLanguage;
    final completeDateNamespace =
        'complete_date|$_cacheNamespace|lang:${resolvedLanguage.code}';

    // Try to get from cache
    final cached = _cache.getCompleteDate(
      dateTime,
      customHolidays: _config.customHolidayRules,
      namespace: completeDateNamespace,
    );
    if (cached != null) {
      return cached;
    }

    // Calculate if not in cache
    final westernDate = WesternDate.fromDateTime(dateTime);
    final myanmarDate = _dateConverter.julianToMyanmar(
      westernDate.julianDayNumber,
    );
    final shanDate = ShanDate.fromMyanmarDate(myanmarDate);
    final astroInfo = _astroCalculator.calculate(myanmarDate);
    final holidayInfo = _holidayCalculator.getHolidays(
      myanmarDate,
      customHolidays: _config.customHolidayRules,
      language: resolvedLanguage,
    );

    final completeDate = CompleteDate(
      western: westernDate,
      myanmar: myanmarDate,
      shan: shanDate,
      astro: astroInfo,
      holidays: holidayInfo,
    );

    // Store in cache
    _cache.putCompleteDate(
      dateTime,
      completeDate,
      customHolidays: _config.customHolidayRules,
      namespace: completeDateNamespace,
    );

    return completeDate;
  }

  /// Find auspicious days for a given Myanmar month and year
  List<CompleteDate> findAuspiciousDays(
    int year,
    int month, {
    Language? language,
  }) {
    final myanmarMonth = getMyanmarMonth(year, month);
    return myanmarMonth
        .map(
          (md) => getCompleteDate(
            myanmarToWestern(md.year, md.month, md.day),
            language: language,
          ),
        )
        .where((cd) => cd.astro.isAuspicious)
        .toList();
  }

  /// Get Myanmar dates for a month
  List<MyanmarDate> getMyanmarMonth(int year, int month) {
    final dates = <MyanmarDate>[];

    // get first day of myanmar month
    final yearInfo = _dateConverter.getMyanmarYearInfo(year);
    final yearType = yearInfo.yearType;

    // We don't use Late Kason, Just Kason
    if (month == 14 && yearType == 0) {
      return dates;
    }

    // No Tagu in special year, only Late Tagu
    if (month == 1 && yearType == 0) {
      return dates;
    }

    // Get first day of the month
    var jdn = _dateConverter.myanmarToJulian(year, month, 1);
    var currentDate = _dateConverter.julianToMyanmar(jdn);

    // Add all days in the month
    while (currentDate.year == year && currentDate.month == month) {
      dates.add(currentDate);
      jdn += 1;
      currentDate = _dateConverter.julianToMyanmar(jdn);
    }

    return dates;
  }

  /// Get Western dates for a Myanmar month
  List<DateTime> getWesternDatesForMyanmarMonth(int year, int month) {
    return getMyanmarMonth(
      year,
      month,
    ).map((date) => myanmarToWestern(date.year, date.month, date.day)).toList();
  }

  /// Check if a Myanmar year is a watat year
  bool isWatatYear(int year) {
    final firstDayOfYear = _dateConverter.myanmarToJulian(year, 1, 1);
    final myanmarDate = _dateConverter.julianToMyanmar(firstDayOfYear);
    return myanmarDate.yearType > 0;
  }

  /// Get year type for a Myanmar year
  int getYearType(int year) {
    final firstDayOfYear = _dateConverter.myanmarToJulian(year, 1, 1);
    final myanmarDate = _dateConverter.julianToMyanmar(firstDayOfYear);
    return myanmarDate.yearType;
  }

  /// Legacy API: language is request-scoped now.
  @Deprecated(
    'Language is request-scoped. Pass language per request instead.',
  )
  void setLanguage(Language language) {
    // no-op: retained for backward compatibility
  }

  /// Legacy API: returns the constructor default language.
  @Deprecated(
    'Language is request-scoped. Pass language per request instead.',
  )
  Language get currentLanguage => _defaultLanguage;

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() => _cache.getStatistics();

  /// Get typed cache statistics.
  CalendarCacheStatistics getTypedCacheStatistics() =>
      _cache.getTypedStatistics();

  /// Reset cache statistics.
  void resetCacheStatistics() => _cache.resetStatistics();

  /// Warm up complete-date cache entries for a date range.
  void warmUpCache({
    DateTime? startDate,
    DateTime? endDate,
    Language? language,
  }) {
    final resolvedLanguage = language ?? _defaultLanguage;
    _cache.warmUp(
      startDate: startDate,
      endDate: endDate,
      resolveCompleteDate: (dateTime) {
        return getCompleteDate(dateTime, language: resolvedLanguage);
      },
    );
  }

  /// Clear cache
  void clearCache() => _cache.clearAll();

  /// Get typed Myanmar year metadata.
  MyanmarYearInfo getMyanmarYearInfo(int myanmarYear) {
    return _dateConverter.getMyanmarYearInfo(myanmarYear);
  }

  /// Validate Myanmar date
  ValidationResult validateMyanmarDate(int year, int month, int day) {
    // Basic range checks
    if (year < 1 || year > 9999) {
      return const ValidationResult(
        isValid: false,
        error: 'Year must be between 1 and 9999',
      );
    }

    if (month < 0 || month > 14) {
      return const ValidationResult(
        isValid: false,
        error: 'Month must be between 0 and 14',
      );
    }

    if (day < 1 || day > 30) {
      return const ValidationResult(
        isValid: false,
        error: 'Day must be between 1 and 30',
      );
    }

    try {
      // Try to create the date
      final jdn = _dateConverter.myanmarToJulian(year, month, day);
      final reconstructed = _dateConverter.julianToMyanmar(jdn);

      // Check if the reconstructed date matches input
      if (reconstructed.year != year ||
          reconstructed.month != month ||
          reconstructed.day != day) {
        return const ValidationResult(
          isValid: false,
          error: 'Invalid date: does not exist in Myanmar calendar',
        );
      }

      return const ValidationResult(isValid: true);
    } on Exception catch (e) {
      return ValidationResult(isValid: false, error: 'Invalid date: $e');
    }
  }
}
