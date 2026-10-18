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
import 'package:myanmar_calendar_dart/src/models/shan_date.dart';
import 'package:myanmar_calendar_dart/src/models/validation_result.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_holiday_provider.dart';
import 'package:myanmar_calendar_dart/src/myanmar_calendar_client.dart';
import 'package:myanmar_calendar_dart/src/services/ai_prompt_service.dart';
import 'package:myanmar_calendar_dart/src/utils/package_constants.dart';
import 'package:myanmar_calendar_dart/src/utils/shan_calendar_constants.dart';

/// {@template myanmar_calendar}
/// Main Myanmar Calendar class providing static access to all package functionality
///
/// This class serves as the primary entry point for the Myanmar Calendar package,
/// offering convenient static methods for common operations while maintaining
/// backward compatibility and ease of use.
///
/// ## Usage Examples
///
/// ```dart
/// // Basic date operations
/// final today = MyanmarCalendar.today();
/// final myanmarDate = MyanmarCalendar.fromWestern(2024, 1, 1);
/// final westernDate = MyanmarCalendar.fromMyanmar(1385, 10, 1);
///
/// // Get complete information
/// final completeDate = MyanmarCalendar.getCompleteDate(DateTime.now());
///
/// // Formatting
/// final formatted = MyanmarCalendar.format(today, language: Language.myanmar);
///
/// // Configuration
/// MyanmarCalendar.configure(
///   language: Language.myanmar,
///   timezoneOffset: 6.5,
///   sasanaYearType: 0,
/// );
/// ```
/// {@endtemplate}
class MyanmarCalendar {
  // Private constructor to prevent instantiation
  MyanmarCalendar._();

  // ============================================================================
  // STATE
  // ============================================================================

  /// The client for the global configuration, created on first use.
  static MyanmarCalendarClient? _defaultClient;

  /// Clients for per-call configs, most recently used last. They share the
  /// global cache; each config has its own cache namespace.
  static final _configClients = <CalendarConfig, MyanmarCalendarClient>{};
  static const _maxConfigClients = 8;

  static MyanmarCalendarClient get _client {
    _watchGlobalConfig();
    return _defaultClient ??= MyanmarCalendarClient(
      config: CalendarConfig.global,
      useGlobalCache: true,
    );
  }

  /// The client for [config], or the global one when it is null or the
  /// global config. Never changes the global configuration.
  static MyanmarCalendarClient _clientFor(CalendarConfig? config) {
    if (config == null || config == CalendarConfig.global) return _client;
    final client =
        _configClients.remove(config) ??
        MyanmarCalendarClient(config: config, useGlobalCache: true);
    _configClients[config] = client;
    if (_configClients.length > _maxConfigClients) {
      _configClients.remove(_configClients.keys.first);
    }
    return client;
  }

  static var _watching = false;

  /// Drop state built for the old configuration whenever
  /// [CalendarConfig.global] changes, however it was changed.
  static void _watchGlobalConfig() {
    if (_watching) return;
    _watching = true;
    CalendarConfig.onGlobalChanged = () {
      _defaultClient = null;
      _configClients.clear();
      MyanmarDateTime.clearSharedInstances();
      cache
        ..clearHolidayInfoCache()
        ..clearCompleteDateCache();
    };
  }

  static void _setGlobal(CalendarConfig config) {
    _watchGlobalConfig();
    CalendarConfig.global = config;
  }

  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  /// Configure the Myanmar Calendar with custom settings
  ///
  /// [language] - Default language for translations
  /// [timezoneOffset] - Timezone offset in hours (default: 6.5 for Myanmar Time)
  /// [sasanaYearType] - Sasana year calculation method (0, 1, or 2)
  /// [calendarType] - Calendar system (0=British, 1=Gregorian, 2=Julian)
  /// [gregorianStart] - Julian Day Number of Gregorian calendar start
  /// [customHolidayRules] - List of custom holiday rules defined by the consumer
  /// [disabledHolidays] - List of built-in holidays to disable globally
  /// [disabledHolidaysByYear] - Map of Western year to list of built-in holidays to disable for that specific year
  /// [disabledHolidaysByDate] - Map of Western date (YYYY-MM-DD) to list of built-in holidays to disable for that specific date
  /// [westernHolidayProvider] - Provider for western-calendar holiday lookup rules
  static void configure({
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
  }) {
    _setGlobal(
      CalendarConfig.global.copyWith(
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
      ),
    );
  }

  /// Add one custom holiday rule to the configuration.
  static void addCustomHolidayRule(CustomHoliday rule) =>
      addCustomHolidayRules([rule]);

  /// Add multiple custom holiday rules to the configuration.
  static void addCustomHolidayRules(List<CustomHoliday> rules) {
    _setGlobal(
      CalendarConfig.global.copyWith(
        customHolidayRules: [
          ...CalendarConfig.global.customHolidayRules,
          ...rules,
        ],
      ),
    );
  }

  /// Remove a custom holiday rule by [id].
  static void removeCustomHolidayRuleById(String id) {
    _setGlobal(
      CalendarConfig.global.copyWith(
        customHolidayRules: CalendarConfig.global.customHolidayRules
            .where((h) => h.id != id)
            .toList(),
      ),
    );
  }

  /// Remove all custom holiday rules from the configuration.
  static void clearCustomHolidayRules() {
    _setGlobal(CalendarConfig.global.copyWith(customHolidayRules: []));
  }

  /// Get current configuration
  static CalendarConfig get config => CalendarConfig.global;

  /// Configure global cache used by all MyanmarCalendar operations
  static void configureCache(CacheConfig cacheConfig) {
    CalendarCache.configureGlobal(cacheConfig);
    _defaultClient = null;
    _configClients.clear();
    MyanmarDateTime.clearSharedInstances();
  }

  /// Get global cache instance
  static CalendarCache get cache => CalendarCache.global();

  /// Create a client with its own configuration and, by default, its own
  /// cache. Without [config] it uses the package defaults, not the global
  /// configuration, like the [MyanmarCalendarClient] constructor.
  static MyanmarCalendarClient createClient({
    CalendarConfig? config,
    CacheConfig cacheConfig = const CacheConfig(),
    bool useGlobalCache = false,
  }) {
    return MyanmarCalendarClient(
      config: config,
      cacheConfig: cacheConfig,
      useGlobalCache: useGlobalCache,
    );
  }

  /// Clear all caches
  static void clearCache() {
    cache.clearAll();
  }

  /// Get global cache statistics
  static Map<String, dynamic> getCacheStatistics() {
    return cache.getStatistics();
  }

  /// Get typed global cache statistics.
  static CalendarCacheStatistics getTypedCacheStatistics() {
    return cache.getTypedStatistics();
  }

  /// Warm up global cache
  static void warmUpCache({DateTime? startDate, DateTime? endDate}) {
    _client.warmUpCache(startDate: startDate, endDate: endDate);
  }

  /// Reset global cache statistics
  static void resetCacheStatistics() {
    cache.resetStatistics();
  }

  // ============================================================================
  // FACTORY METHODS
  // ============================================================================

  /// Get today's Myanmar date
  ///
  /// Returns a [MyanmarDateTime] representing the current date and time
  /// in the configured timezone.
  static MyanmarDateTime today({CalendarConfig? config}) {
    return _clientFor(config).today();
  }

  /// Get current Myanmar date and time
  ///
  /// Alias for [today] method for clarity in usage.
  static MyanmarDateTime now({CalendarConfig? config}) {
    return today(config: config);
  }

  /// Create Myanmar date from Western date
  ///
  /// Converts Western calendar date to Myanmar calendar date.
  ///
  /// Example:
  /// ```dart
  /// final myanmarDate = MyanmarCalendar.fromWestern(2024, 1, 1);
  /// print('Myanmar: ${myanmarDate.formatMyanmar()}');
  /// ```
  static MyanmarDateTime fromWestern(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
    int second = 0,
    CalendarConfig? config,
  }) {
    return _clientFor(config).fromWestern(
      year,
      month,
      day,
      hour: hour,
      minute: minute,
      second: second,
    );
  }

  /// Create Myanmar date from Myanmar calendar components
  ///
  /// Creates a Myanmar date from Myanmar calendar year, month, and day.
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.fromMyanmar(1385, 10, 1);
  /// print('Western: ${date.formatWestern()}');
  /// ```
  static MyanmarDateTime fromMyanmar(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
    int second = 0,
    CalendarConfig? config,
  }) {
    return _clientFor(config).fromMyanmar(
      year,
      month,
      day,
      hour: hour,
      minute: minute,
      second: second,
    );
  }

  /// Create Myanmar date from DateTime object
  ///
  /// Converts a Dart [DateTime] object to Myanmar calendar date.
  ///
  /// Example:
  /// ```dart
  /// final dartDate = DateTime(2024, 1, 1);
  /// final myanmarDate = MyanmarCalendar.fromDateTime(dartDate);
  /// ```
  static MyanmarDateTime fromDateTime(
    DateTime dateTime, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).fromDateTime(dateTime);
  }

  /// Create Myanmar date from Julian Day Number
  ///
  /// Creates a Myanmar date from a Julian Day Number.
  /// Useful for astronomical calculations or when working with
  /// external calendar systems.
  static MyanmarDateTime fromJulianDay(
    double julianDayNumber, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).fromJulianDay(julianDayNumber);
  }

  /// Create Myanmar date from milliseconds since epoch
  ///
  /// Converts Unix timestamp (milliseconds since epoch) to Myanmar date.
  /// The value is an instant, shown in the configured time zone.
  static MyanmarDateTime fromMillisecondsSinceEpoch(
    int milliseconds, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).fromMillisecondsSinceEpoch(milliseconds);
  }

  /// Create Myanmar date from timestamp (seconds since epoch)
  ///
  /// Converts Unix timestamp (seconds since epoch) to Myanmar date.
  static MyanmarDateTime fromTimestamp(
    int timestamp, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).fromTimestamp(timestamp);
  }

  // ============================================================================
  // PARSING METHODS
  // ============================================================================

  /// Parse a Myanmar date string, written year first (`1385/10/1`,
  /// `1385-10-1`) or day first (`1.10.1385`); Myanmar digits work too.
  ///
  /// Throws [DateParseException] if the string isn't a date that exists.
  /// Use [tryParseMyanmar] to get null instead.
  static MyanmarDateTime parseMyanmar(
    String dateString, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).parseMyanmar(dateString);
  }

  /// Like [parseMyanmar], but returns null instead of throwing.
  static MyanmarDateTime? tryParseMyanmar(
    String dateString, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).tryParseMyanmar(dateString);
  }

  /// Parse an ISO 8601 Western date string (as `DateTime.parse` does).
  ///
  /// Throws [DateParseException]; use [tryParseWestern] to get null instead.
  static MyanmarDateTime parseWestern(
    String dateString, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).parseWestern(dateString);
  }

  /// Like [parseWestern], but returns null instead of throwing.
  static MyanmarDateTime? tryParseWestern(
    String dateString, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).tryParseWestern(dateString);
  }

  // ============================================================================
  // INFORMATION METHODS
  // ============================================================================

  /// Get complete date information
  ///
  /// Returns a [CompleteDate] object containing Myanmar date, Western date,
  /// astrological information, and holiday information for the given date.
  ///
  /// Example:
  /// ```dart
  /// final complete = MyanmarCalendar.getCompleteDate(DateTime.now());
  /// print('Holidays: ${complete.allHolidays}');
  /// print('Moon phase: ${complete.moonPhase}');
  /// print('Astrological days: ${complete.astrologicalDays}');
  /// ```
  ///
  /// Pass [config] to use another time zone or holiday rules for this call
  /// only, without changing the global configuration.
  static CompleteDate getCompleteDate(
    DateTime dateTime, {
    Language? language,
    CalendarConfig? config,
  }) {
    return _clientFor(config).getCompleteDate(dateTime, language: language);
  }

  /// Complete information for the calendar day [year]-[month]-[day].
  ///
  /// No time of day or time zone is involved, so this is the safest way to
  /// look up a day on a calendar grid.
  ///
  /// Example:
  /// ```dart
  /// final day = MyanmarCalendar.getCompleteDateFor(2026, 10, 18);
  /// ```
  static CompleteDate getCompleteDateFor(
    int year,
    int month,
    int day, {
    Language? language,
    CalendarConfig? config,
  }) {
    return _clientFor(
      config,
    ).getCompleteDateFor(year, month, day, language: language);
  }

  /// Generate a structured AI prompt for a date
  ///
  /// Returns a prompt string that can be used with AI platforms to get
  /// astrological readings, fortune-telling, or divination.
  ///
  /// Example:
  /// ```dart
  /// final completeDate = MyanmarCalendar.getCompleteDate(DateTime.now());
  /// final prompt = MyanmarCalendar.generateAIPrompt(
  ///   completeDate,
  ///   language: Language.english,
  ///   type: AIPromptType.fortuneTelling,
  /// );
  /// ```
  static String generateAIPrompt(
    CompleteDate date, {
    Language? language,
    AIPromptType type = AIPromptType.horoscope,
  }) {
    return AIPromptService.generatePrompt(date, language: language, type: type);
  }

  /// Get astrological information for a date
  ///
  /// Returns [AstroInfo] containing astrological calculations
  /// such as sabbath days, yatyaza, pyathada, mahabote, etc.
  static AstroInfo getAstroInfo(MyanmarDate date, {CalendarConfig? config}) {
    return _clientFor(config).getAstroInfo(date);
  }

  /// Get holiday information for a date
  ///
  /// Returns [HolidayInfo] containing public, religious, and cultural
  /// holidays for the given Myanmar date.
  static HolidayInfo getHolidayInfo(
    MyanmarDate date, {
    Language? language,
    CalendarConfig? config,
  }) {
    return _clientFor(config).getHolidayInfo(date, language: language);
  }

  /// Check if a Myanmar year is a watat year
  ///
  /// Returns true if the year has an intercalary month.
  ///
  /// Example:
  /// ```dart
  /// final isWatat = MyanmarCalendar.isWatatYear(1385);
  /// print('1385 is watat year: $isWatat');
  /// ```
  static bool isWatatYear(int myanmarYear) {
    return _client.isWatatYear(myanmarYear);
  }

  /// Get year type for a Myanmar year
  ///
  /// Returns:
  /// - 0: Common year
  /// - 1: Little watat year
  /// - 2: Big watat year
  static int getYearType(int myanmarYear) {
    return _client.getYearType(myanmarYear);
  }

  /// Get all dates in a Myanmar month
  ///
  /// Returns a list of [MyanmarDate] objects representing all days
  /// in the specified Myanmar month and year.
  static List<MyanmarDate> getMyanmarMonth(
    int year,
    int month, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).getMyanmarMonth(year, month);
  }

  /// Get Western dates for a Myanmar month
  static List<DateTime> getWesternDatesForMyanmarMonth(
    int year,
    int month, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).getWesternDatesForMyanmarMonth(year, month);
  }

  /// Find auspicious days for a given Myanmar month and year
  static List<CompleteDate> findAuspiciousDays(
    int year,
    int month, {
    Language? language,
    CalendarConfig? config,
  }) {
    return _clientFor(config).findAuspiciousDays(
      year,
      month,
      language: language,
    );
  }

  /// Get description for Nakhat type
  ///
  /// In the configured language (it used to be English regardless).
  static String getNakhatDescription(String nakhat) {
    return _client.getNakhatDescription(nakhat);
  }

  /// Get characteristics for Mahabote type, in the configured language.
  static String getMahaboteCharacteristics(String mahabote) {
    return _client.getMahaboteCharacteristics(mahabote);
  }

  /// Get description for astrological days, in the configured language.
  static String getAstrologicalDayDescription(String dayName) {
    return _client.getAstrologicalDayDescription(dayName);
  }

  // ============================================================================
  // FORMATTING METHODS
  // ============================================================================

  /// Format Myanmar date
  ///
  /// Formats a Myanmar date using the specified pattern and language.
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.today();
  /// final formatted = MyanmarCalendar.formatMyanmar(
  ///   date.myanmarDate,
  ///   pattern: '&y &M &P &ff',
  ///   language: Language.myanmar,
  /// );
  /// ```
  static String formatMyanmar(
    MyanmarDate date, {
    String? pattern,
    Language? language,
  }) {
    return _client.formatMyanmar(date, pattern: pattern, language: language);
  }

  /// Format Western date
  ///
  /// Formats a Western date using the specified pattern and language.
  static String formatWestern(
    WesternDate date, {
    String? pattern,
    Language? language,
  }) {
    return _client.formatWestern(date, pattern: pattern, language: language);
  }

  /// Format date with default patterns
  ///
  /// Convenience method to format a [MyanmarDateTime] with default patterns.
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.today();
  /// final formatted = MyanmarCalendar.format(date, language: Language.myanmar);
  /// ```
  static String format(
    MyanmarDateTime dateTime, {
    String? myanmarPattern,
    String? westernPattern,
    Language? language,
  }) {
    return dateTime.formatComplete(
      myanmarPattern: myanmarPattern,
      westernPattern: westernPattern,
      language: language,
    );
  }

  // ============================================================================
  // VALIDATION METHODS
  // ============================================================================

  /// Validate Myanmar date
  ///
  /// Validates Myanmar date components and returns a [ValidationResult].
  ///
  /// Example:
  /// ```dart
  /// final result = MyanmarCalendar.validateMyanmar(1385, 15, 1);
  /// if (!result.isValid) {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  static ValidationResult validateMyanmar(int year, int month, int day) {
    return _client.validateMyanmar(year, month, day);
  }

  /// Check if Myanmar date is valid
  ///
  /// Returns true if the Myanmar date is valid, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final isValid = MyanmarCalendar.isValidMyanmar(1385, 10, 1);
  /// print('Date is valid: $isValid');
  /// ```
  static bool isValidMyanmar(int year, int month, int day) {
    return validateMyanmar(year, month, day).isValid;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Calculate days between two dates
  ///
  /// Returns the number of days between two [MyanmarDateTime] objects.
  static int daysBetween(MyanmarDateTime date1, MyanmarDateTime date2) {
    return _clientFor(date1.config).daysBetween(date1, date2);
  }

  /// Add days to a Myanmar date
  ///
  /// Returns a new [MyanmarDateTime] with the specified number of days added.
  ///
  /// The result keeps [date]'s configuration.
  static MyanmarDateTime addDays(MyanmarDateTime date, int days) {
    return _clientFor(date.config).addDays(date, days);
  }

  /// Add months to a Myanmar date.
  ///
  /// Returns a new [MyanmarDateTime] by following deterministic Myanmar month
  /// transitions and clamping day-of-month where needed.
  ///
  /// The result keeps [date]'s configuration.
  static MyanmarDateTime addMonths(MyanmarDateTime date, int months) {
    return _clientFor(date.config).addMonths(date, months);
  }

  /// Find next occurrence of a moon phase
  ///
  /// Returns the next [MyanmarDateTime] that has the specified moon phase.
  ///
  /// Moon phases:
  /// - 0: Waxing
  /// - 1: Full moon
  /// - 2: Waning
  /// - 3: New moon
  static MyanmarDateTime findNextMoonPhase(
    MyanmarDateTime startDate,
    int moonPhase,
  ) {
    return _clientFor(
      startDate.config,
    ).findNextMoonPhase(startDate, moonPhase);
  }

  /// Find all sabbath days in a month
  ///
  /// Returns a list of [MyanmarDateTime] objects representing all sabbath
  /// days in the specified Myanmar month and year.
  static List<MyanmarDateTime> findSabbathDays(
    int year,
    int month, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).findSabbathDays(year, month);
  }

  // ============================================================================
  // LANGUAGE AND LOCALIZATION
  // ============================================================================

  /// Set the current language
  ///
  /// Changes the language used for formatting and translations.
  ///
  /// Example:
  /// ```dart
  /// MyanmarCalendar.setLanguage(Language.myanmar);
  /// ```
  static void setLanguage(Language language) {
    _setGlobal(CalendarConfig.global.copyWith(defaultLanguage: language.code));
  }

  /// Get the configured default language.
  static Language get currentLanguage =>
      Language.fromCode(config.defaultLanguage);

  /// Get all supported languages
  static List<Language> get supportedLanguages => Language.values;

  /// Check if a language is supported
  static bool isLanguageSupported(String languageCode) {
    return PackageConstants.isLanguageSupported(languageCode);
  }

  // ============================================================================
  // PACKAGE INFORMATION
  // ============================================================================

  /// Get package version
  static String get version => PackageConstants.version;

  /// Get package name
  static String get packageName => PackageConstants.packageName;

  /// Get package information
  static Map<String, dynamic> get packageInfo => PackageConstants.packageInfo;

  /// Get validation limits
  static Map<String, int> get validationLimits =>
      PackageConstants.validationLimits;

  /// Get available format patterns for Myanmar dates
  static List<String> get availableMyanmarPatterns =>
      PackageConstants.availableMyanmarPatterns;

  /// Get available format patterns for Western dates
  static List<String> get availableWesternPatterns =>
      PackageConstants.availableWesternPatterns;

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Convert multiple Western dates to Myanmar dates
  ///
  /// Efficiently converts a list of Western dates to Myanmar dates.
  /// Useful for batch processing of date data.
  static List<MyanmarDateTime> convertWesternDates(
    List<DateTime> westernDates, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).convertWesternDates(westernDates);
  }

  /// Convert Myanmar (year, month, day) records to [MyanmarDateTime]s.
  ///
  /// Example:
  /// ```dart
  /// final dates = MyanmarCalendar.convertMyanmarDates([
  ///   (1385, 10, 1),
  ///   (1385, 10, 15),
  /// ]);
  /// ```
  static List<MyanmarDateTime> convertMyanmarDates(
    List<(int year, int month, int day)> dates, {
    CalendarConfig? config,
  }) {
    return _clientFor(config).convertMyanmarDates(dates);
  }

  /// Get complete date information for multiple dates
  ///
  /// Returns a list of [CompleteDate] objects for the given dates.
  /// Efficient for bulk processing of date information.
  static List<CompleteDate> getCompleteDates(
    List<DateTime> dates, {
    Language? language,
    CalendarConfig? config,
  }) {
    return _clientFor(config).getCompleteDates(dates, language: language);
  }

  // ============================================================================
  // DEBUGGING AND DIAGNOSTICS
  // ============================================================================

  /// Get diagnostic information about the current configuration
  ///
  /// Returns a map containing diagnostic information useful for
  /// debugging and troubleshooting.
  static Map<String, dynamic> getDiagnostics() {
    return {
      'packageInfo': packageInfo,
      'configuration': {
        'sasanaYearType': config.sasanaYearType,
        'calendarType': config.calendarType,
        'gregorianStart': config.gregorianStart,
        'timezoneOffset': config.timezoneOffset,
        'defaultLanguage': config.defaultLanguage,
      },
      'currentLanguage': currentLanguage.code,
      'supportedLanguages': supportedLanguages
          .map((lang) => lang.code)
          .toList(),
      'validationLimits': validationLimits,
      'availablePatterns': {
        'myanmar': availableMyanmarPatterns,
        'western': availableWesternPatterns,
      },
    };
  }

  /// Reset to default configuration
  ///
  /// Resets all configuration to package defaults.
  /// Useful for testing or clearing custom configurations.
  static void reset() {
    _setGlobal(const CalendarConfig());
    _defaultClient = null;
    _configClients.clear();
    MyanmarDateTime.clearSharedInstances();
    cache.clearAll();
  }

  /// Get chronicles for [DateTime]
  static List<ChronicleEntryData> getChronicleFor(DateTime dt) {
    return _client.getChronicleFor(dt);
  }

  /// Get dynasty data for [DateTime]
  static DynastyData? getDynastyFor(DateTime dt) {
    return _client.getDynastyFor(dt);
  }

  /// Get chronicles for a Julian Day Number
  static List<ChronicleEntryData> getChronicleForJdn(double jdn) {
    return _client.getChronicleForJdn(jdn);
  }

  /// Get dynasty for a Julian Day Number
  static DynastyData? getDynastyForJdn(double jdn) {
    return _client.getDynastyForJdn(jdn);
  }

  /// Get chronicles for a MyanmarDate (uses its JDN)
  static List<ChronicleEntryData> getChronicleForMyanmar(MyanmarDate date) {
    return _client.getChronicleForMyanmar(date);
  }

  /// Get dynasty for a MyanmarDate (uses its JDN)
  static DynastyData? getDynastyForMyanmar(MyanmarDate date) {
    return _client.getDynastyForMyanmar(date);
  }

  /// Get entries for a given dynasty ID
  static List<ChronicleEntryData> getEntriesForDynasty(String dynastyId) {
    return _client.getEntriesForDynasty(dynastyId);
  }

  /// Get chronicle entries intersecting [start, end] (DateTime) range
  static List<ChronicleEntryData> getChroniclesBetween(
    DateTime start,
    DateTime end,
  ) {
    return _client.getChroniclesBetween(start, end);
  }

  /// Get chronicle entries intersecting [startJdn, endJdn]
  static List<ChronicleEntryData> getChroniclesBetweenJdn(
    double startJdn,
    double endJdn,
  ) {
    return _client.getChroniclesBetweenJdn(startJdn, endJdn);
  }

  /// List all dynasties
  static List<DynastyData> listDynasties() {
    return _client.listDynasties();
  }

  /// Lookup a dynasty by ID
  static DynastyData? getDynastyById(String dynastyId) {
    return _client.getDynastyById(dynastyId);
  }

  // ============================================================================
  // SHAN CALENDAR SUPPORT
  // ============================================================================

  /// Get Shan calendar year from Myanmar year
  ///
  /// Formula: Shan Year = Myanmar Year + 733
  ///
  /// Example:
  /// ```dart
  /// final shanYear = MyanmarCalendar.getShanYear(1387); // Returns 2120
  /// ```
  static int getShanYear(int myanmarYear) {
    return ShanCalendarConstants.getShanYear(myanmarYear);
  }

  /// Get Myanmar year from Shan year
  ///
  /// Example:
  /// ```dart
  /// final myanmarYear = MyanmarCalendar.getMyanmarYearFromShan(2120); // Returns 1387
  /// ```
  static int getMyanmarYearFromShan(int shanYear) {
    return ShanCalendarConstants.getMyanmarYearFromShan(shanYear);
  }

  /// Get today's date in Shan calendar
  ///
  /// Example:
  /// ```dart
  /// final shanToday = MyanmarCalendar.todayInShan();
  /// print('Today is Shan year ${shanToday.year}'); // e.g., 2120
  /// ```
  static ShanDate todayInShan() {
    return today().shanDate;
  }

  /// Verify Shan year calculation
  ///
  /// Useful for debugging and validation
  static bool verifyShanYear(int myanmarYear, int expectedShanYear) {
    return ShanCalendarConstants.verifyShanYear(myanmarYear, expectedShanYear);
  }

  /// Format a Shan date
  ///
  /// Example:
  /// ```dart
  /// final shanDate = MyanmarCalendar.todayInShan();
  /// final formatted = MyanmarCalendar.formatShanDate(shanDate);
  /// print(formatted); // "ပီ 2120 လိူၼ်ပူၼ် ဝၼ်း 15"
  /// ```
  static String formatShanDate(ShanDate date, {String? pattern}) {
    return date.format(pattern: pattern ?? 'ပီ &sy &sm ဝၼ်း &d');
  }
}
