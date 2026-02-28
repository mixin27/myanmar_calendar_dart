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
import 'package:myanmar_calendar_dart/src/models/shan_date.dart';
import 'package:myanmar_calendar_dart/src/models/validation_result.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_holiday_provider.dart';
import 'package:myanmar_calendar_dart/src/services/ai_prompt_service.dart';
import 'package:myanmar_calendar_dart/src/services/chronicle_service.dart';
import 'package:myanmar_calendar_dart/src/services/myanmar_calendar_service.dart';
import 'package:myanmar_calendar_dart/src/utils/astro_details.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_utils.dart';
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

  static ChronicleService? _chronicles;
  static ChronicleService _chronicleInstance() {
    _chronicles ??= ChronicleService(config: config, language: currentLanguage);
    return _chronicles!;
  }

  // Private static instances
  static MyanmarCalendarService? _service;

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
  /// [customHolidays] - Legacy alias for [customHolidayRules]
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
    @Deprecated('Use customHolidayRules instead.')
    List<CustomHoliday>? customHolidays,
    List<HolidayId>? disabledHolidays,
    Map<int, List<HolidayId>>? disabledHolidaysByYear,
    Map<String, List<HolidayId>>? disabledHolidaysByDate,
    WesternHolidayProvider? westernHolidayProvider,
  }) {
    final resolvedCustomHolidayRules = customHolidayRules ?? customHolidays;

    // Update configuration
    CalendarConfig.global = CalendarConfig.global.copyWith(
      defaultLanguage: language?.code,
      timezoneOffset: timezoneOffset,
      sasanaYearType: sasanaYearType,
      calendarType: calendarType,
      gregorianStart: gregorianStart,
      customHolidayRules: resolvedCustomHolidayRules,
      disabledHolidays: disabledHolidays,
      disabledHolidaysByYear: disabledHolidaysByYear,
      disabledHolidaysByDate: disabledHolidaysByDate,
      westernHolidayProvider: westernHolidayProvider,
    );

    // Reset service to pick up new configuration
    _service = null;
    _chronicles = null;
    MyanmarDateTime.clearSharedInstances();

    // Clear holiday cache to ensure new custom holidays are picked up
    cache
      ..clearHolidayInfoCache()
      ..clearCompleteDateCache();
  }

  /// Add one custom holiday rule to the configuration.
  static void addCustomHolidayRule(CustomHoliday rule) {
    CalendarConfig.global = CalendarConfig.global.copyWith(
      customHolidayRules: [...CalendarConfig.global.customHolidayRules, rule],
    );
    _service = null;
    MyanmarDateTime.clearSharedInstances();
    cache
      ..clearHolidayInfoCache()
      ..clearCompleteDateCache();
  }

  /// Add multiple custom holiday rules to the configuration.
  static void addCustomHolidayRules(List<CustomHoliday> rules) {
    CalendarConfig.global = CalendarConfig.global.copyWith(
      customHolidayRules: [
        ...CalendarConfig.global.customHolidayRules,
        ...rules,
      ],
    );
    _service = null;
    MyanmarDateTime.clearSharedInstances();
    cache
      ..clearHolidayInfoCache()
      ..clearCompleteDateCache();
  }

  /// Remove a custom holiday rule by [id].
  static void removeCustomHolidayRuleById(String id) {
    CalendarConfig.global = CalendarConfig.global.copyWith(
      customHolidayRules: CalendarConfig.global.customHolidayRules
          .where((h) => h.id != id)
          .toList(),
    );
    _service = null;
    MyanmarDateTime.clearSharedInstances();
    cache
      ..clearHolidayInfoCache()
      ..clearCompleteDateCache();
  }

  /// Remove all custom holiday rules from the configuration.
  static void clearCustomHolidayRules() {
    CalendarConfig.global = CalendarConfig.global.copyWith(
      customHolidayRules: [],
    );
    _service = null;
    MyanmarDateTime.clearSharedInstances();
    cache
      ..clearHolidayInfoCache()
      ..clearCompleteDateCache();
  }

  /// Add a custom holiday to the configuration.
  @Deprecated('Use addCustomHolidayRule instead.')
  static void addCustomHoliday(CustomHoliday holiday) {
    addCustomHolidayRule(holiday);
  }

  /// Add multiple custom holidays to the configuration.
  @Deprecated('Use addCustomHolidayRules instead.')
  static void addCustomHolidays(List<CustomHoliday> holidays) {
    addCustomHolidayRules(holidays);
  }

  /// Remove a custom holiday from the configuration.
  @Deprecated('Use removeCustomHolidayRuleById instead.')
  static void removeCustomHoliday(CustomHoliday holiday) {
    removeCustomHolidayRuleById(holiday.id);
  }

  /// Remove all custom holidays from the configuration.
  @Deprecated('Use clearCustomHolidayRules instead.')
  static void clearCustomHolidays() {
    clearCustomHolidayRules();
  }

  /// Get current configuration
  static CalendarConfig get config => CalendarConfig.global;

  /// Get the service instance (lazy initialization)
  static MyanmarCalendarService get _serviceInstance {
    // Service uses global cache automatically
    _service ??= MyanmarCalendarService.withGlobalCache(config: config);
    return _service!;
  }

  /// Configure global cache used by all MyanmarCalendar operations
  static void configureCache(CacheConfig cacheConfig) {
    CalendarCache.configureGlobal(cacheConfig);
    _service = null; // Reset service to use new cache
    MyanmarDateTime.clearSharedInstances();
  }

  /// Get global cache instance
  static CalendarCache get cache => CalendarCache.global();

  /// Clear all caches
  static void clearCache() {
    cache.clearAll();
  }

  /// Get global cache statistics
  static Map<String, dynamic> getCacheStatistics() {
    return cache.getStatistics();
  }

  /// Warm up global cache
  static void warmUpCache({DateTime? startDate, DateTime? endDate}) {
    cache.warmUp(
      startDate: startDate,
      endDate: endDate,
      resolveCompleteDate: _serviceInstance.getCompleteDate,
    );
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
  static MyanmarDateTime today() {
    return MyanmarDateTime.now(config: config);
  }

  /// Get current Myanmar date and time
  ///
  /// Alias for [today] method for clarity in usage.
  static MyanmarDateTime now() {
    return today();
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

  /// Create Myanmar date from DateTime object
  ///
  /// Converts a Dart [DateTime] object to Myanmar calendar date.
  ///
  /// Example:
  /// ```dart
  /// final dartDate = DateTime(2024, 1, 1);
  /// final myanmarDate = MyanmarCalendar.fromDateTime(dartDate);
  /// ```
  static MyanmarDateTime fromDateTime(DateTime dateTime) {
    return MyanmarDateTime.fromDateTime(dateTime, config: config);
  }

  /// Create Myanmar date from Julian Day Number
  ///
  /// Creates a Myanmar date from a Julian Day Number.
  /// Useful for astronomical calculations or when working with
  /// external calendar systems.
  static MyanmarDateTime fromJulianDay(double julianDayNumber) {
    return MyanmarDateTime.fromJulianDay(julianDayNumber, config: config);
  }

  /// Create Myanmar date from milliseconds since epoch
  ///
  /// Converts Unix timestamp (milliseconds since epoch) to Myanmar date.
  static MyanmarDateTime fromMillisecondsSinceEpoch(
    int milliseconds, {
    bool isUtc = false,
  }) {
    return MyanmarDateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: isUtc,
      config: config,
    );
  }

  /// Create Myanmar date from timestamp (seconds since epoch)
  ///
  /// Converts Unix timestamp (seconds since epoch) to Myanmar date.
  static MyanmarDateTime fromTimestamp(int timestamp) {
    return MyanmarDateTime.fromTimestamp(timestamp, config: config);
  }

  // ============================================================================
  // PARSING METHODS
  // ============================================================================

  /// Parse Myanmar date string
  ///
  /// Attempts to parse various Myanmar date string formats.
  /// Returns null if parsing fails.
  ///
  /// Supported formats:
  /// - "1385/10/1"
  /// - "1385-10-1"
  /// - "1.10.1385"
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.parseMyanmar('1385/10/1');
  /// if (date != null) {
  ///   print('Parsed: ${date.formatMyanmar()}');
  /// }
  /// ```
  static MyanmarDateTime? parseMyanmar(String dateString) {
    return MyanmarDateTime.parseMyanmar(dateString, config: config);
  }

  /// Parse Western date string
  ///
  /// Attempts to parse Western date string using Dart's DateTime.parse.
  /// Returns null if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.parseWestern('2024-01-01');
  /// if (date != null) {
  ///   print('Parsed: ${date.formatWestern()}');
  /// }
  /// ```
  static MyanmarDateTime? parseWestern(String dateString) {
    return MyanmarDateTime.parseWestern(dateString, config: config);
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
  static CompleteDate getCompleteDate(DateTime dateTime) {
    return _serviceInstance.getCompleteDate(dateTime);
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
  static AstroInfo getAstroInfo(MyanmarDate date) {
    return _serviceInstance.getAstroInfo(date);
  }

  /// Get holiday information for a date
  ///
  /// Returns [HolidayInfo] containing public, religious, and cultural
  /// holidays for the given Myanmar date.
  static HolidayInfo getHolidayInfo(MyanmarDate date) {
    return _serviceInstance.getHolidayInfo(date);
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
    return _serviceInstance.isWatatYear(myanmarYear);
  }

  /// Get year type for a Myanmar year
  ///
  /// Returns:
  /// - 0: Common year
  /// - 1: Little watat year
  /// - 2: Big watat year
  static int getYearType(int myanmarYear) {
    return _serviceInstance.getYearType(myanmarYear);
  }

  /// Get all dates in a Myanmar month
  ///
  /// Returns a list of [MyanmarDate] objects representing all days
  /// in the specified Myanmar month and year.
  static List<MyanmarDate> getMyanmarMonth(int year, int month) {
    return _serviceInstance.getMyanmarMonth(year, month);
  }

  /// Get Western dates for a Myanmar month
  static List<DateTime> getWesternDatesForMyanmarMonth(int year, int month) {
    return _serviceInstance.getWesternDatesForMyanmarMonth(year, month);
  }

  /// Find auspicious days for a given Myanmar month and year
  static List<CompleteDate> findAuspiciousDays(int year, int month) {
    return _serviceInstance.findAuspiciousDays(year, month);
  }

  /// Get description for Nakhat type
  static String getNakhatDescription(String nakhat) {
    return AstroDetails.getNakhatDescription(nakhat);
  }

  /// Get characteristics for Mahabote type
  static String getMahaboteCharacteristics(String mahabote) {
    return AstroDetails.getMahaboteCharacteristics(mahabote);
  }

  /// Get description for astrological days
  static String getAstrologicalDayDescription(String dayName) {
    return AstroDetails.getAstrologicalDayDescription(dayName);
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
    return _serviceInstance.formatMyanmarDate(
      date,
      pattern: pattern,
      language: language,
    );
  }

  /// Format Western date
  ///
  /// Formats a Western date using the specified pattern and language.
  static String formatWestern(
    WesternDate date, {
    String? pattern,
    Language? language,
  }) {
    return _serviceInstance.formatWesternDate(
      date,
      pattern: pattern,
      language: language,
    );
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
    return _serviceInstance.validateMyanmarDate(year, month, day);
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
    return date1.differenceInDays(date2).abs();
  }

  /// Add days to a Myanmar date
  ///
  /// Returns a new [MyanmarDateTime] with the specified number of days added.
  static MyanmarDateTime addDays(MyanmarDateTime date, int days) {
    return date.addDays(days);
  }

  /// Add months to a Myanmar date (approximate)
  ///
  /// Returns a new [MyanmarDateTime] with approximately the specified
  /// number of months added. This is an approximation due to varying
  /// month lengths in the Myanmar calendar.
  static MyanmarDateTime addMonths(MyanmarDateTime date, int months) {
    final myanmarDate = CalendarUtils.addMonthsToMyanmarDate(
      date.myanmarDate,
      months,
    );
    return MyanmarDateTime.fromMyanmarDate(myanmarDate, config: config);
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
    final nextDate = CalendarUtils.findNextMoonPhase(
      startDate.myanmarDate,
      moonPhase,
    );
    return MyanmarDateTime.fromMyanmarDate(nextDate, config: config);
  }

  /// Find all sabbath days in a month
  ///
  /// Returns a list of [MyanmarDateTime] objects representing all sabbath
  /// days in the specified Myanmar month and year.
  static List<MyanmarDateTime> findSabbathDays(int year, int month) {
    final sabbathDates = CalendarUtils.findSabbathDaysInMonth(year, month);
    return sabbathDates
        .map((date) => MyanmarDateTime.fromMyanmarDate(date, config: config))
        .toList();
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
    CalendarConfig.global = CalendarConfig.global.copyWith(
      defaultLanguage: language.code,
    );
    _service?.setLanguage(language);
    _chronicles = null;
    MyanmarDateTime.clearSharedInstances();
    cache
      ..clearHolidayInfoCache()
      ..clearCompleteDateCache();
  }

  /// Get the current language
  static Language get currentLanguage => _serviceInstance.currentLanguage;

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
    List<DateTime> westernDates,
  ) {
    return westernDates
        .map((date) => MyanmarDateTime.fromDateTime(date, config: config))
        .toList();
  }

  /// Convert multiple Myanmar date maps to MyanmarDateTime objects
  ///
  /// Converts a list of maps containing Myanmar date components
  /// to [MyanmarDateTime] objects.
  ///
  /// Example:
  /// ```dart
  /// final dateMaps = [
  ///   {'year': 1385, 'month': 10, 'day': 1},
  ///   {'year': 1385, 'month': 10, 'day': 15},
  /// ];
  /// final dates = MyanmarCalendar.convertMyanmarDates(dateMaps);
  /// ```
  static List<MyanmarDateTime> convertMyanmarDates(
    List<Map<String, int>> dateMaps,
  ) {
    return dateMaps
        .map(
          (dateMap) => MyanmarDateTime.fromMyanmar(
            dateMap['year']!,
            dateMap['month']!,
            dateMap['day']!,
            config: config,
          ),
        )
        .toList();
  }

  /// Get complete date information for multiple dates
  ///
  /// Returns a list of [CompleteDate] objects for the given dates.
  /// Efficient for bulk processing of date information.
  static List<CompleteDate> getCompleteDates(List<DateTime> dates) {
    return CalendarUtils.getCompleteDatesForWesternDates(dates);
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
    CalendarConfig.global = const CalendarConfig();
    _chronicles = null;
    _service = null;
    MyanmarDateTime.clearSharedInstances();
    cache.clearAll();
  }

  /// Get chronicles for [DateTime]
  static List<ChronicleEntryData> getChronicleFor(DateTime dt) {
    final jdn = WesternDate.fromDateTime(dt).julianDayNumber;
    return _chronicleInstance().byJdn(jdn);
  }

  /// Get dynasty data for [DateTime]
  static DynastyData? getDynastyFor(DateTime dt) {
    final jdn = WesternDate.fromDateTime(dt).julianDayNumber;
    return _chronicleInstance().dynastyForJdn(jdn);
  }

  /// Get chronicles for a Julian Day Number
  static List<ChronicleEntryData> getChronicleForJdn(double jdn) {
    return _chronicleInstance().byJdn(jdn);
  }

  /// Get dynasty for a Julian Day Number
  static DynastyData? getDynastyForJdn(double jdn) {
    return _chronicleInstance().dynastyForJdn(jdn);
  }

  /// Get chronicles for a MyanmarDate (uses its JDN)
  static List<ChronicleEntryData> getChronicleForMyanmar(MyanmarDate date) {
    return _chronicleInstance().byJdn(date.julianDayNumber);
  }

  /// Get dynasty for a MyanmarDate (uses its JDN)
  static DynastyData? getDynastyForMyanmar(MyanmarDate date) {
    return _chronicleInstance().dynastyForJdn(date.julianDayNumber);
  }

  /// Get entries for a given dynasty ID
  static List<ChronicleEntryData> getEntriesForDynasty(String dynastyId) {
    return _chronicleInstance().entriesForDynasty(dynastyId);
  }

  /// Get chronicle entries intersecting [start, end] (DateTime) range
  static List<ChronicleEntryData> getChroniclesBetween(
    DateTime start,
    DateTime end,
  ) {
    final a = WesternDate.fromDateTime(start).julianDayNumber;
    final b = WesternDate.fromDateTime(end).julianDayNumber;
    return _chronicleInstance().betweenJdn(a, b);
  }

  /// Get chronicle entries intersecting [startJdn, endJdn]
  static List<ChronicleEntryData> getChroniclesBetweenJdn(
    double startJdn,
    double endJdn,
  ) {
    return _chronicleInstance().betweenJdn(startJdn, endJdn);
  }

  /// List all dynasties
  static List<DynastyData> listDynasties() {
    return _chronicleInstance().allDynasties();
  }

  /// Lookup a dynasty by ID
  static DynastyData? getDynastyById(String dynastyId) {
    return _chronicleInstance().dynastyById(dynastyId);
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
