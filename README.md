# Myanmar Calendar Dart

[![ci](https://github.com/mixin27/myanmar_calendar_dart/actions/workflows/main.yaml/badge.svg)](https://github.com/mixin27/myanmar_calendar_dart/actions/workflows/main.yaml)
[![pub package](https://img.shields.io/pub/v/myanmar_calendar_dart.svg)](https://pub.dev/packages/myanmar_calendar_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A pure Dart package for Myanmar calendar calculation, conversion, formatting,
holiday rules, and astrological information.

Results are checked day by day against the reference implementation,
[`ceMmDateTime.js`](https://github.com/yan9a/mmcal): Myanmar dates, holidays
and astrology.

Requires Dart 3.8 or newer.

## Migration

Upgrading from v2 or v1? See the migration guide:
[MIGRATION.md](MIGRATION.md)

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

## Examples

A short tour (dates, a month grid, holidays, parsing):

```sh
dart run example/main.dart
```

The CLI demo app:

```sh
dart run example/lib/main.dart
```

With options:

```sh
dart run example/lib/main.dart \
  --date=2024-01-04 \
  --language=en \
  --timezone=6.5 \
  --cache=high \
  --chronicle=true
```

Options:

- `--date=YYYY-MM-DD` target Western date
- `--language=en|my|zawgyi|mon|shan|karen`
- `--timezone=<offset>` range `-12..14`
- `--cache=default|high|memory|off`
- `--chronicle=true|false`

## What You Get

- Myanmar <-> Western date conversion
- Complete date object (Myanmar, Western, Shan, holidays, astro)
- Typed values (`MoonPhase`, `MyanmarYearType`, `SabbathType`) and holiday IDs
- Myanmar and Western date formatting with localization
- Built-in holidays with flexible disabling rules
- Custom holiday rules (typed matcher + date-rule helpers)
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

// A calendar day, with no time or time zone involved.
final day = MyanmarCalendar.getCompleteDateFor(2026, 10, 18);

// Another time zone or holiday set for one call, without touching the
// global configuration.
final utcDay = MyanmarCalendar.getCompleteDate(
  DateTime.now().toUtc(),
  config: const CalendarConfig(timezoneOffset: 0),
);
```

### Dates, times and time zones

- A **local** `DateTime` is read by its fields, as wall-clock time in the
  configured time zone (Myanmar Time by default), whatever the device's zone.
- A **UTC** `DateTime`, an epoch value (`fromMillisecondsSinceEpoch`,
  `fromTimestamp`) and `now()` are **instants**, shown in the configured zone.
- The Myanmar date depends only on the calendar day, never on the time of
  day. For calendar grids, prefer `getCompleteDateFor(year, month, day)`.
- `MyanmarDateTime.toUtc()` and `millisecondsSinceEpoch` give the instant;
  `toDateTime()` gives the wall-clock fields.

### Instance-first client (recommended for isolation)

`MyanmarCalendarClient` has the whole API and never reads global state;
`MyanmarCalendar` is a static convenience over a client for the global
configuration. Without a `config`, a client uses the package defaults.

```dart
final client = MyanmarCalendar.createClient(
  config: const CalendarConfig(
    defaultLanguage: 'en',
    timezoneOffset: 6.5,
  ),
  cacheConfig: const CacheConfig.memoryEfficient(),
);

final complete = client.getCompleteDate(DateTime(2024, 1, 4));
final yearInfo = client.getMyanmarYearInfo(1385); // MyanmarYearInfo (typed)
print(yearInfo.yearType);
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

// Throws DateParseException if the text isn't a date that exists.
final parsedMyanmar = MyanmarCalendar.parseMyanmar('1385/10/1');
final parsedWestern = MyanmarCalendar.parseWestern('2024-01-01');

// Or get null instead.
final maybe = MyanmarCalendar.tryParseMyanmar(userInput);
```

Myanmar dates are written year first (`1385/10/1`, `1385-10-1`) or day first
(`1.10.1385`); Myanmar digits work too.

### Typed values

The int codes stay, with typed getters beside them:

```dart
final day = MyanmarCalendar.getCompleteDateFor(2026, 10, 26);
if (day.phase == MoonPhase.fullMoon) print('Full moon');
if (day.yearKind.isWatat) print('Watat year');
if (day.astro.sabbathType == SabbathType.sabbath) print('Sabbath');
print(day.myanmar.dartWeekday); // 1 = Monday, like DateTime.weekday
```

## Holiday Customization

### Add custom holidays

```dart
final myHoliday = CustomHoliday.westernDate(
  id: 'team_day',
  name: 'Team Day',
  type: HolidayType.cultural,
  month: 7,
  day: 27,
  cacheVersion: 1,
);

MyanmarCalendar.configure(customHolidayRules: [myHoliday]);
```

When you change predicate logic but keep the same holiday ID, increment
`cacheVersion` so cached holiday results are invalidated deterministically.

You can also write a typed matcher directly:

```dart
final fullMoonFestival = CustomHoliday(
  id: 'full_moon_festival',
  name: 'Full Moon Festival',
  type: HolidayType.cultural,
  cacheVersion: 1,
  localizedNames: {
    Language.myanmar: 'လပြည့်ပွဲ',
  },
  matcher: (context) {
    return context.myanmarDate.phase == MoonPhase.fullMoon;
  },
);
```

Legacy untyped holiday predicates are removed. Use `matcher: (context) { ... }`.

Removed legacy aliases:

- `CustomHoliday.legacy(...)`
- `MyanmarCalendar.addCustomHoliday(...)`
- `MyanmarCalendar.addCustomHolidays(...)`
- `MyanmarCalendar.removeCustomHoliday(...)`
- `MyanmarCalendar.clearCustomHolidays(...)`

### Check for a holiday by ID

Holiday names are translated, so compare IDs instead:

```dart
final info = MyanmarCalendar.getCompleteDateFor(2026, 4, 14).holidays;
if (info.has(HolidayId.thingyanAkya)) print('Thingyan Akya');
if (info.hasCustom('team_day')) print('Team day');
for (final holiday in info.entries) {
  print('${holiday.id ?? holiday.customId}: ${holiday.name}');
}
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

For a custom provider class, implement `matches` and a `cacheKey` that
changes whenever its rules change (results are cached by it):

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

### Remote Configuration (Firebase or Backend)

You can deliver custom holiday rules dynamically from Firebase Remote Config
(Flutter apps) or any backend API (pure Dart/server apps).

Suggested JSON payload:

```json
{
  "holidayRules": [
    {
      "id": "team_day",
      "name": "Team Day",
      "type": "cultural",
      "kind": "western_fixed",
      "month": 7,
      "day": 27,
      "cacheVersion": 1,
      "localizedNames": {
        "my": "အသင်းနေ့"
      }
    }
  ]
}
```

Map remote payload to `CustomHoliday` rules:

```dart
import 'dart:convert';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

HolidayType _holidayTypeFromString(String value) {
  return HolidayType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => HolidayType.other,
  );
}

Map<Language, String> _localizedNames(dynamic raw) {
  if (raw is! Map<String, dynamic>) return const {};
  final result = <Language, String>{};
  for (final entry in raw.entries) {
    result[Language.fromCode(entry.key)] = entry.value as String;
  }
  return result;
}

List<CustomHoliday> parseHolidayRules(Map<String, dynamic> payload) {
  final rules = payload['holidayRules'] as List<dynamic>? ?? const [];
  return rules.map((raw) {
    final item = raw as Map<String, dynamic>;
    final id = item['id'] as String;
    final name = item['name'] as String;
    final type = _holidayTypeFromString(item['type'] as String? ?? 'other');
    final cacheVersion = item['cacheVersion'] as int? ?? 1;
    final localized = _localizedNames(item['localizedNames']);
    final kind = item['kind'] as String? ?? 'western_fixed';

    if (kind == 'myanmar_fixed') {
      return CustomHoliday.myanmarDate(
        id: id,
        name: name,
        type: type,
        month: item['month'] as int,
        day: item['day'] as int,
        year: item['year'] as int?,
        fromYear: item['fromYear'] as int?,
        toYear: item['toYear'] as int?,
        cacheVersion: cacheVersion,
        localizedNames: localized,
      );
    }

    return CustomHoliday.westernDate(
      id: id,
      name: name,
      type: type,
      month: item['month'] as int,
      day: item['day'] as int,
      year: item['year'] as int?,
      fromYear: item['fromYear'] as int?,
      toYear: item['toYear'] as int?,
      cacheVersion: cacheVersion,
      localizedNames: localized,
    );
  }).toList();
}
```

Apply rules from Firebase Remote Config (Flutter app):

```dart
final jsonString = remoteConfig.getString('myanmar_calendar_rules');
final payload = jsonDecode(jsonString) as Map<String, dynamic>;
final rules = parseHolidayRules(payload);
MyanmarCalendar.configure(customHolidayRules: rules);
```

Apply rules from a custom backend:

```dart
final response = await client.get(Uri.parse('https://api.example.com/calendar/rules'));
final payload = jsonDecode(response.body) as Map<String, dynamic>;
final rules = parseHolidayRules(payload);
MyanmarCalendar.configure(customHolidayRules: rules);
```

When remote rule logic changes, increment `cacheVersion` for each changed rule.

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
print(stats.hitRate);
print(stats.toMap());
```

### Notes

- Cache entries are isolated by configuration fingerprint to avoid cross-config collisions.
- Holiday and complete-date cache entries are language-aware.
- Custom holiday cache keys are based on stable `cacheKey/cacheVersion` values.
- Western holiday provider cache keys use `westernHolidayProvider.cacheKey`.
- Complete dates are cached per calendar day, so repeated calls with
  `DateTime.now()` reuse one entry.
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

final mm = MyanmarCalendar.getCompleteDate(
  DateTime(2024, 1, 4),
  language: Language.myanmar,
);
final en = MyanmarCalendar.getCompleteDate(
  DateTime(2024, 1, 4),
  language: Language.english,
);
```

`setLanguage` updates the default language. For per-request localization, pass
`language:` directly to APIs that support it.

`TranslationService.addTranslation` changes a word everywhere, including
results already cached; `TranslationService.resetTranslations()` restores the
built-in words.

## AI Prompts

Prompts for AI assistants live in their own library:

```dart
import 'package:myanmar_calendar_dart/ai.dart';

final prompt = AIPromptService.generatePrompt(
  MyanmarCalendar.getCompleteDateFor(2026, 10, 18),
  language: Language.myanmar,
  type: AIPromptType.horoscope,
);
```

## Chronicle APIs

```dart
final entries = MyanmarCalendar.getChronicleFor(DateTime(1752, 9, 14));
final dynasties = MyanmarCalendar.listDynasties();
final dynasty = MyanmarCalendar.getDynastyById('konbaung');
```

## Error Handling

Invalid input throws a `MyanmarCalendarException`:

- `InvalidMyanmarDateException`: a Myanmar date that doesn't exist (such as
  day 30 of a 29-day month, or First Waso in a common year)
- `InvalidWesternDateException`: a Western date or time that doesn't exist
- `DateParseException`: text that isn't a date (also a `FormatException`)
- `InvalidConfigurationException`: a config value out of range

```dart
try {
  MyanmarCalendar.fromWestern(2024, 2, 30);
} on InvalidWesternDateException catch (e) {
  print(e.message);
}
```

Mistakes in calling code, such as a reversed date range, are reported with
`ArgumentError`.

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
node tool/generate_calendar_sweep_fixtures.mjs
dart test test/parity_reference_test.dart test/calendar_sweep_parity_test.dart
```

The sweep checks every day of several ranges: Myanmar dates both ways,
holidays for 2010-2035 and astrology for 2020-2030.

### Benchmark

```sh
dart run benchmark/month_grid_benchmark.dart
```

## Acknowledgements

The core calculation algorithms are based on the original work by
[Dr Yan Naing Aye](https://github.com/yan9a/mmcal).

## License

MIT License. See [LICENSE](LICENSE).
