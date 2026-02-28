import 'dart:convert';
import 'dart:io';

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/services/date_converter.dart';
import 'package:test/test.dart';

void main() {
  group('ceMmDateTime parity fixtures', () {
    late Map<String, dynamic> fixture;
    late List<dynamic> westernToJulianCases;
    late List<dynamic> julianToWesternCases;
    late List<dynamic> julianToMyanmarCases;

    setUpAll(() {
      final file = File('test/fixtures/reference_parity_fixtures.json');
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'Missing parity fixture file. Regenerate with: node tool/generate_reference_parity_fixtures.mjs',
      );

      fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final cases = fixture['cases'] as Map<String, dynamic>;
      westernToJulianCases = cases['westernToJulian'] as List<dynamic>;
      julianToWesternCases = cases['julianToWestern'] as List<dynamic>;
      julianToMyanmarCases = cases['julianToMyanmar'] as List<dynamic>;
    });

    test('westernToJulian matches JS reference', () {
      for (var i = 0; i < westernToJulianCases.length; i++) {
        final testCase = westernToJulianCases[i] as Map<String, dynamic>;
        final config = _buildConfig(testCase['config'] as Map<String, dynamic>);
        final converter = DateConverter(
          config,
          cache: CalendarCache.independent(
            config: const CacheConfig.disabled(),
          ),
        );

        final input = testCase['input'] as Map<String, dynamic>;
        final expected = testCase['expected'] as Map<String, dynamic>;

        final actual = converter.westernToJulian(
          input['year'] as int,
          input['month'] as int,
          input['day'] as int,
          input['hour'] as int,
          input['minute'] as int,
          input['second'] as int,
        );

        expect(
          actual,
          closeTo((expected['julianDayNumber'] as num).toDouble(), 1e-9),
          reason: 'westernToJulian case index $i failed',
        );
      }
    });

    test('julianToWestern matches JS reference', () {
      for (var i = 0; i < julianToWesternCases.length; i++) {
        final testCase = julianToWesternCases[i] as Map<String, dynamic>;
        final config = _buildConfig(testCase['config'] as Map<String, dynamic>);
        final converter = DateConverter(
          config,
          cache: CalendarCache.independent(
            config: const CacheConfig.disabled(),
          ),
        );

        final input = testCase['input'] as Map<String, dynamic>;
        final expected = testCase['expected'] as Map<String, dynamic>;
        final actual = converter.julianToWestern(
          (input['julianDayNumber'] as num).toDouble(),
        );

        expect(actual.year, expected['year'], reason: 'year case index $i');
        expect(actual.month, expected['month'], reason: 'month case index $i');
        expect(actual.day, expected['day'], reason: 'day case index $i');
        expect(actual.hour, expected['hour'], reason: 'hour case index $i');
        expect(
          actual.minute,
          expected['minute'],
          reason: 'minute case index $i',
        );
        expect(
          actual.second,
          expected['second'],
          reason: 'second case index $i',
        );
        expect(
          actual.weekday,
          expected['weekday'],
          reason: 'weekday case index $i',
        );
      }
    });

    test('julianToMyanmar matches JS reference', () {
      for (var i = 0; i < julianToMyanmarCases.length; i++) {
        final testCase = julianToMyanmarCases[i] as Map<String, dynamic>;
        final config = _buildConfig(
          testCase['config'] as Map<String, dynamic>,
          includeCalendarType: false,
        );
        final converter = DateConverter(
          config,
          cache: CalendarCache.independent(
            config: const CacheConfig.disabled(),
          ),
        );

        final input = testCase['input'] as Map<String, dynamic>;
        final expected = testCase['expected'] as Map<String, dynamic>;
        final actual = converter.julianToMyanmar(
          (input['julianDayNumber'] as num).toDouble(),
        );

        expect(actual.year, expected['year'], reason: 'year case index $i');
        expect(actual.month, expected['month'], reason: 'month case index $i');
        expect(actual.day, expected['day'], reason: 'day case index $i');
        expect(
          actual.yearType,
          expected['yearType'],
          reason: 'yearType case index $i',
        );
        expect(
          actual.moonPhase,
          expected['moonPhase'],
          reason: 'moonPhase case index $i',
        );
        expect(
          actual.fortnightDay,
          expected['fortnightDay'],
          reason: 'fortnightDay case index $i',
        );
        expect(
          actual.weekday,
          expected['weekday'],
          reason: 'weekday case index $i',
        );
        expect(
          actual.sasanaYear,
          expected['sasanaYear'],
          reason: 'sasanaYear case index $i',
        );
        expect(
          actual.monthLength,
          expected['monthLength'],
          reason: 'monthLength case index $i',
        );
        expect(
          actual.monthType,
          expected['monthType'],
          reason: 'monthType case index $i',
        );
      }
    });
  });
}

CalendarConfig _buildConfig(
  Map<String, dynamic> config, {
  bool includeCalendarType = true,
}) {
  return CalendarConfig(
    timezoneOffset: (config['timezoneOffset'] as num).toDouble(),
    calendarType: includeCalendarType ? config['calendarType'] as int? ?? 0 : 0,
    gregorianStart: includeCalendarType
        ? config['gregorianStart'] as int? ?? 2361222
        : 2361222,
    sasanaYearType: config['sasanaYearType'] as int? ?? 0,
  );
}
