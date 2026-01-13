import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  // Configure the calendar (optional)
  MyanmarCalendar.configure(
    language: Language.english,
    timezoneOffset: 0, // Myanmar Standard Time
    customHolidays: [
      CustomHoliday(
        id: 'my_birthday',
        name: 'My Birthday',
        type: HolidayType.other,
        predicate: (myanmarDate, westernDate) {
          return westernDate.day == 27 && westernDate.month == 7;
        },
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
