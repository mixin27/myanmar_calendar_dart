import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(MyanmarCalendar.reset);

  test('every holiday name has an entry with an ID', () {
    for (
      var d = DateTime(2024);
      d.year < 2027;
      d = d.add(const Duration(days: 1))
    ) {
      final info = MyanmarCalendar.getCompleteDateFor(
        d.year,
        d.month,
        d.day,
      ).holidays;
      final names = [...info.allHolidays, ...info.allAnniversaryDays]..sort();
      final fromEntries = [for (final h in info.entries) h.name]..sort();
      expect(fromEntries, names, reason: '$d');
      for (final h in info.entries) {
        expect(h.id, isNotNull, reason: '$d $h');
      }
    }
  });

  test('has() works whatever the language', () {
    // 17 April 2026 is Thingyan Akyat; 26 Oct 2026 is Thadingyut full moon.
    for (final language in Language.values) {
      final day = MyanmarCalendar.getCompleteDateFor(
        2026,
        10,
        26,
        language: language,
      ).holidays;
      expect(day.has(HolidayId.endOfBuddhistLent), isTrue, reason: '$language');
      expect(day.has(HolidayId.christmasDay), isFalse);
    }
  });

  test('custom holidays carry their own ID and type', () {
    final rule = CustomHoliday.westernDate(
      id: 'family-day',
      name: 'Family day',
      type: HolidayType.otherAnniversary,
      month: 10,
      day: 18,
    );
    final info = MyanmarCalendar.getCompleteDateFor(
      2026,
      10,
      18,
      config: CalendarConfig(customHolidays: [rule]),
    ).holidays;
    expect(info.hasCustom('family-day'), isTrue);
    final entry = info.entries.singleWhere((h) => h.isCustom);
    expect(entry.type, HolidayType.otherAnniversary);
    expect(info.ofType(HolidayType.otherAnniversary), contains(entry));
  });
}
