import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Localization and Formatting', () {
    tearDown(MyanmarCalendar.reset);

    test('western month helpers are 1-based', () {
      expect(
        TranslationService.getWesternMonthName(1, Language.myanmar),
        'ဇန်နဝါရီ',
      );
      expect(
        TranslationService.getShortWesternMonthName(2, Language.myanmar),
        'ဖေ',
      );
      expect(TranslationService.getWesternMonthName(0, Language.myanmar), '0');
    });

    test('western short month token uses translated short month key', () {
      final date = MyanmarCalendar.fromWestern(2024, 2, 1);
      expect(
        date.formatWestern('%Mmm', Language.myanmar),
        TranslationService.getShortWesternMonthName(2, Language.myanmar),
      );
    });

    test(
      'western short weekday token uses dedicated short weekday translation',
      () {
        final date = MyanmarCalendar.fromWestern(2024, 1, 1); // Monday
        expect(
          date.formatWestern('%Www', Language.myanmar),
          TranslationService.getShortWeekdayName(2, Language.myanmar),
        );
      },
    );

    test('meridiem tokens are localized', () {
      final morning = MyanmarCalendar.fromWestern(2024, 1, 1, hour: 9);
      final evening = MyanmarCalendar.fromWestern(2024, 1, 1, hour: 18);

      expect(morning.formatWestern('%AA', Language.myanmar), 'နံနက်');
      expect(evening.formatWestern('%AA', Language.myanmar), 'ညနေ');
      expect(morning.formatWestern('%aa', Language.myanmar), 'နံနက်');
      expect(evening.formatWestern('%aa', Language.myanmar), 'ညနေ');
    });

    test('digit translation applies for mon language too', () {
      final date = MyanmarCalendar.fromWestern(2024, 2, 1);
      final expectedYear = '2024'
          .split('')
          .map((e) => TranslationService.translateTo(e, Language.mon))
          .join();

      expect(date.formatWestern('%yyyy', Language.mon), expectedYear);
    });

    test('formatMyanmar supports Yat token', () {
      final date = MyanmarCalendar.fromWestern(2024, 2, 1);
      final expected = TranslationService.translateTo('Yat', Language.myanmar);

      expect(date.formatMyanmar('&Yat', Language.myanmar), expected);
    });

    test('formatMyanmar supports Nay token without colliding with &N', () {
      final date = MyanmarCalendar.fromWestern(2024, 2, 1);
      final formatted = date.formatMyanmar('&Nay', Language.myanmar);
      final expected = TranslationService.translateTo('Nay', Language.myanmar);

      expect(formatted, expected);
      expect(formatted, isNot(contains('ay')));
    });
  });
}
