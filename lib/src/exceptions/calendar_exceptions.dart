/// Exceptions the package throws for bad input.
///
/// All of them are [MyanmarCalendarException]s, so one `on` clause catches
/// any of them. Mistakes in calling code (such as a reversed date range)
/// are still reported as `ArgumentError`.
library;

/// Base class for the package's exceptions.
abstract class MyanmarCalendarException implements Exception {
  /// Create a new [MyanmarCalendarException]
  const MyanmarCalendarException(
    this.message, {
    this.details,
    this.originalError,
    this.stackTrace,
  });

  /// The error message
  final String message;

  /// Optional details about the error
  final Map<String, dynamic>? details;

  /// Optional original error that caused this exception
  final Object? originalError;

  /// Optional stack trace
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    return buffer.toString();
  }
}

/// A Myanmar date that doesn't exist, or is outside the supported range.
class InvalidMyanmarDateException extends MyanmarCalendarException {
  /// Create a new [InvalidMyanmarDateException]
  InvalidMyanmarDateException({
    required this.year,
    required this.month,
    required this.day,
    String? customMessage,
    Map<String, dynamic>? details,
  }) : super(
         customMessage ??
             'Invalid Myanmar date: Year $year, Month $month, Day $day',
         details: {
           'year': year,
           'month': month,
           'day': day,
           'suggestion': _getSuggestion(month, day),
           ...?details,
         },
       );

  /// The invalid year
  final int year;

  /// The invalid month
  final int month;

  /// The invalid day
  final int day;

  static String _getSuggestion(int month, int day) {
    if (month < 0 || month > 14) {
      return 'Myanmar months are 0 (First Waso, watat years only) to 12, '
          'plus 13 (Late Tagu) and 14 (Late Kason).';
    }
    if (day < 1 || day > 30) {
      return 'Myanmar days are 1 to 30, and odd months have 29.';
    }
    return 'Check that the month exists in that year and has that day.';
  }
}

/// A Western date or time that doesn't exist, or is outside the supported
/// range.
class InvalidWesternDateException extends MyanmarCalendarException {
  /// Create a new [InvalidWesternDateException]
  InvalidWesternDateException({
    required this.year,
    required this.month,
    required this.day,
    String? customMessage,
    Map<String, dynamic>? details,
  }) : super(
         customMessage ??
             'Invalid Western date: Year $year, Month $month, Day $day',
         details: {
           'year': year,
           'month': month,
           'day': day,
           'suggestion': _getSuggestion(month, day),
           ...?details,
         },
       );

  /// The invalid year
  final int year;

  /// The invalid month
  final int month;

  /// The invalid day
  final int day;

  static String _getSuggestion(int month, int day) {
    if (month < 1 || month > 12) {
      return 'Western month must be between 1 and 12.';
    }
    if (day < 1 || day > 31) {
      return 'Western day must be between 1 and 31.';
    }
    return 'Check the number of days in that month and year.';
  }
}

/// A date string that couldn't be parsed. It is also a [FormatException],
/// like the errors from `DateTime.parse`.
class DateParseException extends MyanmarCalendarException
    implements FormatException {
  /// Create a new [DateParseException]
  DateParseException({
    required this.dateString,
    this.expectedFormat,
    String? customMessage,
    super.originalError,
    super.stackTrace,
  }) : super(
         customMessage ?? 'Failed to parse date string: "$dateString"',
         details: {
           'dateString': dateString,
           'expectedFormat': ?expectedFormat,
         },
       );

  /// The string that failed to parse
  final String dateString;

  /// The expected format
  final String? expectedFormat;

  @override
  String get source => dateString;

  @override
  int? get offset => null;
}

/// A configuration value outside its allowed range.
class InvalidConfigurationException extends MyanmarCalendarException {
  /// Create a new [InvalidConfigurationException]
  InvalidConfigurationException({
    required this.parameter,
    required this.value,
    String? customMessage,
  }) : super(
         customMessage ??
             'Invalid configuration for parameter "$parameter": $value',
         details: {
           'parameter': parameter,
           'value': value,
           'suggestion': _getSuggestion(parameter),
         },
       );

  /// The configuration parameter that is invalid
  final String parameter;

  /// The invalid value
  final Object? value;

  static String _getSuggestion(String parameter) => switch (parameter) {
    'timezoneOffset' =>
      'Timezone offset must be between -12 and 14 hours. Myanmar Time is 6.5.',
    'sasanaYearType' => 'Sasana year type must be 0, 1 or 2.',
    'calendarType' =>
      'Calendar type must be 0 (British), 1 (Gregorian) or 2 (Julian).',
    'gregorianStart' => 'gregorianStart must be a positive Julian day.',
    'defaultLanguage' =>
      'Use one of the Language codes: en, my, zawgyi, mon, shan, karen.',
    _ => 'Please check the documentation for valid values.',
  };
}
