import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/localization/translation_service.dart';
import 'package:myanmar_calendar_dart/src/models/astro_info.dart';
import 'package:myanmar_calendar_dart/src/models/complete_date.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';

/// Service for formatting dates and providing string representations
class FormatService {
  /// Format Myanmar date according to pattern and language
  ///
  /// Pattern placeholders:
  /// - `&yyyy` : Myanmar year [0000-9999, e.g. 1380]
  /// - `&y` : Myanmar year [0-9999, e.g. 138]
  /// - `&YYYY` : Sasana year [0000-9999, e.g. 2562]
  /// - `&mm` : month with zero padding [01-14]
  /// - `&M` : month name [e.g. Tagu]
  /// - `&m` : month [1-14]
  /// - `&P` : moon phase [e.g. Waxing, Full Moon]
  /// - `&dd` : day with zero padding [01-31]
  /// - `&d` : day [1-31]
  /// - `&ff` : fortnight day with zero padding [01-15]
  /// - `&f` : fortnight day [1-15]
  /// - `&W` : weekday name [e.g. Monday]
  /// - `&w` : weekday number [0-6]
  /// - `&YT` : year type [e.g. Common Year, Little Watat]
  /// - `&N` : year name [e.g. Hpusha, Magha]
  /// - `&Nay` : localized "Nay/Day" word
  /// - `&Yat` : localized "Yat/Date-Day" word
  /// - `&Sy` : year name [e.g. Sasana Year]
  String formatMyanmarDate(
    MyanmarDate date, {
    String? pattern,
    Language? language,
  }) {
    final currentLang = language ?? TranslationService.currentLanguage;
    final format = pattern ?? '&y &M &P &ff';
    var result = format;

    // Myanmar year with zero padding
    result = result.replaceAll('&yyyy', date.year.toString().padLeft(4, '0'));

    // Myanmar year
    result = result.replaceAll('&y', date.year.toString());

    // Sasana year with zero padding
    result = result.replaceAll(
      '&YYYY',
      date.sasanaYear.toString().padLeft(4, '0'),
    );

    // Month with zero padding
    result = result.replaceAll('&mm', date.month.toString().padLeft(2, '0'));

    // Month name
    result = result.replaceAll(
      '&M',
      getMonthName(date.month, date.yearType, language: currentLang),
    );

    // Month number
    result = result.replaceAll('&m', date.month.toString());

    // Moon phase
    result = result.replaceAll(
      '&P',
      _getMoonPhaseName(date.moonPhase, currentLang),
    );

    // Day with zero padding
    result = result.replaceAll('&dd', date.day.toString().padLeft(2, '0'));

    // Day
    result = result.replaceAll('&d', date.day.toString());

    // Fortnight day with zero padding
    result = result.replaceAll(
      '&ff',
      date.fortnightDay.toString().padLeft(2, '0'),
    );

    // Fortnight day
    result = result.replaceAll('&f', date.fortnightDay.toString());

    // Weekday name
    result = result.replaceAll(
      '&W',
      _getWeekdayName(date.weekday, currentLang),
    );

    // Weekday number
    result = result.replaceAll('&w', date.weekday.toString());

    // Year type
    result = result.replaceAll(
      '&YT',
      _getYearTypeName(date.yearType, currentLang),
    );

    // Day words (replace longer token before &N to avoid collision)
    result = result.replaceAll(
      '&Nay',
      TranslationService.translateTo('Nay', currentLang),
    );
    result = result.replaceAll(
      '&Yat',
      TranslationService.translateTo('Yat', currentLang),
    );

    // Year name (12-year cycle)
    result = result.replaceAll('&N', _getYearName(date.year, currentLang));

    // Sasana Year
    result = result.replaceAll('&Sy', date.sasanaYear.toString());

    return translateNumbers(result, language: currentLang);
  }

  /// Format Western date according to pattern and language
  ///
  /// Pattern placeholders:
  /// - `%yyyy` : year [0000-9999, e.g. 2018]
  /// - `%yy` : year [00-99 e.g. 18]
  /// - `%y` : year [0-9999, e.g. 201]
  /// - `%MMM` : month [e.g. JAN]
  /// - `%Mmm` : month [e.g. Jan]
  /// - `%mm` : month with zero padding [01-12]
  /// - `%M` : month [e.g. January]
  /// - `%m` : month [1-12]
  /// - `%dd` : day with zero padding [01-31]
  /// - `%d` : day [1-31]
  /// - `%HH` : hour [00-23]
  /// - `%hh` : hour [01-12]
  /// - `%H` : hour [0-23]
  /// - `%h` : hour [1-12]
  /// - `%AA` : AM or PM
  /// - `%aa` : am or pm
  /// - `%nn` : minute with zero padding [00-59]
  /// - `%n` : minute [0-59]
  /// - `%ss` : second [00-59]
  /// - `%s` : second [0-59]
  /// - `%WWW` : Weekday [e.g. SAT]
  /// - `%Www` : Weekday [e.g. Sat]
  /// - `%W` : Weekday [e.g. Saturday]
  /// - `%w` : Weekday number [0=sat, 1=sun, ..., 6=fri]
  String formatWesternDate(
    WesternDate date, {
    String? pattern,
    Language? language,
  }) {
    final currentLang = language ?? TranslationService.currentLanguage;
    final format = pattern ?? '%Www %y-%mm-%dd %HH:%nn:%ss';
    var result = format;
    final shortMonthName = _getShortWesternMonthName(date.month, currentLang);

    // Year with zero padding
    result = result.replaceAll('%yyyy', date.year.toString().padLeft(4, '0'));

    // Year (2 digits)
    final year2 = date.year % 100;
    result = result.replaceAll('%yy', year2.toString().padLeft(2, '0'));

    // Year
    result = result.replaceAll('%y', date.year.toString());

    // Month (abbreviated, uppercase)
    result = result.replaceAll('%MMM', shortMonthName.toUpperCase());

    // Month (abbreviated)
    result = result.replaceAll('%Mmm', shortMonthName);

    // Month with zero padding
    result = result.replaceAll('%mm', date.month.toString().padLeft(2, '0'));

    // Month name
    result = result.replaceAll(
      '%M',
      _getWesternMonthName(date.month, currentLang),
    );

    // Month number
    result = result.replaceAll('%m', date.month.toString());

    // Day with zero padding
    result = result.replaceAll('%dd', date.day.toString().padLeft(2, '0'));

    // Day
    result = result.replaceAll('%d', date.day.toString());

    // Hour (24-hour with zero padding)
    result = result.replaceAll('%HH', date.hour.toString().padLeft(2, '0'));

    // Hour (24-hour)
    result = result.replaceAll('%H', date.hour.toString());

    // Hour (12-hour with zero padding)
    final hour12 = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    result = result.replaceAll('%hh', hour12.toString().padLeft(2, '0'));

    // Hour (12-hour)
    result = result.replaceAll('%h', hour12.toString());

    // AM/PM (uppercase)
    result = result.replaceAll(
      '%AA',
      TranslationService.getMeridiem(
        isAm: date.hour < 12,
        language: currentLang,
      ),
    );

    // am/pm (lowercase)
    result = result.replaceAll(
      '%aa',
      TranslationService.getMeridiem(
        isAm: date.hour < 12,
        lowercase: true,
        language: currentLang,
      ),
    );

    // Minute with zero padding
    result = result.replaceAll('%nn', date.minute.toString().padLeft(2, '0'));

    // Minute
    result = result.replaceAll('%n', date.minute.toString());

    // Second with zero padding
    result = result.replaceAll('%ss', date.second.toString().padLeft(2, '0'));

    // Second
    result = result.replaceAll('%s', date.second.toString());

    // Weekday (abbreviated, uppercase)
    result = result.replaceAll(
      '%WWW',
      _getShortWeekdayName(date.weekday, currentLang).toUpperCase(),
    );

    // Weekday (abbreviated)
    result = result.replaceAll(
      '%Www',
      _getShortWeekdayName(date.weekday, currentLang),
    );

    // Weekday name
    result = result.replaceAll(
      '%W',
      _getWeekdayName(date.weekday, currentLang),
    );

    // Weekday number
    result = result.replaceAll('%w', date.weekday.toString());

    return translateNumbers(result, language: currentLang);
  }

  /// Get localized month name
  String getMonthName(
    int monthIndex,
    int yearType, {
    Language? language,
  }) {
    return TranslationService.getMonthName(monthIndex, yearType, language);
  }

  /// Get localized moon phase name
  String _getMoonPhaseName(int phaseIndex, Language language) {
    return TranslationService.getMoonPhaseName(phaseIndex, language);
  }

  /// Get localized weekday name
  String _getWeekdayName(int weekdayIndex, Language language) {
    return TranslationService.getWeekdayName(weekdayIndex, language);
  }

  String _getShortWeekdayName(int weekdayIndex, Language language) {
    return TranslationService.getShortWeekdayName(weekdayIndex, language);
  }

  /// Get localized year type name
  String _getYearTypeName(int yearTypeIndex, Language language) {
    return TranslationService.getYearTypeName(yearTypeIndex, language);
  }

  /// Get localized year name from 12-year cycle
  String _getYearName(int year, Language language) {
    const yearNames = [
      'Hpusha', // 0
      'Magha', // 1
      'Phalguni', // 2
      'Chitra', // 3
      'Visakha', // 4
      'Jyeshtha', // 5
      'Ashadha', // 6
      'Sravana', // 7
      'Bhadrapaha', // 8
      'Asvini', // 9
      'Krittika', // 10
      'Mrigasiras', // 11
    ];

    final index = year % 12;
    return TranslationService.translateTo(yearNames[index], language);
  }

  /// Get localized Western month name
  String _getWesternMonthName(int monthIndex, Language language) {
    return TranslationService.getWesternMonthName(monthIndex, language);
  }

  String _getShortWesternMonthName(int monthIndex, Language language) {
    return TranslationService.getShortWesternMonthName(monthIndex, language);
  }

  /// Translate numbers to the current language
  String translateNumbers(String text, {Language? language}) {
    final currentLang = language ?? TranslationService.currentLanguage;

    if (!TranslationService.shouldTranslateDigits(currentLang)) return text;

    var result = text;
    for (var i = 0; i <= 9; i++) {
      result = result.replaceAll(
        i.toString(),
        TranslationService.translateTo(i.toString(), currentLang),
      );
    }
    return result;
  }

  /// Format astro information
  String formatAstroInfo(AstroInfo astro, {Language? language}) {
    final currentLang = language ?? TranslationService.currentLanguage;

    final tokens = <String>[
      if (astro.sabbath.isNotEmpty) astro.sabbath,
      if (astro.yatyaza.isNotEmpty) astro.yatyaza,
      if (astro.pyathada.isNotEmpty) astro.pyathada,
      ...astro.astrologicalDays.where((day) => day.isNotEmpty),
    ];

    if (tokens.isEmpty) return '';

    return tokens
        .map((token) => TranslationService.translateTo(token, currentLang))
        .join(', ');
  }

  /// Format holiday information
  String formatHolidayInfo(HolidayInfo holidays, {Language? language}) {
    final currentLang = language ?? TranslationService.currentLanguage;
    final allHolidays = holidays.allHolidays;
    if (allHolidays.isEmpty) return '';

    return allHolidays
        .map((holiday) => TranslationService.translateTo(holiday, currentLang))
        .join(', ');
  }

  /// Format complete date information
  String formatCompleteDate(
    CompleteDate completeDate, {
    String? myanmarPattern,
    String? westernPattern,
    Language? language,
    bool includeAstro = false,
    bool includeHolidays = false,
  }) {
    final buffer = StringBuffer()
      // Myanmar date
      ..write(
        formatMyanmarDate(
          completeDate.myanmar,
          pattern: myanmarPattern,
          language: language,
        ),
      )
      // Western date
      ..write(' (')
      ..write(
        formatWesternDate(
          completeDate.western,
          pattern: westernPattern,
          language: language,
        ),
      )
      ..write(')');

    // Astro information
    if (includeAstro) {
      final astroText = formatAstroInfo(completeDate.astro, language: language);
      if (astroText.isNotEmpty) {
        buffer
          ..write(' - ')
          ..write(astroText);
      }
    }

    // Holiday information
    if (includeHolidays) {
      final holidayText = formatHolidayInfo(
        completeDate.holidays,
        language: language,
      );
      if (holidayText.isNotEmpty) {
        buffer
          ..write(' [')
          ..write(holidayText)
          ..write(']');
      }
    }

    return buffer.toString();
  }
}
