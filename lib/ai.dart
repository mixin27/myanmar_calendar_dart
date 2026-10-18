/// Prompts for AI assistants built from a date's Myanmar calendar and
/// astrological details. Kept apart from the core calendar API.
///
/// ```dart
/// import 'package:myanmar_calendar_dart/ai.dart';
///
/// final prompt = AIPromptService.generatePrompt(
///   MyanmarCalendar.getCompleteDateFor(2026, 10, 18),
///   language: Language.myanmar,
///   type: AIPromptType.horoscope,
/// );
/// ```
library;

export 'src/services/ai_prompt_service.dart';
