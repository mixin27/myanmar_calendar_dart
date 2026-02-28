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
  includeAstro: true,
  includeHolidays: true,
);
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
  predicate: (myanmarDate, westernDate) {
    return westernDate.month == 7 && westernDate.day == 27;
  },
);

MyanmarCalendar.configure(customHolidays: [myHoliday]);
```

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

## Acknowledgements

The core calculation algorithms are based on the original work by
[Dr Yan Naing Aye](https://github.com/yan9a/mmcal).

## License

MIT License. See [LICENSE](LICENSE).

[dart_install_link]: https://dart.dev/get-dart
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
