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
