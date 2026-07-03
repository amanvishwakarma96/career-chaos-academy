enum GeneratedContentIssueSeverity { error, warning }

class GeneratedContentValidationIssue {
  final GeneratedContentIssueSeverity severity;
  final String path;
  final String message;

  const GeneratedContentValidationIssue({
    required this.severity,
    required this.path,
    required this.message,
  });

  bool get isError => severity == GeneratedContentIssueSeverity.error;

  String get label => isError ? 'Error' : 'Warning';
}

class GeneratedContentValidationResult {
  final String rawJson;
  final String? normalizedJson;
  final List<GeneratedContentValidationIssue> issues;

  const GeneratedContentValidationResult({
    required this.rawJson,
    required this.normalizedJson,
    required this.issues,
  });

  bool get hasInput => rawJson.trim().isNotEmpty;

  bool get hasErrors => issues.any((issue) => issue.isError);

  bool get hasWarnings => issues.any((issue) => !issue.isError);

  bool get isAppReady => hasInput && !hasErrors && normalizedJson != null;

  List<GeneratedContentValidationIssue> get errors {
    return issues.where((issue) => issue.isError).toList(growable: false);
  }

  List<GeneratedContentValidationIssue> get warnings {
    return issues.where((issue) => !issue.isError).toList(growable: false);
  }
}
