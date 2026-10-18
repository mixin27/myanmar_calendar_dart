import 'package:myanmar_calendar_dart/src/core/calendar_cache.dart';
import 'package:myanmar_calendar_dart/src/core/calendar_config.dart';
import 'package:myanmar_calendar_dart/src/exceptions/calendar_exceptions.dart';
import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/models/astro_info.dart';
import 'package:myanmar_calendar_dart/src/models/calendar_enums.dart';
import 'package:myanmar_calendar_dart/src/models/complete_date.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/shan_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/services/astro_calculator.dart';
import 'package:myanmar_calendar_dart/src/services/date_converter.dart';
import 'package:myanmar_calendar_dart/src/services/format_service.dart';
import 'package:myanmar_calendar_dart/src/services/holiday_calculator.dart';
import 'package:myanmar_calendar_dart/src/services/myanmar_calendar_service.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_constants.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_utils.dart';

/// Myanmar DateTime class that provides a convenient interface for Myanmar calendar operations
///
/// This class acts as a wrapper around the DateConverter service, providing:
/// - Easy creation from various date sources
/// - Convenient getters for all date properties
/// - Factory constructors for different use cases
/// - Integration with Dart's DateTime class
/// - Astrological and holiday information access
class MyanmarDateTime implements Comparable<MyanmarDateTime> {
  /// Create from Map (deserialization)
  factory MyanmarDateTime.fromMap(
    Map<String, dynamic> map, {
    CalendarConfig? config,
  }) {
    final completeDate = CompleteDate.fromMap(map);
    return MyanmarDateTime.fromMyanmarDate(
      completeDate.myanmar,
      config: config,
    );
  }

  /// Create from timestamp (seconds since epoch), an instant.
  factory MyanmarDateTime.fromTimestamp(
    int timestamp, {
    CalendarConfig? config,
  }) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    );
    return MyanmarDateTime.fromDateTime(dateTime, config: config);
  }

  /// Creates Myanmar DateTime from milliseconds since epoch.
  ///
  /// The value is an instant, shown in the configured time zone whatever the
  /// device's zone.
  factory MyanmarDateTime.fromMillisecondsSinceEpoch(
    int milliseconds, {
    CalendarConfig? config,
  }) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    );

    return MyanmarDateTime.fromDateTime(dateTime, config: config);
  }

  /// Creates Myanmar DateTime from Julian Day Number
  factory MyanmarDateTime.fromJulianDay(
    double julianDayNumber, {
    CalendarConfig? config,
  }) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      julianDayNumber,
    );
  }

  /// Creates Myanmar DateTime from WesternDate object
  factory MyanmarDateTime.fromWesternDate(
    WesternDate westernDate, {
    CalendarConfig? config,
  }) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    // WesternDate's own Julian day is local time; convert its fields.
    final jdn = converter.westernToJulian(
      westernDate.year,
      westernDate.month,
      westernDate.day,
      westernDate.hour,
      westernDate.minute,
      westernDate.second,
    );
    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      jdn,
    );
  }

  /// Creates Myanmar DateTime from MyanmarDate object
  factory MyanmarDateTime.fromMyanmarDate(
    MyanmarDate myanmarDate, {
    CalendarConfig? config,
  }) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    // MyanmarDate holds the local day number (local noon).
    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      myanmarDate.julianDayNumber.roundToDouble() - cfg.timezoneOffsetInDays,
    );
  }

  /// Creates Myanmar DateTime from Myanmar date components
  factory MyanmarDateTime.fromMyanmar(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
    int second = 0,
    CalendarConfig? config,
  }) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    final jdn = converter.myanmarToJulian(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );

    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      jdn,
    );
  }

  /// Creates Myanmar DateTime from Western date components
  factory MyanmarDateTime.fromWestern(
    int year,
    int month,
    int day, {
    int hour = 12,
    int minute = 0,
    int second = 0,
    CalendarConfig? config,
  }) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    final jdn = converter.westernToJulian(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );

    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      jdn,
    );
  }

  /// Parses a Myanmar date such as `1385/10/1` or `1.10.1385` (see
  /// `CalendarUtils.parseMyanmarDate`). Throws [DateParseException].
  factory MyanmarDateTime.parseMyanmar(
    String dateString, {
    CalendarConfig? config,
  }) {
    final date = CalendarUtils.parseMyanmarDate(
      dateString,
      service: MyanmarCalendarService.withGlobalCache(
        config: config ?? CalendarConfig.global,
      ),
    );
    return MyanmarDateTime.fromMyanmarDate(date, config: config);
  }

  /// Parses an ISO 8601 Western date such as `2024-01-01` (as
  /// `DateTime.parse` does). Throws [DateParseException].
  factory MyanmarDateTime.parseWestern(
    String dateString, {
    CalendarConfig? config,
  }) {
    final DateTime dateTime;
    try {
      dateTime = DateTime.parse(dateString);
    } on FormatException catch (e, stack) {
      throw DateParseException(
        dateString: dateString,
        expectedFormat: 'ISO 8601, such as 2024-01-01',
        originalError: e,
        stackTrace: stack,
      );
    }
    return MyanmarDateTime.fromDateTime(dateTime, config: config);
  }

  /// Creates Myanmar DateTime from DateTime object.
  ///
  /// A local [dateTime]'s fields are read as wall-clock time in the
  /// configured time zone; a UTC [dateTime] is an instant.
  factory MyanmarDateTime.fromDateTime(
    DateTime dateTime, {
    CalendarConfig? config,
  }) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    // Local values are wall-clock time in the configured zone; UTC values
    // are instants.
    final jdn = converter.dateTimeToJulian(dateTime);

    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      jdn,
    );
  }
  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Creates Myanmar DateTime from current date/time
  factory MyanmarDateTime.now({CalendarConfig? config}) {
    final cfg = config ?? CalendarConfig.global;
    final converter = _getConverter(cfg);

    // The current instant, shown in the configured time zone.
    final jdn = converter.dateTimeToJulian(DateTime.now().toUtc());

    return MyanmarDateTime._(
      converter,
      _sharedAstroCalculator,
      _getHolidayCalculator(cfg),
      jdn,
    );
  }

  /// Private constructor
  MyanmarDateTime._(
    this._converter,
    this._astroCalculator,
    this._holidayCalculator,
    this._julianDayNumber,
  );

  final DateConverter _converter;
  final AstroCalculator _astroCalculator;
  final HolidayCalculator _holidayCalculator;
  final double _julianDayNumber;

  // Cache for computed properties
  MyanmarDate? _myanmarDate;
  WesternDate? _westernDate;
  AstroInfo? _astroInfo;
  HolidayInfo? _holidayInfo;

  // Cache for Shan date
  ShanDate? _shanDate;

  static final Map<String, DateConverter> _converters = {};
  static final Map<String, HolidayCalculator> _holidayCalculators = {};

  // Recreated by clearSharedInstances, so it follows the current global
  // cache after configureCache (it used to keep writing to the old one).
  static AstroCalculator _sharedAstroCalculator = AstroCalculator(
    cache: CalendarCache.global(),
  );
  static final FormatService _sharedFormatService = FormatService();

  /// Clear shared converters and holiday calculators.
  ///
  /// This is used when global configuration is updated so future instances
  /// are created with the latest configuration object.
  static void clearSharedInstances() {
    _converters.clear();
    _holidayCalculators.clear();
    _sharedAstroCalculator = AstroCalculator(cache: CalendarCache.global());
  }

  /// Converters and calculators kept per config, most recent last.
  static const _maxSharedPerConfig = 16;

  static T _remember<T>(Map<String, T> map, String key, T Function() create) {
    final value = map.remove(key) ?? create();
    map[key] = value;
    if (map.length > _maxSharedPerConfig) map.remove(map.keys.first);
    return value;
  }

  /// Get or create a shared converter for the given config
  static DateConverter _getConverter(CalendarConfig config) {
    final key = config.cacheNamespace;
    return _remember(
      _converters,
      key,
      () => DateConverter(
        config,
        cache: CalendarCache.global(),
        cacheNamespace: 'date_converter|$key',
      ),
    );
  }

  /// Get or create a shared holiday calculator for the given config
  static HolidayCalculator _getHolidayCalculator(CalendarConfig config) {
    final key = config.cacheNamespace;
    return _remember(
      _holidayCalculators,
      key,
      () => HolidayCalculator(cache: CalendarCache.global(), config: config),
    );
  }

  // ============================================================================
  // GETTERS - BASIC PROPERTIES
  // ============================================================================

  /// Julian Day Number for this date
  double get julianDayNumber => _julianDayNumber;

  /// Julian Day Number adjusted for local timezone
  double get localJulianDayNumber =>
      _julianDayNumber + _converter.config.timezoneOffset / 24.0;

  /// Rounded Julian Day Number
  int get julianDay => _julianDayNumber.round();

  /// Rounded local Julian Day Number
  int get localJulianDay => localJulianDayNumber.round();

  /// Calendar configuration
  CalendarConfig get config => _converter.config;

  // ============================================================================
  // GETTERS - MYANMAR DATE PROPERTIES
  // ============================================================================

  /// Myanmar date object (cached)
  MyanmarDate get myanmarDate {
    _myanmarDate ??= _converter.julianToMyanmar(_julianDayNumber);
    return _myanmarDate!;
  }

  /// Myanmar year
  int get myanmarYear => myanmarDate.year;

  /// Myanmar month (0-14)
  int get myanmarMonth => myanmarDate.month;

  /// Myanmar day (1-30)
  int get myanmarDay => myanmarDate.day;

  /// Year type (0=common, 1=little watat, 2=big watat)
  int get yearType => myanmarDate.yearType;

  /// [yearType] as a [MyanmarYearType].
  MyanmarYearType get yearKind => myanmarDate.yearKind;

  /// Sasana year
  int get sasanaYear => myanmarDate.sasanaYear;

  /// Month length (29 or 30 days)
  int get monthLength => myanmarDate.monthLength;

  /// Moon phase (0=waxing, 1=full moon, 2=waning, 3=new moon)
  int get moonPhase => myanmarDate.moonPhase;

  /// [moonPhase] as a [MoonPhase].
  MoonPhase get phase => myanmarDate.phase;

  /// Fortnight day (1-15)
  int get fortnightDay => myanmarDate.fortnightDay;

  /// Weekday (0=Saturday, 1=Sunday, ..., 6=Friday)
  int get weekday => myanmarDate.weekday;

  // ============================================================================
  // GETTERS - WESTERN DATE PROPERTIES
  // ============================================================================

  /// Western date object (cached)
  WesternDate get westernDate {
    _westernDate ??= _converter.julianToWestern(_julianDayNumber);
    return _westernDate!;
  }

  /// Western year
  int get westernYear => westernDate.year;

  /// Western month (1-12)
  int get westernMonth => westernDate.month;

  /// Western day (1-31)
  int get westernDay => westernDate.day;

  /// Hour (0-23)
  int get hour => westernDate.hour;

  /// Minute (0-59)
  int get minute => westernDate.minute;

  /// Second (0-59)
  int get second => westernDate.second;

  /// Millisecond (0-999)
  int get millisecond => westernDate.millisecond;

  // ============================================================================
  // GETTERS - ASTROLOGICAL PROPERTIES
  // ============================================================================

  /// Astrological information (cached)
  AstroInfo get astroInfo {
    _astroInfo ??= _astroCalculator.calculate(myanmarDate);
    return _astroInfo!;
  }

  /// List of astrological days
  List<String> get astrologicalDays => astroInfo.astrologicalDays;

  /// Sabbath information
  String get sabbath => astroInfo.sabbath;

  /// Yatyaza information
  String get yatyaza => astroInfo.yatyaza;

  /// Pyathada information
  String get pyathada => astroInfo.pyathada;

  /// Naga head direction
  String get nagahle => astroInfo.nagahle;

  /// Mahabote value
  String get mahabote => astroInfo.mahabote;

  /// Nakhat value
  String get nakhat => astroInfo.nakhat;

  /// Year name from 12-year cycle
  String get yearName => astroInfo.yearName;

  // ============================================================================
  // GETTERS - HOLIDAY PROPERTIES
  // ============================================================================

  /// Holiday information (cached)
  HolidayInfo get holidayInfo {
    _holidayInfo ??= _holidayCalculator.getHolidays(
      myanmarDate,
      customHolidays: config.customHolidayRules,
      language: Language.fromCode(config.defaultLanguage),
    );
    return _holidayInfo!;
  }

  /// All holidays
  List<String> get allHolidays => holidayInfo.allHolidays;

  /// Public holidays
  List<String> get publicHolidays => holidayInfo.publicHolidays;

  /// Religious holidays
  List<String> get religiousHolidays => holidayInfo.religiousHolidays;

  /// Cultural holidays
  List<String> get culturalHolidays => holidayInfo.culturalHolidays;

  /// All anniversary days
  List<String> get allAnniversaryDays => holidayInfo.allAnniversaryDays;

  /// All myanmar anniversary days
  List<String> get myanmarAnniversaryDays => holidayInfo.myanmarAnniversaryDays;

  /// All other anniversary days
  List<String> get otherAnniversaryDays => holidayInfo.otherAnniversaryDays;

  /// All other holidays
  List<String> get otherHolidays => holidayInfo.otherHolidays;

  // ============================================================================
  // GETTERS - BOOLEAN PROPERTIES
  // ============================================================================

  /// Check if this is a watat year
  bool get isWatatYear => yearType > 0;

  /// Check if this is a big watat year
  bool get isBigWatatYear => yearType == 2;

  /// Check if this is a little watat year
  bool get isLittleWatatYear => yearType == 1;

  /// Check if this is a common year
  bool get isCommonYear => yearType == 0;

  /// Check if this is a sabbath day
  bool get isSabbath => sabbath == 'Sabbath';

  /// Check if this is a sabbath eve
  bool get isSabbathEve => sabbath == 'Sabbath Eve';

  /// Check if this is a yatyaza day
  bool get isYatyaza => yatyaza == 'Yatyaza';

  /// Check if this has pyathada
  bool get hasPyathada => pyathada.isNotEmpty;

  /// Check if this date has holidays
  bool get hasHolidays => holidayInfo.hasHolidays;

  /// Check if this date has anniversary days
  bool get hasAnniversaryDays => holidayInfo.hasAnniversaryDays;

  /// Check if this date has astrological significance
  bool get hasAstrologicalDays => astrologicalDays.isNotEmpty;

  /// Check if this is a full moon day
  bool get isFullMoon => moonPhase == CalendarConstants.moonPhaseFullMoon;

  /// Check if this is a new moon day
  bool get isNewMoon => moonPhase == CalendarConstants.moonPhaseNewMoon;

  /// Check if this is in waxing phase
  bool get isWaxing => moonPhase == CalendarConstants.moonPhaseWaxing;

  /// Check if this is in waning phase
  bool get isWaning => moonPhase == CalendarConstants.moonPhaseWaning;

  // ============================================================================
  // DATE ARITHMETIC METHODS
  // ============================================================================

  /// Add days to this Myanmar DateTime
  MyanmarDateTime addDays(int days) {
    final newJdn = _julianDayNumber + days;
    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  /// Subtract days from this Myanmar DateTime
  MyanmarDateTime subtractDays(int days) {
    return addDays(-days);
  }

  /// Add hours to this Myanmar DateTime
  MyanmarDateTime addHours(int hours) {
    final newJdn = _julianDayNumber + (hours / 24.0);
    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  /// Add minutes to this Myanmar DateTime
  MyanmarDateTime addMinutes(int minutes) {
    final newJdn = _julianDayNumber + (minutes / 1440.0); // 24 * 60
    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  /// Add seconds to this Myanmar DateTime
  MyanmarDateTime addSeconds(int seconds) {
    final newJdn = _julianDayNumber + (seconds / 86400.0); // 24 * 60 * 60
    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  /// Add a Duration to this Myanmar DateTime
  MyanmarDateTime add(Duration duration) {
    final newJdn = _julianDayNumber + (duration.inMicroseconds / 86400000000.0);
    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  /// Subtract a Duration from this Myanmar DateTime
  MyanmarDateTime subtract(Duration duration) {
    return add(-duration);
  }

  /// Calculate difference between this and another Myanmar DateTime
  Duration difference(MyanmarDateTime other) {
    final dayDifference = _julianDayNumber - other._julianDayNumber;
    final microseconds = (dayDifference * 86400000000.0).round();
    return Duration(microseconds: microseconds);
  }

  /// Calculate difference in days between this and another Myanmar DateTime
  int differenceInDays(MyanmarDateTime other) {
    return (_julianDayNumber - other._julianDayNumber).round();
  }

  // ============================================================================
  // COMPARISON METHODS
  // ============================================================================

  /// Check if this is before another Myanmar DateTime
  bool isBefore(MyanmarDateTime other) {
    return _julianDayNumber < other._julianDayNumber;
  }

  /// Check if this is after another Myanmar DateTime
  bool isAfter(MyanmarDateTime other) {
    return _julianDayNumber > other._julianDayNumber;
  }

  /// Check if this is at the same moment as another Myanmar DateTime
  bool isAtSameMomentAs(MyanmarDateTime other) {
    return _julianDayNumber == other._julianDayNumber;
  }

  /// Compare this with another Myanmar DateTime
  /// Returns -1 if before, 0 if same, 1 if after
  @override
  int compareTo(MyanmarDateTime other) {
    return _julianDayNumber.compareTo(other._julianDayNumber);
  }

  // ============================================================================
  // CONVERSION METHODS
  // ============================================================================

  /// The wall-clock time in the configured zone, as a local [DateTime]
  /// (its fields, not the device's zone, carry the meaning). Use [toUtc]
  /// for the instant.
  DateTime toDateTime() {
    return westernDate.toDateTime();
  }

  /// This instant as a UTC [DateTime].
  DateTime toUtc() => _converter.julianToUtcDateTime(_julianDayNumber);

  /// Milliseconds since epoch of this instant.
  int get millisecondsSinceEpoch => toUtc().millisecondsSinceEpoch;

  /// Microseconds since epoch of this instant.
  int get microsecondsSinceEpoch => toUtc().microsecondsSinceEpoch;

  /// Create a copy with different time components
  MyanmarDateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    bool? isUtc,
  }) {
    final currentWestern = westernDate;

    final newJdn = _converter.westernToJulian(
      year ?? currentWestern.year,
      month ?? currentWestern.month,
      day ?? currentWestern.day,
      hour ?? currentWestern.hour,
      minute ?? currentWestern.minute,
      second ?? currentWestern.second,
    );

    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  /// Create a copy with different Myanmar date components
  MyanmarDateTime copyWithMyanmar({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
  }) {
    final currentMyanmar = myanmarDate;
    final currentWestern = westernDate;

    final newJdn = _converter.myanmarToJulian(
      year ?? currentMyanmar.year,
      month ?? currentMyanmar.month,
      day ?? currentMyanmar.day,
      hour ?? currentWestern.hour,
      minute ?? currentWestern.minute,
      second ?? currentWestern.second,
    );

    return MyanmarDateTime._(
      _converter,
      _astroCalculator,
      _holidayCalculator,
      newJdn,
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get the start of the day (00:00:00)
  MyanmarDateTime get startOfDay {
    return copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  }

  /// Get the end of the day (23:59:59.999)
  MyanmarDateTime get endOfDay {
    return copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  }

  /// Get the start of the month (first day, 00:00:00)
  MyanmarDateTime get startOfMonth {
    return copyWith(day: 1, hour: 0, minute: 0, second: 0, millisecond: 0);
  }

  /// Get the end of the month (last day, 23:59:59.999)
  MyanmarDateTime get endOfMonth {
    // The Western month, like startOfMonth. (It used the Myanmar month's
    // length as a Western day, so a 30-day Myanmar month threw in
    // February.)
    final western = westernDate;
    final daysInMonth = DateTime.utc(western.year, western.month + 1, 0).day;
    return copyWith(
      day: daysInMonth,
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
    );
  }

  /// Get the start of the year (Tagu 1, 00:00:00)
  MyanmarDateTime get startOfYear {
    return copyWithMyanmar(month: 1, day: 1, hour: 0, minute: 0, second: 0);
  }

  /// Check if this date is in the same day as another
  bool isSameDay(MyanmarDateTime other) {
    return startOfDay.isAtSameMomentAs(other.startOfDay);
  }

  /// Check if this date is in the same month as another
  bool isSameMonth(MyanmarDateTime other) {
    final thisMyanmar = myanmarDate;
    final otherMyanmar = other.myanmarDate;
    return thisMyanmar.year == otherMyanmar.year &&
        thisMyanmar.month == otherMyanmar.month;
  }

  /// Check if this date is in the same year as another
  bool isSameYear(MyanmarDateTime other) {
    return myanmarYear == other.myanmarYear;
  }

  /// Get complete date information
  CompleteDate get completeDate {
    return CompleteDate(
      western: westernDate,
      myanmar: myanmarDate,
      shan: shanDate,
      astro: astroInfo,
      holidays: holidayInfo,
    );
  }

  // ============================================================================
  // FORMATTING METHODS
  // ============================================================================

  /// Format Myanmar date with pattern
  String formatMyanmar([String? pattern, Language? language]) {
    final currentLanguage =
        language ?? Language.fromCode(config.defaultLanguage);
    return _sharedFormatService.formatMyanmarDate(
      myanmarDate,
      pattern: pattern,
      language: currentLanguage,
    );
  }

  /// Format Western date with pattern
  String formatWestern([String? pattern, Language? language]) {
    final currentLanguage =
        language ?? Language.fromCode(config.defaultLanguage);
    return _sharedFormatService.formatWesternDate(
      westernDate,
      pattern: pattern,
      language: currentLanguage,
    );
  }

  /// Format complete date information
  String formatComplete({
    String? myanmarPattern,
    String? westernPattern,
    Language? language,
    bool includeAstro = false,
    bool includeHolidays = false,
  }) {
    final currentLanguage =
        language ?? Language.fromCode(config.defaultLanguage);
    return _sharedFormatService.formatCompleteDate(
      completeDate,
      myanmarPattern: myanmarPattern,
      westernPattern: westernPattern,
      language: currentLanguage,
      includeAstro: includeAstro,
      includeHolidays: includeHolidays,
    );
  }

  // ============================================================================
  // STATIC UTILITY METHODS
  // ============================================================================

  /// Like [parseMyanmar], but returns null instead of throwing.
  static MyanmarDateTime? tryParseMyanmar(
    String dateString, {
    CalendarConfig? config,
  }) {
    try {
      return MyanmarDateTime.parseMyanmar(dateString, config: config);
    } on DateParseException {
      return null;
    }
  }

  /// Like [parseWestern], but returns null instead of throwing.
  static MyanmarDateTime? tryParseWestern(
    String dateString, {
    CalendarConfig? config,
  }) {
    try {
      return MyanmarDateTime.parseWestern(dateString, config: config);
    } on DateParseException {
      return null;
    }
  }

  // ============================================================================
  // OVERRIDDEN METHODS
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MyanmarDateTime &&
        other._julianDayNumber == _julianDayNumber;
  }

  @override
  int get hashCode => _julianDayNumber.hashCode;

  @override
  String toString() {
    return 'MyanmarDateTime('
        'MY: $myanmarYear/$myanmarMonth/$myanmarDay, '
        'WD: $westernYear-${westernMonth.toString().padLeft(2, '0')}-${westernDay.toString().padLeft(2, '0')} '
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}, '
        'JD: $julianDay'
        ')';
  }

  /// Detailed string representation
  String toDetailedString() {
    return completeDate.toDetailedString();
  }

  /// Compact string representation
  String toCompactString() {
    return completeDate.toCompactString();
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return completeDate.toMap();
  }

  // ==== Shan Calendar =======

  /// Shan date object (cached)
  ///
  /// Converts Myanmar date to Shan calendar using the formula:
  /// Shan Year = Myanmar Year + 733
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.today();
  /// print('Shan Year: ${date.shanYear}'); // e.g., 2120
  /// print('Shan Date: ${date.shanDate.format()}');
  /// ```
  ShanDate get shanDate {
    _shanDate ??= ShanDate.fromMyanmarDate(myanmarDate);
    return _shanDate!;
  }

  /// Shan calendar year
  ///
  /// Example: For Myanmar year 1387, returns 2120
  int get shanYear => shanDate.year;

  /// Shan month name in Shan language
  String get shanMonthName => shanDate.monthName;

  /// Format as Shan date with custom pattern
  ///
  /// Example:
  /// ```dart
  /// final date = MyanmarCalendar.today();
  /// print(date.formatShan()); // "ပီ 2120 လိူၼ်ပူၼ် ဝၼ်း 15"
  /// print(date.formatShan('&sy-&sm-&d')); // "2120-လိူၼ်ပူၼ်-15"
  /// ```
  String formatShan([String? pattern]) {
    return shanDate.format(pattern: pattern ?? 'ပီ &sy &sm ဝၼ်း &d');
  }

  /// Format complete date with Shan calendar included
  ///
  /// Example:
  /// ```dart
  /// final complete = date.formatCompleteWithShan(
  ///   language: Language.shan,
  ///   includeShan: true,
  /// );
  /// // Output: "ပီ 2120 လိူၼ်ပူၼ် ဝၼ်း 15 | ၁၃၈၇ ပြာသို လဆန်း ၁၅ ရက် | 2025-01-15"
  /// ```
  String formatCompleteWithShan({
    String? shanPattern,
    String? myanmarPattern,
    String? westernPattern,
    Language? language,
    bool includeShan = true,
    bool includeMyanmarDate = true,
    bool includeWesternDate = true,
  }) {
    final parts = <String>[];

    // Shan date (show when Shan language or explicitly requested)
    if (includeShan && (language == Language.shan || shanPattern != null)) {
      parts.add(formatShan(shanPattern));
    }

    // Myanmar date
    if (includeMyanmarDate) {
      parts.add(formatMyanmar(myanmarPattern, language));
    }

    // Western date
    if (includeWesternDate) {
      parts.add(formatWestern(westernPattern, language));
    }

    return parts.join(' | ');
  }
}
