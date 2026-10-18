/// Typed values for the calendar's numeric codes. The int fields remain;
/// these getters make code read better and catch typos.
library;

/// The phase of the moon on a Myanmar day (the int `moonPhase` codes).
enum MoonPhase {
  /// Waxing moon (လဆန်း), code 0.
  waxing,

  /// Full moon (လပြည့်), code 1.
  fullMoon,

  /// Waning moon (လဆုတ်), code 2.
  waning,

  /// New moon (လကွယ်), code 3.
  newMoon;

  /// The phase for a `moonPhase` code.
  static MoonPhase fromCode(int code) => values[code];

  /// The int code used by `MyanmarDate.moonPhase`.
  int get code => index;
}

/// The kind of Myanmar year (the int `yearType` codes).
enum MyanmarYearType {
  /// No intercalary month, code 0.
  common,

  /// An intercalary month (First Waso), code 1.
  littleWatat,

  /// An intercalary month and an extra day in Nayon, code 2.
  bigWatat;

  /// The year type for a `yearType` code.
  static MyanmarYearType fromCode(int code) => values[code];

  /// The int code used by `MyanmarDate.yearType`.
  int get code => index;

  /// Whether the year has an intercalary month.
  bool get isWatat => this != common;
}

/// Whether a day is a Buddhist sabbath (ဥပုသ်).
enum SabbathType {
  /// Neither a sabbath nor its eve.
  none,

  /// A sabbath day.
  sabbath,

  /// The day before a sabbath.
  sabbathEve,
}

/// The Western calendar system (the int `CalendarConfig.calendarType`).
enum CalendarSystem {
  /// Julian before 14 September 1752, Gregorian after; code 0.
  british,

  /// Gregorian throughout, code 1.
  gregorian,

  /// Julian throughout, code 2.
  julian;

  /// The system for a `calendarType` code.
  static CalendarSystem fromCode(int code) => values[code];

  /// The int code used by `CalendarConfig.calendarType`.
  int get code => index;
}

/// How the Sasana (Buddhist era) year is counted (the int
/// `CalendarConfig.sasanaYearType`).
enum SasanaYearType {
  /// It follows the sun only, ignoring the moon; code 0.
  solar,

  /// It starts on the first day of Tagu, code 1.
  firstOfTagu,

  /// It starts on Kason full moon, code 2.
  kasonFullMoon;

  /// The type for a `sasanaYearType` code.
  static SasanaYearType fromCode(int code) => values[code];

  /// The int code used by `CalendarConfig.sasanaYearType`.
  int get code => index;
}

/// Converts the package's weekday codes (0 Saturday … 6 Friday) to
/// `DateTime.weekday` (1 Monday … 7 Sunday).
int dartWeekdayFromMyanmar(int weekday) => (weekday + 5) % 7 + 1;
