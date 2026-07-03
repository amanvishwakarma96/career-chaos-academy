import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/reputation_model.dart';
import 'package:career_chaos_academy/models/role_progress_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/consequence_service.dart';
import 'package:career_chaos_academy/services/finale_service.dart';
import 'package:career_chaos_academy/services/reputation_service.dart';

void main() {
  test('ConsequenceService sets and clears flags', () {
    final outcome = OutcomeModel.fromJson(<String, dynamic>{
      'title': 'Shortcut',
      'description': 'A shortcut creates future cleanup.',
      'moralLesson': 'Shortcuts create hidden work.',
      'setFlags': <String>['skipped_testing'],
      'clearFlags': <String>['unknown_root_cause'],
      'unlockCleanupMissionIds': <String>['rollback_cleanup'],
    });

    final result = ConsequenceService.instance.applyOutcome(
      currentFlags: <String>{'unknown_root_cause'},
      outcome: outcome,
    );

    expect(result.activeFlags, contains('skipped_testing'));
    expect(result.activeFlags, isNot(contains('unknown_root_cause')));
    expect(result.flagsSet, contains('skipped_testing'));
    expect(result.flagsCleared, contains('unknown_root_cause'));
    expect(result.unlockedCleanupMissionIds, contains('rollback_cleanup'));
  });

  test('ReputationService applies impact', () {
    final updated = ReputationService.instance.applyImpact(
      current: const ReputationModel(trust: 2),
      impact: const ReputationModel(trust: -1, safety: 3),
    );

    expect(updated.trust, 1);
    expect(updated.safety, 3);
  });

  test('FinaleService calculates unsafe and expert endings', () {
    final unsafe = FinaleService.instance.calculateEnding(
      progress: const RoleProgressModel(roleId: 'developer'),
      roleScore: const ScoreModel(chaos: 13),
      reputation: const ReputationModel(safety: -6),
      activeFlags: const <String>{'skipped_testing'},
      completedCleanupMissionIds: const <String>{},
    );

    final expert = FinaleService.instance.calculateEnding(
      progress: const RoleProgressModel(roleId: 'developer'),
      roleScore: const ScoreModel(
        skill: 20,
        discipline: 15,
        ethics: 12,
        communication: 10,
        chaos: 2,
      ),
      reputation: const ReputationModel(
        trust: 8,
        safety: 7,
        professionalism: 7,
        reliability: 7,
        stakeholderConfidence: 7,
      ),
      activeFlags: const <String>{},
      completedCleanupMissionIds: const <String>{'rollback_cleanup'},
    );

    expect(unsafe, 'Unsafe Intern');
    expect(expert, 'Role Expert');
  });
}
