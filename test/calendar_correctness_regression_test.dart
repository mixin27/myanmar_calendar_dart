import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_utils.dart';
import 'package:test/test.dart';

String _ymd(MyanmarDate d) => '${d.year}/${d.month}/${d.day}';

/// A year's type read from a mid-year day (Waso 15 always exists).
int _actualYearType(int year) =>
    MyanmarCalendar.fromMyanmar(year, 4, 15).myanmarDate.yearType;

void main() {
  setUp(MyanmarCalendar.reset);

  group('years and months', () {
    test('isWatatYear and getYearType describe the year asked for', () {
      // They used to read the type from 1 Tagu, which belongs to the
      // previous year.
      for (var year = 1370; year <= 1400; year++) {
        final type = _actualYearType(year);
        expect(MyanmarCalendar.getYearType(year), type, reason: '$year');
        expect(MyanmarCalendar.isWatatYear(year), type > 0, reason: '$year');
      }
    });

    test("a year's months hold every day of the year exactly once", () {
      for (var year = 1370; year <= 1400; year++) {
        final days = [
          for (var month = 0; month <= 14; month++)
            ...MyanmarCalendar.getMyanmarMonth(year, month),
        ];
        for (final day in days) {
          expect(day.year, year);
        }
        // New Year to New Year: a solar year, with no gaps or repeats.
        days.sort((a, b) => a.julianDayNumber.compareTo(b.julianDayNumber));
        for (var i = 1; i < days.length; i++) {
          expect(
            days[i].julianDayNumber - days[i - 1].julianDayNumber,
            1,
            reason: '${_ymd(days[i - 1])} -> ${_ymd(days[i])}',
          );
        }
        expect(days.length, inInclusiveRange(365, 366), reason: '$year');
      }
    });

    test('Tagu and Kason are not empty in years that have them', () {
      // Kason 1388 (2026) holds Vesak; it used to come back empty.
      final kason = MyanmarCalendar.getMyanmarMonth(1388, 2);
      expect(kason, isNotEmpty);
      expect(kason.any((d) => d.moonPhase == 1), isTrue);
      // Late Kason only exists in some common years.
      expect(MyanmarCalendar.getMyanmarMonth(1379, 14), isNotEmpty);
    });

    test('a year has one full moon per month, late months included', () {
      for (var year = 1380; year <= 1395; year++) {
        final fullMoons = CalendarUtils.findMoonPhaseDatesInYear(year, 1);
        final months = {
          for (var month = 0; month <= 14; month++)
            if (MyanmarCalendar.getMyanmarMonth(
              year,
              month,
            ).any((d) => d.moonPhase == 1))
              month,
        };
        expect(fullMoons.length, months.length, reason: '$year');
      }
    });
  });

  group('day arithmetic keeps the day', () {
    test('adding months', () {
      // The offset used to compound on every month step.
      final date = MyanmarCalendar.fromMyanmar(1387, 10, 2);
      // It used to give 1388/3/2 here.
      final later = MyanmarCalendar.addMonths(date, 5).myanmarDate;
      expect([later.year, later.month], [1388, 2]);
      for (var i = 0; i < 80; i++) {
        final start = MyanmarCalendar.addDays(date, i * 5);
        for (final months in [1, 3, -2]) {
          final target = MyanmarCalendar.addMonths(start, months).myanmarDate;
          final monthDays = MyanmarCalendar.getMyanmarMonth(
            target.year,
            target.month,
          ).map((d) => d.day);
          // The same day number when the target month has it, else its
          // last day.
          final expected = monthDays.contains(start.myanmarDay)
              ? start.myanmarDay
              : monthDays.reduce((a, b) => a > b ? a : b);
          expect(target.day, expected, reason: '$start + $months');
        }
      }
    });

    test('adding days and counting them', () {
      final start = MyanmarCalendar.fromMyanmar(1386, 12, 20);
      var previous = start.myanmarDate;
      for (var i = 1; i <= 400; i++) {
        final next = CalendarUtils.addDaysToMyanmarDate(start.myanmarDate, i);
        expect(next.julianDayNumber - previous.julianDayNumber, 1);
        expect(
          CalendarUtils.daysBetweenMyanmarDates(start.myanmarDate, next),
          i,
        );
        previous = next;
      }
    });

    test('the next full moon is the next one, in any time zone', () {
      for (final offset in [6.5, -5.0, 13.0]) {
        final config = CalendarConfig(timezoneOffset: offset);
        final date = MyanmarDateTime.fromMyanmar(1388, 7, 3, config: config);
        final full = CalendarUtils.findNextMoonPhase(date.myanmarDate, 1);
        expect(_ymd(full), '1388/7/15', reason: 'UTC$offset');
      }
    });

    test('fromMyanmarDate gives back the same day', () {
      final date = MyanmarCalendar.fromMyanmar(1388, 7, 15).myanmarDate;
      expect(
        _ymd(MyanmarDateTime.fromMyanmarDate(date).myanmarDate),
        _ymd(date),
      );
    });
  });

  group('dates that do not exist are rejected', () {
    test('day 30 of a 29-day month', () {
      // Wagaung (5) has 29 days; day 30 used to become day 29.
      expect(
        () => MyanmarCalendar.fromMyanmar(1386, 5, 30),
        throwsA(isA<InvalidMyanmarDateException>()),
      );
    });

    test('First Waso in a common year', () {
      expect(_actualYearType(1386), 0);
      expect(
        () => MyanmarCalendar.fromMyanmar(1386, 0, 1),
        throwsA(isA<InvalidMyanmarDateException>()),
      );
      expect(MyanmarCalendar.getMyanmarMonth(1386, 0), isEmpty);
    });
  });

  test('endOfMonth is the last Western day of the month', () {
    // It used the Myanmar month's length and threw in February.
    final feb = MyanmarCalendar.fromWestern(2026, 2, 10).endOfMonth;
    expect(feb.westernDate.day, 28);
    final jan = MyanmarCalendar.fromWestern(2026, 1, 10).endOfMonth;
    expect(jan.westernDate.day, 31);
  });

  test('the Shan year turns over at Shan New Year (Nadaw 1)', () {
    expect(MyanmarCalendar.getCompleteDateFor(2026, 5, 10).shan.year, 2120);
    final nadaw = MyanmarCalendar.getMyanmarMonth(1388, 9).first;
    final day = MyanmarDateTime.fromMyanmarDate(nadaw);
    expect(
      MyanmarCalendar.getCompleteDate(day.toDateTime()).shan.year,
      2121,
    );
  });

  group('holidays', () {
    test('Tazaungmon 14 is a public holiday', () {
      final day = MyanmarCalendar.fromMyanmar(1388, 8, 14).toDateTime();
      final info = MyanmarCalendar.getCompleteDate(
        day,
        language: Language.english,
      ).holidays;
      expect(info.publicHolidays, contains('Holiday'));
      expect(info.culturalHolidays, isNot(contains('Holiday')));
    });

    test('Thadingyut full moon is End of Buddhist Lent only', () {
      final day = MyanmarCalendar.fromMyanmar(1388, 7, 15).toDateTime();
      final info = MyanmarCalendar.getCompleteDate(
        day,
        language: Language.english,
      ).holidays;
      expect(info.religiousHolidays, contains('End of Buddhist Lent'));
      expect(info.publicHolidays, isNot(contains('Holiday')));
    });

    test("New Year's Day was a public holiday only from 2018 to 2021", () {
      List<String> publicOn(int year) => MyanmarCalendar.getCompleteDateFor(
        year,
        1,
        1,
        language: Language.english,
      ).publicHolidays;
      expect(publicOn(2017), isNot(contains("New Year's")));
      expect(publicOn(2019), contains("New Year's"));
      expect(publicOn(2025), isNot(contains("New Year's")));
    });
  });

  group('equality', () {
    test('comparing with another type is false, not a crash', () {
      final date = MyanmarCalendar.fromMyanmar(1388, 7, 15);
      expect(date.myanmarDate == Object(), isFalse);
      expect(<Object>{date.myanmarDate}.contains('x'), isFalse);
    });

    test('equal complete dates are equal', () {
      final a = MyanmarCalendarClient().getCompleteDateFor(2026, 10, 18);
      final b = MyanmarCalendarClient().getCompleteDateFor(2026, 10, 18);
      expect(a.western, b.western);
      expect(a.western.hashCode, b.western.hashCode);
    });

    test('MyanmarDateTime sorts without a comparator', () {
      final dates = [
        MyanmarCalendar.fromWestern(2026, 3, 1),
        MyanmarCalendar.fromWestern(2025, 3, 1),
        MyanmarCalendar.fromWestern(2027, 3, 1),
      ]..sort();
      expect(dates.map((d) => d.westernDate.year), [2025, 2026, 2027]);
    });

    test('equal validation results hash alike', () {
      final a = MyanmarCalendar.validateMyanmar(1386, 5, 30);
      final b = MyanmarCalendar.validateMyanmar(1386, 5, 30);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
