/// ------------------------------------------------------------
/// Myanmar Calendar Calculation Core
///
/// Ported from the original Myanmar calendar implementation by Dr Yan Naing Aye.
/// Source: https://github.com/yan9a/mmcal (MIT License)
///
/// Dart conversion and adaptations by: Kyaw Zayar Tun
/// Website: https://github.com/mixin27
///
/// Notes:
/// - The core algorithm originates from the above source.
/// - This implementation is a re-creation in Dart, with
///   modifications and optimizations for Dart package usage.
/// ------------------------------------------------------------
library;

import 'package:myanmar_calendar_dart/src/core/calendar_cache.dart';
import 'package:myanmar_calendar_dart/src/core/calendar_config.dart';
import 'package:myanmar_calendar_dart/src/exceptions/calendar_exceptions.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_year_info.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_constants.dart';
import 'package:myanmar_calendar_dart/src/utils/myanmar_year_constants.dart';
import 'package:myanmar_calendar_dart/src/utils/package_constants.dart';

/// Date converter core
class DateConverter {
  /// Create a new date converter
  DateConverter(
    this._config, {
    required CalendarCache cache,
    String? cacheNamespace,
  }) : _cache = cache,
       _cacheNamespace =
           cacheNamespace ?? 'date_converter|${_config.cacheNamespace}';
  final CalendarConfig _config;
  final CalendarCache _cache;
  final String _cacheNamespace;

  /// Get current calendar config.
  CalendarConfig get config => _config;

  /// Convert JDN to readable date for debugging
  static String jdnToGregorianDate(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;

    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);

    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // WESTERN DATE CONVERSIONS
  // ============================================================================

  /// [dateTime] as wall-clock time in this calendar's time zone.
  ///
  /// A local [DateTime]'s fields already are that wall-clock time. A UTC
  /// [DateTime] is an instant, so it is moved by the configured offset.
  DateTime wallClockOf(DateTime dateTime) {
    if (!dateTime.isUtc) return dateTime;
    return dateTime.add(_offsetDuration);
  }

  /// The UTC Julian Day Number of [dateTime], read as in [wallClockOf].
  double dateTimeToJulian(DateTime dateTime) {
    final wall = wallClockOf(dateTime);
    return westernToJulian(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    );
  }

  /// The UTC Julian Day Number of local noon on the calendar day that
  /// [dateTime] falls on (read as in [wallClockOf]). Myanmar days match
  /// civil days, so the time of day never changes the Myanmar date.
  double dayJulian(DateTime dateTime) {
    final wall = wallClockOf(dateTime);
    return westernToJulian(wall.year, wall.month, wall.day, 12, 0, 0);
  }

  /// The UTC Julian Day Number of local noon on [year]-[month]-[day].
  double civilDayJulian(int year, int month, int day) =>
      westernToJulian(year, month, day, 12, 0, 0);

  /// The instant [julianDayNumber] (UTC) as a UTC [DateTime].
  DateTime julianToUtcDateTime(double julianDayNumber) {
    final wall = julianToWestern(julianDayNumber);
    return DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
    ).subtract(_offsetDuration);
  }

  /// About 9 ms, far below a day yet above double rounding error.
  static const _boundaryEpsilon = 1e-7;

  Duration get _offsetDuration => Duration(
    microseconds: (_config.timezoneOffset * Duration.microsecondsPerHour)
        .round(),
  );

  /// Convert Western date to Julian Day Number
  double westernToJulian(
    int year,
    int month,
    int day, [
    int hour = 12,
    int minute = 0,
    int second = 0,
  ]) {
    _validateWesternDate(year, month, day, hour, minute, second);

    // Try to get from cache
    // final cached = _cache.g(julianDayNumber);
    // if (cached != null) {
    //   return cached;
    // }

    // Calculate if not in cache
    final jd = _calculateWesternToJulian(
      year,
      month,
      day,
      hour,
      minute,
      second,
    );

    // Store in cache
    // _cache.putWesternDate(julianDayNumber, westernDate);

    return jd;
  }

  double _calculateWesternToJulian(
    int year,
    int month,
    int day, [
    int hour = 12,
    int minute = 0,
    int second = 0,
  ]) {
    final calType = _config.calendarType;
    final gregorianStart = _config.gregorianStart.toDouble();

    final a = ((14 - month) / 12).floor();
    final adjustedYear = year + 4800 - a;
    final adjustedMonth = month + 12 * a - 3;

    var jd =
        (day +
                ((153 * adjustedMonth + 2) / 5).floor() +
                365 * adjustedYear +
                (adjustedYear / 4).floor())
            .toDouble();

    if (calType == CalendarConstants.calendarTypeGregorian) {
      jd =
          jd -
          (adjustedYear / 100).floor() +
          (adjustedYear / 400).floor() -
          32045;
    } else if (calType == CalendarConstants.calendarTypeJulian) {
      jd = jd - 32083;
    } else {
      // British calendar (default)
      jd =
          jd -
          (adjustedYear / 100).floor() +
          (adjustedYear / 400).floor() -
          32045;
      if (jd < gregorianStart) {
        jd =
            day +
            ((153 * adjustedMonth + 2) / 5).floor() +
            365 * adjustedYear +
            (adjustedYear / 4).floor() -
            32083;
        if (jd > gregorianStart) jd = gregorianStart;
      }
    }

    // Add time fraction
    final timeFraction = _timeToFraction(hour, minute, second);
    return jd + timeFraction - _config.timezoneOffsetInDays;
  }

  /// Convert Julian Day Number to Western date
  WesternDate julianToWestern(double julianDayNumber) {
    // Try to get from cache
    final cached = _cache.getWesternDate(
      julianDayNumber,
      namespace: _cacheNamespace,
    );
    if (cached != null) {
      return cached;
    }

    // Calculate if not in cache
    // Add timezone offset to convert UTC JDN to Local Time JDN for calculation
    final westernDate = _calculateJulianToWestern(
      julianDayNumber + _config.timezoneOffsetInDays,
    );

    // Store in cache
    _cache.putWesternDate(
      julianDayNumber,
      westernDate,
      namespace: _cacheNamespace,
    );

    return westernDate;
  }

  WesternDate _calculateJulianToWestern(double julianDayNumber) {
    final localJdn = julianDayNumber;
    final calType = _config.calendarType;
    final gregorianStart = _config.gregorianStart.toDouble();

    // Snap to the nearest whole second before splitting date and time, so a
    // value a hair under 02:30:00 doesn't come out as 02:29:60, nor a hair
    // under midnight as the previous day.
    final totalSeconds = ((localJdn + 0.5) * 86400).round();
    final dayNumber = totalSeconds ~/ 86400;
    final secondOfDay = totalSeconds - dayNumber * 86400;

    double j;
    double y;
    double m;
    double d;

    if (calType == CalendarConstants.calendarTypeJulian ||
        (calType == CalendarConstants.calendarTypeBritish &&
            localJdn < gregorianStart)) {
      // Julian Calendar
      final b = dayNumber + 1524;
      final c = ((b - 122.1) / 365.25).floor();
      final f = (365.25 * c).floor();
      final e = ((b - f) / 30.6001).floor();

      m = e > 13 ? e - 13 : e - 1;
      d = b - f - (30.6001 * e).floorToDouble();
      y = m < 3 ? c - 4715 : c - 4716;
    } else {
      // Gregorian Calendar
      j = dayNumber.toDouble();

      j -= 1721119;
      y = ((4 * j - 1) / 146097).floorToDouble();
      j = 4 * j - 1 - 146097 * y;
      d = (j / 4).floorToDouble();

      j = ((4 * d + 3) / 1461).floorToDouble();
      d = 4 * d + 3 - 1461 * j;
      d = ((d + 4) / 4).floorToDouble();

      m = ((5 * d - 3) / 153).floorToDouble();
      d = 5 * d - 3 - 153 * m;
      d = ((d + 5) / 5).floorToDouble();

      y = 100 * y + j;
      if (m < 10) {
        m += 3;
      } else {
        m -= 9;
        y += 1;
      }
    }

    // Extract time components
    final h = secondOfDay ~/ 3600;
    final n = (secondOfDay % 3600) ~/ 60;
    final s = secondOfDay % 60;

    final weekday = (dayNumber + 2) % 7;

    return WesternDate(
      year: y.toInt(),
      month: m.toInt(),
      day: d.toInt(),
      hour: h,
      minute: n,
      second: s,
      weekday: weekday,
      julianDayNumber: localJdn,
    );
  }

  // ============================================================================
  // MYANMAR DATE CONVERSIONS
  // ============================================================================

  /// Convert Myanmar date to Julian Day Number
  double myanmarToJulian(
    int year,
    int month,
    int day, [
    int hour = 12,
    int minute = 0,
    int second = 0,
  ]) {
    _validateMyanmarDate(year, month, day);

    // Get Myanmar year info
    final yearInfo = _getMyanmarYearInfo(year);

    // Calculate month type (0=normal, 1=watat)
    final monthType = month ~/ 13;
    final normalizedMonth = month % 13 + monthType;

    // Year type adjustments
    final b = (yearInfo['myt']! / 2).floor(); // Big watat adjustment
    final c = (yearInfo['myt'] == 0) ? 1 : 0; // Common year adjustment

    // Calculate month length
    var monthLength = 30 - normalizedMonth % 2;
    if (normalizedMonth == 3) monthLength += b; // Nayon in big watat

    // Dates the calendar doesn't have used to slide onto a neighbour (day 30
    // of a 29-day month became day 29; First Waso in a common year became
    // Waso), so a typo produced a real but different day.
    if (day > monthLength) {
      throw InvalidMyanmarDateException(
        year: year,
        month: month,
        day: day,
        customMessage:
            'Myanmar month $month of $year has $monthLength days, not $day',
      );
    }
    if (month == 0 && yearInfo['myt'] == 0) {
      throw InvalidMyanmarDateException(
        year: year,
        month: month,
        day: day,
        customMessage:
            'First Waso (month 0) only exists in watat years; $year is common',
      );
    }

    // Calculate moon phase for validation
    final moonPhase =
        ((day + 1) / 16).floor() +
        (day / 16).floor() +
        (day / monthLength).floor();
    final fortnightDay = day - 15 * (day ~/ 16);

    // Use the proven conversion formula
    final m1 = moonPhase % 2;
    final m2 = (moonPhase / 2).floor();

    final md =
        m1 * (15 + m2 * (monthLength - 15)) +
        (1 - m1) * (fortnightDay + 15 * m2);

    final adjustedMonth =
        normalizedMonth +
        4 -
        ((normalizedMonth + 15) / 16).floor() * 4 +
        ((normalizedMonth + 12) / 16).floor();

    var dd =
        (md +
                (29.544 * adjustedMonth - 29.26).floor() -
                c * ((adjustedMonth + 11) / 16).floor() * 30 +
                b * ((adjustedMonth + 12) / 16).floor())
            .toDouble();

    dd += monthType * (354 + (1 - c) * 30 + b);

    final jd = dd + yearInfo['tg1']! - 1;

    // Add time fraction
    final timeFraction = _timeToFraction(hour, minute, second);
    return jd + timeFraction - _config.timezoneOffsetInDays;
  }

  /// Convert Julian Day Number to Myanmar date
  MyanmarDate julianToMyanmar(double julianDayNumber) {
    // Try to get from cache
    final cached = _cache.getMyanmarDate(
      julianDayNumber,
      namespace: _cacheNamespace,
    );
    if (cached != null) {
      return cached;
    }

    // Calculate if not in cache
    // Add timezone offset to convert UTC JDN to Local Time JDN for calculation
    // A hair past the offset keeps exact local midnight on its own day
    // when subtracting and adding the offset leaves a rounding error.
    final myanmarDate = _calculateJulianToMyanmar(
      julianDayNumber + _config.timezoneOffsetInDays + _boundaryEpsilon,
    );

    // Store in cache
    _cache.putMyanmarDate(
      julianDayNumber,
      myanmarDate,
      namespace: _cacheNamespace,
    );

    return myanmarDate;
  }

  /// The Myanmar date of the local day number [localDay], such as a
  /// [MyanmarDate.julianDayNumber] (local noon), without applying the
  /// time-zone offset again.
  MyanmarDate myanmarForLocalDay(double localDay) =>
      julianToMyanmar(localDay.roundToDouble() - _config.timezoneOffsetInDays);

  MyanmarDate _calculateJulianToMyanmar(double julianDayNumber) {
    final jdn = julianDayNumber.round();

    // Calculate Myanmar year
    final myYear =
        ((jdn - 0.5 - CalendarConstants.myanmarEpoch) /
                CalendarConstants.solarYear)
            .floor();

    final yearInfo = _getMyanmarYearInfo(myYear);
    var dayCount = (jdn - yearInfo['tg1']!).toInt() + 1;

    // Year adjustments
    final b = (yearInfo['myt']! / 2).floor();
    final c = (1 / (yearInfo['myt']! + 1)).floor();
    final yearLength = 354 + (1 - c) * 30 + b;

    final monthType = (dayCount - 1) ~/ yearLength;
    dayCount -= monthType * yearLength;

    final a = ((dayCount + 423) / 512).floor();

    // Month calculation
    var mmonth = ((dayCount - b * a + c * a * 30 + 29.26) / 29.544).floor();
    final e = ((mmonth + 12) / 16).floor();
    final f = ((mmonth + 11) / 16).floor();

    final monthDay =
        dayCount - (29.544 * mmonth - 29.26).floor() - b * e + c * f * 30;
    mmonth += f * 3 - e * 4;

    // Month length calculation
    var monthLength = 30 - mmonth % 2;
    if (mmonth == 3) monthLength += (yearInfo['myt']! / 2).toInt();

    // Moon phase calculation
    final moonPhase =
        ((monthDay + 1) / 16).floor() +
        (monthDay / 16).floor() +
        (monthDay / monthLength).floor();

    final fortnightDay = monthDay - 15 * (monthDay ~/ 16);
    final weekDay = (jdn + 2) % 7;

    final fullMonth = mmonth + 12 * monthType;

    // Calculate Sasana year using full month numbering (includes late months).
    final sasanaYear = _calculateSasanaYear(myYear, fullMonth, monthDay);

    return MyanmarDate(
      year: myYear,
      month: fullMonth,
      day: monthDay,
      yearType: yearInfo['myt']!.toInt(),
      moonPhase: moonPhase,
      fortnightDay: fortnightDay,
      weekday: weekDay,
      // The day itself (local noon), not the time it was asked for.
      julianDayNumber: jdn.toDouble(),
      sasanaYear: sasanaYear,
      monthLength: monthLength,
      monthType: monthType,
    );
  }

  // ============================================================================
  // MYANMAR YEAR CALCULATIONS
  // ============================================================================

  /// Get Myanmar year information
  /// Year info depends only on the year, so it's computed once per year
  /// for the whole process. A month grid used to recompute it for every day.
  static final _yearInfoMemo = <int, Map<String, double>>{};

  Map<String, double> _getMyanmarYearInfo(int myear) =>
      _yearInfoMemo[myear] ??= Map.unmodifiable(_computeMyanmarYearInfo(myear));

  Map<String, double> _computeMyanmarYearInfo(int myear) {
    var offset = 0;
    Map<String, double> prevYearInfo;
    double nd = 0;
    double werr = 0;
    double fm = 0;

    final currentYear = _checkWatat(myear);
    var myt = currentYear['watat']!;

    do {
      offset++;
      prevYearInfo = _checkWatat(myear - offset);
    } while (prevYearInfo['watat'] == 0 && offset < 3);

    if (myt > 0) {
      nd = (currentYear['fm']! - prevYearInfo['fm']!) % 354;
      myt = (nd / 31).floorToDouble() + 1;
      fm = currentYear['fm']!;
      if (nd != 30 && nd != 31) werr = 1;
    } else {
      fm = prevYearInfo['fm']! + 354 * offset;
    }

    final tg1 = prevYearInfo['fm']! + 354 * offset - 102;

    return {'myt': myt, 'tg1': tg1, 'fm': fm, 'werr': werr};
  }

  /// Check watat (intercalary month) using the exact proven algorithm
  Map<String, double> _checkWatat(int myear) {
    // Find the appropriate era for this year
    final era = MyanmarYearConstants.getMyConst(myear);

    final nm = era['NM']!;
    final wo = era['WO']!;

    final ta =
        (CalendarConstants.solarYear / 12 - CalendarConstants.lunarMonth) *
        (12 - nm);
    var ed =
        (CalendarConstants.solarYear * (myear + 3739)) %
        CalendarConstants.lunarMonth;
    if (ed < ta) ed += CalendarConstants.lunarMonth;

    final fm =
        (CalendarConstants.solarYear * myear +
                CalendarConstants.myanmarEpoch -
                ed +
                4.5 * CalendarConstants.lunarMonth +
                wo)
            .round()
            .toDouble();
    var watat = 0;

    if (era['EI']! >= 2) {
      final tw =
          CalendarConstants.lunarMonth -
          (CalendarConstants.solarYear / 12 - CalendarConstants.lunarMonth) *
              nm;
      if (ed >= tw) watat = 1;
    } else {
      watat = (myear * 7 + 2) % 19;
      if (watat < 0) watat += 19;
      watat = (watat / 12).floor();
    }

    // Apply watat exceptions from era data
    watat ^= era['EW']!.toInt();

    return {'fm': fm, 'watat': watat.toDouble()};
  }

  // ============================================================================
  // LUNAR CALCULATIONS
  // ============================================================================

  /// Calculate moon phase
  int _calculateMoonPhase(int day, int month, int yearType) {
    final monthLength = _getMonthLength(month, yearType);
    return ((day + 1) / 16).floor() +
        (day / 16).floor() +
        (day / monthLength).floor();
  }

  /// Calculate fortnight day
  int _calculateFortnightDay(int day) {
    return day - 15 * (day ~/ 16);
  }

  /// Get month length
  int _getMonthLength(int month, int yearType) {
    var length = 30 - month % 2;
    if (month == 3) length += yearType ~/ 2; // Nayon in big watat
    return length;
  }

  /// Calculate Sasana year
  int _calculateSasanaYear(int myanmarYear, int month, int day) {
    var offset = CalendarConstants.buddhistEraOffset;

    switch (_config.sasanaYearType) {
      case 1:
        if (month >= 13) offset = CalendarConstants.buddhistEraOffset + 1;
        break;
      case 2:
        if (month == 1 || (month == 2 && day < 15)) {
          offset = CalendarConstants.buddhistEraOffset - 1;
        }
        break;
      default:
        break;
    }

    return myanmarYear + offset;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Convert time to fraction of day (noon-based)
  double _timeToFraction(int hour, int minute, int second) {
    return (hour - 12) / 24.0 + minute / 1440.0 + second / 86400.0;
  }

  /// Validate Western date
  void _validateWesternDate(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) {
    Never invalid(String message) => throw InvalidWesternDateException(
      year: year,
      month: month,
      day: day,
      customMessage: message,
    );
    if (year < 1 || year > 9999) invalid('Invalid Western year: $year');
    if (month < 1 || month > 12) invalid('Invalid Western month: $month');
    final maxDay = _getDaysInWesternMonth(year, month);
    if (day < 1 || day > maxDay) {
      invalid('Invalid Western day: $day for year $year month $month');
    }
    if (hour < 0 || hour > 23) invalid('Invalid hour: $hour');
    if (minute < 0 || minute > 59) invalid('Invalid minute: $minute');
    if (second < 0 || second > 59) invalid('Invalid second: $second');
  }

  int _getDaysInWesternMonth(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        return _isWesternLeapYear(year) ? 29 : 28;
      default:
        return 0;
    }
  }

  bool _isWesternLeapYear(int year) {
    // The British calendar is Julian until September 1752, so 1700 had a
    // 29 February.
    final julian =
        _config.calendarType == CalendarConstants.calendarTypeJulian ||
        (_config.calendarType == CalendarConstants.calendarTypeBritish &&
            year < 1753);
    if (julian) return year % 4 == 0;
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Validate Myanmar date
  void _validateMyanmarDate(int year, int month, int day) {
    String? problem;
    if (year < PackageConstants.minMyanmarYear ||
        year > PackageConstants.maxMyanmarYear) {
      problem =
          'Myanmar year must be between ${PackageConstants.minMyanmarYear} '
          'and ${PackageConstants.maxMyanmarYear}';
    } else if (month < PackageConstants.minMyanmarMonth ||
        month > PackageConstants.maxMyanmarMonth) {
      problem =
          'Myanmar month must be between ${PackageConstants.minMyanmarMonth} '
          'and ${PackageConstants.maxMyanmarMonth}';
    } else if (day < PackageConstants.minMyanmarDay ||
        day > PackageConstants.maxMyanmarDay) {
      problem =
          'Myanmar day must be between ${PackageConstants.minMyanmarDay} '
          'and ${PackageConstants.maxMyanmarDay}';
    }
    if (problem != null) {
      throw InvalidMyanmarDateException(
        year: year,
        month: month,
        day: day,
        customMessage: problem,
      );
    }
  }

  // ============================================================================
  // PUBLIC HELPER METHODS
  // ============================================================================

  /// Calculate year type for a given Myanmar year
  int calculateYearType(int myanmarYear) {
    final yearInfo = _getMyanmarYearInfo(myanmarYear);
    return yearInfo['myt']!.toInt();
  }

  /// Check if a Myanmar year is a watat year
  bool isWatatYear(int myanmarYear) {
    return calculateYearType(myanmarYear) > 0;
  }

  /// Get month length for a specific month and year type
  int getMonthLength(int month, int yearType) {
    return _getMonthLength(month, yearType);
  }

  /// Calculate moon phase for any Myanmar date
  int calculateMoonPhase(int day, int month, int yearType) {
    return _calculateMoonPhase(day, month, yearType);
  }

  /// Calculate fortnight day for any Myanmar day
  int calculateFortnightDay(int day) {
    return _calculateFortnightDay(day);
  }

  /// Get the Julian Day Number for the first day of a Myanmar year
  double getYearStartJdn(int myanmarYear) {
    final yearInfo = _getMyanmarYearInfo(myanmarYear);
    return yearInfo['tg1']!;
  }

  /// Get complete typed year information.
  MyanmarYearInfo getMyanmarYearInfo(int myanmarYear) {
    final yearInfo = _getMyanmarYearInfo(myanmarYear);

    return MyanmarYearInfo(
      year: myanmarYear,
      yearType: yearInfo['myt']!.toInt(),
      isWatat: yearInfo['myt']! > 0,
      firstDayJdn: yearInfo['tg1']!.toInt(),
      fullMoonJdn: yearInfo['fm']!.toInt(),
    );
  }
}
