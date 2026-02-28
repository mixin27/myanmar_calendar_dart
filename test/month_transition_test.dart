import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/utils/calendar_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Myanmar Month Transition', () {
    test('month stepping is deterministic across repeated additions', () {
      final base = MyanmarCalendar.fromWestern(2024, 7, 1).myanmarDate;

      var stepped = base;
      for (var i = 0; i < 6; i++) {
        stepped = CalendarUtils.addMonthsToMyanmarDate(stepped, 1);
      }

      final direct = CalendarUtils.addMonthsToMyanmarDate(base, 6);

      expect(direct.year, stepped.year);
      expect(direct.month, stepped.month);
    });

    test('first Waso transitions to Waso when adding one month', () {
      MyanmarDate? firstWaso;
      var cursor = DateTime(2024, 1, 1);
      final end = DateTime(2026, 12, 31);

      while (!cursor.isAfter(end)) {
        final candidate = MyanmarCalendar.fromDateTime(cursor).myanmarDate;
        if (candidate.month == 0) {
          firstWaso = candidate;
          break;
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      expect(
        firstWaso,
        isNotNull,
        reason: 'Expected to find a First Waso date',
      );

      final nextMonth = CalendarUtils.addMonthsToMyanmarDate(firstWaso!, 1);
      expect(
        nextMonth.month,
        4,
        reason: 'First Waso should transition to Waso',
      );
    });
  });
}
