import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Custom Holidays Tests', () {
    tearDown(MyanmarCalendar.reset);

    test('should add western date based custom holiday', () {
      // Define a custom holiday: "My Birthday" on Jan 15
      final birthday = CustomHoliday.westernDate(
        id: 'my_birthday',
        name: 'My Birthday',
        type: HolidayType.other,
        month: 1,
        day: 15,
      );

      // Configure calendar with custom holiday
      MyanmarCalendar.configure(
        customHolidayRules: [birthday],
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
      final specialEvent = CustomHoliday.myanmarDate(
        id: 'special_event',
        name: 'Special Event',
        type: HolidayType.cultural,
        month: 2, // Kason
        day: 1,
      );

      MyanmarCalendar.configure(
        customHolidayRules: [specialEvent],
      );

      // Check dates (1385 Kason 1)
      final date = MyanmarCalendar.fromMyanmar(1385, 2, 1);
      expect(date.hasHolidays, isTrue);
      expect(date.culturalHolidays, contains('Special Event'));
    });

    test('should coexist with standard holidays', () {
      // Add custom holiday on Independence Day (Jan 4)
      final extraHoliday = CustomHoliday.westernDate(
        id: 'extra_holiday',
        name: 'Extra Holiday',
        type: HolidayType.public,
        month: 1,
        day: 4,
      );

      MyanmarCalendar.configure(
        customHolidayRules: [extraHoliday],
      );

      final date = MyanmarCalendar.fromWestern(2024, 1, 4);
      // Independence Day is standard ("Independence" in TranslationService default/en)
      expect(date.publicHolidays, contains('Independence'));
      // Custom holiday also present
      expect(date.publicHolidays, contains('Extra Holiday'));
    });

    test('should localize custom holiday names by current language', () {
      final localizedRule = CustomHoliday.westernDate(
        id: 'new_moon_reflection_day',
        name: 'New Moon Reflection Day',
        type: HolidayType.cultural,
        month: 1,
        day: 11,
        cacheVersion: 1,
        localizedNames: const {
          Language.myanmar: 'လကွယ်တရားထိုင်နေ့',
        },
      );

      MyanmarCalendar.configure(
        customHolidayRules: [localizedRule],
        language: Language.english,
      );

      final english = MyanmarCalendar.fromWestern(2024, 1, 11);
      expect(english.culturalHolidays, contains('New Moon Reflection Day'));

      MyanmarCalendar.setLanguage(Language.myanmar);
      final myanmar = MyanmarCalendar.fromWestern(2024, 1, 11);
      expect(myanmar.culturalHolidays, contains('လကွယ်တရားထိုင်နေ့'));
    });
  });
}
