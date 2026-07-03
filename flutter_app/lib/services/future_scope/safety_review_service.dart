import '../../models/future_scope/safety_review_model.dart';
import '../../models/scenario_model.dart';

class SafetyReviewService {
  const SafetyReviewService();

  bool requiresHumanReview(ScenarioModel scenario) {
    final role = scenario.role.name.toLowerCase();
    return role.contains('doctor') ||
        role.contains('engineer') ||
        role.contains('hr') ||
        scenario.safetyGuardrails.isNotEmpty ||
        scenario.safetyDisclaimer != null;
  }

  bool canPublish(ScenarioModel scenario) {
    if (!requiresHumanReview(scenario)) return true;
    return scenario.safetyReview.isApproved;
  }

  SafetyReviewModel defaultDraft({List<String> domains = const <String>[]}) {
    return SafetyReviewModel(domains: domains);
  }
}
