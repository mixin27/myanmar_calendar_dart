# Migration Guide (v2 -> v3)

v3 fixes calendar results that were wrong in v2 and tightens the API. Most
apps need only a few mechanical changes.

## Quick Checklist

- Update the dependency to `^3.0.0` (Dart 3.8 or newer)
- Catch `MyanmarCalendarException` (or a subclass) instead of `ArgumentError`
- Switch `parseMyanmar`/`parseWestern` calls that expect null to
  `tryParseMyanmar`/`tryParseWestern`
- Import `package:myanmar_calendar_dart/ai.dart` for AI prompts
- Use `getCacheStatistics()` (now typed) instead of `getTypedCacheStatistics()`
- Give custom `WesternHolidayProvider`s a `cacheKey`
- Remove `hide CacheException` from imports of this package

---

## 1) Errors

Invalid input throws typed exceptions, all subclasses of
`MyanmarCalendarException` (an `Exception`):

| Situation | v2 | v3 |
| --- | --- | --- |
| Myanmar date doesn't exist | `ArgumentError`, or silently moved to a neighbouring day | `InvalidMyanmarDateException` |
| Western date doesn't exist | `ArgumentError` | `InvalidWesternDateException` |
| Unparseable string | `null` | `DateParseException` (also a `FormatException`) |
| Bad config value | release builds: wrong results | `InvalidConfigurationException` |

```dart
// v2
try {
  MyanmarCalendar.fromMyanmar(year, month, day);
} on ArgumentError catch (e) { ... }

// v3
try {
  MyanmarCalendar.fromMyanmar(year, month, day);
} on InvalidMyanmarDateException catch (e) {
  print(e.message);
}
```

Day 30 of a 29-day month and First Waso (month 0) in a common year used to
become day 29 or Waso. They are now rejected; `validateMyanmar` explains why.

Removed exception classes (they were never thrown): `CacheException`,
`DateConversionException`, `DateOutOfRangeException`,
`AstrologicalCalculationException`, `HolidayCalculationException`.

## 2) Parsing

```dart
// v2: null on failure
final date = MyanmarCalendar.parseMyanmar(text);

// v3
final date = MyanmarCalendar.tryParseMyanmar(text); // null on failure
final strict = MyanmarCalendar.parseMyanmar(text);  // throws DateParseException
```

Myanmar strings must be a whole date, year first (`1385/10/1`) or day first
(`1.10.1385`), with one separator. Strings like `abc1385/10/1` no longer
parse. Myanmar digits are accepted.

## 3) Renamed or moved

| v2 | v3 |
| --- | --- |
| `getTypedCacheStatistics()` | `getCacheStatistics()` |
| `getCacheStatistics()` (map) | `getCacheStatistics().toMap()` |
| `CalendarCache.getTypedStatistics()` | `CalendarCache.getStatistics()` |
| `MyanmarCalendar.generateAIPrompt(date, ...)` | `AIPromptService.generatePrompt(date, ...)` from `package:myanmar_calendar_dart/ai.dart` |
| `convertMyanmarDates([{'year': y, 'month': m, 'day': d}])` | `convertMyanmarDates([(y, m, d)])` |
| `copyWith(millisecond: ..., isUtc: ...)` | removed (they were ignored) |
| `fromMillisecondsSinceEpoch(ms, isUtc: ...)` | `fromMillisecondsSinceEpoch(ms)` (always an instant) |

## 4) Custom Western holiday providers

`WesternHolidayProvider` is abstract. Implement both members:

```dart
class MyProvider extends WesternHolidayProvider {
  const MyProvider();

  @override
  String get cacheKey => 'my_provider:v1'; // change it when the rules change

  @override
  bool matches(HolidayId id, int year, int month, int day) => false;
}
```

## 5) Behaviour you may notice

- **Holidays match the reference calendar.** Tazaungmon 14 is a public
  holiday. The Thadingyut full moon is only "End of Buddhist Lent". 1 January
  is a public holiday only 2018–2021. The December 2017–2021 and 2019–2021
  substitute holidays appear.
- **Shan year** changes at Shan New Year (Nadaw 1), not at Thingyan.
- **`MyanmarDate.julianDayNumber`** is the whole local day number (local
  noon).
- **`createClient()` without a config** uses the package defaults, like the
  `MyanmarCalendarClient` constructor.
- **Helpers that take a date** (`addDays`, `addMonths`, `findNextMoonPhase`)
  keep that date's configuration.
- **`isWatatYear`, `getYearType`, `getMyanmarMonth`, `addMonths`** and moon
  phase searches return correct results; v2 could be off by a year, a month
  or a day.

## 6) New, optional

- `HolidayInfo.entries` and `has(HolidayId)` to test holidays without
  matching translated names
- `phase`, `yearKind`, `sabbathType` and `dartWeekday` typed getters
- `config:` on most `MyanmarCalendar` methods for one-off settings

---

# Migration Guide (v1 -> v2)

This guide helps you migrate from `myanmar_calendar_dart` v1.x to v2.x.

## Quick Checklist

- Update dependency version to `^2.0.0`
- Replace removed custom-holiday legacy APIs
- Move from map-style year metadata to typed `MyanmarYearInfo`
- Replace removed translation-service legacy APIs with explicit-language calls
- Optionally adopt `MyanmarCalendarClient` for isolated runtime state

---

## 1) Custom Holiday API Changes

### Removed

- `CustomHoliday.legacy(...)`
- Un-typed legacy `predicate`-style usage
- `MyanmarCalendar.addCustomHoliday(...)`
- `MyanmarCalendar.addCustomHolidays(...)`
- `MyanmarCalendar.removeCustomHoliday(...)`
- `MyanmarCalendar.clearCustomHolidays(...)`
- `MyanmarCalendar.configure(customHolidays: ...)` parameter alias

### Use Instead

- Typed matcher with `CustomHolidayContext`
- `customHolidayRules` everywhere
- Rule-oriented methods:
  - `MyanmarCalendar.addCustomHolidayRule(...)`
  - `MyanmarCalendar.addCustomHolidayRules(...)`
  - `MyanmarCalendar.removeCustomHolidayRuleById(...)`
  - `MyanmarCalendar.clearCustomHolidayRules()`

### Before (v1)

```dart
final holiday = CustomHoliday.legacy(
  id: 'team_day',
  name: 'Team Day',
  type: HolidayType.cultural,
  predicate: (myanmarDate, westernDate) => westernDate.month == 7 && westernDate.day == 27,
);

MyanmarCalendar.configure(customHolidays: [holiday]);
MyanmarCalendar.addCustomHoliday(holiday);
```

### After (v2)

```dart
final holiday = CustomHoliday(
  id: 'team_day',
  name: 'Team Day',
  type: HolidayType.cultural,
  matcher: (context) =>
      context.westernDate.month == 7 && context.westernDate.day == 27,
);

MyanmarCalendar.configure(customHolidayRules: [holiday]);
MyanmarCalendar.addCustomHolidayRule(holiday);
```

---

## 2) Typed Myanmar Year Metadata

### Removed

- `DateConverter.getYearInfo(...)` (map-based)

### Use Instead

- `DateConverter.getMyanmarYearInfo(...)` returning `MyanmarYearInfo`
- `MyanmarCalendarClient.getMyanmarYearInfo(...)`

### Before (v1)

```dart
final info = converter.getYearInfo(1385);
final yearType = info['yearType'] as int;
```

### After (v2)

```dart
final info = converter.getMyanmarYearInfo(1385);
final yearType = info.yearType;
```

---

## 3) Translation Service Legacy Methods Removed

### Removed

- `TranslationService.currentLanguage`
- `TranslationService.setLanguage(...)`
- `TranslationService.translate(...)`
- `MyanmarCalendarService.setLanguage(...)`
- `MyanmarCalendarService.currentLanguage`

### Use Instead

- Explicit language calls:
  - `TranslationService.translateTo(key, language)`
- Request-scoped language arguments in APIs that support `language:`
- Default language via configuration:
  - `MyanmarCalendar.configure(language: ...)`
  - `CalendarConfig(defaultLanguage: ...)`

### Before (v1)

```dart
TranslationService.setLanguage(Language.myanmar);
final text = TranslationService.translate('Independence');
```

### After (v2)

```dart
final text = TranslationService.translateTo('Independence', Language.myanmar);
```

---

## 4) Instance-First API (Recommended in v2)

v2 introduces `MyanmarCalendarClient` for isolated runtime behavior
(config/cache/service) and safer multi-tenant/server usage.

### Example

```dart
final client = MyanmarCalendar.createClient(
  config: const CalendarConfig(
    defaultLanguage: 'en',
    timezoneOffset: 6.5,
  ),
  cacheConfig: const CacheConfig.memoryEfficient(),
);

final complete = client.getCompleteDate(DateTime(2024, 1, 4));
final yearInfo = client.getMyanmarYearInfo(1385);
```

---

## 5) Cache Behavior Reminder

If custom-holiday matcher logic changes while `id` stays the same, increment
`cacheVersion` to invalidate fingerprints deterministically.

```dart
final holiday = CustomHoliday(
  id: 'team_day',
  name: 'Team Day',
  type: HolidayType.cultural,
  cacheVersion: 2, // bump when matcher logic changes
  matcher: (context) => context.westernDate.month == 7,
);
```

---

## Need Help Migrating?

If you share your v1 usage snippets, migration can be mapped line-by-line to v2.
