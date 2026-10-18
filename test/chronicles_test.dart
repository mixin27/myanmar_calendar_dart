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
}
