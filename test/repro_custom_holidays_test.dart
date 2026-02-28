import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Reproduction of Custom Holidays Cache Issue', () {
    tearDown(() {
      MyanmarCalendar.reset();
      MyanmarCalendar.clearCache();
    });

    test('cache collision between different custom holidays', () {
      final date15 = DateTime(2024, 1, 15);

      // 1. First call with custom holiday
      final holiday = CustomHoliday.westernDate(
        id: 'h1',
        name: 'Holiday 1',
        type: HolidayType.other,
        month: 1,
        day: 15,
      );
      MyanmarCalendar.configure(customHolidayRules: [holiday]);
      final d1 = MyanmarCalendar.fromDateTime(date15);
      expect(d1.otherHolidays, contains('Holiday 1'));

      // 2. Second call with DIFFERENT custom holiday for SAME date
      final holiday2 = CustomHoliday.westernDate(
        id: 'h2',
        name: 'Holiday 2',
        type: HolidayType.other,
        month: 1,
        day: 15,
      );
      MyanmarCalendar.configure(customHolidayRules: [holiday2]);
      final d2 = MyanmarCalendar.fromDateTime(date15);

      // If caching is broken, this will contain 'Holiday 1' instead of 'Holiday 2'
      // or it might contain both if not cleared, but here we expect ONLY 'Holiday 2'
      expect(
        d2.otherHolidays,
        contains('Holiday 2'),
        reason: 'Should have Holiday 2',
      );
      expect(
        d2.otherHolidays,
        isNot(contains('Holiday 1')),
        reason: 'Should NOT have Holiday 1',
      );
    });

    test('MyanmarCalendar.getHolidayInfo should support custom holidays', () {
      final holiday = CustomHoliday.westernDate(
        id: 'h1',
        name: 'Holiday 1',
        type: HolidayType.other,
        month: 1,
        day: 15,
      );
      MyanmarCalendar.configure(customHolidayRules: [holiday]);

      final mDate = MyanmarCalendar.fromWestern(2024, 1, 15).myanmarDate;
      final hInfo = MyanmarCalendar.getHolidayInfo(mDate);

      expect(
        hInfo.otherHolidays,
        contains('Holiday 1'),
        reason: 'MyanmarCalendar.getHolidayInfo should return custom holidays',
      );
    });

    test('should reflect changes even if holiday ID is reused', () {
      final date15 = DateTime(2024, 1, 15);

      // 1. Initial configuration
      final holidayV1 = CustomHoliday.westernDate(
        id: 'reuse_id',
        name: 'V1',
        type: HolidayType.other,
        month: 1,
        day: 15,
      );
      MyanmarCalendar.configure(customHolidayRules: [holidayV1]);
      expect(
        MyanmarCalendar.fromDateTime(date15).otherHolidays,
        contains('V1'),
      );

      // 2. Modify with same ID but different name
      final holidayV2 = CustomHoliday.westernDate(
        id: 'reuse_id',
        name: 'V2',
        type: HolidayType.other,
        month: 1,
        day: 15,
      );
      MyanmarCalendar.configure(customHolidayRules: [holidayV2]);

      // Should show V2 if cache was cleared correctly
      expect(
        MyanmarCalendar.fromDateTime(date15).otherHolidays,
        contains('V2'),
      );
      expect(
        MyanmarCalendar.fromDateTime(date15).otherHolidays,
        isNot(contains('V1')),
      );
    });
  });
}
