import 'package:meta/meta.dart';
import 'package:myanmar_calendar_dart/src/localization/language.dart';
import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';

/// Legacy predicate function to determine if a date is a holiday.
///
/// Deprecated in favor of [CustomHolidayMatcher] using [CustomHolidayContext].
typedef HolidayPredicate =
    bool Function(
      MyanmarDate myanmarDate,
      WesternDate westernDate,
    );

/// Predicate function evaluated against a typed holiday context.
typedef CustomHolidayMatcher = bool Function(CustomHolidayContext context);

/// Type of holiday
enum HolidayType {
  /// Public holiday (Gazetted)
  public,

  /// Religious holiday
  religious,

  /// Cultural holiday
  cultural,

  /// Other significant day
  other,

  /// Myanmar anniversary day
  myanmarAnniversary,

  /// Other anniversary day (Western/International)
  otherAnniversary,
}

/// Evaluation context for custom holiday rules.
@immutable
class CustomHolidayContext {
  /// Creates a [CustomHolidayContext].
  const CustomHolidayContext({
    required this.myanmarDate,
    required this.westernDate,
  });

  /// Myanmar calendar date.
  final MyanmarDate myanmarDate;

  /// Western calendar date.
  final WesternDate westernDate;
}

/// Represents a custom holiday rule defined by the consumer.
class CustomHoliday {
  /// Creates a custom holiday rule.
  ///
  /// Use [matcher] for new code. [predicate] is kept for backward compatibility.
  const CustomHoliday({
    required this.id,
    required this.name,
    required this.type,
    this.localizedNames = const {},
    CustomHolidayMatcher? matcher,
    @Deprecated(
      'Use matcher or a builder like CustomHoliday.westernDate / '
      'CustomHoliday.myanmarDate.',
    )
    HolidayPredicate? predicate,
    String? cacheKey,
    this.cacheVersion = 1,
  }) : _matcher = matcher,
       _legacyPredicate = predicate,
       cacheKey = (cacheKey == null || cacheKey == '') ? id : cacheKey,
       assert(
         matcher != null || predicate != null,
         'Either matcher or predicate must be provided',
       ),
       assert(cacheVersion > 0, 'cacheVersion must be greater than zero');

  /// Creates a fixed-date western holiday rule.
  ///
  /// This supports optional [year], [fromYear], and [toYear] restrictions.
  factory CustomHoliday.westernDate({
    required String id,
    required String name,
    required HolidayType type,
    required int month,
    required int day,
    int? year,
    int? fromYear,
    int? toYear,
    Map<Language, String> localizedNames = const {},
    String? cacheKey,
    int cacheVersion = 1,
  }) {
    assert(month >= 1 && month <= 12, 'month must be between 1 and 12');
    assert(day >= 1 && day <= 31, 'day must be between 1 and 31');
    assert(
      year == null || (fromYear == null && toYear == null),
      'year cannot be combined with fromYear/toYear',
    );
    assert(
      fromYear == null || toYear == null || fromYear <= toYear,
      'fromYear must be less than or equal to toYear',
    );

    final normalizedCacheKey =
        cacheKey ??
        'western'
            ':m${month.toString().padLeft(2, '0')}'
            ':d${day.toString().padLeft(2, '0')}'
            ':y${year ?? '*'}'
            ':fy${fromYear ?? '*'}'
            ':ty${toYear ?? '*'}';

    return CustomHoliday(
      id: id,
      name: name,
      type: type,
      localizedNames: localizedNames,
      matcher: (context) {
        final western = context.westernDate;
        if (western.month != month || western.day != day) return false;
        if (year != null && western.year != year) return false;
        if (fromYear != null && western.year < fromYear) return false;
        if (toYear != null && western.year > toYear) return false;
        return true;
      },
      cacheKey: normalizedCacheKey,
      cacheVersion: cacheVersion,
    );
  }

  /// Creates a fixed-date Myanmar holiday rule.
  ///
  /// This supports optional [year], [fromYear], and [toYear] restrictions.
  factory CustomHoliday.myanmarDate({
    required String id,
    required String name,
    required HolidayType type,
    required int month,
    required int day,
    int? year,
    int? fromYear,
    int? toYear,
    Map<Language, String> localizedNames = const {},
    String? cacheKey,
    int cacheVersion = 1,
  }) {
    assert(month >= 0 && month <= 14, 'month must be between 0 and 14');
    assert(day >= 1 && day <= 30, 'day must be between 1 and 30');
    assert(
      year == null || (fromYear == null && toYear == null),
      'year cannot be combined with fromYear/toYear',
    );
    assert(
      fromYear == null || toYear == null || fromYear <= toYear,
      'fromYear must be less than or equal to toYear',
    );

    final normalizedCacheKey =
        cacheKey ??
        'myanmar'
            ':m${month.toString().padLeft(2, '0')}'
            ':d${day.toString().padLeft(2, '0')}'
            ':y${year ?? '*'}'
            ':fy${fromYear ?? '*'}'
            ':ty${toYear ?? '*'}';

    return CustomHoliday(
      id: id,
      name: name,
      type: type,
      localizedNames: localizedNames,
      matcher: (context) {
        final myanmar = context.myanmarDate;
        if (myanmar.month != month || myanmar.day != day) return false;
        if (year != null && myanmar.year != year) return false;
        if (fromYear != null && myanmar.year < fromYear) return false;
        if (toYear != null && myanmar.year > toYear) return false;
        return true;
      },
      cacheKey: normalizedCacheKey,
      cacheVersion: cacheVersion,
    );
  }

  /// Legacy constructor name kept for clearer migration messaging.
  @Deprecated(
    'Use CustomHoliday(...) with matcher or factory helpers '
    '(CustomHoliday.westernDate / CustomHoliday.myanmarDate).',
  )
  factory CustomHoliday.legacy({
    required String id,
    required String name,
    required HolidayType type,
    required HolidayPredicate predicate,
    String? cacheKey,
    int cacheVersion = 1,
  }) {
    return CustomHoliday(
      id: id,
      name: name,
      type: type,
      predicate: predicate,
      cacheKey: cacheKey,
      cacheVersion: cacheVersion,
    );
  }

  final CustomHolidayMatcher? _matcher;
  final HolidayPredicate? _legacyPredicate;

  /// Unique identifier for the holiday.
  ///
  /// Two [CustomHoliday] instances with the same [id] are treated as equal.
  final String id;

  /// Default holiday label (English / fallback).
  final String name;

  /// Optional localized labels.
  ///
  /// When a language does not exist in this map, [name] is used.
  final Map<Language, String> localizedNames;

  /// Type of holiday.
  final HolidayType type;

  /// Legacy predicate API.
  @Deprecated(
    'Use matcher or a builder like CustomHoliday.westernDate / '
    'CustomHoliday.myanmarDate.',
  )
  HolidayPredicate? get predicate => _legacyPredicate;

  /// Function to check if a specific date is this holiday.
  bool matches(CustomHolidayContext context) {
    final matcher = _matcher;
    if (matcher != null) return matcher(context);

    final legacyPredicate = _legacyPredicate;
    if (legacyPredicate == null) return false;
    return legacyPredicate(context.myanmarDate, context.westernDate);
  }

  /// Resolve holiday display name for [language].
  String nameFor(Language language) {
    return localizedNames[language] ?? localizedNames[Language.english] ?? name;
  }

  /// Stable name fingerprint for cache keys.
  String get nameFingerprint {
    final entries = localizedNames.entries.toList()
      ..sort((a, b) => a.key.code.compareTo(b.key.code));
    final localizedFingerprint = entries
        .map((entry) => '${entry.key.code}:${entry.value}')
        .join(',');
    return 'default:$name|localized:$localizedFingerprint';
  }

  /// Deterministic key used for cache fingerprinting.
  ///
  /// Defaults to [id].
  final String cacheKey;

  /// Cache-busting version for this holiday definition.
  ///
  /// Increase this when matcher logic changes while [id] remains the same.
  final int cacheVersion;

  /// Stable matcher fingerprint used in cache keys.
  String get cacheFingerprint => '$cacheKey:v$cacheVersion';

  /// Full stable descriptor used to fingerprint this rule in caches.
  String get cacheDescriptor =>
      '$cacheFingerprint:type${type.index}:name{$nameFingerprint}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomHoliday && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CustomHoliday('
        'id: $id, '
        'name: $name, '
        'type: $type, '
        'cacheKey: $cacheKey, '
        'cacheVersion: $cacheVersion'
        ')';
  }
}
