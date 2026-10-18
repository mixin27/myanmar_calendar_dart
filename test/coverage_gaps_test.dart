import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(MyanmarCalendar.reset);

  group('Shan calendar', () {
    test('Shan dates follow their Myanmar dates', () {
      for (
        var d = DateTime(2025);
        d.year < 2027;
        d = d.add(const Duration(days: 11))
      ) {
        final day = MyanmarCalendar.getCompleteDateFor(d.year, d.month, d.day);
        expect(day.shan.month, day.myanmar.month);
        expect(day.shan.day, day.myanmar.day);
        expect(
          day.shan.year,
          MyanmarCalendar.getShanYearForDate(
            day.myanmar.year,
            day.myanmar.month,
          ),
        );
        expect(day.shan.monthName, isNotEmpty);
        expect(
          MyanmarCalendar.formatShanDate(day.shan),
          contains('${day.shan.year}'),
        );
      }
    });
  });

  group('chronicles', () {
    test('dynasties are sorted and can be looked up', () {
      final dynasties = MyanmarCalendar.listDynasties();
      expect(dynasties, isNotEmpty);
      for (var i = 1; i < dynasties.length; i++) {
        expect(
          dynasties[i].startJdn,
          greaterThanOrEqualTo(dynasties[i - 1].startJdn),
        );
      }
      for (final dynasty in dynasties) {
        expect(MyanmarCalendar.getDynastyById(dynasty.id), dynasty);
        for (final entry in MyanmarCalendar.getEntriesForDynasty(dynasty.id)) {
          expect(entry.dynastyId, dynasty.id);
        }
      }
    });

    test('entries found by day are inside a range around it', () {
      final dynasty = MyanmarCalendar.listDynasties().first;
      final jdn = (dynasty.startJdn + dynasty.endJdn) / 2;
      expect(MyanmarCalendar.getDynastyForJdn(jdn), isNotNull);
      final around = MyanmarCalendar.getChroniclesBetweenJdn(jdn - 1, jdn + 1);
      for (final entry in MyanmarCalendar.getChronicleForJdn(jdn)) {
        expect(around, contains(entry));
      }
    });
  });

  group('cache', () {
    test('asking for "now" twice reuses one entry for the day', () {
      final stats =
          (MyanmarCalendarClient()
                ..getCompleteDate(DateTime(2026, 10, 18, 9))
                ..getCompleteDate(DateTime(2026, 10, 18, 21, 30)))
              .getCacheStatistics();
      expect(stats.completeDate.size, 1);
      expect(stats.hits, greaterThan(0));
    });

    test('warmUpCache fills the complete-date cache', () {
      final client = MyanmarCalendarClient()
        ..warmUpCache(
          startDate: DateTime(2026, 10),
          endDate: DateTime(2026, 10, 31),
        );
      expect(client.getCacheStatistics().completeDate.size, greaterThan(20));
    });
  });

  test('auspicious days are auspicious and in their month', () {
    final days = MyanmarCalendar.findAuspiciousDays(1388, 7);
    for (final day in days) {
      expect(day.astro.isAuspicious, isTrue);
      expect([day.myanmar.year, day.myanmar.month], [1388, 7]);
    }
  });
}
