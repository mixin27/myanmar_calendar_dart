import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  test('typed getters match the int codes', () {
    for (
      var d = DateTime(2026);
      d.year == 2026;
      d = d.add(const Duration(days: 1))
    ) {
      final day = MyanmarCalendar.getCompleteDateFor(d.year, d.month, d.day);
      expect(day.phase.code, day.moonPhase);
      expect(day.yearKind.code, day.yearType);
      expect(day.myanmar.dartWeekday, d.weekday, reason: '$d');
      expect(day.western.dartWeekday, d.weekday, reason: '$d');
      expect(
        day.astro.sabbathType,
        switch (day.astro.sabbath) {
          'Sabbath' => SabbathType.sabbath,
          'Sabbath Eve' => SabbathType.sabbathEve,
          _ => SabbathType.none,
        },
      );
    }
  });

  test('full moons and year kinds read naturally', () {
    final fullMoon = MyanmarCalendar.fromMyanmar(1388, 7, 15);
    expect(fullMoon.phase, MoonPhase.fullMoon);
    expect(fullMoon.yearKind, MyanmarYearType.bigWatat);
    expect(fullMoon.yearKind.isWatat, isTrue);
    expect(
      MyanmarCalendar.findNextMoonPhase(fullMoon, MoonPhase.newMoon.code).phase,
      MoonPhase.newMoon,
    );
  });

  test('config codes as enums', () {
    const config = CalendarConfig();
    expect(config.calendarSystem, CalendarSystem.british);
    expect(config.sasanaYear, SasanaYearType.solar);
  });
}
