import '../models/relationship_score_model.dart';

class RelationshipService {
  RelationshipService._();

  static final RelationshipService instance = RelationshipService._();

  RelationshipScoreModel applyImpact({
    required RelationshipScoreModel current,
    required RelationshipScoreModel impact,
  }) {
    return current.add(impact).clamp();
  }

  List<String> strengths(RelationshipScoreModel relationship) {
    final result = <String>[];
    if (relationship.mentorTrust >= 5) result.add('Mentor trusts your judgment');
    if (relationship.clientTrust >= 5) result.add('Client confidence is growing');
    if (relationship.teamTrust >= 5) result.add('Team trusts your process');
    if (relationship.publicReputation >= 5) result.add('Public reputation is strong');
    return result;
  }

  List<String> risks(RelationshipScoreModel relationship) {
    final result = <String>[];
    if (relationship.mentorTrust <= -3) result.add('Mentor trust is damaged');
    if (relationship.clientTrust <= -3) result.add('Client trust is weak');
    if (relationship.teamTrust <= -3) result.add('Team trust is strained');
    if (relationship.publicReputation <= -3) result.add('Public reputation is at risk');
    return result;
  }
}
