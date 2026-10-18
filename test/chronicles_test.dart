import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(MyanmarCalendar.reset);

  group('one-day events', () {
    test('an entry without an end date covers only its own day', () {
      const entry = ChronicleEntryData(
        id: 'e',
        startJdn: 2400000,
        title: {'en': 'e'},
      );
      expect(entry.includesJdn(2400000), isTrue);
      expect(entry.includesJdn(2400001), isFalse);
      expect(entry.includesJdn(2500000), isFalse);
      expect(entry.includesJdn(2399999), isFalse);
    });

    test('an entry with an end date covers every day through its end', () {
      const entry = ChronicleEntryData(
        id: 'e',
        startJdn: 2400000,
        endJdn: 2400002,
        title: {'en': 'e'},
      );
      expect(entry.includesJdn(2400001), isTrue);
      expect(entry.includesJdn(2400002), isTrue);
      expect(entry.includesJdn(2400003), isFalse);
    });

    test('later days do not return every earlier event', () {
      expect(MyanmarCalendar.getChronicleFor(DateTime(1850)), isEmpty);
      expect(MyanmarCalendar.getChronicleForJdn(2500000), isEmpty);
    });

    test('a range returns only the events inside it', () {
      final all = MyanmarCalendar.getChroniclesBetweenJdn(0, 3000000);
      expect(all, hasLength(263));
      for (final entry in all) {
        final day = entry.startDay.toDouble();
        expect(
          MyanmarCalendar.getChroniclesBetweenJdn(day - 10, day + 10),
          contains(entry),
        );
        expect(
          MyanmarCalendar.getChroniclesBetweenJdn(day + 1, day + 10),
          isNot(contains(entry)),
        );
      }
      expect(
        MyanmarCalendar.getChroniclesBetweenJdn(2400000, 2500000),
        isEmpty,
      );
    });
  });

  group('day matching', () {
    final entries = MyanmarCalendar.getChroniclesBetweenJdn(0, 3000000);

    test('an entry is found on its own day and not the days around it', () {
      for (final entry in entries) {
        final day = entry.startDay.toDouble();
        expect(MyanmarCalendar.getChronicleForJdn(day), contains(entry));
        expect(
          MyanmarCalendar.getChronicleForJdn(day - 1),
          isNot(contains(entry)),
        );
        expect(
          MyanmarCalendar.getChronicleForJdn(day + 1),
          isNot(contains(entry)),
        );
      }
    });

    test('Myanmar dates and DateTimes find the entry of their day', () {
      for (final entry in entries) {
        final dt = MyanmarCalendar.fromJulianDay(entry.startDay.toDouble());
        expect(
          MyanmarCalendar.getChronicleForMyanmar(dt.myanmarDate),
          contains(entry),
        );
        // DateTime is proleptic Gregorian; day 2400001 is 1858-11-17.
        final w = DateTime.utc(
          1858,
          11,
          17,
        ).add(Duration(days: entry.startDay - 2400001));
        for (final hour in [0, 12, 23]) {
          final local = DateTime(w.year, w.month, w.day, hour);
          expect(MyanmarCalendar.getChronicleFor(local), contains(entry));
          expect(
            MyanmarCalendar.getChronicleFor(
              local.subtract(const Duration(days: 1)),
            ),
            isNot(contains(entry)),
          );
        }
      }
    });

    test('an inscription dated ME 420 Tabaung waxing 5 lands on that day', () {
      final date = MyanmarCalendar.fromMyanmar(420, 12, 5);
      expect(
        MyanmarCalendar.getChronicleForMyanmar(
          date.myanmarDate,
        ).map((e) => e.id),
        contains('jdn_2107906'),
      );
    });
  });
}
