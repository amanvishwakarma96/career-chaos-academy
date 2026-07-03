import 'content_agent_prompt.dart';

class ContentGenerationPromptService {
  const ContentGenerationPromptService._();

  static const outputJsonFormat = '''
Return only one app-ready JSON object using this structure:
{
  "role": {
    "id": "snake_case_role_id",
    "name": "Human Readable Role Name",
    "description": "One sentence role description.",
    "iconKey": "code | science | engineering | architecture | business | manager | hr | medical | education | default"
  },
  "chapters": [
    {
      "id": "role_unique_chapter_id",
      "title": "Funny scenario title",
      "difficulty": "Beginner | Intermediate | Advanced",
      "theme": "Skills/theme covered",
      "story": "Dialogue-style scenario with humor and realistic workplace chaos.",
      "scenario": "Same meaning as story, included for AI review compatibility.",
      "task": "What the player must decide or solve.",
      "professionalLearningPoint": "Safe practical learning point for this role.",
      "safetyDisclaimer": "Required for medical, legal, financial, safety-critical, or high-risk content. Keep it educational and tell the user to consult a qualified professional when needed.",
      "choices": [
        {
          "text": "Player choice text",
          "outcome": {
            "title": "Outcome title",
            "description": "Funny consequence or positive result.",
            "moralLesson": "Clear moral lesson."
          },
          "scoreImpact": {
            "skill": 0,
            "discipline": 0,
            "ethics": 0,
            "communication": 0,
            "chaos": 0
          }
        }
      ],
      "miniGame": {
        "id": "optional_unique_minigame_id",
        "type": "multiple_select | code_fix | match_pairs | arrange_order | data_cleanup | decision_matrix",
        "title": "Mini-game title",
        "instructions": "How to play safely.",
        "prompt": "Mini-game prompt.",
        "hint": "Helpful hint.",
        "options": [
          {"id": "a", "text": "Option text", "helperText": "Optional helper"}
        ],
        "correctOptionIds": ["a"],
        "pairs": [
          {"leftId": "l1", "leftText": "Left", "rightId": "r1", "rightText": "Right"}
        ],
        "orderItems": [
          {"id": "step_1", "text": "Step text"}
        ],
        "correctOrderIds": ["step_1"],
        "successScoreImpact": {
          "skill": 2,
          "discipline": 1,
          "ethics": 0,
          "communication": 0,
          "chaos": -1
        },
        "failureScoreImpact": {
          "skill": 0,
          "discipline": -1,
          "ethics": 0,
          "communication": 0,
          "chaos": 2
        },
        "successMessage": "Funny success message.",
        "failureMessage": "Funny failure consequence."
      }
    }
  ]
}

Mini-game shape notes:
- multiple_select, code_fix, data_cleanup, and decision_matrix need options + correctOptionIds.
- match_pairs needs pairs.
- arrange_order needs orderItems + correctOrderIds.
- Every scoreImpact must include skill, discipline, ethics, communication, and chaos.
''';

  static const List<ContentAgentPrompt> prompts = <ContentAgentPrompt>[
    ContentAgentPrompt(
      agentName: 'Brainstorming Lead',
      responsibility: 'Create funny, playable ideas without unsafe advice.',
      prompt: '''
You are the Brainstorming Lead for Career Chaos Academy.
Generate 5 funny role-based scenario ideas for the requested profession.
Each idea must include workplace chaos, player decision tension, humor, a moral lesson, and a professional learning point.
Avoid real harmful instructions. For medical, legal, financial, safety, or compliance topics, keep content educational and recommend qualified human review.
Do not write final JSON yet. Provide concise idea cards only.
''',
    ),
    ContentAgentPrompt(
      agentName: 'Business Analyst',
      responsibility: 'Turn the selected idea into structured learning requirements.',
      prompt: '''
You are the Business Analyst for Career Chaos Academy.
Convert the selected idea into a structured chapter requirement.
Define role name, chapter title, difficulty, theme, scenario, task, learning objective, moral lesson, professional learning point, player choices, expected outcomes, safe limits, and whether a mini-game is useful.
For medical/legal/financial content, include a safety disclaimer and avoid diagnosis, prescription, guaranteed financial claims, legal conclusions, or step-by-step high-risk advice.
''',
    ),
    ContentAgentPrompt(
      agentName: 'Developer',
      responsibility: 'Produce app-ready JSON compatible with the Flutter parser.',
      prompt: '''
You are the Developer Agent for Career Chaos Academy.
Transform the approved BA requirement into valid app-ready JSON.
Follow the exact JSON format provided by the project. Use snake_case ids. Include role, chapters, choices, outcomes, scoreImpact, professionalLearningPoint, and optional miniGame.
Return only JSON. Do not include markdown, comments, or explanations.
''',
    ),
    ContentAgentPrompt(
      agentName: 'QA Tester',
      responsibility: 'Validate JSON structure, gameplay completeness, and safety rules.',
      prompt: '''
You are the QA Tester Agent for Career Chaos Academy.
Review the generated JSON before it is added to the app.
Check that every required field exists, choices have outcomes, scoreImpact has all 5 score keys, mini-game shape matches its type, humor is present, learning is clear, and high-stakes content is safe.
Reject content that provides dangerous diagnosis, prescription, guaranteed financial advice, legal conclusions, discrimination, harassment, or harmful instructions.
Return a pass/fail report with exact JSON paths to fix.
''',
    ),
    ContentAgentPrompt(
      agentName: 'Project Manager',
      responsibility: 'Approve only safe, useful, shippable content.',
      prompt: '''
You are the Project Manager Agent for Career Chaos Academy.
Make the final release decision after QA review.
Approve only if the JSON is app-ready, safe, funny, educational, and aligned with the target role.
Require human approval before saving the scenario file into assets/scenarios.
If rejected, list the minimum fixes required for approval.
''',
    ),
  ];

  static String get combinedWorkflowPrompt {
    final buffer = StringBuffer()
      ..writeln('Career Chaos Academy Multi-Agent Content Workflow')
      ..writeln()
      ..writeln('Run these agents in order. Do not skip review or safety checks.')
      ..writeln();

    for (final prompt in prompts) {
      buffer
        ..writeln('## ${prompt.agentName}')
        ..writeln('Responsibility: ${prompt.responsibility}')
        ..writeln(prompt.prompt.trim())
        ..writeln();
    }

    buffer
      ..writeln('## Required Output JSON Format')
      ..writeln(outputJsonFormat.trim())
      ..writeln()
      ..writeln('Final rule: user approval is required before saving generated JSON into the app.');

    return buffer.toString();
  }
}
