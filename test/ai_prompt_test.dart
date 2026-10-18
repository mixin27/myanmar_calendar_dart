import 'package:myanmar_calendar_dart/ai.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:test/test.dart';

void main() {
  test('prompts include the date and differ by type and language', () {
    final day = MyanmarCalendar.getCompleteDateFor(2026, 10, 18);
    final english = AIPromptService.generatePrompt(
      day,
      language: Language.english,
    );
    final myanmar = AIPromptService.generatePrompt(
      day,
      language: Language.myanmar,
    );
    final fortune = AIPromptService.generatePrompt(
      day,
      language: Language.english,
      type: AIPromptType.fortuneTelling,
    );
    expect(english, contains('2026'));
    expect(english, isNot(myanmar));
    expect(english, isNot(fortune));
    for (final type in AIPromptType.values) {
      expect(
        AIPromptService.generatePrompt(day, type: type).trim(),
        isNotEmpty,
      );
    }
  });
}
