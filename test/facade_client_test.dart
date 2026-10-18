import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(MyanmarCalendar.reset);
  tearDown(MyanmarCalendar.reset);

  test('assigning CalendarConfig.global directly is picked up', () {
    final instant = DateTime.utc(2026, 10, 18, 20); // 19 Oct in Myanmar Time
    expect(MyanmarCalendar.getCompleteDate(instant).western.day, 19);
    CalendarConfig.global = const CalendarConfig(timezoneOffset: 0);
    expect(MyanmarCalendar.getCompleteDate(instant).western.day, 18);
  });

  test('helpers keep the configuration of the date they are given', () {
    const utc = CalendarConfig(timezoneOffset: 0);
    final date = MyanmarCalendar.fromWestern(2026, 10, 18, config: utc);
    expect(date.config, utc);
    expect(MyanmarCalendar.addMonths(date, 1).config, utc);
    expect(MyanmarCalendar.addDays(date, 3).config, utc);
    expect(MyanmarCalendar.findNextMoonPhase(date, 1).config, utc);
  });

  test('the facade and a client for the same config agree', () {
    MyanmarCalendar.configure(language: Language.myanmar);
    final client = MyanmarCalendarClient(config: MyanmarCalendar.config);
    final day = MyanmarCalendar.getCompleteDateFor(2026, 10, 18);
    expect(
      day.allHolidays,
      client.getCompleteDateFor(2026, 10, 18).allHolidays,
    );
    final nakhat = day.astro.nakhat;
    expect(
      MyanmarCalendar.getNakhatDescription(nakhat),
      client.getNakhatDescription(nakhat),
    );
    expect(
      MyanmarCalendar.findSabbathDays(1388, 7).length,
      client.findSabbathDays(1388, 7).length,
    );
  });

  test('createClient without a config uses the defaults, not the global', () {
    MyanmarCalendar.configure(timezoneOffset: 0);
    expect(MyanmarCalendar.createClient().config.timezoneOffset, 6.5);
  });

  test('records convert to dates', () {
    final dates = MyanmarCalendar.convertMyanmarDates([
      (1385, 10, 1),
      (1385, 10, 15),
    ]);
    expect(dates.map((d) => d.myanmarDay), [1, 15]);
  });
}
