import '../models/badge_model.dart';
import '../models/rank_model.dart';
import '../models/role_progress_model.dart';
import '../models/role_scenario_model.dart';
import '../models/score_model.dart';

class BadgeEvaluationResult {
  final Set<String> allUnlockedBadgeIds;
  final List<BadgeModel> newlyUnlockedBadges;
  final Set<String> currentRoleBadgeIds;

  const BadgeEvaluationResult({
    required this.allUnlockedBadgeIds,
    required this.newlyUnlockedBadges,
    required this.currentRoleBadgeIds,
  });
}

class GamificationService {
  GamificationService._();

  static final GamificationService instance = GamificationService._();

  static const List<RankModel> ranks = <RankModel>[
    RankModel(
      rank: CareerRank.intern,
      title: 'Intern',
      minimumXp: 0,
      nextRankXp: 250,
    ),
    RankModel(
      rank: CareerRank.junior,
      title: 'Junior',
      minimumXp: 250,
      nextRankXp: 600,
    ),
    RankModel(
      rank: CareerRank.associate,
      title: 'Associate',
      minimumXp: 600,
      nextRankXp: 1100,
    ),
    RankModel(
      rank: CareerRank.professional,
      title: 'Professional',
      minimumXp: 1100,
      nextRankXp: 1750,
    ),
    RankModel(
      rank: CareerRank.senior,
      title: 'Senior',
      minimumXp: 1750,
      nextRankXp: 2550,
    ),
    RankModel(
      rank: CareerRank.expert,
      title: 'Expert',
      minimumXp: 2550,
      nextRankXp: 3500,
    ),
    RankModel(
      rank: CareerRank.legend,
      title: 'Legend',
      minimumXp: 3500,
    ),
  ];

  List<BadgeModel> get allBadges => const <BadgeModel>[
        BadgeModel(
          id: 'first_chapter_completed',
          title: 'First Day Survivor',
          description: 'Completed your first Career Chaos chapter.',
          lockedHint: 'Complete any Chapter 1 to unlock this badge.',
          iconKey: 'flag',
        ),
        BadgeModel(
          id: 'five_chapter_finisher',
          title: 'Chaos Regular',
          description: 'Completed 5 chapters across all careers.',
          lockedHint: 'Complete 5 total chapters.',
          iconKey: 'menu_book',
        ),
        BadgeModel(
          id: 'ten_chapter_finisher',
          title: 'Multi-Role Explorer',
          description: 'Completed 10 chapters across different careers.',
          lockedHint: 'Complete 10 total chapters.',
          iconKey: 'explore',
        ),
        BadgeModel(
          id: 'skill_builder',
          title: 'Skill Builder',
          description: 'Reached 25 total skill points.',
          lockedHint: 'Choose outcomes that improve skill.',
          iconKey: 'build',
        ),
        BadgeModel(
          id: 'ethical_operator',
          title: 'Ethical Operator',
          description: 'Reached 20 total ethics points.',
          lockedHint: 'Choose responsible outcomes that improve ethics.',
          iconKey: 'verified',
        ),
        BadgeModel(
          id: 'calm_communicator',
          title: 'Calm Communicator',
          description: 'Reached 20 communication points while keeping chaos below 25.',
          lockedHint: 'Improve communication without creating too much chaos.',
          iconKey: 'chat',
        ),
        BadgeModel(
          id: 'chaos_survivor',
          title: 'Chaos Survivor',
          description: 'Collected 20 chaos points and still kept playing.',
          lockedHint: 'Experience enough chaotic outcomes.',
          iconKey: 'local_fire_department',
        ),
        BadgeModel(
          id: 'junior_rank_reached',
          title: 'Promoted to Junior',
          description: 'Reached Junior career rank.',
          lockedHint: 'Earn 250 XP.',
          iconKey: 'trending_up',
        ),
        BadgeModel(
          id: 'professional_rank_reached',
          title: 'Professional Mode',
          description: 'Reached Professional career rank.',
          lockedHint: 'Earn 1100 XP.',
          iconKey: 'workspace_premium',
        ),
        BadgeModel(
          id: 'legend_rank_reached',
          title: 'Career Chaos Legend',
          description: 'Reached Legend career rank.',
          lockedHint: 'Earn 3500 XP.',
          iconKey: 'emoji_events',
        ),
        BadgeModel(
          id: 'developer_role_completed',
          title: 'Developer Debugger',
          description: 'Completed every Developer chapter.',
          lockedHint: 'Complete all Developer chapters.',
          iconKey: 'code',
        ),
        BadgeModel(
          id: 'qa_tester_role_completed',
          title: 'Bug Hunter',
          description: 'Completed every QA Tester chapter.',
          lockedHint: 'Complete all QA Tester chapters.',
          iconKey: 'bug',
        ),
        BadgeModel(
          id: 'doctor_role_completed',
          title: 'Diagnosis Dynamo',
          description: 'Completed every Doctor chapter.',
          lockedHint: 'Complete all Doctor chapters.',
          iconKey: 'medical',
        ),
        BadgeModel(
          id: 'civil_engineer_role_completed',
          title: 'Site Safety Hero',
          description: 'Completed every Civil Engineer chapter.',
          lockedHint: 'Complete all Civil Engineer chapters.',
          iconKey: 'engineering',
        ),
        BadgeModel(
          id: 'architect_role_completed',
          title: 'Blueprint Boss',
          description: 'Completed every Architect chapter.',
          lockedHint: 'Complete all Architect chapters.',
          iconKey: 'architecture',
        ),
        BadgeModel(
          id: 'back_office_executive_role_completed',
          title: 'Spreadsheet Saviour',
          description: 'Completed every Back Office Executive chapter.',
          lockedHint: 'Complete all Back Office chapters.',
          iconKey: 'table',
        ),
        BadgeModel(
          id: 'project_manager_role_completed',
          title: 'Scope Controller',
          description: 'Completed every Project Manager chapter.',
          lockedHint: 'Complete all Project Manager chapters.',
          iconKey: 'project',
        ),
        BadgeModel(
          id: 'hr_executive_role_completed',
          title: 'People Pro',
          description: 'Completed every HR Executive chapter.',
          lockedHint: 'Complete all HR chapters.',
          iconKey: 'people',
        ),
        BadgeModel(
          id: 'daily_chaos_starter',
          title: 'Daily Chaos Starter',
          description: 'Completed a daily activity challenge.',
          lockedHint: 'Complete a daily challenge in Activity Hub.',
          iconKey: 'today',
        ),
        BadgeModel(
          id: 'bug_hunt_pro',
          title: 'Bug Hunt Pro',
          description: 'Completed a bug hunt activity.',
          lockedHint: 'Complete the QA bug hunt activity.',
          iconKey: 'bug',
        ),
        BadgeModel(
          id: 'cleanup_racer',
          title: 'Cleanup Racer',
          description: 'Completed a data cleanup race.',
          lockedHint: 'Complete the Back Office cleanup race.',
          iconKey: 'table',
        ),
        BadgeModel(
          id: 'scope_negotiator',
          title: 'Scope Negotiator',
          description: 'Completed a client negotiation activity.',
          lockedHint: 'Complete the Project Manager negotiation activity.',
          iconKey: 'project',
        ),
        BadgeModel(
          id: 'safe_triage_thinker',
          title: 'Safe Triage Thinker',
          description: 'Completed a safe triage dilemma.',
          lockedHint: 'Complete the Doctor ethical dilemma activity.',
          iconKey: 'medical',
        ),
        BadgeModel(
          id: 'ethical_feedback_quiz',
          title: 'Ethical Feedback Quizzer',
          description: 'Completed the HR feedback quiz activity.',
          lockedHint: 'Complete the HR role quiz activity.',
          iconKey: 'people',
        ),
      ];

  int calculateXp(ScoreModel scoreImpact) {
    final positiveScore = scoreImpact.skill +
        scoreImpact.discipline +
        scoreImpact.ethics +
        scoreImpact.communication;
    final chaosPenalty = scoreImpact.chaos * 3;
    final xp = 75 + (positiveScore * 12) - chaosPenalty;

    return xp.clamp(25, 250).toInt();
  }

  RankModel rankForXp(int xp) {
    RankModel currentRank = ranks.first;

    for (final rank in ranks) {
      if (xp >= rank.minimumXp) {
        currentRank = rank;
      }
    }

    return currentRank;
  }

  BadgeModel? badgeForId(String badgeId) {
    for (final badge in allBadges) {
      if (badge.id == badgeId) {
        return badge;
      }
    }

    return null;
  }

  List<BadgeModel> badgesForIds(Set<String> badgeIds) {
    return allBadges
        .where((badge) => badgeIds.contains(badge.id))
        .toList(growable: false);
  }

  BadgeEvaluationResult evaluateBadgesAfterCompletion({
    required RoleScenarioModel roleScenario,
    required Map<String, RoleProgressModel> progressByRole,
    required ScoreModel totalScore,
    required int totalXp,
    required Set<String> previouslyUnlockedBadgeIds,
  }) {
    final candidateBadgeIds = <String>{};
    final totalCompletedChapters = progressByRole.values.fold<int>(
      0,
      (total, progress) => total + progress.completedChapterIds.length,
    );
    final currentRoleProgress = progressByRole[roleScenario.role.id];

    if (totalCompletedChapters >= 1) {
      candidateBadgeIds.add('first_chapter_completed');
    }

    if (totalCompletedChapters >= 5) {
      candidateBadgeIds.add('five_chapter_finisher');
    }

    if (totalCompletedChapters >= 10) {
      candidateBadgeIds.add('ten_chapter_finisher');
    }

    if (totalScore.skill >= 25) {
      candidateBadgeIds.add('skill_builder');
    }

    if (totalScore.ethics >= 20) {
      candidateBadgeIds.add('ethical_operator');
    }

    if (totalScore.communication >= 20 && totalScore.chaos < 25) {
      candidateBadgeIds.add('calm_communicator');
    }

    if (totalScore.chaos >= 20) {
      candidateBadgeIds.add('chaos_survivor');
    }

    final rank = rankForXp(totalXp);
    if (rank.rank.index >= CareerRank.junior.index) {
      candidateBadgeIds.add('junior_rank_reached');
    }
    if (rank.rank.index >= CareerRank.professional.index) {
      candidateBadgeIds.add('professional_rank_reached');
    }
    if (rank.rank.index >= CareerRank.legend.index) {
      candidateBadgeIds.add('legend_rank_reached');
    }

    if (currentRoleProgress != null &&
        roleScenario.totalChapters > 0 &&
        currentRoleProgress.completedChapterIds.length >=
            roleScenario.totalChapters) {
      candidateBadgeIds.add('${roleScenario.role.id}_role_completed');
    }

    final allUnlockedBadgeIds = <String>{
      ...previouslyUnlockedBadgeIds,
      ...candidateBadgeIds,
    };
    final newlyUnlockedBadgeIds = candidateBadgeIds
        .where((badgeId) => !previouslyUnlockedBadgeIds.contains(badgeId))
        .toSet();

    final currentRoleBadgeIds = candidateBadgeIds
        .where((badgeId) => badgeId == '${roleScenario.role.id}_role_completed')
        .toSet();

    return BadgeEvaluationResult(
      allUnlockedBadgeIds: allUnlockedBadgeIds,
      newlyUnlockedBadges: badgesForIds(newlyUnlockedBadgeIds),
      currentRoleBadgeIds: currentRoleBadgeIds,
    );
  }
}
