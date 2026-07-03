import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/models/skill_tree/skill_tree_model.dart';

void main() {
  test('skill tree model parses nodes and prerequisite unlocks', () {
    final tree = SkillTreeModel.fromJson({
      'roleId': 'developer',
      'title': 'Developer Skill Tree',
      'nodes': [
        {'id': 'dev_foundations', 'title': 'Foundations'},
        {
          'id': 'dev_release_safety',
          'title': 'Release Safety',
          'prerequisiteNodeIds': ['dev_foundations'],
          'masteryTarget': 100,
        },
      ],
    });
    expect(tree.nodes.length, 2);
    var progress = const SkillTreeProgressModel(roleId: 'developer');
    expect(progress.isNodeUnlocked(tree.nodes.first), true);
    expect(progress.isNodeUnlocked(tree.nodes.last), false);
    progress = progress.upsertNodeProgress(
      const SkillNodeProgressModel(nodeId: 'dev_foundations', masteryPoints: 100),
    );
    expect(progress.isNodeUnlocked(tree.nodes.last), true);
  });

  test('scenario JSON can link a chapter to skill node ids', () {
    final role = RoleModel(id: 'developer', name: 'Developer', description: 'Build safely.', iconKey: 'developer');
    final scenario = ScenarioModel.fromJson({
      'id': 'dev_story',
      'title': 'Production Panic',
      'difficulty': 'beginner',
      'theme': 'release safety',
      'story': 'A deployment is about to go sideways.',
      'task': 'Choose the safest response.',
      'choices': [
        {
          'id': 'safe',
          'text': 'Pause and verify evidence.',
          'outcome': {
            'title': 'Evidence first',
            'description': 'You prevented chaos.',
            'moralLesson': 'Safety needs verification.',
            'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0}
          }
        }
      ],
      'skillNodeIds': ['dev_release_safety']
    }, role: role);
    expect(scenario.skillNodeIds, contains('dev_release_safety'));
  });

  test('old progress JSON remains compatible with empty skill progress', () {
    final snapshot = ProgressSnapshotModel.fromJson({
      'version': 1,
      'progressByRole': {},
      'totalXp': 0,
    });
    expect(snapshot.skillTreeProgressByRole, isEmpty);
  });

  test('new progress JSON preserves skill progress', () {
    final snapshot = ProgressSnapshotModel.fromJson({
      'version': 13,
      'skillTreeProgressByRole': {
        'developer': {
          'roleId': 'developer',
          'nodeProgress': {
            'dev_foundations': {
              'nodeId': 'dev_foundations',
              'masteryPoints': 45,
              'completedSourceIds': ['chapter:dev_story']
            }
          }
        }
      }
    });
    expect(snapshot.skillTreeProgressByRole['developer']!.progressFor('dev_foundations').masteryPoints, 45);
  });
}
