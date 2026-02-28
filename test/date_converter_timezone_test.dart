// ignore_for_file: prefer_const_declarations, omit_local_variable_types, document_ignores, avoid_redundant_argument_values, avoid_multiple_declarations_per_line

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/services/date_converter.dart';
import 'package:test/test.dart';

void main() {
  group('DateConverter Timezone Tests', () {
    late DateConverter converter;
    late CalendarConfig config;
    // Myanmar Time is UTC+6:30 (6.5 hours)
    final double offset = 6.5;
    final double offsetInDays = offset / 24.0;

    setUp(() {
      config = CalendarConfig(timezoneOffset: offset);
      // Use independent cache with default config since CalendarConfig doesn't expose it
      converter = DateConverter(config, cache: CalendarCache.independent());
    });

    test('westernToJulian should subtract timezone offset', () {
      // 2024-01-01 12:00:00 Local Time

      // We'll calculate "Local JDN" by using a 0-offset converter
      final zeroConfig = const CalendarConfig(timezoneOffset: 0);
      final zeroConverter = DateConverter(
        zeroConfig,
        cache: CalendarCache.independent(),
      );
      final localJdn = zeroConverter.westernToJulian(2024, 1, 1, 12, 0, 0);

      final utcJdn = converter.westernToJulian(2024, 1, 1, 12, 0, 0);

      // Expected: UTC JDN should be smaller than Local JDN by exactly offsetInDays
      // because UTC time is earlier than Myanmar time
      expect(utcJdn, closeTo(localJdn - offsetInDays, 0.000001));
    });

    test('julianToWestern should add timezone offset', () {
      final zeroConfig = const CalendarConfig(timezoneOffset: 0);
      final zeroConverter = DateConverter(
        zeroConfig,
        cache: CalendarCache.independent(),
      );

      // Let's pick a JDN that represents 2024-01-01 12:00:00 UTC
      final utcJdn = zeroConverter.westernToJulian(2024, 1, 1, 12, 0, 0);

      // Convert this UTC JDN back to Western Date using the timezone-aware converter
      final westernDate = converter.julianToWestern(utcJdn);

      // 12:00:00 UTC should be 18:30:00 Myanmar Time (12 + 6.5)
      expect(westernDate.year, 2024);
      expect(westernDate.month, 1);
      expect(westernDate.day, 1);
      expect(westernDate.hour, 18);
      expect(westernDate.minute, 30);
      expect(westernDate.second, 0);
    });

    test('Round Trip verification', () {
      // 2024-04-17 12:00:00 (Thingyan New Year usually)
      final y = 2024, m = 4, d = 17, h = 12, min = 0, s = 0;

      final jdn = converter.westernToJulian(y, m, d, h, min, s);
      final westernDate = converter.julianToWestern(jdn);

      expect(westernDate.year, y);
      expect(westernDate.month, m);
      expect(westernDate.day, d);
      expect(westernDate.hour, h);
      expect(westernDate.minute, min);
      expect(westernDate.second, s);
    });

    test('Myanmar Date conversion should respect timezone', () {
      // Myanmar Year 1385, Thadingyut Full Moon (Month 7, Day 15), 12:00:00 Local
      // Should result in a JDN that is offsetInDays less than "Local JDN"

      final myYear = 1385;
      final myMonth = 7;
      final myDay = 15;

      final zeroConfig = const CalendarConfig(timezoneOffset: 0);
      final zeroConverter = DateConverter(
        zeroConfig,
        cache: CalendarCache.independent(),
      );
      final localJdn = zeroConverter.myanmarToJulian(
        myYear,
        myMonth,
        myDay,
        12,
        0,
        0,
      );

      final utcJdn = converter.myanmarToJulian(
        myYear,
        myMonth,
        myDay,
        12,
        0,
        0,
      );

      expect(utcJdn, closeTo(localJdn - offsetInDays, 0.000001));

      // Reverse
      final myanmarDate = converter.julianToMyanmar(utcJdn);

      expect(myanmarDate.year, myYear);
      expect(myanmarDate.month, myMonth);
      expect(myanmarDate.day, myDay);
    });
  });
}
