import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  setUp(MyanmarCalendar.reset);
  tearDown(TranslationService.resetTranslations);

  test('clients reject an unknown language code', () {
    // Ranges are also asserted by the constructor; an unknown language code
    // is only caught here.
    expect(
      () => MyanmarCalendarClient(
        config: const CalendarConfig(defaultLanguage: 'mm'),
      ),
      throwsA(
        isA<InvalidConfigurationException>().having(
          (e) => e.parameter,
          'parameter',
          'defaultLanguage',
        ),
      ),
    );
    expect(
      const CalendarConfig(defaultLanguage: 'my').language,
      Language.myanmar,
    );
    expect(Language.tryFromCode('mm'), isNull);
  });

  test('configs built separately with the same rules are equal', () {
    // Not const: the point is two separately built configs.
    // ignore: prefer_const_constructors
    CalendarConfig make() => CalendarConfig(
      disabledHolidaysByYear: {
        2026: [HolidayId.christmasDay],
      },
    );
    expect(make(), make());
    expect(make().hashCode, make().hashCode);
  });

  test('changing a translation reaches cached results', () {
    final first = MyanmarCalendar.getCompleteDateFor(
      2026,
      12,
      25,
      language: Language.english,
    );
    expect(first.allHolidays, contains('Christmas'));

    TranslationService.addTranslation('Christmas', Language.english, 'Xmas');
    final second = MyanmarCalendar.getCompleteDateFor(
      2026,
      12,
      25,
      language: Language.english,
    );
    expect(second.allHolidays, contains('Xmas'));

    TranslationService.resetTranslations();
    expect(
      MyanmarCalendar.getCompleteDateFor(
        2026,
        12,
        25,
        language: Language.english,
      ).allHolidays,
      contains('Christmas'),
    );
  });

  test('digits are translated in one pass', () {
    final date = MyanmarCalendar.fromMyanmar(1388, 7, 15).myanmarDate;
    expect(
      MyanmarCalendar.formatMyanmar(
        date,
        pattern: '&y',
        language: Language.myanmar,
      ),
      '၁၃၈၈',
    );
    expect(
      MyanmarCalendar.formatMyanmar(
        date,
        pattern: '&y',
        language: Language.english,
      ),
      '1388',
    );
  });
}
