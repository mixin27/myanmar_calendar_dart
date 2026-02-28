import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/services/date_converter.dart';
import 'package:test/test.dart';

void main() {
  group('Cache System Improvements', () {
    tearDown(() {
      MyanmarCalendar.reset();
      MyanmarCalendar.clearCache();
    });

    test('shared cache isolates converter entries per configuration', () {
      final sharedCache = CalendarCache.independent();
      final utcConverter = DateConverter(
        const CalendarConfig(timezoneOffset: 0),
        cache: sharedCache,
      );
      final myanmarConverter = DateConverter(
        const CalendarConfig(timezoneOffset: 6.5),
        cache: sharedCache,
      );

      final utcJdn = utcConverter.westernToJulian(2024, 1, 1, 12, 0, 0);

      final asUtc = utcConverter.julianToWestern(utcJdn);
      final asMyanmarTime = myanmarConverter.julianToWestern(utcJdn);

      expect(asUtc.hour, 12);
      expect(asUtc.minute, 0);
      expect(asMyanmarTime.hour, 18);
      expect(asMyanmarTime.minute, 30);
    });

    test('complete date cache is language-aware', () {
      MyanmarCalendar.setLanguage(Language.english);
      final englishDate = MyanmarCalendar.getCompleteDate(DateTime(2024, 1, 4));
      expect(englishDate.publicHolidays, contains('Independence'));

      MyanmarCalendar.setLanguage(Language.myanmar);
      final myanmarDate = MyanmarCalendar.getCompleteDate(DateTime(2024, 1, 4));
      final expectedMyanmar = TranslationService.translateTo(
        'Independence',
        Language.myanmar,
      );

      expect(myanmarDate.publicHolidays, contains(expectedMyanmar));
      expect(myanmarDate.publicHolidays, isNot(contains('Independence')));
    });

    test('invalid Western calendar date is rejected', () {
      expect(
        () => MyanmarCalendar.fromWestern(2024, 2, 30),
        throwsArgumentError,
      );
      expect(
        () => MyanmarCalendar.fromWestern(2025, 11, 31),
        throwsArgumentError,
      );
    });

    test('clearAll clears shan cache entries too', () {
      final cache = CalendarCache.independent();
      const keyJdn = 2460310.5;
      const shanDate = ShanDate(
        year: 2120,
        month: 10,
        day: 5,
        myanmarYear: 1387,
        weekday: 2,
        monthType: 0,
        moonPhase: 0,
        fortnightDay: 5,
      );

      cache.putShanDate(keyJdn, shanDate);
      expect(cache.getShanDate(keyJdn), isNotNull);

      cache.clearAll();
      expect(cache.getShanDate(keyJdn), isNull);
    });
  });

  group('Model Immutability Improvements', () {
    test('HolidayInfo lists are immutable', () {
      final holidays = HolidayInfo(
        publicHolidays: ['A'],
        religiousHolidays: const [],
        culturalHolidays: const [],
        otherHolidays: const [],
        myanmarAnniversaryDays: const [],
        otherAnniversaryDays: const [],
      );

      expect(() => holidays.publicHolidays.add('B'), throwsUnsupportedError);
    });

    test('AstroInfo list is immutable', () {
      final astro = AstroInfo(
        astrologicalDays: ['Thamanyo'],
        sabbath: '',
        yatyaza: '',
        pyathada: '',
        nagahle: 'East',
        mahabote: 'Atun',
        nakhat: 'Human',
        yearName: 'Hpusha',
      );

      expect(
        () => astro.astrologicalDays.add('Yatyotema'),
        throwsUnsupportedError,
      );
    });

    test('CompleteDate.fromMap accepts integer JDN values', () {
      final complete = MyanmarCalendar.getCompleteDate(DateTime(2024, 1, 1));
      final map = complete.toMap();

      final western = Map<String, dynamic>.from(map['western'] as Map);
      western['julianDayNumber'] = (western['julianDayNumber'] as num).toInt();

      final myanmar = Map<String, dynamic>.from(map['myanmar'] as Map);
      myanmar['julianDayNumber'] = (myanmar['julianDayNumber'] as num).toInt();

      final payload = Map<String, dynamic>.from(map)
        ..['western'] = western
        ..['myanmar'] = myanmar;

      final restored = CompleteDate.fromMap(payload);

      expect(restored.western.year, complete.western.year);
      expect(restored.myanmar.year, complete.myanmar.year);
      expect(restored.shan.year, complete.shan.year);
    });
  });
}
