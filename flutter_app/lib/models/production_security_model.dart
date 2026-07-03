class ProductionSecurityPolicyModel {
  const ProductionSecurityPolicyModel({
    required this.version,
    required this.authentication,
    required this.secureStorage,
    required this.rateLimiting,
    required this.requestValidation,
    required this.rbac,
    required this.privacy,
    required this.monitoring,
  });

  final int version;
  final Map<String, dynamic> authentication;
  final Map<String, dynamic> secureStorage;
  final Map<String, dynamic> rateLimiting;
  final Map<String, dynamic> requestValidation;
  final Map<String, dynamic> rbac;
  final Map<String, dynamic> privacy;
  final Map<String, dynamic> monitoring;

  factory ProductionSecurityPolicyModel.fromJson(Map<String, dynamic> json) {
    return ProductionSecurityPolicyModel(
      version: (json['version'] as num?)?.toInt() ?? 1,
      authentication: _map(json['authentication']),
      secureStorage: _map(json['secureStorage']),
      rateLimiting: _map(json['rateLimiting']),
      requestValidation: _map(json['requestValidation']),
      rbac: _map(json['rbac']),
      privacy: _map(json['privacy']),
      monitoring: _map(json['monitoring']),
    );
  }

  bool get secureTokenStorageRequired {
    final value = secureStorage['flutter'];
    return value is String && value.toLowerCase().contains('securetokenstorageservice');
  }

  bool get rateLimitingEnabled => rateLimiting['enabled'] == true;

  bool get requestValidationEnabled => requestValidation['enabled'] == true;
}

class ProductionSecurityStatusModel {
  const ProductionSecurityStatusModel({
    required this.status,
    required this.secureHeadersEnabled,
    required this.rateLimitingEnabled,
    required this.requestValidationEnabled,
    required this.rbacEnabled,
    required this.auditLogsEnabled,
    required this.moderationWorkflowExists,
    required this.promptAbuseProtectionEnabled,
    required this.backupRestoreStrategyExists,
    required this.crashReportingEnabled,
    required this.privacyRetentionRulesExists,
    required this.productionChecklistComplete,
  });

  final String status;
  final bool secureHeadersEnabled;
  final bool rateLimitingEnabled;
  final bool requestValidationEnabled;
  final bool rbacEnabled;
  final bool auditLogsEnabled;
  final bool moderationWorkflowExists;
  final bool promptAbuseProtectionEnabled;
  final bool backupRestoreStrategyExists;
  final bool crashReportingEnabled;
  final bool privacyRetentionRulesExists;
  final bool productionChecklistComplete;

  factory ProductionSecurityStatusModel.fromJson(Map<String, dynamic> json) {
    return ProductionSecurityStatusModel(
      status: json['status'] as String? ?? 'unknown',
      secureHeadersEnabled: json['secureHeadersEnabled'] == true,
      rateLimitingEnabled: json['rateLimitingEnabled'] == true,
      requestValidationEnabled: json['requestValidationEnabled'] == true,
      rbacEnabled: json['rbacEnabled'] == true,
      auditLogsEnabled: json['auditLogsEnabled'] == true,
      moderationWorkflowExists: json['moderationWorkflowExists'] == true,
      promptAbuseProtectionEnabled: json['promptAbuseProtectionEnabled'] == true,
      backupRestoreStrategyExists: json['backupRestoreStrategyExists'] == true,
      crashReportingEnabled: json['crashReportingEnabled'] == true,
      privacyRetentionRulesExists: json['privacyRetentionRulesExists'] == true,
      productionChecklistComplete: json['productionChecklistComplete'] == true,
    );
  }

  int get passedControlCount {
    return [
      secureHeadersEnabled,
      rateLimitingEnabled,
      requestValidationEnabled,
      rbacEnabled,
      auditLogsEnabled,
      moderationWorkflowExists,
      promptAbuseProtectionEnabled,
      backupRestoreStrategyExists,
      crashReportingEnabled,
      privacyRetentionRulesExists,
      productionChecklistComplete,
    ].where((value) => value).length;
  }
}

class ContentModerationItemModel {
  const ContentModerationItemModel({
    required this.id,
    required this.title,
    required this.status,
    required this.safetyStatus,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String status;
  final String safetyStatus;
  final String createdAt;

  factory ContentModerationItemModel.fromJson(Map<String, dynamic> json) {
    return ContentModerationItemModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      status: json['status'] as String? ?? 'pending_review',
      safetyStatus: json['safetyStatus'] as String? ?? 'needs_human_review',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
  return <String, dynamic>{};
}
