import 'package:career_chaos_academy/data/scenario_asset_paths.dart';
import 'package:career_chaos_academy/models/mini_game_model.dart';
import 'package:career_chaos_academy/services/scenario_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every static scenario JSON asset without using API', () async {
    final result = await ScenarioService.instance.loadScenarios(
      assetPaths: scenarioAssetPaths,
      preferApi: false,
    );

    expect(result.errors, isEmpty);
    expect(result.roles, hasLength(8));
    expect(result.roles.every((role) => role.chapters.isNotEmpty), isTrue);
    expect(result.scenarios.length, greaterThanOrEqualTo(24));
  });

  test('keeps valid scenarios when one JSON asset is missing or invalid', () async {
    final result = await ScenarioService.instance.loadScenarios(
      assetPaths: const <String>[
        'assets/scenarios/developer.json',
        'assets/scenarios/not_real.json',
      ],
      preferApi: false,
    );

    expect(result.roles, hasLength(1));
    expect(result.roles.first.role.id, 'developer');
    expect(result.errors, hasLength(1));
    expect(result.hasScenarios, isTrue);
  });

  test('loads mini-games required for Phase 6 regression', () async {
    final result = await ScenarioService.instance.loadScenarios(
      assetPaths: scenarioAssetPaths,
      preferApi: false,
    );

    final developer = result.roles.firstWhere((role) => role.role.id == 'developer');
    final qa = result.roles.firstWhere((role) => role.role.id == 'qa_tester');
    final backOffice = result.roles.firstWhere(
      (role) => role.role.id == 'back_office_executive',
    );

    expect(developer.chapters.first.miniGame?.type, MiniGameType.codeFix);
    expect(qa.chapters.first.miniGame?.type, MiniGameType.multipleSelect);
    expect(backOffice.chapters.first.miniGame?.type, MiniGameType.dataCleanup);
  });
}
