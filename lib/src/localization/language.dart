/// Supported languages for the Myanmar Calendar
enum Language {
  /// English
  english('en'),

  /// Myanmar
  myanmar('my'),

  /// Myanmar (Zawgyi)
  zawgyi('zawgyi'),

  /// Mon
  mon('mon'),

  /// Shan
  shan('shan'),

  /// Karen
  karen('karen');

  const Language(this.code);

  /// code
  final String code;

  /// The language for [code], or null if it isn't one.
  static Language? tryFromCode(String code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// The language for [code], or English if it isn't one. Use [tryFromCode]
  /// to tell an unknown code apart.
  static Language fromCode(String code) {
    return Language.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.english,
    );
  }
}
