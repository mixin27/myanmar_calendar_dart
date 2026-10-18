## 3.0.0

A major release: calendar fixes checked day by day against the reference
`ceMmDateTime.js`, one code path for the static and instance APIs, typed
values and errors. See [MIGRATION.md](MIGRATION.md) for upgrading from 2.x.

### Breaking changes

- Invalid input throws typed exceptions (`InvalidMyanmarDateException`,
  `InvalidWesternDateException`, `DateParseException`,
  `InvalidConfigurationException`, all `MyanmarCalendarException`s) instead
  of `ArgumentError`. Exceptions that were never thrown are removed
  (`CacheException`, `DateConversionException`, `DateOutOfRangeException`,
  `AstrologicalCalculationException`, `HolidayCalculationException`)
- Myanmar dates that don't exist (day 30 of a 29-day month, First Waso in a
  common year) are rejected instead of moving to a neighbouring day
- `parseMyanmar` and `parseWestern` throw `DateParseException`; use
  `tryParseMyanmar` and `tryParseWestern` for null. Myanmar parsing is strict:
  the whole string, year first or day first, one separator
- `MyanmarDate.julianDayNumber` is the whole local day number of the day
- `getCacheStatistics()` returns `CalendarCacheStatistics` (`toMap()` for a
  map); `getTypedCacheStatistics` and `CalendarCache.getTypedStatistics` are
  removed
- `AIPromptService` moves to `package:myanmar_calendar_dart/ai.dart`;
  `MyanmarCalendar.generateAIPrompt` is removed
- `WesternHolidayProvider` is abstract: custom providers implement `cacheKey`
  and `matches`
- `convertMyanmarDates` takes `(year, month, day)` records
- `MyanmarDateTime.copyWith` drops the ignored `millisecond` and `isUtc`;
  `fromMillisecondsSinceEpoch` drops `isUtc`
- `createClient()` without a config uses the defaults, like
  `MyanmarCalendarClient()`, not the global configuration
- Clients validate their config and throw `InvalidConfigurationException`
  for an unknown language code or out-of-range values
- Holidays now match the reference (see Fixed), so some days gain or lose a
  holiday
- The Shan year turns over at Shan New Year (Nadaw 1)
- The minimum SDK is now Dart 3.8 (was 3.11), so more Flutter versions can use
  the package

### Fixed

- `isWatatYear` and `getYearType` returned the previous year's type
- `getMyanmarMonth` returned nothing for Tagu, for Kason in years whose New
  Year falls in Kason, and for Late Kason; this also fixes
  `getWesternDatesForMyanmarMonth`, `findAuspiciousDays` and sabbath lookups
- Day arithmetic (`addDays`, `addMonths`, `findNextMoonPhase`, `daysBetween`,
  `fromMyanmarDate`) applied the time-zone offset again on each step;
  `addMonths` keeps the day number across a month split by New Year
- `findMoonPhaseDatesInYear` left out Late Tagu and Late Kason
- `endOfMonth` used the Myanmar month's length as a Western day and threw in
  February
- Holidays match `cal_holiday`/`cal_holiday2`: Tazaungmon 14 is a public
  holiday; no extra "Holiday" on Thadingyut full moon; New Year's Day is a
  public holiday only 2018-2021 (an anniversary before); 30-31 December 2017
  and 31 December to 2021; the 2019-2021 substitute holidays; Mothers' Day
  from ME 1356; Easter and Good Friday from 1876
- Under the British calendar, years before 1753 use the Julian leap rule
  (29 February 1700 exists)
- `MyanmarCalendarClient()` without a config used the global configuration
- Facade helpers that take a date kept the global config instead of the
  date's; description helpers ignored the configured language
- Assigning `CalendarConfig.global` directly left stale services and caches
- The shared astro calculator kept writing to the old cache after
  `configureCache`
- Changing translations didn't reach cached holiday names
- Config equality treated equal per-year/per-date holiday maps as different
- `==` on `MyanmarDate`, `CompleteDate` and `ValidationResult` threw for other
  types; `WesternDate` had no value equality; `ValidationResult` hashed by
  identity
- Julian-day-to-time conversion could give times like 02:29:60
- `MyanmarCalendar.version` was wrong

### Added

- `MyanmarCalendarClient` has the whole API; `MyanmarCalendar` delegates to
  it, and most facade methods take an optional `config:`
- `HolidayInfo.entries` (`Holiday` with `HolidayId` or custom id, type and
  name), `has(id)`, `hasCustom(id)` and `ofType(type)`
- Typed values: `MoonPhase`, `MyanmarYearType`, `SabbathType`,
  `CalendarSystem`, `SasanaYearType`, with `phase`, `yearKind`, `sabbathType`,
  `calendarSystem`, `sasanaYear` and `dartWeekday` getters
- `MyanmarDateTime` implements `Comparable`
- `CalendarConfig.validate()`, `CalendarConfig.language`,
  `Language.tryFromCode`
- `TranslationService.resetTranslations()` and `revision`
- `MyanmarCalendar.getShanYearForDate`
- A runnable quick start, `example/main.dart`

### Performance

- Year info is computed once per year, config namespaces once per config
- Complete dates are cached per calendar day, so "now" hits the cache
- Smaller cache keys; digits translated in one pass; default complete-date
  cache of 400 days; `benchmark/month_grid_benchmark.dart`

### Tooling

- Day-by-day parity tests against `ceMmDateTime.js`: Myanmar dates both ways
  for 17,530 days, holidays for 2010-2035, astrology for 2020-2030
- CI tests on the Dart 3.8 floor and stable; publishing runs every check, a
  tag/version check and a dry run first
- `.pubignore` keeps the JS reference, tools and fixtures out of the package

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
