import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MyanmarCalendarClient', () {
    test('isolates default language per client instance', () {
      final englishClient = MyanmarCalendarClient(
        config: const CalendarConfig(defaultLanguage: 'en'),
      );
      final myanmarClient = MyanmarCalendarClient(
        config: const CalendarConfig(defaultLanguage: 'my'),
      );
      final date = DateTime(2024, 1, 4);

      final english = englishClient.getCompleteDate(date);
      final myanmar = myanmarClient.getCompleteDate(date);

      expect(english.publicHolidays, contains('Independence'));
      expect(
        myanmar.publicHolidays,
        contains(
          TranslationService.translateTo('Independence', Language.myanmar),
        ),
      );
    });

    test('provides typed Myanmar year metadata', () {
      final client = MyanmarCalendarClient();
      final info = client.getMyanmarYearInfo(1385);

      expect(info.year, 1385);
      expect(info.yearType, inInclusiveRange(0, 2));
      expect(info.toMap()['year'], 1385);
    });

    test(
      'copyWith can change holiday rules without mutating source client',
      () {
        final baseClient = MyanmarCalendarClient();
        final withRuleClient = baseClient.copyWith(
          customHolidayRules: [
            CustomHoliday.westernDate(
              id: 'team_day',
              name: 'Team Day',
              type: HolidayType.other,
              month: 7,
              day: 27,
            ),
          ],
        );
        final date = DateTime(2024, 7, 27);

        final base = baseClient.getCompleteDate(date);
        final withRule = withRuleClient.getCompleteDate(date);

        expect(base.holidays.otherHolidays, isNot(contains('Team Day')));
        expect(withRule.holidays.otherHolidays, contains('Team Day'));
      },
    );

    test('keeps cache statistics isolated with independent caches', () {
      final clientA = MyanmarCalendarClient();
      final clientB = MyanmarCalendarClient();
      final date = DateTime(2024, 1, 4);

      clientA
        ..resetCacheStatistics()
        ..getCompleteDate(date)
        ..getCompleteDate(date);
      clientB.resetCacheStatistics();

      final statsA = clientA.getTypedCacheStatistics();
      final statsB = clientB.getTypedCacheStatistics();

      expect(statsA.totalRequests, greaterThan(0));
      expect(statsA.hits, greaterThan(0));
      expect(statsB.totalRequests, 0);
    });
  });
}
