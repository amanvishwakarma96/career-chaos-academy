import 'package:career_chaos_academy/models/choice_model.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/role_progress_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/progress_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build and debug software.',
    iconKey: 'code',
  );

  ScenarioModel chapter(String id) => ScenarioModel(
        id: id,
        role: role,
        title: 'Chapter $id',
        difficulty: 'Beginner',
        theme: 'Testing',
        story: 'A small story.',
        task: 'Choose wisely.',
        professionalLearningPoint: 'Test before release.',
        choices: const <ChoiceModel>[
          ChoiceModel(
            text: 'Do the right thing',
            outcome: OutcomeModel(
              title: 'Good',
              description: 'Everything works.',
              moralLesson: 'Quality matters.',
            ),
            scoreImpact: ScoreModel(skill: 1),
          ),
        ],
      );

  test('chapter 1 is unlocked by default and completing it unlocks next chapter', () {
    final chapters = <ScenarioModel>[chapter('c1'), chapter('c2'), chapter('c3')];
    final initial = const RoleProgressModel(roleId: 'developer');

    expect(initial.isChapterUnlocked(0), isTrue);
    expect(initial.isChapterUnlocked(1), isFalse);
    expect(initial.chapterState(0, 'c1'), ChapterProgressState.current);

    final updated = initial.completeChapter(
      chapters: chapters,
      completedChapter: chapters.first,
      scoreImpact: const ScoreModel(skill: 4, discipline: 2),
      xpGained: 120,
    );

    expect(updated.isChapterCompleted('c1'), isTrue);
    expect(updated.isChapterUnlocked(1), isTrue);
    expect(updated.chapterState(0, 'c1'), ChapterProgressState.completed);
    expect(updated.chapterState(1, 'c2'), ChapterProgressState.current);
    expect(updated.roleScore.skill, 4);
    expect(updated.roleXp, 120);
  });

  test('re-completing the same chapter does not double count score or XP', () {
    final chapters = <ScenarioModel>[chapter('c1'), chapter('c2')];
    final once = const RoleProgressModel(roleId: 'developer').completeChapter(
      chapters: chapters,
      completedChapter: chapters.first,
      scoreImpact: const ScoreModel(skill: 4),
      xpGained: 100,
    );

    final twice = once.completeChapter(
      chapters: chapters,
      completedChapter: chapters.first,
      scoreImpact: const ScoreModel(skill: 4),
      xpGained: 100,
    );

    expect(twice.completedChapterIds, {'c1'});
    expect(twice.roleScore.skill, 4);
    expect(twice.roleXp, 100);
  });

  test('in-memory progress storage saves and restores a full progress snapshot', () async {
    final storage = InMemoryProgressStorage();
    final snapshot = ProgressSnapshotModel(
      progressByRole: <String, RoleProgressModel>{
        'developer': const RoleProgressModel(
          roleId: 'developer',
          completedChapterIds: <String>{'c1'},
          unlockedChapterIndex: 1,
          roleScore: ScoreModel(skill: 3),
          roleXp: 100,
          badges: <String>{'first_chapter_completed'},
        ),
      },
      totalScore: const ScoreModel(skill: 3),
      totalXp: 100,
      badges: const <String>{'first_chapter_completed'},
    );

    await storage.saveProgress(snapshot);
    final restored = await storage.loadProgress();

    expect(restored.totalXp, 100);
    expect(restored.progressByRole['developer']?.unlockedChapterIndex, 1);
    expect(restored.badges, contains('first_chapter_completed'));
  });

  test('shared preferences storage safely falls back when saved JSON is corrupt', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'career_chaos_progress_v1': '{broken json',
    });

    final restored = await SharedPreferencesProgressStorage().loadProgress();

    expect(restored.progressByRole, isEmpty);
    expect(restored.totalXp, 0);
  });
}
