/// Custom exceptions for Myanmar Calendar package
///
/// This file contains all custom exception types used throughout the package
/// to provide better error handling and debugging experience.
library;

/// Base exception class for all Myanmar Calendar exceptions
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
  final dynamic originalError;

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

/// Exception thrown when an invalid Myanmar date is provided
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
           'suggestion': _getSuggestion(year, month, day),
           ...?details,
         },
       );

  /// The invalid year
  final int year;

  /// The invalid month
  final int month;

  /// The invalid day
  final int day;

  static String _getSuggestion(int year, int month, int day) {
    if (month < 1 || month > 13) {
      return 'Myanmar month must be between 1 and 13. Month 13 is the second Waso in watat years.';
    }
    if (day < 1 || day > 30) {
      return 'Myanmar day must be between 1 and 30.';
    }
    if (year < 0) {
      return 'Myanmar year must be a positive number.';
    }
    return 'Please verify the date components are valid for the Myanmar calendar system.';
  }
}

/// Exception thrown when an invalid Western date is provided
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
           'suggestion': _getSuggestion(year, month, day),
           ...?details,
         },
       );

  /// The invalid year
  final int year;

  /// The invalid month
  final int month;

  /// The invalid day
  final int day;

  static String _getSuggestion(int year, int month, int day) {
    if (month < 1 || month > 12) {
      return 'Western month must be between 1 and 12.';
    }
    if (day < 1 || day > 31) {
      return 'Western day must be between 1 and 31.';
    }
    if (year < 1) {
      return 'Western year must be a positive number.';
    }
    return 'Please verify the date is valid in the Gregorian calendar.';
  }
}

/// Exception thrown when date conversion fails
class DateConversionException extends MyanmarCalendarException {
  /// Create a new [DateConversionException]
  DateConversionException({
    required this.conversionType,
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) : super(
         message,
         originalError: originalError,
         stackTrace: stackTrace,
         details: {
           'conversionType': conversionType,
           'suggestion':
               'Verify input date is valid and within supported range.',
           ...?details,
         },
       );

  /// Create exception for Julian Day conversion failure
  factory DateConversionException.julianDay({
    required double julianDay,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DateConversionException(
      conversionType: 'Julian Day',
      message: 'Failed to convert Julian Day Number ($julianDay) to date',
      originalError: originalError,
      stackTrace: stackTrace,
      details: {'julianDay': julianDay},
    );
  }

  /// Create exception for Western to Myanmar conversion failure
  factory DateConversionException.westernToMyanmar({
    required int year,
    required int month,
    required int day,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DateConversionException(
      conversionType: 'Western to Myanmar',
      message:
          'Failed to convert Western date ($year/$month/$day) to Myanmar date',
      originalError: originalError,
      stackTrace: stackTrace,
      details: {'westernYear': year, 'westernMonth': month, 'westernDay': day},
    );
  }

  /// Create exception for Myanmar to Western conversion failure
  factory DateConversionException.myanmarToWestern({
    required int year,
    required int month,
    required int day,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DateConversionException(
      conversionType: 'Myanmar to Western',
      message:
          'Failed to convert Myanmar date ($year/$month/$day) to Western date',
      originalError: originalError,
      stackTrace: stackTrace,
      details: {'myanmarYear': year, 'myanmarMonth': month, 'myanmarDay': day},
    );
  }

  /// The type of conversion that failed
  final String conversionType;
}

/// Exception thrown when date parsing fails
class DateParseException extends MyanmarCalendarException {
  /// Create a new [DateParseException]
  DateParseException({
    required this.dateString,
    this.expectedFormat,
    String? customMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
         customMessage ?? 'Failed to parse date string: "$dateString"',
         originalError: originalError,
         stackTrace: stackTrace,
         details: {
           'dateString': dateString,
           'expectedFormat': ?expectedFormat,
           'suggestion': expectedFormat != null
               ? 'Ensure date string matches format: $expectedFormat'
               : 'Verify date string format is correct (e.g., "1385/10/1" for Myanmar dates)',
         },
       );

  /// The string that failed to parse
  final String dateString;

  /// The expected format
  final String? expectedFormat;
}

/// Exception thrown when calendar configuration is invalid
class InvalidConfigurationException extends MyanmarCalendarException {
  /// Create a new [InvalidConfigurationException]
  InvalidConfigurationException({
    required this.parameter,
    required this.value,
    String? customMessage,
    Map<String, dynamic>? details,
  }) : super(
         customMessage ??
             'Invalid configuration for parameter "$parameter": $value',
         details: {
           'parameter': parameter,
           'value': value,
           'suggestion': _getSuggestion(parameter, value),
           ...?details,
         },
       );

  /// The configuration parameter that is invalid
  final String parameter;

  /// The invalid value
  final dynamic value;

  static String _getSuggestion(String parameter, dynamic value) {
    switch (parameter) {
      case 'timezoneOffset':
        return 'Timezone offset must be between -12 and 14 hours. Myanmar Standard Time is 6.5.';
      case 'sasanaYearType':
        return 'Sasana year type must be 0, 1, or 2.';
      case 'calendarType':
        return 'Calendar type must be 0 (British) or 1 (Gregorian).';
      case 'language':
        return 'Language must be one of: myanmar, english, zawgyi, mon, shan, karen.';
      default:
        return 'Please check the documentation for valid values.';
    }
  }
}

/// Exception thrown when a date is out of supported range
class DateOutOfRangeException extends MyanmarCalendarException {
  /// Create a new [DateOutOfRangeException]
  DateOutOfRangeException({
    required this.date,
    this.minDate,
    this.maxDate,
    String? customMessage,
  }) : super(
         customMessage ?? 'Date $date is out of supported range',
         details: {
           'date': date.toIso8601String(),
           if (minDate != null) 'minDate': minDate.toIso8601String(),
           if (maxDate != null) 'maxDate': maxDate.toIso8601String(),
           'suggestion': _getSuggestion(minDate, maxDate),
         },
       );

  /// The date that is out of range
  final DateTime date;

  /// The minimum supported date
  final DateTime? minDate;

  /// The maximum supported date
  final DateTime? maxDate;

  static String _getSuggestion(DateTime? minDate, DateTime? maxDate) {
    if (minDate != null && maxDate != null) {
      return 'Date must be between ${minDate.year}-${minDate.month}-${minDate.day} and ${maxDate.year}-${maxDate.month}-${maxDate.day}.';
    } else if (minDate != null) {
      return 'Date must be on or after ${minDate.year}-${minDate.month}-${minDate.day}.';
    } else if (maxDate != null) {
      return 'Date must be on or before ${maxDate.year}-${maxDate.month}-${maxDate.day}.';
    }
    return 'Please use a date within the supported range.';
  }
}

/// Exception thrown when cache operation fails
class CacheException extends MyanmarCalendarException {
  /// Create a new [CacheException]
  CacheException({
    required this.operation,
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) : super(
         message,
         originalError: originalError,
         stackTrace: stackTrace,
         details: {'operation': operation, ...?details},
       );

  /// The cache operation that failed
  final String operation;
}

/// Exception thrown when astrological calculation fails
class AstrologicalCalculationException extends MyanmarCalendarException {
  /// Create a new [AstrologicalCalculationException]
  AstrologicalCalculationException({
    required this.calculationType,
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) : super(
         message,
         originalError: originalError,
         stackTrace: stackTrace,
         details: {'calculationType': calculationType, ...?details},
       );

  /// The type of calculation that failed
  final String calculationType;
}

/// Exception thrown when holiday calculation fails
class HolidayCalculationException extends MyanmarCalendarException {
  /// Create a new [HolidayCalculationException]
  HolidayCalculationException({
    required String message,
    this.year,
    this.month,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) : super(
         message,
         originalError: originalError,
         stackTrace: stackTrace,
         details: {
           'year': ?year,
           'month': ?month,
           ...?details,
         },
       );

  /// The year for which holiday calculation failed
  final int? year;

  /// The month for which holiday calculation failed
  final int? month;
}
