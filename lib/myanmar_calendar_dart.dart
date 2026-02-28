/// Myanmar Calendar Package
///
/// A comprehensive Dart package for Myanmar calendar with date conversions,
/// astrological calculations, holiday information, and multi-language support.
///
/// Author: Kyaw Zayar Tun
/// Website: https://www.kyawzayartun.com
/// GitHub:  https://github.com/mixin27/myanmar_calendar_dart
/// License: MIT
///
/// ## Features
///
/// - **Date Conversions**: Bidirectional conversion between Myanmar and Western calendars
/// - **Astrological Information**: Complete astrological calculations including watat years, moon phases
/// - **Holiday Calculations**: Myanmar holidays, religious days, cultural celebrations
/// - **Multi-language Support**: Myanmar (Unicode), Myanmar (Zawgyi), Mon, Shan, Karen, English
/// - **Formatting Services**: Flexible date formatting with localization
/// - **Chronicle Data**: Historical chronicle and dynasty lookup support
/// - **Validation**: Comprehensive date validation with detailed error messages
/// - **Utilities**: Helper functions for date calculations and manipulations
///
/// ## Quick Start
///
/// ```dart
/// import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
///
/// // Get today's Myanmar date
/// final today = MyanmarCalendar.today();
/// print('Today: ${today.formatMyanmar()}');
///
/// // Convert dates
/// final myanmarDate = MyanmarCalendar.fromWestern(2024, 1, 1);
/// final westernDate = MyanmarCalendar.fromMyanmar(1385, 10, 1);
///
/// // Get complete date information
/// final completeDate = MyanmarCalendar.getCompleteDate(DateTime.now());
/// print('Holidays: ${completeDate.allHolidays}');
/// print('Astrological days: ${completeDate.astrologicalDays}');
/// ```
///
/// For detailed documentation and examples, visit: https://pub.dev/packages/myanmar_calendar_dart
library;

// Core
export 'src/core/calendar_cache.dart';
export 'src/core/calendar_config.dart';
export 'src/core/myanmar_date_time.dart';
// Exceptions
export 'src/exceptions/calendar_exceptions.dart';
// Localization
export 'src/localization/language.dart';
export 'src/localization/translation_service.dart';
// Models
export 'src/models/astro_info.dart';
export 'src/models/chronicle_models.dart';
export 'src/models/complete_date.dart';
export 'src/models/custom_holiday.dart';
export 'src/models/holiday_id.dart';
export 'src/models/holiday_info.dart';
export 'src/models/myanmar_date.dart';
export 'src/models/shan_date.dart';
export 'src/models/validation_result.dart';
export 'src/models/western_date.dart';
export 'src/models/western_holiday_provider.dart';
// Public API
export 'src/myanmar_calendar_dart.dart';
// Services
export 'src/services/ai_prompt_service.dart';
