import 'package:career_chaos_academy/models/choice_model.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/role_scenario_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/widgets/choice_button.dart';
import 'package:career_chaos_academy/widgets/role_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build and debug software.',
    iconKey: 'code',
  );

  const choice = ChoiceModel(
    text: 'Read logs before changing code',
    outcome: OutcomeModel(
      title: 'Clean Fix',
      description: 'The bug is fixed.',
      moralLesson: 'Evidence first.',
    ),
    scoreImpact: ScoreModel(skill: 3),
  );

  testWidgets('RoleCard displays role, chapter count, progress, and handles tap', (tester) async {
    var tapped = false;
    final roleScenario = RoleScenarioModel(
      role: role,
      chapters: <ScenarioModel>[
        ScenarioModel(
          id: 'c1',
          role: role,
          title: 'One',
          difficulty: 'Beginner',
          theme: 'Theme',
          story: 'Story',
          task: 'Task',
          choices: const <ChoiceModel>[choice],
        ),
        ScenarioModel(
          id: 'c2',
          role: role,
          title: 'Two',
          difficulty: 'Beginner',
          theme: 'Theme',
          story: 'Story',
          task: 'Task',
          choices: const <ChoiceModel>[choice],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 220,
            child: RoleCard(
              roleScenario: roleScenario,
              progressPercent: 0.5,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('2 chapters'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    await tester.tap(find.byType(RoleCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('ChoiceButton displays choice text and calls onPressed', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChoiceButton(
            choice: choice,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Read logs before changing code'), findsOneWidget);
    await tester.tap(find.byType(ChoiceButton));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
