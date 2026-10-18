import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

String _ymd(MyanmarDateTime d) =>
    '${d.myanmarYear}/${d.myanmarMonth}/${d.myanmarDay}';

void main() {
  setUp(MyanmarCalendar.reset);

  group('parseMyanmar', () {
    test('accepts year-first and day-first, with any one separator', () {
      for (final text in [
        '1385/10/1',
        '1385-10-1',
        '1385.10.1',
        '1/10/1385',
        '1.10.1385',
        ' 1385/10/01 ',
        '၁၃၈၅/၁၀/၁',
      ]) {
        expect(
          _ymd(MyanmarCalendar.parseMyanmar(text)),
          '1385/10/1',
          reason: text,
        );
      }
    });

    test('rejects anything else with a DateParseException', () {
      for (final text in [
        'abc1385/10/1',
        '1385/10/1/999',
        '1385/10-1',
        '1385/10',
        '',
        '1386/0/1', // First Waso in a common year
        '1386/5/30', // Wagaung has 29 days
      ]) {
        expect(
          () => MyanmarCalendar.parseMyanmar(text),
          throwsA(isA<DateParseException>()),
          reason: text,
        );
        expect(MyanmarCalendar.tryParseMyanmar(text), isNull, reason: text);
      }
    });

    test('a parse error is also a FormatException', () {
      expect(
        () => MyanmarCalendar.parseWestern('2024-13-45x'),
        throwsA(isA<FormatException>()),
      );
      expect(MyanmarCalendar.tryParseWestern('nope'), isNull);
      expect(MyanmarCalendar.parseWestern('2024-01-01').westernDate.day, 1);
    });
  });

  group('typed exceptions', () {
    test('Myanmar and Western dates that do not exist', () {
      expect(
        () => MyanmarCalendar.fromMyanmar(1386, 5, 30),
        throwsA(
          isA<InvalidMyanmarDateException>()
              .having((e) => e.month, 'month', 5)
              .having((e) => e.day, 'day', 30),
        ),
      );
      expect(
        () => MyanmarCalendar.fromWestern(2025, 2, 29),
        throwsA(isA<InvalidWesternDateException>()),
      );
      expect(
        () => MyanmarCalendar.fromMyanmar(1386, 15, 1),
        throwsA(isA<MyanmarCalendarException>()),
      );
    });

    test('1700 had 29 February in the British calendar', () {
      expect(MyanmarCalendar.fromWestern(1700, 2, 29).westernDate.day, 29);
      expect(
        () => MyanmarCalendar.fromWestern(
          1700,
          2,
          29,
          config: const CalendarConfig(calendarType: 1),
        ),
        throwsA(isA<InvalidWesternDateException>()),
      );
    });
  });
}
