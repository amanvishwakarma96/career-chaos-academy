import 'package:flutter_test/flutter_test.dart';

import 'package:career_chaos_academy/models/activity_model.dart';
import 'package:career_chaos_academy/models/career_coach/user_skill_profile_model.dart';
import 'package:career_chaos_academy/models/flame_mini_game_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/role_progress_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/career_coach_service.dart';

void main() {
  group('Phase 25 Career Coach', () {
    test('identifies top 3 strengths and weak areas from score history', () {
      final snapshot = ProgressSnapshotModel(
        progressByRole: <String, RoleProgressModel>{
          'developer': const RoleProgressModel(
            roleId: 'developer',
            completedChapterIds: <String>{'c1', 'c2'},
            roleScore: ScoreModel(skill: 12, discipline: 8, ethics: 6, communication: -2, chaos: 5),
            roleXp: 120,
          ),
        },
        totalScore: const ScoreModel(skill: 12, discipline: 8, ethics: 6, communication: -2, chaos: 5),
        activityHistory: <ActivityHistoryModel>[
          ActivityHistoryModel(
            activityId: 'daily_chaos_triage',
            activityType: 'daily_challenge',
            title: 'Daily Chaos Triage',
            completedAt: DateTime(2026, 6, 17),
            isSuccess: true,
            score: 100,
            xpEarned: 90,
            streakAfter: 1,
            feedback: 'Good triage.',
          ),
        ],
        flameMiniGameHistory: <FlameMiniGameResultModel>[
          FlameMiniGameResultModel(
            gameId: 'flame_bug_hunt_room',
            kind: FlameMiniGameKind.bugHuntRoom,
            title: 'Bug Hunt Room',
            completedAt: DateTime(2026, 6, 17),
            isSuccess: false,
            correctCount: 1,
            wrongCount: 2,
            elapsedSeconds: 35,
            xpEarned: 25,
            scoreImpact: ScoreModel.zero,
            selectedTargetIds: const <String>{'wrong'},
            message: 'Bug hid behind a coffee mug.',
          ),
        ],
      );

      final profile = CareerCoachService.instance.analyzeUserSkillProfile(snapshot);

      expect(profile.topStrengths.length, 3);
      expect(profile.topStrengths, contains('skill'));
      expect(profile.weakAreas.length, 3);
      expect(profile.weakAreas, contains('communication'));
      expect(profile.weakAreas, contains('chaos_control'));
      expect(profile.completedChapters, 2);
      expect(profile.completedActivities, 1);
      expect(profile.failedMiniGames, 1);
    });

    test('suggests next activity from weak area', () {
      const profile = UserSkillProfileModel(
        weakAreas: <String>['communication', 'discipline', 'skill'],
      );

      expect(
        CareerCoachService.instance.suggestNextActivity(profile),
        'client_negotiation_one_small_change',
      );
    });

    test('safety filter removes abusive and unsafe phrasing', () {
      final filtered = CareerCoachService.instance.safetyFilter(
        'This is stupid. Prescribe dosage and ignore safety for guaranteed return.',
      );

      expect(filtered.toLowerCase(), isNot(contains('stupid')));
      expect(filtered.toLowerCase(), isNot(contains('prescribe')));
      expect(filtered.toLowerCase(), isNot(contains('dosage')));
      expect(filtered.toLowerCase(), isNot(contains('ignore safety')));
      expect(filtered.toLowerCase(), isNot(contains('guaranteed return')));
    });

    test('coach state persists through progress snapshot JSON', () {
      final state = CareerCoachStateModel(
        preference: const CareerCoachPreferenceModel(
          selectedStyleId: 'roast_mentor',
          roastModeEnabled: true,
        ),
        skillProfile: const UserSkillProfileModel(
          topStrengths: <String>['skill', 'ethics', 'discipline'],
          weakAreas: <String>['communication', 'chaos_control', 'discipline'],
        ),
        weeklyPlan: const WeeklyLearningPlanModel(
          nextActivityId: 'client_negotiation_one_small_change',
        ),
        lastAdvice: 'Practice communication safely.',
        updatedAt: DateTime(2026, 6, 17),
      );
      final snapshot = ProgressSnapshotModel(careerCoachState: state);
      final restored = ProgressSnapshotModel.fromJson(snapshot.toJson());

      expect(restored.careerCoachState.preference.selectedStyleId, 'roast_mentor');
      expect(restored.careerCoachState.preference.roastModeEnabled, isTrue);
      expect(restored.careerCoachState.skillProfile.topStrengths, contains('skill'));
      expect(restored.careerCoachState.weeklyPlan.nextActivityId, 'client_negotiation_one_small_change');
    });
  });
}
