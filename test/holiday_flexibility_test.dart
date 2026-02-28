import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Holiday Flexibility Tests', () {
    tearDown(MyanmarCalendar.reset);

    test('should disable a holiday globally', () {
      // Jan 4, 2024 is Independence Day
      final dateBefore = MyanmarCalendar.fromWestern(2024, 1, 4);
      expect(dateBefore.publicHolidays, contains('Independence'));

      // Disable Independence Day globally
      MyanmarCalendar.configure(
        disabledHolidays: [HolidayId.independenceDay],
      );

      final dateAfter = MyanmarCalendar.fromWestern(2024, 1, 4);
      expect(dateAfter.publicHolidays, isNot(contains('Independence')));

      // Also check another year
      final dateOtherYear = MyanmarCalendar.fromWestern(2025, 1, 4);
      expect(dateOtherYear.publicHolidays, isNot(contains('Independence')));
    });

    test('should disable a holiday for a specific year only', () {
      // Disable Independence Day only for 2024
      MyanmarCalendar.configure(
        disabledHolidaysByYear: {
          2024: [HolidayId.independenceDay],
        },
      );

      final date2024 = MyanmarCalendar.fromWestern(2024, 1, 4);
      expect(date2024.publicHolidays, isNot(contains('Independence')));

      final date2025 = MyanmarCalendar.fromWestern(2025, 1, 4);
      expect(date2025.publicHolidays, contains('Independence'));
    });

    test('should disable multiple holidays in the same year', () {
      // In 2024, Jan 1 is New Year's Day and Jan 4 is Independence Day
      MyanmarCalendar.configure(
        disabledHolidaysByYear: {
          2024: [HolidayId.newYearDay, HolidayId.independenceDay],
        },
      );

      final jan1 = MyanmarCalendar.fromWestern(2024, 1, 1);
      final jan4 = MyanmarCalendar.fromWestern(2024, 1, 4);

      expect(jan1.publicHolidays, isNot(contains("New Year's")));
      expect(jan4.publicHolidays, isNot(contains('Independence')));
    });

    test('should disable Myanmar calendar based holidays', () {
      // 1385 Kason Full Moon (Buddha Day)
      // Western date: May 22, 2024
      final buddhaDay = MyanmarCalendar.fromWestern(2024, 5, 22);
      expect(buddhaDay.religiousHolidays, contains('Buddha'));

      MyanmarCalendar.configure(
        disabledHolidays: [HolidayId.buddha],
      );

      final buddhaDayDisabled = MyanmarCalendar.fromWestern(2024, 5, 22);
      expect(buddhaDayDisabled.religiousHolidays, isNot(contains('Buddha')));
    });

    test('should disable anniversaries', () {
      // Feb 13 is Aung San's Birthday
      final aungSanBirthday = MyanmarCalendar.fromWestern(2024, 2, 13);
      expect(aungSanBirthday.otherAnniversaryDays, contains('G. Aung San BD'));

      MyanmarCalendar.configure(
        disabledHolidays: [HolidayId.aungSanBirthday],
      );

      final disabled = MyanmarCalendar.fromWestern(2024, 2, 13);
      expect(disabled.otherAnniversaryDays, isNot(contains('G. Aung San BD')));
    });

    test('should work with custom holidays while built-in is disabled', () {
      final extraHoliday = CustomHoliday.westernDate(
        id: 'extra',
        name: 'Extra',
        type: HolidayType.public,
        month: 1,
        day: 4,
      );

      MyanmarCalendar.configure(
        disabledHolidays: [HolidayId.independenceDay],
        customHolidayRules: [extraHoliday],
      );

      final date = MyanmarCalendar.fromWestern(2024, 1, 4);
      expect(date.publicHolidays, isNot(contains('Independence')));
      expect(date.publicHolidays, contains('Extra'));
    });

    test('should disable a holiday for a specific date only', () {
      // April 17 is usually Myanmar New Year's Day.
      // In 2026, April 17 is indeed Myanmar New Year's Day.
      MyanmarCalendar.configure(
        disabledHolidaysByDate: {
          '2026-04-17': [HolidayId.myanmarNewYearDay],
        },
      );

      final dateDisabled = MyanmarCalendar.fromWestern(2026, 4, 17);
      expect(
        dateDisabled.publicHolidays,
        isNot(contains("Myanmar New Year's Day")),
      );

      // Check other year - same date
      final dateOtherYear = MyanmarCalendar.fromWestern(2025, 4, 17);
      expect(dateOtherYear.publicHolidays, contains("Myanmar New Year's Day"));
    });

    test('should allow custom western holiday provider rules', () {
      const provider = TableWesternHolidayProvider(
        singleDayRules: {
          HolidayId.diwali: {
            2045: WesternHolidayDate(month: 11, day: 2),
          },
        },
      );

      MyanmarCalendar.configure(westernHolidayProvider: provider);

      final matching = MyanmarCalendar.fromWestern(2045, 11, 2);
      final nonMatching = MyanmarCalendar.fromWestern(2045, 11, 3);

      expect(matching.otherHolidays, contains('Diwali'));
      expect(nonMatching.otherHolidays, isNot(contains('Diwali')));
    });

    test('empty western holiday provider disables approximate defaults', () {
      MyanmarCalendar.configure(
        westernHolidayProvider: const TableWesternHolidayProvider(),
      );

      final knownDiwali = MyanmarCalendar.fromWestern(2026, 11, 8);
      final knownEidFitr = MyanmarCalendar.fromWestern(2026, 3, 20);

      expect(knownDiwali.otherHolidays, isNot(contains('Diwali')));
      expect(
        knownEidFitr.otherAnniversaryDays,
        isNot(contains('Eid al-Fitr')),
      );
    });
  });
}
