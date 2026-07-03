import '../models/reputation_model.dart';

class ReputationService {
  ReputationService._();

  static final ReputationService instance = ReputationService._();

  ReputationModel applyImpact({
    required ReputationModel current,
    required ReputationModel impact,
  }) {
    return current.add(impact);
  }

  List<String> strengths(ReputationModel reputation) {
    final strengths = reputation.strengths();
    return strengths.isEmpty ? const <String>['No standout strength yet'] : strengths;
  }

  List<String> weaknesses(ReputationModel reputation) {
    final weaknesses = reputation.weaknesses();
    return weaknesses.isEmpty ? const <String>['No serious weakness yet'] : weaknesses;
  }
}
