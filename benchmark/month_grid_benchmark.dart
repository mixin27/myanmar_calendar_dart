// Rough timings for the work an app does most: rendering month grids.
//
//   dart run benchmark/month_grid_benchmark.dart
//
// Prints microseconds per day for a cold start (empty caches), browsing
// (each month once) and revisiting months already seen.
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main() {
  double perDay(void Function() run, int days) {
    final watch = Stopwatch()..start();
    run();
    return watch.elapsedMicroseconds / days;
  }

  // 42 cells per month grid, 10 years of months.
  final months = [
    for (var y = 2020; y < 2030; y++)
      for (var m = 1; m <= 12; m++) (y, m),
  ];
  void grid(MyanmarCalendarClient client, int year, int month) {
    final first = DateTime(year, month);
    for (var i = -6; i < 36; i++) {
      final d = first.add(Duration(days: i));
      client.getCompleteDateFor(d.year, d.month, d.day);
    }
  }

  final days = months.length * 42;
  for (final language in [Language.english, Language.myanmar]) {
    final client = MyanmarCalendarClient(
      config: CalendarConfig(defaultLanguage: language.code),
    );
    final cold = perDay(() => grid(client, 2026, 10), 42);
    final browse = perDay(() {
      for (final (y, m) in months) {
        grid(client, y, m);
      }
    }, days);
    final revisit = perDay(() {
      for (var i = 0; i < 20; i++) {
        grid(client, 2026, 10);
        grid(client, 2026, 11);
      }
    }, 40 * 42);
    print(
      '${language.code.padRight(3)} cold ${cold.toStringAsFixed(1)} µs/day, '
      'browse ${browse.toStringAsFixed(1)} µs/day, '
      'revisit ${revisit.toStringAsFixed(1)} µs/day',
    );
  }
}
