## Unreleased

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
