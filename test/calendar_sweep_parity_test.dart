import 'dart:convert';
import 'dart:io';

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:myanmar_calendar_dart/src/services/date_converter.dart';
import 'package:test/test.dart';

/// Day-by-day parity with reference/ceMmDateTime.js.
/// Regenerate with: node tool/generate_calendar_sweep_fixtures.mjs
void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/calendar_sweep_fixtures.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  const config = CalendarConfig();
  final converter = DateConverter(
    config,
    cache: CalendarCache.independent(config: const CacheConfig.disabled()),
  );

  test('every day has the reference Myanmar date, both ways', () {
    var checked = 0;
    for (final range in fixture['myanmar'] as List<dynamic>) {
      final start = (range as Map<String, dynamic>)['startJdn'] as int;
      final days = (range['days'] as List<dynamic>).cast<int>();
      for (var i = 0; i < days.length; i++) {
        final jdn = start + i;
        final year = days[i] ~/ 10000 + 1000;
        final month = days[i] % 10000 ~/ 100;
        final day = days[i] % 100;

        final date = converter.myanmarForLocalDay(jdn.toDouble());
        expect(
          [date.year, date.month, date.day],
          [year, month, day],
          reason: 'j2m($jdn)',
        );
        expect(date.julianDayNumber, jdn, reason: 'local day $jdn');

        final back =
            converter.myanmarToJulian(year, month, day) +
            config.timezoneOffsetInDays;
        expect(back.round(), jdn, reason: 'm2j($year, $month, $day)');
        checked++;
      }
    }
    expect(checked, greaterThan(17000));
  });

  test('holidays and anniversaries match the reference, 2010-2035', () {
    final client = MyanmarCalendarClient();
    final expected = {
      for (final h in fixture['holidays'] as List<dynamic>)
        (h as Map<String, dynamic>)['jdn'] as int: h,
    };
    final first = expected.keys.reduce((a, b) => a < b ? a : b);
    final last = expected.keys.reduce((a, b) => a > b ? a : b);
    final mismatches = <String>[];

    for (var jdn = first; jdn <= last; jdn++) {
      final w = converter.julianToWestern(jdn - config.timezoneOffsetInDays);
      final info = client
          .getCompleteDateFor(
            w.year,
            w.month,
            w.day,
            language: Language.english,
          )
          .holidays;
      final public = [
        for (final name in [
          ...info.publicHolidays,
          ...info.religiousHolidays,
          ...info.culturalHolidays,
        ])
          if (!_referenceAnniversaries.contains(name) &&
              !_dartOnly.contains(name))
            _referenceName(name),
      ]..sort();
      final anniversaries = [
        for (final name in [
          ...info.myanmarAnniversaryDays,
          ...info.otherAnniversaryDays,
          ...info.religiousHolidays.where(_referenceAnniversaries.contains),
        ])
          if (!_dartOnly.contains(name)) _referenceName(name),
      ]..sort();

      final entry = expected[jdn];
      final refPublic = [
        ...?(entry?['public'] as List<dynamic>?)?.cast<String>(),
      ]..sort();
      final refAnniversaries = [
        ...?(entry?['anniversary'] as List<dynamic>?)?.cast<String>(),
      ]..sort();
      if (public.join('|') != refPublic.join('|') ||
          anniversaries.join('|') != refAnniversaries.join('|')) {
        mismatches.add(
          '${w.year}-${w.month}-${w.day}: $public / $anniversaries, '
          'reference $refPublic / $refAnniversaries',
        );
      }
    }
    expect(mismatches, isEmpty);
  });

  test('astrology matches the reference, 2020-2030', () {
    final astro = fixture['astro'] as Map<String, dynamic>;
    final start = astro['startJdn'] as int;
    final days = (astro['days'] as List<dynamic>).cast<String>();
    const sabbath = ['', 'Sabbath', 'Sabbath Eve'];
    const pyathada = ['', 'Pyathada', 'Afternoon Pyathada'];
    const nagahle = ['West', 'North', 'East', 'South'];
    const mahabote = [
      'Binga',
      'Atun',
      'Yaza',
      'Adipati',
      'Marana',
      'Thike',
      'Puti',
    ];
    const nakhat = ['Ogre', 'Elf', 'Human'];
    final client = MyanmarCalendarClient();
    for (var i = 0; i < days.length; i++) {
      final [codes, named] = days[i].split('|');
      final c = codes.split(' ').map(int.parse).toList();
      final date = converter.myanmarForLocalDay((start + i).toDouble());
      final info = client.getAstroInfo(date);
      final reason = 'local day ${start + i}';
      expect(info.sabbath, sabbath[c[0]], reason: reason);
      expect(info.yatyaza, c[1] == 1 ? 'Yatyaza' : '', reason: reason);
      expect(info.pyathada, pyathada[c[2]], reason: reason);
      expect(info.nagahle, nagahle[c[3]], reason: reason);
      expect(info.mahabote, mahabote[c[4]], reason: reason);
      expect(info.nakhat, nakhat[c[5]], reason: reason);
      expect(
        info.astrologicalDays,
        named.isEmpty ? <String>[] : named.split(','),
        reason: reason,
      );
    }
  });
}

/// The package's English names are shorter than the reference's.
String _referenceName(String name) => _names[name] ?? name;

const _names = {
  'Independence': 'Independence Day',
  'Labour': 'Labour Day',
  "Martyrs'": "Martyrs' Day",
  "New Year's": "New Year's Day",
  'Peasants': "Peasants' Day",
  'Resistance': 'Resistance Day',
  'Union': 'Union Day',
  'Buddha': 'Buddha Day',
  'Christmas': 'Christmas Day',
  "Karen New Year's": "Karen New Year's Day",
  'Authors': "Authors' Day",
  'Fathers': "Fathers' Day",
  'Garudhamma': 'Garudhamma Day',
  'Mahathamaya': 'Mahathamaya Day',
  'Metta': 'Metta Day',
  'Mon National': "'Mon' National Day",
  'Mothers': "Mothers' Day",
  "Shan New Year's": "Shan New Year's Day",
  "April Fools'": "April Fools' Day",
  'Earth': 'Earth Day',
  'Red Cross': 'Red Cross Day',
  'United Nations': 'United Nations Day',
  'Valentines': 'Valentines Day',
  "World Teachers'": "World Teachers' Day",
};

/// In the reference's anniversary list, but religious holidays here.
const _referenceAnniversaries = {'Easter', 'Good Friday'};

/// Holidays this package adds from its own tables; the reference has none.
const _dartOnly = {
  "Chinese New Year's",
  'Eid al-Adha',
  'Eid al-Fitr',
  'Diwali',
};
