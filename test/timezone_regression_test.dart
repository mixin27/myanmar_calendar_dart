import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/services/myanmar_calendar_service.dart';
import 'package:test/test.dart';

/// Myanmar Time, the package default.
const _mmt = Duration(hours: 6, minutes: 30);

String _mm(MyanmarDate d) => '${d.year}/${d.month}/${d.day}';

void main() {
  setUp(MyanmarCalendar.reset);

  group('a calendar day has one Myanmar date at every hour', () {
    test('getCompleteDate ignores the time of day', () {
      // Evening times used to roll over to the next Myanmar day after 17:30.
      for (var day = DateTime(2026); day.year == 2026;) {
        final expected = _mm(MyanmarCalendar.getCompleteDate(day).myanmar);
        for (final hour in [6, 12, 17, 18, 23]) {
          final at = DateTime(day.year, day.month, day.day, hour, 59);
          expect(
            _mm(MyanmarCalendar.getCompleteDate(at).myanmar),
            expected,
            reason: '$at',
          );
        }
        day = DateTime(day.year, day.month, day.day + 9);
      }
    });

    test('westernToMyanmar ignores the time of day', () {
      final service = MyanmarCalendarService.withIndependentCache();
      final morning = service.westernToMyanmar(DateTime(2026, 10, 18, 1));
      final evening = service.westernToMyanmar(DateTime(2026, 10, 18, 22));
      expect(_mm(evening), _mm(morning));
    });

    test('midnight stays on its own day across centuries', () {
      final service = MyanmarCalendarService.withIndependentCache();
      for (var year = 1900; year <= 2100; year += 7) {
        for (final month in [1, 4, 10]) {
          final midnight = DateTime(year, month, 15);
          final noon = DateTime(year, month, 15, 12);
          expect(
            _mm(service.westernToMyanmar(midnight)),
            _mm(service.westernToMyanmar(noon)),
            reason: '$midnight',
          );
        }
      }
    });

    test('getCompleteDateFor matches the same day as a DateTime', () {
      final a = MyanmarCalendar.getCompleteDateFor(2026, 10, 18);
      final b = MyanmarCalendar.getCompleteDate(DateTime(2026, 10, 18, 20));
      expect(_mm(a.myanmar), _mm(b.myanmar));
      expect(a.western.day, 18);
      final client = MyanmarCalendarClient();
      expect(
        _mm(client.getCompleteDateFor(2026, 10, 18).myanmar),
        _mm(a.myanmar),
      );
    });
  });

  group('instants', () {
    test('now() is the current time in Myanmar Time', () {
      final expected = DateTime.now().toUtc().add(_mmt);
      final now = MyanmarDateTime.now().westernDate;
      final shown = DateTime.utc(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      expect(shown.difference(expected).inSeconds.abs(), lessThan(5));
    });

    test('epoch values and UTC DateTimes are instants', () {
      final instant = DateTime.utc(2026, 10, 18, 20); // 19 Oct 02:30 MMT
      for (final m in [
        MyanmarDateTime.fromMillisecondsSinceEpoch(
          instant.millisecondsSinceEpoch,
        ),
        MyanmarDateTime.fromTimestamp(instant.millisecondsSinceEpoch ~/ 1000),
        MyanmarDateTime.fromDateTime(instant),
      ]) {
        expect(m.westernDate.day, 19);
        expect(m.westernDate.hour, 2);
        expect(m.westernDate.minute, 30);
        expect(m.millisecondsSinceEpoch, instant.millisecondsSinceEpoch);
        expect(m.toUtc(), instant);
        expect(m.toUtc().isUtc, isTrue);
      }
      final complete = MyanmarCalendar.getCompleteDate(instant);
      expect(complete.western.day, 19);
      expect(
        _mm(complete.myanmar),
        _mm(MyanmarCalendar.getCompleteDateFor(2026, 10, 19).myanmar),
      );
    });

    test('local DateTimes are wall-clock time in the calendar zone', () {
      final m = MyanmarDateTime.fromDateTime(DateTime(2026, 10, 18, 18));
      expect(m.westernDate.day, 18);
      expect(m.westernDate.hour, 18);
      expect(m.toUtc(), DateTime.utc(2026, 10, 18, 11, 30));
    });
  });

  test('every minute of a day survives a round trip', () {
    // Floored hours and minutes with rounded seconds used to give 02:29:60.
    for (var minute = 0; minute < 24 * 60; minute++) {
      final instant = DateTime.utc(2026, 10, 18).add(Duration(minutes: minute));
      final m = MyanmarDateTime.fromDateTime(instant);
      expect(m.westernDate.second, 0, reason: '$instant');
      expect(m.toUtc(), instant, reason: '$instant');
    }
  });

  test('the cache tells a UTC value from a local one at the same instant', () {
    final utc = DateTime.utc(2026, 1, 1); // 06:30 MMT
    final local = utc.toLocal(); // the device's wall clock

    // Warm the cache with the local value first; the UTC lookup must not
    // reuse it (they only agree when the device itself is on Myanmar Time).
    final fromLocal = MyanmarCalendar.getCompleteDate(local);
    final fromUtc = MyanmarCalendar.getCompleteDate(utc);
    expect(fromLocal.western.hour, local.hour);
    expect(fromUtc.western.hour, 6);
    expect(fromUtc.western.minute, 30);
  });

  group('per-call config', () {
    test('changes only that call', () {
      final instant = DateTime.utc(2026, 10, 18, 20);
      final atUtc = MyanmarCalendar.getCompleteDate(
        instant,
        config: const CalendarConfig(timezoneOffset: 0),
      );
      expect(atUtc.western.day, 18);
      expect(atUtc.western.hour, 20);

      expect(CalendarConfig.global.timezoneOffset, 6.5);
      expect(MyanmarCalendar.getCompleteDate(instant).western.day, 19);
    });

    test('keeps custom holiday rules to that call', () {
      final rule = CustomHoliday.westernDate(
        id: 'family-day',
        name: 'Family day',
        type: HolidayType.public,
        month: 10,
        day: 18,
      );
      final config = CalendarConfig(customHolidays: [rule]);
      final withRule = MyanmarCalendar.getCompleteDateFor(
        2026,
        10,
        18,
        config: config,
      );
      final without = MyanmarCalendar.getCompleteDateFor(2026, 10, 18);
      expect(withRule.allHolidays, contains('Family day'));
      expect(without.allHolidays, isNot(contains('Family day')));
    });

    test('bulk and month helpers accept it too', () {
      const config = CalendarConfig(timezoneOffset: 0);
      final days = MyanmarCalendar.getCompleteDates([
        DateTime.utc(2026, 10, 18, 20),
      ], config: config);
      expect(days.single.western.day, 18);
      expect(
        MyanmarCalendar.getMyanmarMonth(1388, 7, config: config),
        isNotEmpty,
      );
    });
  });
}
