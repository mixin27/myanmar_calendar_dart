## Unreleased

- Fix `MyanmarCalendarClient()` without a config computing with the global
  configuration while reporting the defaults
- Fix complete-date cache keys that could collide for sub-second times
- Fix `MyanmarCalendar.version` reporting 2.0.1 in the 2.0.2 release
- Correct the `CalendarConfig.timezoneOffset` docs: it decides which calendar
  day an instant falls on

## 2.0.2

- Fix `getCompleteDate` and `westernToMyanmar` returning the next Myanmar day
  for times from 17:30 onwards (the offset was applied twice)
- Fix `MyanmarDateTime.now()` running 6½ hours behind (UTC fields were read as
  Myanmar Time), which gave the previous day before 06:30
- Treat UTC `DateTime`s, epoch values and `fromTimestamp` as instants, and make
  `toUtc()`, `millisecondsSinceEpoch` and `microsecondsSinceEpoch` return the
  real instant whatever the device's time zone
- Fix Julian-day-to-time conversion giving `hh:59:60`-style times; values are
  snapped to the nearest second first
- Fix the complete-date cache confusing a UTC value with a local value at the
  same instant
- Guard exact local midnight against floating-point rounding into the previous
  Myanmar day
- Add `getCompleteDateFor(year, month, day)` on `MyanmarCalendar`, the client
  and the service, for time-zone-free calendar-day lookups
- Add an optional `config` to `MyanmarCalendar.getCompleteDate`,
  `getCompleteDateFor`, `getCompleteDates`, `getHolidayInfo`,
  `getMyanmarMonth`, `getWesternDatesForMyanmarMonth` and `findAuspiciousDays`
  to use another time zone or holiday set for one call without changing the
  global configuration
- Deprecate the `isUtc` flag of `fromMillisecondsSinceEpoch`; epoch values are
  always instants

## 2.0.1

- Fix translation data for special months such as `Late Tagu`, `Late Kason` and `First Waso`
- Fix short form of months and weekdays with appropriate translations

## 2.0.0

- Refactor package documentation for Dart-only usage
- Replace CI runtime with pure Dart commands and add `dart test` gate
- Improve cache system:
  - O(1) LRU bookkeeping with `LinkedHashMap`
  - cache namespace isolation by configuration
  - language-aware complete-date/holiday cache entries
  - fix `clearAll()` to clear Shan-date cache entries
- Harden date validation for invalid Western month/day combinations
- Fix Sasana year calculation for `sasanaYearType=1` on late months
- Add pluggable `WesternHolidayProvider` and table-driven default rules
- Refactor custom holiday system:
  - add typed `CustomHolidayContext` matcher API
  - add `CustomHoliday.westernDate` and `CustomHoliday.myanmarDate` builders
  - add localized custom holiday names via `localizedNames`
  - remove legacy `predicate`-based API in favor of matcher/context
  - remove `CustomHoliday.legacy(...)`
  - keep rule-oriented management APIs based on `customHolidayRules`
- Add instance-first API:
  - add `MyanmarCalendarClient` for isolated runtime/config/cache usage
  - add `MyanmarCalendar.createClient(...)`
- Add typed Myanmar-year metadata API:
  - add `MyanmarYearInfo`
  - add `DateConverter.getMyanmarYearInfo(...)`
  - remove map-based `DateConverter.getYearInfo(...)`
- Remove deprecated aliases:
  - remove `MyanmarCalendar.addCustomHoliday(...)`
  - remove `MyanmarCalendar.addCustomHolidays(...)`
  - remove `MyanmarCalendar.removeCustomHoliday(...)`
  - remove `MyanmarCalendar.clearCustomHolidays(...)`
  - remove `customHolidays` alias parameter from `MyanmarCalendar.configure(...)`
  - remove `customHolidays` alias parameter from `CalendarConfig.copyWith(...)`
- Remove deprecated translation/service legacy methods:
  - remove `TranslationService.currentLanguage`
  - remove `TranslationService.setLanguage(...)`
  - remove `TranslationService.translate(...)`
  - remove `MyanmarCalendarService.setLanguage(...)`
  - remove `MyanmarCalendarService.currentLanguage`
- Make `HolidayInfo` and `AstroInfo` list fields immutable
- Improve `CompleteDate` model consistency:
  - include Shan date in equality/hashCode
  - include `monthType` in serialized Myanmar map
  - accept integer JDN values in `fromMap`
- Fix publish workflow tag trigger pattern
- Tighten public API surface by removing internal service/utils exports
- Add JS parity regression fixtures against `reference/ceMmDateTime.js`
- Add regression tests for cache isolation, localization cache behavior,
  invalid dates, and model immutability

## 1.1.5

- Add `disabledHolidaysByDate` config

## 1.1.4

- Add support for flexible built-in holidays. Now you can disable specific built-in holidays for specific years.

## 1.1.3

- Fixed custom holidays cache
- Fixed `CompleteDate` isToday wrong condition

## 1.1.2

- Refactor CalendarConfig to use factory constructors for global config access without circular dependency
- Fixed global config access issue

## 1.1.1

- Fix custom holidays are not passed down to calendar service

## 1.1.0

- Add custom holiday support
- TimezoneOffset config now effective

## 1.0.1

- Export Shan date related classes
- Export Chronicle related classes

## 1.0.0

- Initial release.

### Features

- **Complete Myanmar Calendar System**: Full support for Myanmar calendar with accurate date conversions
- **Astrological Calculations**: Buddhist era, sabbath days, moon phases, yatyaza, pyathada, and more
- **Multi-language Support**: Myanmar, English, Mon, Shan, Karen, and Zawgyi scripts
- **Holiday Support**: Myanmar public holidays, religious days, and cultural events
- **Highly Configurable**: Calendar system, timezone, language, and holiday settings
- **Date Arithmetic**: Easy date calculations and manipulations
- **Type Safe**: Full null safety support with comprehensive error handling
- **Custom Exceptions**: Detailed error messages with recovery suggestions
