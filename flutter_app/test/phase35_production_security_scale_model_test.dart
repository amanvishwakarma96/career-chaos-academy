import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/production_security_model.dart';

void main() {
  test('Phase 35 security policy and status models parse production controls', () {
    final policy = ProductionSecurityPolicyModel.fromJson(<String, dynamic>{
      'version': 1,
      'authentication': <String, dynamic>{'tokenTtlMinutes': 120},
      'secureStorage': <String, dynamic>{
        'flutter': 'Use SecureTokenStorageService backed by flutter_secure_storage.',
      },
      'rateLimiting': <String, dynamic>{'enabled': true, 'maxRequests': 120},
      'requestValidation': <String, dynamic>{'enabled': true, 'maxBodyBytes': 1048576},
      'rbac': <String, dynamic>{'roles': <String>['super_admin', 'auditor']},
      'privacy': <String, dynamic>{'retentionDays': 365},
      'monitoring': <String, dynamic>{'crashMonitoringEnabled': true},
    });

    expect(policy.version, 1);
    expect(policy.secureTokenStorageRequired, isTrue);
    expect(policy.rateLimitingEnabled, isTrue);
    expect(policy.requestValidationEnabled, isTrue);

    final status = ProductionSecurityStatusModel.fromJson(<String, dynamic>{
      'status': 'hardened_for_production_preparation',
      'secureHeadersEnabled': true,
      'rateLimitingEnabled': true,
      'requestValidationEnabled': true,
      'rbacEnabled': true,
      'auditLogsEnabled': true,
      'moderationWorkflowExists': true,
      'promptAbuseProtectionEnabled': true,
      'backupRestoreStrategyExists': true,
      'crashReportingEnabled': true,
      'privacyRetentionRulesExists': true,
      'productionChecklistComplete': true,
    });

    expect(status.status, 'hardened_for_production_preparation');
    expect(status.passedControlCount, 11);
  });

  test('Phase 35 moderation model parses safety status', () {
    final item = ContentModerationItemModel.fromJson(<String, dynamic>{
      'id': 'mod-1',
      'title': 'AI generated scenario',
      'status': 'pending_review',
      'safetyStatus': 'needs_human_review',
      'createdAt': '2026-06-17T00:00:00.000Z',
    });

    expect(item.id, 'mod-1');
    expect(item.status, 'pending_review');
    expect(item.safetyStatus, 'needs_human_review');
  });
}
