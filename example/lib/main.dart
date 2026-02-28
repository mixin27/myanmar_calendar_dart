import 'dart:io';

import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';

void main(List<String> args) {
  try {
    final options = _ExampleOptions.parse(args);
    if (options.showHelp) {
      _printUsage();
      return;
    }

    _runExample(options);
  } on FormatException catch (e) {
    stderr.writeln('Invalid arguments: ${e.message}');
    _printUsage();
    exitCode = 64;
  }
}

class _ExampleOptions {
  const _ExampleOptions({
    required this.targetDate,
    required this.language,
    required this.timezoneOffset,
    required this.cacheProfile,
    required this.includeChronicle,
    required this.showHelp,
  });

  factory _ExampleOptions.parse(List<String> args) {
    var targetDate = DateTime.now();
    var language = Language.english;
    var timezoneOffset = 6.5;
    var cacheProfile = _CacheProfile.defaultProfile;
    var includeChronicle = true;
    var showHelp = false;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
        continue;
      }

      if (arg.startsWith('--date=')) {
        final value = arg.substring('--date='.length);
        targetDate = _parseDate(value);
        continue;
      }

      if (arg.startsWith('--language=')) {
        final value = arg.substring('--language='.length);
        language = _parseLanguage(value);
        continue;
      }

      if (arg.startsWith('--timezone=')) {
        final value = arg.substring('--timezone='.length);
        timezoneOffset =
            double.tryParse(value) ??
            (throw FormatException('timezone must be numeric: "$value"'));
        if (timezoneOffset < -12 || timezoneOffset > 14) {
          throw const FormatException('timezone must be between -12 and 14');
        }
        continue;
      }

      if (arg.startsWith('--cache=')) {
        final value = arg.substring('--cache='.length);
        cacheProfile = _CacheProfile.parse(value);
        continue;
      }

      if (arg.startsWith('--chronicle=')) {
        final value = arg.substring('--chronicle='.length).toLowerCase();
        if (value == 'true') {
          includeChronicle = true;
        } else if (value == 'false') {
          includeChronicle = false;
        } else {
          throw FormatException('chronicle must be true/false: "$value"');
        }
        continue;
      }

      throw FormatException('unknown argument "$arg"');
    }

    return _ExampleOptions(
      targetDate: DateTime(targetDate.year, targetDate.month, targetDate.day),
      language: language,
      timezoneOffset: timezoneOffset,
      cacheProfile: cacheProfile,
      includeChronicle: includeChronicle,
      showHelp: showHelp,
    );
  }

  final DateTime targetDate;
  final Language language;
  final double timezoneOffset;
  final _CacheProfile cacheProfile;
  final bool includeChronicle;
  final bool showHelp;
}

enum _CacheProfile {
  defaultProfile,
  highPerformance,
  memoryEfficient,
  disabled
  ;

  static _CacheProfile parse(String value) {
    switch (value.toLowerCase()) {
      case 'default':
        return _CacheProfile.defaultProfile;
      case 'high':
      case 'high_performance':
        return _CacheProfile.highPerformance;
      case 'memory':
      case 'memory_efficient':
        return _CacheProfile.memoryEfficient;
      case 'off':
      case 'disabled':
        return _CacheProfile.disabled;
      default:
        throw const FormatException(
          'cache must be one of: default, high, memory, off',
        );
    }
  }
}

void _runExample(_ExampleOptions options) {
  final customHolidayRules = <CustomHoliday>[
    CustomHoliday.westernDate(
      id: 'example_runtime_day',
      name: 'Example Runtime Day',
      type: HolidayType.other,
      month: options.targetDate.month,
      day: options.targetDate.day,
      year: options.targetDate.year,
      localizedNames: const {
        Language.myanmar: 'ဥပမာရက်',
      },
      cacheVersion: 1,
    ),
    CustomHoliday(
      id: 'example_waxing_day_8',
      name: 'Waxing Day Eight',
      type: HolidayType.cultural,
      cacheVersion: 1,
      localizedNames: const {
        Language.myanmar: 'လဆန်းရှစ်ရက်',
      },
      matcher: (context) =>
          context.myanmarDate.moonPhase == 0 && context.myanmarDate.day == 8,
    ),
  ];

  final client = MyanmarCalendarClient(
    config: CalendarConfig(
      defaultLanguage: options.language.code,
      timezoneOffset: options.timezoneOffset,
      customHolidays: customHolidayRules,
    ),
    cacheConfig: _cacheConfigFor(options.cacheProfile),
  );

  final dateTime = DateTime(
    options.targetDate.year,
    options.targetDate.month,
    options.targetDate.day,
    12,
  );
  final myanmarDateTime = client.fromDateTime(dateTime);
  final completeDefault = client.getCompleteDate(dateTime);
  final completeEnglish = client.getCompleteDate(
    dateTime,
    language: Language.english,
  );
  final completeMyanmar = client.getCompleteDate(
    dateTime,
    language: Language.myanmar,
  );

  _printHeader('Myanmar Calendar Dart Example');
  print('Target Western Date : ${_isoDate(options.targetDate)}');
  print('Default Language    : ${options.language.code}');
  print('Timezone Offset     : ${options.timezoneOffset}');
  print('Cache Profile       : ${options.cacheProfile.name}');
  print('');

  _printHeader('Conversions & Formatting');
  print(
    'Myanmar Format  : '
    '${myanmarDateTime.formatMyanmar('&W, &d &Yat &M &P &ff, &y', options.language)}',
  );
  print(
    'Western Format  : '
    '${myanmarDateTime.formatWestern('%Www %y-%mm-%dd %HH:%nn:%ss', options.language)}',
  );
  print(
    'Complete Format : '
    '${myanmarDateTime.formatComplete(language: options.language, includeAstro: true, includeHolidays: true)}',
  );
  print('');

  _printHeader('Request-Scoped Localization');
  print(
    'Public Holidays (EN): ${_joinOrNone(completeEnglish.publicHolidays)}',
  );
  print(
    'Public Holidays (MY): ${_joinOrNone(completeMyanmar.publicHolidays)}',
  );
  print(
    'Other Holidays (Default): ${_joinOrNone(completeDefault.holidays.otherHolidays)}',
  );
  print('');

  _printHeader('Month Transition Demo');
  final previousMonth = client.addMonths(myanmarDateTime, -1);
  final nextMonth = client.addMonths(myanmarDateTime, 1);
  print('Previous Month: ${previousMonth.formatMyanmar('&y &M &d')}');
  print('Current Date  : ${myanmarDateTime.formatMyanmar('&y &M &d')}');
  print('Next Month    : ${nextMonth.formatMyanmar('&y &M &d')}');
  print('');

  _printHeader('Cache Demo');
  client.resetCacheStatistics();
  for (var i = 0; i < 5; i++) {
    client.getCompleteDate(dateTime, language: options.language);
  }
  for (var i = 0; i < 3; i++) {
    client.getCompleteDate(
      dateTime.add(Duration(days: i)),
      language: options.language,
    );
  }

  final typedStats = client.getTypedCacheStatistics();
  print('Requests: ${typedStats.totalRequests}');
  print('Hits    : ${typedStats.hits}');
  print('Misses  : ${typedStats.misses}');
  print('Hit Rate: ${(typedStats.hitRate * 100).toStringAsFixed(2)}%');
  print(
    'CompleteDate Cache: '
    '${typedStats.completeDate.size}/${typedStats.completeDate.maxSize}',
  );
  print('');

  if (options.includeChronicle) {
    _printHeader('Chronicle Snapshot');
    final entries = client.getChronicleFor(dateTime);
    final dynasty = client.getDynastyFor(dateTime);
    print('Entries On Date: ${entries.length}');
    if (entries.isNotEmpty) {
      print(
        'First Entry   : ${_localizedValue(entries.first.title, options.language)}',
      );
    }
    if (dynasty != null) {
      print(
        'Dynasty       : ${_localizedValue(dynasty.name, options.language)}',
      );
    }
  }
}

void _printUsage() {
  print('Usage: dart run example/lib/main.dart [options]');
  print('');
  print('Options:');
  print('  --date=YYYY-MM-DD        Western date to inspect (default: today)');
  print('  --language=<code>        en | my | zawgyi | mon | shan | karen');
  print('  --timezone=<offset>      -12..14 (default: 6.5)');
  print('  --cache=<profile>        default | high | memory | off');
  print('  --chronicle=true|false   include chronicle lookup (default: true)');
  print('  --help, -h               show this help');
}

DateTime _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('date must be YYYY-MM-DD: "$value"');
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);

  if (year == null || month == null || day == null) {
    throw const FormatException('date must contain numeric year, month, day');
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('invalid date: "$value"');
  }
  return parsed;
}

Language _parseLanguage(String code) {
  return Language.values.firstWhere(
    (value) => value.code == code,
    orElse: () => throw FormatException('unsupported language code: "$code"'),
  );
}

CacheConfig _cacheConfigFor(_CacheProfile profile) {
  switch (profile) {
    case _CacheProfile.defaultProfile:
      return const CacheConfig();
    case _CacheProfile.highPerformance:
      return const CacheConfig.highPerformance();
    case _CacheProfile.memoryEfficient:
      return const CacheConfig.memoryEfficient();
    case _CacheProfile.disabled:
      return const CacheConfig.disabled();
  }
}

String _joinOrNone(List<String> values) {
  if (values.isEmpty) return '<none>';
  return values.join(', ');
}

String _localizedValue(Map<String, String> values, Language language) {
  return values[language.code] ?? values['en'] ?? values.values.first;
}

String _isoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

void _printHeader(String title) {
  print('=== $title ===');
}
