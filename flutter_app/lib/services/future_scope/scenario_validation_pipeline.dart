import '../../models/scenario_model.dart';
import '../../models/future_scope/safety_review_model.dart';

class ScenarioValidationIssue {
  final String severity;
  final String message;
  final String path;

  const ScenarioValidationIssue({
    required this.severity,
    required this.message,
    this.path = '',
  });
}

class ScenarioValidationReport {
  final List<ScenarioValidationIssue> issues;

  const ScenarioValidationReport(this.issues);

  bool get canPublish => issues.every((issue) => issue.severity != 'error');
  bool get hasIssues => issues.isNotEmpty;
}

class ScenarioValidationPipeline {
  const ScenarioValidationPipeline();

  ScenarioValidationReport validate(ScenarioModel scenario) {
    final issues = <ScenarioValidationIssue>[];
    if (scenario.id.isEmpty) {
      issues.add(const ScenarioValidationIssue(severity: 'error', message: 'Scenario id is required.', path: 'id'));
    }
    if (scenario.choices.isEmpty) {
      issues.add(const ScenarioValidationIssue(severity: 'error', message: 'At least one choice is required.', path: 'choices'));
    }
    final safety = scenario.safetyReview;
    final serious = scenario.role.name.toLowerCase().contains('doctor') ||
        scenario.role.name.toLowerCase().contains('engineer') ||
        scenario.safetyGuardrails.isNotEmpty;
    if (serious && safety.status != SafetyReviewStatus.approved) {
      issues.add(const ScenarioValidationIssue(
        severity: 'warning',
        message: 'Professional safety-sensitive content should be approved before release.',
        path: 'safetyReview.status',
      ));
    }
    if (scenario.contentVersion.isEmpty) {
      issues.add(const ScenarioValidationIssue(severity: 'warning', message: 'Content version is missing.', path: 'contentVersion'));
    }
    return ScenarioValidationReport(List<ScenarioValidationIssue>.unmodifiable(issues));
  }
}
