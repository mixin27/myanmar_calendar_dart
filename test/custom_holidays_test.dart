import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Holidays Tests', () {
    tearDown(MyanmarCalendar.reset);

    test('should add western date based custom holiday', () {
      // Define a custom holiday: "My Birthday" on Jan 15
      final birthday = CustomHoliday(
        id: 'my_birthday',
        name: 'My Birthday',
        type: HolidayType.other,
        predicate: (myanmarDate, westernDate) {
          return westernDate.month == 1 && westernDate.day == 15;
        },
      );

      // Configure calendar with custom holiday
      MyanmarCalendar.configure(
        customHolidays: [birthday],
      );

      // Check dates
      final date = MyanmarCalendar.fromWestern(2024, 1, 15);
      expect(date.hasHolidays, isTrue);
      expect(date.otherHolidays, contains('My Birthday'));

      // Check non-holiday date
      final otherDate = MyanmarCalendar.fromWestern(2024, 1, 16);
      expect(otherDate.otherHolidays, isNot(contains('My Birthday')));
    });

    test('should add myanmar date based custom holiday', () {
      // Define a custom holiday: "Special Event" on Kason 1 (Month 2)
      final specialEvent = CustomHoliday(
        id: 'special_event',
        name: 'Special Event',
        type: HolidayType.cultural,
        predicate: (myanmarDate, westernDate) {
          // Kason is month 2
          return myanmarDate.month == 2 && myanmarDate.day == 1;
        },
      );

      MyanmarCalendar.configure(
        customHolidays: [specialEvent],
      );

      // Check dates (1385 Kason 1)
      final date = MyanmarCalendar.fromMyanmar(1385, 2, 1);
      expect(date.hasHolidays, isTrue);
      expect(date.culturalHolidays, contains('Special Event'));
    });

    test('should coexist with standard holidays', () {
      // Add custom holiday on Independence Day (Jan 4)
      final extraHoliday = CustomHoliday(
        id: 'extra_holiday',
        name: 'Extra Holiday',
        type: HolidayType.public,
        predicate: (myanmarDate, westernDate) {
          return westernDate.month == 1 && westernDate.day == 4;
        },
      );

      MyanmarCalendar.configure(
        customHolidays: [extraHoliday],
      );

      final date = MyanmarCalendar.fromWestern(2024, 1, 4);
      // Independence Day is standard ("Independence" in TranslationService default/en)
      expect(date.publicHolidays, contains('Independence'));
      // Custom holiday also present
      expect(date.publicHolidays, contains('Extra Holiday'));
    });
  });
}
