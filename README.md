# Myanmar Calendar Dart

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

A pure Dart package for Myanmar calendar calculation, conversion, formatting,
holiday rules, and astrological information.

## Installation

```sh
dart pub add myanmar_calendar_dart
```

## Quick Start

```dart
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  MyanmarCalendar.configure(
    language: Language.english,
    timezoneOffset: 6.5,
  );

  final today = MyanmarCalendar.today();
  print(today.formatComplete(includeAstro: true, includeHolidays: true));

  final converted = MyanmarCalendar.fromWestern(2024, 1, 1);
  print(converted.formatMyanmar('&y &M &P &ff'));
}
```

## What You Get

- Myanmar <-> Western date conversion
- Complete date object (Myanmar, Western, Shan, holidays, astro)
- Myanmar and Western date formatting with localization
- Built-in holidays with flexible disabling rules
- Custom holiday predicates
- Pluggable western holiday provider (Eid/Diwali/Chinese New Year)
- Chronicle and dynasty lookup APIs
- Cache controls for throughput and memory tuning

## Core API

### Main entry point

```dart
final date = MyanmarCalendar.today();
final fromWestern = MyanmarCalendar.fromWestern(2024, 4, 17);
final fromMyanmar = MyanmarCalendar.fromMyanmar(1385, 1, 1);

final complete = MyanmarCalendar.getCompleteDate(DateTime.now());
final astro = MyanmarCalendar.getAstroInfo(date.myanmarDate);
final holidays = MyanmarCalendar.getHolidayInfo(date.myanmarDate);
```

### Formatting

```dart
final myanmarText = date.formatMyanmar('&y &M &P &ff');
final westernText = date.formatWestern('%yyyy-%mm-%dd');

final localized = MyanmarCalendar.format(
  date,
  language: Language.myanmar,
);
```

### Myanmar format tokens

Common tokens:

- `&y` Myanmar year
- `&M` Myanmar month name
- `&P` moon phase
- `&ff` fortnight day (zero padded)
- `&W` weekday name
- `&N` year name cycle
- `&Nay` localized day word (`Nay`)
- `&Yat` localized date-day word (`Yat`)

```dart
final withYat = date.formatMyanmar('&d &Yat', Language.myanmar);
final withNay = date.formatMyanmar('&d &Nay', Language.myanmar);
```

### Validation and parsing

```dart
final valid = MyanmarCalendar.isValidMyanmar(1385, 10, 1);
final result = MyanmarCalendar.validateMyanmar(1385, 10, 1);

final parsedMyanmar = MyanmarCalendar.parseMyanmar('1385/10/1');
final parsedWestern = MyanmarCalendar.parseWestern('2024-01-01');
```

## Holiday Customization

### Add custom holidays

```dart
final myHoliday = CustomHoliday(
  id: 'team_day',
  name: 'Team Day',
  type: HolidayType.cultural,
  cacheVersion: 1,
  predicate: (myanmarDate, westernDate) {
    return westernDate.month == 7 && westernDate.day == 27;
  },
);

MyanmarCalendar.configure(customHolidays: [myHoliday]);
```

When you change predicate logic but keep the same holiday ID, increment
`cacheVersion` so cached holiday results are invalidated deterministically.

### Disable built-in holidays

```dart
MyanmarCalendar.configure(
  disabledHolidays: [HolidayId.independenceDay],
  disabledHolidaysByYear: {
    2026: [HolidayId.newYearDay],
  },
  disabledHolidaysByDate: {
    '2026-04-17': [HolidayId.myanmarNewYearDay],
  },
);
```

### Override western-calendar holiday lookup

Use this when you need custom or more accurate date tables for holidays like
Eid, Diwali, or Chinese New Year.

```dart
const provider = TableWesternHolidayProvider(
  singleDayRules: {
    HolidayId.diwali: {
      2045: WesternHolidayDate(month: 11, day: 2),
    },
  },
  multiDayRules: {
    HolidayId.eidAlFitr: {
      2045: [
        WesternHolidayDate(month: 1, day: 1),
        WesternHolidayDate(month: 1, day: 2),
      ],
    },
  },
);

MyanmarCalendar.configure(westernHolidayProvider: provider);
```

Use an empty provider to disable built-in table-based western holiday matches:

```dart
MyanmarCalendar.configure(
  westernHolidayProvider: const TableWesternHolidayProvider(),
);
```

For custom provider classes, override `cacheKey` with a stable value that
changes when the provider's rule table changes:

```dart
class MyHolidayProvider extends WesternHolidayProvider {
  const MyHolidayProvider({required this.version});

  final int version;

  @override
  String get cacheKey => 'my_holiday_provider:v$version';

  @override
  bool matches(HolidayId holidayId, int year, int month, int day) {
    // Implement your lookup logic
    return false;
  }
}
```

## Caching

Caching is enabled by default to improve repeated conversion and lookup paths.

### Configure cache profile

```dart
// Default profile
MyanmarCalendar.configureCache(const CacheConfig());

// Larger cache for heavy throughput
MyanmarCalendar.configureCache(const CacheConfig.highPerformance());

// Smaller cache with TTL
MyanmarCalendar.configureCache(const CacheConfig.memoryEfficient());

// Disable cache completely
MyanmarCalendar.configureCache(const CacheConfig.disabled());
```

### Cache operations

```dart
MyanmarCalendar.clearCache();
MyanmarCalendar.resetCacheStatistics();

final stats = MyanmarCalendar.getCacheStatistics();
print(stats);
```

### Notes

- Cache entries are isolated by configuration fingerprint to avoid cross-config collisions.
- Holiday and complete-date cache entries are language-aware.
- Custom holiday cache keys are based on stable `cacheKey/cacheVersion` values.
- Western holiday provider cache keys use `westernHolidayProvider.cacheKey`.
- If your workload is mostly one-off conversions, disabling cache is reasonable.

## Localization

Supported languages:

- `Language.english`
- `Language.myanmar`
- `Language.zawgyi`
- `Language.mon`
- `Language.shan`
- `Language.karen`

```dart
MyanmarCalendar.setLanguage(Language.myanmar);
```

## Chronicle APIs

```dart
final entries = MyanmarCalendar.getChronicleFor(DateTime(1752, 9, 14));
final dynasties = MyanmarCalendar.listDynasties();
final dynasty = MyanmarCalendar.getDynastyById('konbaung');
```

## Error Handling

```dart
try {
  MyanmarCalendar.fromWestern(2024, 2, 30); // invalid date
} on ArgumentError catch (e) {
  print(e);
}
```

## Development

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

### Reference parity fixtures

The package includes golden fixture tests that compare Dart outputs with
`reference/ceMmDateTime.js`.

Regenerate fixtures when algorithm behavior changes:

```sh
node tool/generate_reference_parity_fixtures.mjs
dart test test/parity_reference_test.dart
```

## Acknowledgements

The core calculation algorithms are based on the original work by
[Dr Yan Naing Aye](https://github.com/yan9a/mmcal).

## License

MIT License. See [LICENSE](LICENSE).

[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
