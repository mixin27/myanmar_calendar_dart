/// ------------------------------------------------------------
/// Translation service.
///
/// Ported from the original Myanmar calendar implementation by Dr Yan Naing Aye.
/// Source: https://github.com/yan9a/mmcal (MIT License)
///
/// Dart conversion and adaptations by: Kyaw Zayar Tun
/// Website: https://github.com/mixin27
///
/// Notes:
/// - Most of translations originate from the above source.
/// - This implementation is a re-creation in Dart, with
///   modifications and optimizations for Dart package usage.
/// ------------------------------------------------------------
library;

import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/localization/translation_data.dart';

/// Service for translating text between different languages
class TranslationService {
  static const Language _defaultLanguage = Language.english;

  /// Translate a key to a specific language
  static String translateTo(String key, Language language) {
    return _translations[key]?[language] ?? key;
  }

  /// Get all available translations for a key
  static Map<Language, String>? getTranslations(String key) {
    return _translations[key];
  }

  /// Check if a translation exists for a key
  static bool hasTranslation(String key, [Language? language]) {
    language ??= _defaultLanguage;
    return _translations[key]?.containsKey(language) ?? false;
  }

  /// Add or update a translation
  static void addTranslation(
    String key,
    Language language,
    String translation,
  ) {
    _translations[key] ??= {};
    _translations[key]![language] = translation;
  }

  /// Remove a translation
  static void removeTranslation(String key, [Language? language]) {
    if (language == null) {
      _translations.remove(key);
    } else {
      _translations[key]?.remove(language);
    }
  }

  /// Get all translation keys
  static List<String> get allKeys => _translations.keys.toList();

  /// Get month name by index (0-14)
  static String getMonthName(
    int monthIndex,
    int yearType, [
    Language? language,
  ]) {
    language ??= _defaultLanguage;

    const months = [
      'First Waso', // 0
      'Tagu', // 1
      'Kason', // 2
      'Nayon', // 3
      'Waso', // 4
      'Wagaung', // 5
      'Tawthalin', // 6
      'Thadingyut', // 7
      'Tazaungmon', // 8
      'Nadaw', // 9
      'Pyatho', // 10
      'Tabodwe', // 11
      'Tabaung', // 12
      'Late Tagu', // 13
      'Late Kason', // 14
    ];

    if (monthIndex >= 0 && monthIndex < months.length) {
      var monthName = TranslationService.translateTo(
        months[monthIndex],
        language,
      );

      // // Handle special cases for watat years
      if (monthIndex == 4 && yearType > 0) {
        monthName =
            '${TranslationService.translateTo('Second', language)} $monthName';
      }

      return monthName;
    }
    return monthIndex.toString();
  }

  /// Get western month name by month number (1-12)
  static String getWesternMonthName(int monthIndex, [Language? language]) {
    language ??= _defaultLanguage;
    const months = [
      '', // 0 placeholder
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (monthIndex >= 1 && monthIndex < months.length) {
      return translateTo(months[monthIndex], language);
    }
    return monthIndex.toString();
  }

  /// Get short western month name by month number (1-12)
  static String getShortWesternMonthName(int monthIndex, [Language? language]) {
    language ??= _defaultLanguage;
    const months = [
      '', // 0 placeholder
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (monthIndex >= 1 && monthIndex < months.length) {
      return translateTo(months[monthIndex], language);
    }
    return monthIndex.toString();
  }

  /// Get weekday name by index (0-6)
  static String getWeekdayName(int weekdayIndex, [Language? language]) {
    language ??= _defaultLanguage;
    const weekdays = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    if (weekdayIndex >= 0 && weekdayIndex < weekdays.length) {
      return translateTo(weekdays[weekdayIndex], language);
    }
    return weekdayIndex.toString();
  }

  /// Get short weekday name by index (0-6)
  static String getShortWeekdayName(int weekdayIndex, [Language? language]) {
    language ??= _defaultLanguage;
    const weekdays = ['wSat', 'wSun', 'wMon', 'wTue', 'wWed', 'wThu', 'wFri'];

    if (weekdayIndex >= 0 && weekdayIndex < weekdays.length) {
      return translateTo(weekdays[weekdayIndex], language);
    }
    return weekdayIndex.toString();
  }

  /// Get moon phase name by index (0-3)
  static String getMoonPhaseName(int phaseIndex, [Language? language]) {
    language ??= _defaultLanguage;
    const phases = ['Waxing', 'Full Moon', 'Waning', 'New Moon'];

    if (phaseIndex >= 0 && phaseIndex < phases.length) {
      return translateTo(phases[phaseIndex], language);
    }
    return phaseIndex.toString();
  }

  /// Get year type name by index (0-2)
  static String getYearTypeName(int yearTypeIndex, [Language? language]) {
    language ??= _defaultLanguage;
    const yearTypes = ['Common Year', 'Little Watat', 'Big Watat'];

    if (yearTypeIndex >= 0 && yearTypeIndex < yearTypes.length) {
      return translateTo(yearTypes[yearTypeIndex], language);
    }
    return yearTypeIndex.toString();
  }

  /// Get localized AM/PM label.
  static String getMeridiem({
    required bool isAm,
    bool lowercase = false,
    Language? language,
  }) {
    language ??= _defaultLanguage;
    final key = isAm ? (lowercase ? 'am' : 'AM') : (lowercase ? 'pm' : 'PM');
    return translateTo(key, language);
  }

  /// Whether numeric glyph translation is needed for [language].
  static bool shouldTranslateDigits([Language? language]) {
    language ??= _defaultLanguage;
    for (var i = 0; i <= 9; i++) {
      final digit = i.toString();
      if (translateTo(digit, language) != digit) {
        return true;
      }
    }
    return false;
  }

  static final Map<String, Map<Language, String>> _translations =
      _createMutableTranslations();

  static Map<String, Map<Language, String>> _createMutableTranslations() {
    return {
      for (final entry in kTranslationData.entries)
        entry.key: _normalizeLanguageMap(
          key: entry.key,
          source: entry.value,
        ),
    };
  }

  static Map<Language, String> _normalizeLanguageMap({
    required String key,
    required Map<Language, String> source,
  }) {
    final fallback = source[Language.english]?.trim();
    final fallbackText = (fallback == null || fallback.isEmpty)
        ? key
        : fallback;
    final normalized = <Language, String>{};

    for (final language in Language.values) {
      final value = source[language]?.trim();
      normalized[language] = (value == null || value.isEmpty)
          ? fallbackText
          : value;
    }

    return normalized;
  }
}
