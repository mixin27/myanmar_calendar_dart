import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/localization/translation_service.dart';
import 'package:test/test.dart';

void main() {
  group('Translation Completeness', () {
    test(
      'every translation key includes values for all supported languages',
      () {
        for (final key in TranslationService.allKeys) {
          final translations = TranslationService.getTranslations(key);
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
