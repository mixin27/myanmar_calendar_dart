// Not required for test files
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  group('MyanmarCalendar', () {
    test('today must not null', () {
      expect(MyanmarCalendar.today(), isNotNull);
    });
  });
}
