import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/mentor/mentor_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/mentor_service.dart';

void main() {
  group('Phase 22 mentor system', () {
    test('mentor JSON parses with personality and safety boundary', () {
      final mentor = MentorModel.fromJson(<String, dynamic>{
        'id': 'strict_senior',
        'name': 'Rao Sir',
        'title': 'Strict Senior Reviewer',
        'style': 'direct_process_first',
        'description': 'Direct but safe feedback.',
        'archetype': 'mentor',
        'emoji': '📋',
        'strengths': ['discipline'],
        'roastLines': ['The shortcut needed a helmet.'],
        'safetyBoundary': 'Never abusive.',
      });

      expect(mentor.id, 'strict_senior');
      expect(mentor.style, 'direct_process_first');
      expect(mentor.roastLines, isNotEmpty);
      expect(mentor.safetyBoundary, contains('Never'));
    });

    test('mentor preference defaults and serializes safely', () {
      const preference = MentorPreferenceModel(
        selectedMentorId: 'funny_friend',
        roastModeEnabled: true,
      );
      final restored = MentorPreferenceModel.fromJson(preference.toJson());

      expect(restored.selectedMentorId, 'funny_friend');
      expect(restored.roastModeEnabled, true);
      expect(MentorPreferenceModel.fromJson(const <String, dynamic>{}).selectedMentorId, 'balanced_coach');
    });

    test('progress snapshot stores mentor preference with old data fallback', () {
      final oldSnapshot = ProgressSnapshotModel.fromJson(const <String, dynamic>{
        'version': 1,
        'progressByRole': {},
        'totalXp': 0,
      });
      expect(oldSnapshot.mentorPreference.selectedMentorId, 'balanced_coach');
      expect(oldSnapshot.mentorPreference.roastModeEnabled, false);

      final newSnapshot = ProgressSnapshotModel.fromJson(<String, dynamic>{
        'version': 9,
        'progressByRole': <String, dynamic>{},
        'mentorPreference': <String, dynamic>{
          'selectedMentorId': 'empathetic_mentor',
          'roastModeEnabled': false,
        },
      });
      expect(newSnapshot.mentorPreference.selectedMentorId, 'empathetic_mentor');
    });

    test('weak area detection identifies low score dimensions', () {
      final weakAreas = MentorService.instance.detectWeakAreas(
        const ScoreModel(skill: -1, discipline: 0, ethics: 2, communication: -2, chaos: 3),
      );

      expect(weakAreas, contains('skill'));
      expect(weakAreas, contains('discipline'));
      expect(weakAreas, contains('communication'));
      expect(weakAreas, contains('chaos control'));
      expect(weakAreas, isNot(contains('ethics')));
    });

    test('next activity suggestion maps weak area to practice', () {
      final suggestion = MentorService.instance.suggestNextActivity(
        const <String>['communication'],
      );
      expect(suggestion.toLowerCase(), contains('negotiation'));
    });

    test('weekly summary is safe and non-blocking with empty progress', () {
      final summary = MentorService.instance.weeklyProgressSummary(
        const ProgressSnapshotModel(),
      );
      expect(summary, contains('XP'));
      expect(summary, isNot(contains('idiot')));
    });
  });
}
