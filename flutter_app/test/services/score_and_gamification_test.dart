import 'package:career_chaos_academy/models/rank_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/gamification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ScoreModel adds all score dimensions and subtracts chaos from total', () {
    final first = const ScoreModel(skill: 3, discipline: 2, ethics: 1, communication: 4, chaos: 1);
    final second = const ScoreModel(skill: 2, discipline: -1, ethics: 3, communication: 0, chaos: 2);

    final total = first.add(second);

    expect(total.skill, 5);
    expect(total.discipline, 1);
    expect(total.ethics, 4);
    expect(total.communication, 4);
    expect(total.chaos, 3);
    expect(total.total, 11);
  });

  test('XP calculation rewards positive score but clamps extreme values safely', () {
    final service = GamificationService.instance;

    expect(
      service.calculateXp(const ScoreModel(skill: 4, discipline: 4, ethics: 2, communication: 2)),
      greaterThan(75),
    );
    expect(
      service.calculateXp(const ScoreModel(skill: -10, discipline: -10, ethics: -10, communication: -10, chaos: 99)),
      25,
    );
    expect(
      service.calculateXp(const ScoreModel(skill: 99, discipline: 99, ethics: 99, communication: 99)),
      250,
    );
  });

  test('career rank updates from Intern to higher ranks based on XP', () {
    final service = GamificationService.instance;

    expect(service.rankForXp(0).rank, CareerRank.intern);
    expect(service.rankForXp(250).rank, CareerRank.junior);
    expect(service.rankForXp(1100).rank, CareerRank.professional);
    expect(service.rankForXp(3500).rank, CareerRank.legend);
  });
}
