/// ------------------------------------------------------------
/// Holiday Calculation Core
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
import 'package:myanmar_calendar_dart/src/localization/translation_service.dart';
import 'package:myanmar_calendar_dart/src/models/custom_holiday.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_id.dart';
import 'package:myanmar_calendar_dart/src/models/holiday_info.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_constants.dart';

/// Service for calculating holidays in the Myanmar calendar system
class HolidayCalculator {
  /// Create a new [HolidayCalculator] instance
  HolidayCalculator({
    required CalendarCache cache,
    CalendarConfig config = const CalendarConfig(),
  }) : _cache = cache,
       _config = config,
       _cacheNamespace = 'holiday_info|${config.cacheNamespace}';
  late final CalendarCache _cache;
  final CalendarConfig _config;
  final String _cacheNamespace;

  /// Get all holidays for a Myanmar date
  HolidayInfo getHolidays(
    MyanmarDate date, {
    List<CustomHoliday> customHolidays = const [],
  }) {
    final key = _generateCacheKey(date, customHolidays);

    // Try to get from cache
    final cached = _cache.getHolidayInfoByKey(
      key,
      namespace: _cacheNamespace,
    );
    if (cached != null) {
      return cached;
    }

    // Calculate if not in cache
    final holidayInfo = _calculateHolidays(date, customHolidays);

    // Store in cache
    _cache.putHolidayInfoByKey(
      key,
      holidayInfo,
      namespace: _cacheNamespace,
    );

    return holidayInfo;
  }

  String _generateCacheKey(
    MyanmarDate date,
    List<CustomHoliday> customHolidays,
  ) {
    final dateKey = '${date.year}-${date.month}-${date.day}';

    // Include disabled holidays in cache key
    final disabledHolidaysKey =
        _config.disabledHolidays.map((e) => e.name).toList()..sort();

    // Include year-specific disabled holidays (only for the current year)
    final westernDate = _jdnToWestern(date.julianDayNumber);
    final westernYear = westernDate['year']!;
    final westernMonth = westernDate['month']!;
    final westernDay = westernDate['day']!;

    final yearSpecificDisabled =
        _config.disabledHolidaysByYear[westernYear]
                  ?.map((e) => e.name)
                  .toList() ??
              []
          ..sort();

    // Include date-specific disabled holidays
    final dateSpecificKey =
        '$westernYear-${westernMonth.toString().padLeft(2, '0')}-${westernDay.toString().padLeft(2, '0')}';
    final dateSpecificDisabled =
        _config.disabledHolidaysByDate[dateSpecificKey]
                  ?.map((e) => e.name)
                  .toList() ??
              []
          ..sort();

    final customHolidayFingerprints = customHolidays.map((holiday) {
      return '${holiday.id}:${holiday.name}:${holiday.type.index}:${identityHashCode(holiday.predicate)}';
    }).toList()..sort();

    return '$dateKey|lang:${TranslationService.currentLanguage.code}|${disabledHolidaysKey.join(',')}|${yearSpecificDisabled.join(',')}|${dateSpecificDisabled.join(',')}|${customHolidayFingerprints.join(',')}';
  }

  HolidayInfo _calculateHolidays(
    MyanmarDate date,
    List<CustomHoliday> customHolidays,
  ) {
    final publicHolidays = <String>[];
    final religiousHolidays = <String>[];
    final culturalHolidays = <String>[];
    final otherHolidays = <String>[];
    final myanmarAnniversaryDays = <String>[];
    final otherAnniversaryDays = <String>[];

    // Convert to Western date for Gregorian-based holidays
    final westernJdn = date.julianDayNumber;
    final westernDate = _jdnToWestern(westernJdn);

    // Myanmar calendar based holidays
    _addMyanmarHolidays(
      date,
      westernDate,
      publicHolidays,
      religiousHolidays,
      culturalHolidays,
    );

    // Western calendar based holidays
    _addWesternHolidays(
      westernDate,
      publicHolidays,
      religiousHolidays,
      culturalHolidays,
    );

    // Thingyan holidays (Myanmar New Year)
    _addThingyanHolidays(
      date,
      westernDate,
      publicHolidays,
      culturalHolidays,
    );

    // Other holidays
    _addOtherHolidays(westernDate, otherHolidays);

    // Myanmar anniversary days
    _addMyanmarAnniversaryDays(
      date,
      westernDate,
      myanmarAnniversaryDays,
    );

    // Other anniversary days
    _addOtherAnniversaryDays(westernDate, otherAnniversaryDays);

    // Custom holidays
    _addCustomHolidays(
      date,
      westernDate,
      westernJdn,
      customHolidays,
      publicHolidays,
      religiousHolidays,
      culturalHolidays,
      otherHolidays,
      myanmarAnniversaryDays,
      otherAnniversaryDays,
    );

    return HolidayInfo(
      publicHolidays: publicHolidays,
      religiousHolidays: religiousHolidays,
      culturalHolidays: culturalHolidays,
      otherHolidays: otherHolidays,
      myanmarAnniversaryDays: myanmarAnniversaryDays,
      otherAnniversaryDays: otherAnniversaryDays,
    );
  }

  /// Check if a holiday is disabled globally, for a specific year, or date
  bool _isDisabled(HolidayId holidayId, int year, [int? month, int? day]) {
    if (_config.disabledHolidays.contains(holidayId)) return true;
    final disabledInYear = _config.disabledHolidaysByYear[year];
    if (disabledInYear != null && disabledInYear.contains(holidayId)) {
      return true;
    }
    if (month != null && day != null) {
      final dateKey =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final disabledOnDate = _config.disabledHolidaysByDate[dateKey];
      if (disabledOnDate != null && disabledOnDate.contains(holidayId)) {
        return true;
      }
    }
    return false;
  }

  /// Add Myanmar calendar based holidays
  void _addMyanmarHolidays(
    MyanmarDate date,
    Map<String, int> westernDate,
    List<String> publicHolidays,
    List<String> religiousHolidays,
    List<String> culturalHolidays,
  ) {
    final westernYear = westernDate['year']!;
    final westernMonth = westernDate['month']!;
    final westernDay = westernDate['day']!;

    // Vesak Day (Buddha Day) - Kason full moon
    if (date.month == CalendarConstants.monthKason &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(HolidayId.buddha, westernYear, westernMonth, westernDay)) {
      religiousHolidays.add(TranslationService.translate('Buddha'));
    }

    // Start of Buddhist Lent - Waso full moon
    if (date.month == CalendarConstants.monthWaso &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.startOfBuddhistLent,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      religiousHolidays.add(
        TranslationService.translate('Start of Buddhist Lent'),
      );
    }

    // End of Buddhist Lent - Thadingyut full moon
    if (date.month == CalendarConstants.monthThadingyut &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon) {
      if (!_isDisabled(
        HolidayId.endOfBuddhistLent,
        westernYear,
        westernMonth,
        westernDay,
      )) {
        religiousHolidays.add(
          TranslationService.translate('End of Buddhist Lent'),
        );
      }
      if (!_isDisabled(
        HolidayId.holiday,
        westernYear,
        westernMonth,
        westernDay,
      )) {
        publicHolidays.add(TranslationService.translate('Holiday'));
      }
    }

    if (date.year >= 1379 &&
        date.month == CalendarConstants.monthThadingyut &&
        (date.day == 14 || date.day == 16) &&
        !_isDisabled(
          HolidayId.holiday,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      publicHolidays.add(TranslationService.translate('Holiday'));
    }

    // Tazaungdaing Festival - Tazaungmon full moon
    if (date.month == CalendarConstants.monthTazaungmon &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.tazaungdaing,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      religiousHolidays.add(TranslationService.translate('Tazaungdaing'));
    }

    if (date.year >= 1379 &&
        date.month == CalendarConstants.monthTazaungmon &&
        date.day == 14 &&
        !_isDisabled(
          HolidayId.holiday,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      culturalHolidays.add(TranslationService.translate('Holiday'));
    }

    // National Day - Tazaungmon waning 10
    if (date.year >= 1282 &&
        date.month == CalendarConstants.monthTazaungmon &&
        date.moonPhase == CalendarConstants.moonPhaseWaning &&
        date.fortnightDay == 10 &&
        !_isDisabled(
          HolidayId.nationalDay,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      publicHolidays.add(TranslationService.translate('National Day'));
    }

    // Karen New Year - Pyatho 1
    if (date.month == CalendarConstants.monthPyatho &&
        date.day == 1 &&
        !_isDisabled(
          HolidayId.karenNewYear,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      culturalHolidays.add(
        '${TranslationService.translate('Karen')} ${TranslationService.translate("New Year's")}',
      );
    }

    // Tabaung Pwe - Tabaung full moon
    if (date.month == CalendarConstants.monthTabaung &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.tabaungPwe,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      culturalHolidays.add(
        '${TranslationService.translate('Tabaung')} ${TranslationService.translate('Pwe')}',
      );
    }
  }

  /// Add Myanmar anniversary days
  void _addMyanmarAnniversaryDays(
    MyanmarDate date,
    Map<String, int> westernDate,
    List<String> items,
  ) {
    final westernYear = westernDate['year']!;
    final westernMonth = westernDate['month']!;
    final westernDay = westernDate['day']!;

    // Mahathamaya Day - Nayon full moon
    if (date.month == CalendarConstants.monthNayon &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.mahathamaya,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(TranslationService.translate('Mahathamaya'));
    }

    // Garudhamma Day - Tawthalin full moon
    if (date.month == CalendarConstants.monthTawthalin &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.garudhamma,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(TranslationService.translate('Garudhamma'));
    }

    // Mothers' Day - Pyatho full moon (since 1998 CE / 1360 ME)
    if (date.year >= 1360 &&
        date.month == CalendarConstants.monthPyatho &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.mothersDay,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(TranslationService.translate('Mothers'));
    }

    // Fathers' Day - Tabaung full moon (since 2008 CE / 1370 ME)
    if (date.year >= 1370 &&
        date.month == CalendarConstants.monthTabaung &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.fathersDay,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(TranslationService.translate('Fathers'));
    }

    // Metta Day - Wagaung full moon
    if (date.month == CalendarConstants.monthWagaung &&
        date.moonPhase == CalendarConstants.moonPhaseFullMoon &&
        !_isDisabled(
          HolidayId.mettaDay,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(TranslationService.translate('Metta'));
    }

    // Taungpyone Pwe - Wagaung 10
    if (date.month == CalendarConstants.monthWagaung &&
        date.day == 10 &&
        !_isDisabled(
          HolidayId.taungpyonePwe,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(
        '${TranslationService.translate('Taungpyone')} ${TranslationService.translate('Pwe')}',
      );
    }

    // Yadanagu Pwe - Wagaung 23
    if (date.month == CalendarConstants.monthWagaung &&
        date.day == 23 &&
        !_isDisabled(
          HolidayId.yadanaguPwe,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(
        '${TranslationService.translate('Yadanagu')} ${TranslationService.translate('Pwe')}',
      );
    }

    // Mon National Day - Tabodwe 16 (since 1947 CE / 1309 ME)
    if (date.year >= 1309 &&
        date.month == CalendarConstants.monthTabodwe &&
        date.day == 16 &&
        !_isDisabled(
          HolidayId.monNationalDay,
          westernYear,
          westernMonth,
          westernDay,
        )) {
      items.add(
        '${TranslationService.translate('Mon')} ${TranslationService.translate('National')}',
      );
    }

    // Shan New Year & Authors' Day - Nadaw 1
    if (date.month == CalendarConstants.monthNadaw && date.day == 1) {
      if (!_isDisabled(
        HolidayId.shanNewYear,
        westernYear,
        westernMonth,
        westernDay,
      )) {
        final shan = TranslationService.translate('Shan');
        final newYear = TranslationService.translate("New Year's");
        items.add('$shan $newYear');
      }

      if (date.year >= 1306 &&
          !_isDisabled(
            HolidayId.authorsDay,
            westernYear,
            westernMonth,
            westernDay,
          )) {
        items.add(TranslationService.translate('Authors'));
      }
    }
  }

  /// Add other anniversary days
  void _addOtherAnniversaryDays(
    Map<String, int> westernDate,
    List<String> items,
  ) {
    final year = westernDate['year']!;
    final month = westernDate['month']!;
    final day = westernDate['day']!;

    // General Aung San's Birthday (February 13, since 1915)
    if (year >= 1915 &&
        month == 2 &&
        day == 13 &&
        !_isDisabled(HolidayId.aungSanBirthday, year, month, day)) {
      items.add(TranslationService.translate('G. Aung San BD'));
    }

    // Valentines Day
    if ((year >= 1969) &&
        (month == 2 && day == 14) &&
        !_isDisabled(HolidayId.valentinesDay, year, month, day)) {
      items.add(TranslationService.translate('Valentines'));
    }

    // Earth Day
    if ((year >= 1970) &&
        (month == 4 && day == 22) &&
        !_isDisabled(HolidayId.earthDay, year, month, day)) {
      items.add(TranslationService.translate('Earth'));
    }

    // April Fools'
    if ((year >= 1392) &&
        (month == 4 && day == 1) &&
        !_isDisabled(HolidayId.aprilFoolsDay, year, month, day)) {
      items.add(TranslationService.translate("April Fools'"));
    }

    // Red cross
    if ((year >= 1948) &&
        (month == 5 && day == 8) &&
        !_isDisabled(HolidayId.redCrossDay, year, month, day)) {
      items.add(TranslationService.translate('Red Cross'));
    }

    // World Teachers'
    if ((year >= 1994) &&
        (month == 10 && day == 5) &&
        !_isDisabled(HolidayId.worldTeachersDay, year, month, day)) {
      items.add(TranslationService.translate("World Teachers'"));
    }

    // UN Day
    if ((year >= 1947) &&
        (month == 10 && day == 24) &&
        !_isDisabled(HolidayId.unitedNationsDay, year, month, day)) {
      items.add(TranslationService.translate('United Nations'));
    }

    // Halloween
    if ((year >= 1753) &&
        (month == 10 && day == 31) &&
        !_isDisabled(HolidayId.halloween, year, month, day)) {
      items.add(TranslationService.translate('Halloween'));
    }

    // Eid al-Fitr (provider-based lookup)
    if (_matchesWesternHoliday(HolidayId.eidAlFitr, year, month, day) &&
        !_isDisabled(HolidayId.eidAlFitr, year, month, day)) {
      items.add(TranslationService.translate('Eid al-Fitr'));
    }

    // Eid al-Adha (provider-based lookup)
    if (_matchesWesternHoliday(HolidayId.eidAlAdha, year, month, day) &&
        !_isDisabled(HolidayId.eidAlAdha, year, month, day)) {
      items.add(TranslationService.translate('Eid al-Adha'));
    }

    // Chinese New Year
    if (_matchesWesternHoliday(HolidayId.chineseNewYear, year, month, day) &&
        !_isDisabled(HolidayId.chineseNewYear, year, month, day)) {
      items.add(TranslationService.translate("Chinese New Year's"));
    }
  }

  /// Add Western calendar based holidays
  void _addWesternHolidays(
    Map<String, int> westernDate,
    List<String> publicHolidays,
    List<String> religiousHolidays,
    List<String> culturalHolidays,
  ) {
    final year = westernDate['year']!;
    final month = westernDate['month']!;
    final day = westernDate['day']!;

    // New Year's Day (since 2018)
    if (year >= 2018 &&
        month == 1 &&
        day == 1 &&
        !_isDisabled(HolidayId.newYearDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate("New Year's"));
    }

    // Pre New Year's
    if (year >= 2018 &&
        month == 12 &&
        day == 31 &&
        !_isDisabled(HolidayId.holiday, year, month, day)) {
      publicHolidays.add(TranslationService.translate('Holiday'));
    }

    // Independence Day (January 4, since 1948)
    if (year >= 1948 &&
        month == 1 &&
        day == 4 &&
        !_isDisabled(HolidayId.independenceDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate('Independence'));
    }

    // Union Day (February 12, since 1947)
    if (year >= 1947 &&
        month == 2 &&
        day == 12 &&
        !_isDisabled(HolidayId.unionDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate('Union'));
    }

    // Peasants' Day (March 2, since 1958)
    if (year >= 1958 &&
        month == 3 &&
        day == 2 &&
        !_isDisabled(HolidayId.peasantsDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate('Peasants'));
    }

    // Resistance Day (March 27, since 1945)
    if (year >= 1945 &&
        month == 3 &&
        day == 27 &&
        !_isDisabled(HolidayId.resistanceDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate('Resistance'));
    }

    // Labour Day (May 1, since 1923)
    if (year >= 1923 &&
        month == 5 &&
        day == 1 &&
        !_isDisabled(HolidayId.labourDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate('Labour'));
    }

    // Martyrs' Day (July 19, since 1947)
    if (year >= 1947 &&
        month == 7 &&
        day == 19 &&
        !_isDisabled(HolidayId.martyrsDay, year, month, day)) {
      publicHolidays.add(TranslationService.translate("Martyrs'"));
    }

    // Christmas Day (since 1752)
    if (year >= 1752 &&
        month == 12 &&
        day == 25 &&
        !_isDisabled(HolidayId.christmasDay, year, month, day)) {
      religiousHolidays.add(TranslationService.translate('Christmas'));
    }

    // Easter calculation
    final easterJdn = _calculateEaster(year);
    final currentJdn = _westernToJdn(year, month, day);

    if (currentJdn == easterJdn &&
        !_isDisabled(HolidayId.easterSunday, year, month, day)) {
      religiousHolidays.add(TranslationService.translate('Easter'));
    } else if (currentJdn == (easterJdn - 2) &&
        !_isDisabled(HolidayId.goodFriday, year, month, day)) {
      religiousHolidays.add(TranslationService.translate('Good Friday'));
    }
  }

  /// Add Thingyan (Water Festival) holidays
  void _addThingyanHolidays(
    MyanmarDate date,
    Map<String, int> westernDate,
    List<String> publicHolidays,
    List<String> culturalHolidays,
  ) {
    final westernYear = westernDate['year']!;
    const solarYear = CalendarConstants.solarYear;
    const myanmarEpoch = CalendarConstants.myanmarEpoch;
    const beginThingyan = 1100;
    const thirdEra = 1312;

    if (date.year >= beginThingyan) {
      final monthType = date.monthType;
      final atatTime = solarYear * (date.year + monthType) + myanmarEpoch;

      final akyaTime = (date.year >= thirdEra)
          ? atatTime - 2.169918982
          : atatTime - 2.1675;

      final atatJdn = atatTime.roundToDouble();
      final akyaJdn = akyaTime.round();
      final akyoJdn = akyaJdn - 1;
      final newYearJdn = atatJdn + 1;
      final currentJdn = date.julianDayNumber.round();

      final thinGyan = TranslationService.translate('Thingyan');
      final westernMonth = westernDate['month']!;
      final westernDay = westernDate['day']!;

      // Myanmar New Year's Day
      if (currentJdn == newYearJdn &&
          !_isDisabled(
            HolidayId.myanmarNewYearDay,
            westernYear,
            westernMonth,
            westernDay,
          )) {
        publicHolidays.add(
          TranslationService.translate("Myanmar New Year's Day"),
        );
      }
      // Thingyan Atat
      else if (currentJdn == atatJdn &&
          !_isDisabled(
            HolidayId.thingyanAtat,
            westernYear,
            westernMonth,
            westernDay,
          )) {
        culturalHolidays.add(
          '$thinGyan ${TranslationService.translate('Atat')}',
        );
      }
      // Thingyan Akyat (water throwing days)
      else if (currentJdn > akyaJdn &&
          currentJdn < atatJdn &&
          !_isDisabled(
            HolidayId.thingyanAkyat,
            westernYear,
            westernMonth,
            westernDay,
          )) {
        culturalHolidays.add(
          '$thinGyan ${TranslationService.translate('Akyat')}',
        );
      }
      // Thingyan Akya
      else if (currentJdn == akyaJdn &&
          !_isDisabled(
            HolidayId.thingyanAkya,
            westernYear,
            westernMonth,
            westernDay,
          )) {
        culturalHolidays.add(
          '$thinGyan ${TranslationService.translate('Akya')}',
        );
      }
      // Thingyan Akyo
      else if (currentJdn == akyoJdn &&
          !_isDisabled(
            HolidayId.thingyanAkyo,
            westernYear,
            westernMonth,
            westernDay,
          )) {
        culturalHolidays.add(
          '$thinGyan ${TranslationService.translate('Akyo')}',
        );
      }

      // Additional holiday periods for specific years
      if (!_isDisabled(
        HolidayId.holiday,
        westernYear,
        westernMonth,
        westernDay,
      )) {
        if ((date.year + monthType) >= 1369 && (date.year + monthType) < 1379) {
          if (currentJdn == (akyaJdn - 2) ||
              (currentJdn >= (atatJdn + 2) && currentJdn <= (akyaJdn + 7))) {
            publicHolidays.add(TranslationService.translate('Holiday'));
          }
        } else if ((date.year + monthType) >= 1384 &&
            (date.year + monthType) <= 1385) {
          if (currentJdn >= (akyaJdn - 5) && currentJdn <= (akyaJdn - 2)) {
            publicHolidays.add(TranslationService.translate('Holiday'));
          }
        } else if ((date.year + monthType) >= 1386) {
          if (currentJdn >= (atatJdn + 2) && currentJdn <= (akyaJdn + 7)) {
            publicHolidays.add(TranslationService.translate('Holiday'));
          }
        }
      }
    }
  }

  /// Add other holidays
  void _addOtherHolidays(
    Map<String, int> westernDate,
    List<String> otherHolidays,
  ) {
    final year = westernDate['year']!;
    final month = westernDate['month']!;
    final day = westernDate['day']!;

    // Diwali (provider-based lookup)
    if (_matchesWesternHoliday(HolidayId.diwali, year, month, day) &&
        !_isDisabled(HolidayId.diwali, year, month, day)) {
      otherHolidays.add(TranslationService.translate('Diwali'));
    }
  }

  bool _matchesWesternHoliday(HolidayId id, int year, int month, int day) {
    return _config.westernHolidayProvider.matches(id, year, month, day);
  }

  /// Calculate Easter Sunday for a given year using Gregorian calendar
  int _calculateEaster(int year) {
    final a = year % 19;
    final b = (year / 100).floor();
    final c = year % 100;
    final d = (b / 4).floor();
    final e = b % 4;
    final f = ((b + 8) / 25).floor();
    final g = ((b - f + 1) / 3).floor();
    final h = (19 * a + b - d - g + 15) % 30;
    final i = (c / 4).floor();
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = ((a + 11 * h + 22 * l) / 451).floor();
    final q = h + l - 7 * m + 114;
    final p = (q % 31) + 1;
    final n = (q / 31).floor();

    return _westernToJdn(year, n, p);
  }

  /// Convert Western date to Julian Day Number
  int _westernToJdn(int year, int month, int day) {
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + (12 * a) - 3;

    final jdn = day + ((153 * m + 2) / 5).floor() + (365 * y) + (y / 4).floor();
    return jdn - (y / 100).floor() + (y / 400).floor() - 32045;
  }

  /// Convert Julian Day Number to Western date
  Map<String, int> _jdnToWestern(double julianDayNumber) {
    var j = (julianDayNumber + 0.5).floor();
    j -= 1721119;

    final year = ((4 * j - 1) / 146097).floor();
    j = 4 * j - 1 - 146097 * year;
    var day = (j / 4).floor();
    j = ((4 * day + 3) / 1461).floor();
    day = 4 * day + 3 - 1461 * j;
    day = ((day + 4) / 4).floor();
    var month = ((5 * day - 3) / 153).floor();
    day = 5 * day - 3 - 153 * month;
    day = ((day + 5) / 5).floor();
    var finalYear = 100 * year + j;

    if (month < 10) {
      month += 3;
    } else {
      month -= 9;
      finalYear += 1;
    }

    return {'year': finalYear, 'month': month, 'day': day};
  }

  /// Check if a date is a substitute holiday
  bool isSubstituteHoliday(double julianDayNumber, int year) {
    if (year >= 2019 && year <= 2021) {
      final substituteHolidays = _getSubstituteHolidays();
      return substituteHolidays.contains(julianDayNumber.round());
    }
    return false;
  }

  /// Get substitute holidays for specific years (2019-2021)
  List<int> _getSubstituteHolidays() {
    return [
      // 2019
      2458768, 2458772, 2458785, 2458800,
      // 2020
      2458855, 2458918, 2458950, 2459051, 2459062,
      2459152, 2459156, 2459167, 2459181, 2459184,
      // 2021
      2459300, 2459303, 2459323, 2459324,
      2459335, 2459548, 2459573,
    ];
  }

  /// Add custom holidays defined in configuration
  void _addCustomHolidays(
    MyanmarDate myanmarDate,
    Map<String, int> westernDateMap,
    double westernJdn,
    List<CustomHoliday> customHolidays,
    List<String> publicHolidays,
    List<String> religiousHolidays,
    List<String> culturalHolidays,
    List<String> otherHolidays,
    List<String> myanmarAnniversaryDays,
    List<String> otherAnniversaryDays,
  ) {
    if (customHolidays.isEmpty) return;

    // Create WesternDate object for predicate
    // Calculate weekday: 0=Saturday, 1=Sunday, ..., 6=Friday
    final weekday = (westernJdn.round() + 2) % 7;

    final westernDateObj = WesternDate(
      year: westernDateMap['year']!,
      month: westernDateMap['month']!,
      day: westernDateMap['day']!,
      hour: 12,
      minute: 0,
      second: 0,
      weekday: weekday,
      julianDayNumber: westernJdn,
    );

    for (final holiday in customHolidays) {
      if (holiday.predicate(myanmarDate, westernDateObj)) {
        switch (holiday.type) {
          case HolidayType.public:
            publicHolidays.add(holiday.name);
            break;
          case HolidayType.religious:
            religiousHolidays.add(holiday.name);
            break;
          case HolidayType.cultural:
            culturalHolidays.add(holiday.name);
            break;
          case HolidayType.other:
            otherHolidays.add(holiday.name);
            break;
          case HolidayType.myanmarAnniversary:
            myanmarAnniversaryDays.add(holiday.name);
            break;
          case HolidayType.otherAnniversary:
            otherAnniversaryDays.add(holiday.name);
            break;
        }
      }
    }
  }
}
