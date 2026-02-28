import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/localization/translation_service.dart';

/// Descriptive information for Myanmar astrological elements
class AstroDetails {
  static const Language _fallbackLanguage = Language.english;

  /// Get description for Nakhat type
  static String getNakhatDescription(String nakhat, {Language? language}) {
    final currentLanguage = language ?? _fallbackLanguage;
    final key = 'desc_${nakhat.toLowerCase()}';
    if (TranslationService.hasTranslation(key)) {
      return TranslationService.translateTo(key, currentLanguage);
    }
    return TranslationService.translateTo(
      'desc_not_available',
      currentLanguage,
    );
  }

  /// Get characteristics for Mahabote type
  static String getMahaboteCharacteristics(
    String mahabote, {
    Language? language,
  }) {
    final currentLanguage = language ?? _fallbackLanguage;
    final key = 'desc_${mahabote.toLowerCase()}';
    if (TranslationService.hasTranslation(key)) {
      return TranslationService.translateTo(key, currentLanguage);
    }
    return TranslationService.translateTo(
      'desc_not_available',
      currentLanguage,
    );
  }

  /// Get description for astrological days
  static String getAstrologicalDayDescription(
    String dayName, {
    Language? language,
  }) {
    final currentLanguage = language ?? _fallbackLanguage;
    final key = 'desc_${dayName.toLowerCase()}';
    if (TranslationService.hasTranslation(key)) {
      return TranslationService.translateTo(key, currentLanguage);
    }
    return TranslationService.translateTo(
      'desc_not_available',
      currentLanguage,
    );
  }
}
