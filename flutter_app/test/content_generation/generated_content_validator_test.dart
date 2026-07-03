import 'dart:convert';

import 'package:career_chaos_academy/content_generation/generated_content_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validGeneratedJson = '''
{
  "role": {
    "id": "support_engineer",
    "name": "Support Engineer",
    "description": "Handle production support with calm investigation.",
    "iconKey": "support"
  },
  "chapters": [
    {
      "id": "support_ticket_tornado",
      "title": "Ticket Tornado",
      "difficulty": "Beginner",
      "theme": "Incident triage",
      "scenario": "Ten users report the same bug and one message only says: app doing dhak-dhak.",
      "task": "Triage the incident safely.",
      "professionalLearningPoint": "Group duplicate reports and verify impact before escalation.",
      "choices": [
        {
          "text": "Group duplicate reports and collect logs.",
          "outcome": {
            "title": "Calm Triage Ending",
            "description": "You identify one root cause instead of ten imaginary monsters.",
            "moralLesson": "Structure turns chaos into action."
          },
          "scoreImpact": { "skill": 4, "discipline": 3, "ethics": 1, "communication": 3, "chaos": 0 }
        },
        {
          "text": "Close all tickets as cannot reproduce.",
          "outcome": {
            "title": "Boomerang Ticket Ending",
            "description": "The tickets return with sunglasses and louder subject lines.",
            "moralLesson": "Ignoring evidence creates bigger problems."
          },
          "scoreImpact": { "skill": -1, "discipline": -2, "ethics": -2, "communication": -1, "chaos": 5 }
        }
      ]
    }
  ]
}
''';

  test('valid generated content becomes app-ready normalized JSON', () {
    final result = GeneratedContentValidator.instance.validate(validGeneratedJson);

    expect(result.isAppReady, isTrue);
    expect(result.hasErrors, isFalse);
    expect(result.normalizedJson, isNotNull);

    final normalized = jsonDecode(result.normalizedJson!) as Map<String, dynamic>;
    final chapter = (normalized['chapters'] as List).first as Map<String, dynamic>;
    expect(chapter['story'], isNotEmpty);
    expect(chapter['scenario'], isNotEmpty);
  });

  test('medical content without safety disclaimer is blocked for review', () {
    final unsafeMedical = validGeneratedJson
        .replaceAll('"id": "support_engineer"', '"id": "doctor"')
        .replaceAll('"name": "Support Engineer"', '"name": "Doctor"')
        .replaceAll('"description": "Handle production support with calm investigation."', '"description": "Handle patient scenarios safely."')
        .replaceAll('"iconKey": "support"', '"iconKey": "medical"')
        .replaceAll('Triage the incident safely.', 'Diagnose and prescribe immediately.');

    final result = GeneratedContentValidator.instance.validate(unsafeMedical);

    expect(result.hasErrors, isTrue);
    expect(
      result.errors.map((issue) => issue.message).join('\n').toLowerCase(),
      contains('medical'),
    );
  });

  test('unsupported mini-game types are rejected', () {
    final json = validGeneratedJson.replaceFirst(
      '"choices": [',
      '"miniGame": { "id": "bad_game", "type": "rocket_launcher", "title": "Bad", "instructions": "Bad", "prompt": "Bad", "hint": "Bad", "successMessage": "Bad", "failureMessage": "Bad", "successScoreImpact": { "skill": 1, "discipline": 0, "ethics": 0, "communication": 0, "chaos": 0 }, "failureScoreImpact": { "skill": 0, "discipline": 0, "ethics": 0, "communication": 0, "chaos": 1 } }, "choices": [',
    );

    final result = GeneratedContentValidator.instance.validate(json);

    expect(result.hasErrors, isTrue);
    expect(result.errors.any((issue) => issue.message.contains('Unsupported mini-game')), isTrue);
  });
}
