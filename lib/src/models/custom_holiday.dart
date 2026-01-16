import 'package:myanmar_calendar_dart/src/models/myanmar_date.dart';
import 'package:myanmar_calendar_dart/src/models/western_date.dart';

/// Predicate function to determine if a date is a holiday
typedef HolidayPredicate =
    bool Function(
      MyanmarDate myanmarDate,
      WesternDate westernDate,
    );

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

/// Represents a custom holiday defined by the consumer
class CustomHoliday {
  /// Create a new custom holiday
  const CustomHoliday({
    required this.id,
    required this.name,
    required this.type,
    required this.predicate,
  });

  /// Unique identifier for the holiday
  final String id;

  /// Display name of the holiday (can be localized text)
  final String name;

  /// Type of holiday
  final HolidayType type;

  /// Function to check if a specific date is this holiday
  final HolidayPredicate predicate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomHoliday && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomHoliday(id: $id, name: $name, type: $type)';
}
