import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  // Configure the calendar (optional)
  MyanmarCalendar.configure(
    language: Language.english,
    timezoneOffset: 0, // Myanmar Standard Time
    customHolidayRules: [
      CustomHoliday.westernDate(
        id: 'my_birthday',
        name: 'My Birthday',
        type: HolidayType.other,
        month: 7,
        day: 27,
      ),
    ],
  );

  // Get today's date
  final today = MyanmarCalendar.today();
  print('Today: ${today.formatComplete()}');

  // Convert Western date to Myanmar
  final myanmarDate = MyanmarCalendar.fromWestern(1998, 7, 27);
  print('Myanmar: ${myanmarDate.formatMyanmar()}');
  print('Western: ${myanmarDate.formatWestern()}');
  final holidays = myanmarDate.otherHolidays;
  print('Other Holidays: $holidays');
}
