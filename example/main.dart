// Quick start: dart run example/main.dart
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  // Today, and any Western date, in the Myanmar calendar.
  final today = MyanmarCalendar.today();
  print('Today: ${today.formatMyanmar('&y &M &P &ff', Language.english)}');

  // A month grid: one call per calendar day, no time zone involved.
  print('\nOctober 2026');
  for (var day = 1; day <= 31; day++) {
    final date = MyanmarCalendar.getCompleteDateFor(2026, 10, day);
    final marks = [
      if (date.phase == MoonPhase.fullMoon) 'full moon',
      if (date.astro.sabbathType == SabbathType.sabbath) 'sabbath',
      ...date.allHolidays,
    ];
    final myanmar = MyanmarCalendar.formatMyanmar(
      date.myanmar,
      pattern: '&M &P &f',
      language: Language.english,
    );
    print(
      '${'$day'.padLeft(2)}  $myanmar${marks.isEmpty ? '' : '  (${marks.join(', ')})'}',
    );
  }

  // Holidays by ID, whatever the display language.
  final lent = MyanmarCalendar.getCompleteDateFor(
    2026,
    10,
    26,
    language: Language.myanmar,
  );
  print(
    '\nEnd of Buddhist Lent: ${lent.holidays.has(HolidayId.endOfBuddhistLent)}',
  );

  // Parsing, with errors you can catch.
  print('Parsed: ${MyanmarCalendar.parseMyanmar('1388/7/15').westernDate}');
  try {
    MyanmarCalendar.parseMyanmar('1386/5/30'); // Wagaung has 29 days
  } on DateParseException catch (e) {
    print('Rejected: ${e.message}');
  }

  // Another time zone for one call, without changing the global setup.
  final atUtc = MyanmarCalendar.getCompleteDate(
    DateTime.utc(2026, 10, 18, 20),
    config: const CalendarConfig(timezoneOffset: 0),
  );
  print('20:00 UTC is still ${atUtc.western.day} October at UTC+0');
}
