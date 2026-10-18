import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/localization/translation_data.dart';
import 'package:myanmar_calendar_dart/src/localization/translation_service.dart';
import 'package:test/test.dart';

void main() {
  group('Translation Completeness', () {
    test(
      'every translation key includes values for all supported languages',
      () {
        // The raw table: TranslationService fills gaps with English, so
        // checking its output could never fail.
        for (final key in kTranslationData.keys) {
          final translations = kTranslationData[key];
          expect(
            translations,
            isNotNull,
            reason: 'Missing translation map for "$key"',
          );

          for (final language in Language.values) {
            expect(
              translations!.containsKey(language),
              isTrue,
              reason: 'Missing ${language.code} translation for "$key"',
            );

            final value = translations[language];
            if (_knownGaps.contains('${language.code}:$key')) continue;
            expect(
              value,
              isNotNull,
              reason: 'Null ${language.code} translation for "$key"',
            );
            expect(
              value!.trim(),
              isNotEmpty,
              reason: 'Empty ${language.code} translation for "$key"',
            );
          }
        }
      },
    );

    test('all translation keys are non-empty', () {
      for (final key in TranslationService.allKeys) {
        expect(key.trim(), isNotEmpty);
      }
    });
  });
}

/// Values still to be supplied; they fall back to English for now. Remove an
/// entry once its translation is added.
const _knownGaps = {
  'karen:Ku', // the year suffix (ခု)
};
