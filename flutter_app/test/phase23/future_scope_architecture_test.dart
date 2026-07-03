import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/future_scope/access_models.dart';
import 'package:career_chaos_academy/models/future_scope/feature_flag_model.dart';
import 'package:career_chaos_academy/models/future_scope/multiplayer_models.dart';
import 'package:career_chaos_academy/models/future_scope/role_plugin_model.dart';
import 'package:career_chaos_academy/models/future_scope/safety_review_model.dart';
import 'package:career_chaos_academy/models/future_scope/versioning_models.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/services/future_scope/offline_content_cache_service.dart';
import 'package:career_chaos_academy/services/future_scope/premium_content_service.dart';
import 'package:career_chaos_academy/services/future_scope/scenario_validation_pipeline.dart';

void main() {
  const role = RoleModel(
    id: 'doctor',
    name: 'Doctor',
    description: 'Safe triage learning.',
    iconKey: 'medical_services',
  );

  group('Phase 23 future-scope architecture', () {
    test('feature flags parse with rollout information', () {
      final flag = FeatureFlagModel.fromJson(const <String, dynamic>{
        'key': 'premium_content',
        'enabled': false,
        'description': 'Future paid packs',
        'owner': 'business',
        'rolloutPercentage': 25,
      });

      expect(flag.key, 'premium_content');
      expect(flag.enabled, false);
      expect(flag.rolloutPercentage, 25);
    });

    test('content and asset versions parse safely', () {
      final content = ContentVersionModel.fromJson(const <String, dynamic>{
        'contentPackId': 'core_roles_v23',
        'version': '23.0.0',
        'minAppVersion': '1.0.0',
        'roleIds': ['developer'],
      });
      final assets = AssetVersionModel.fromJson(const <String, dynamic>{
        'assetPackId': 'base_visuals_v23',
        'version': '23.0.0',
        'assetVersions': {'bg_office_morning': '23.0.0'},
      });

      expect(content.version, '23.0.0');
      expect(content.roleIds, contains('developer'));
      expect(assets.assetVersions['bg_office_morning'], '23.0.0');
    });

    test('scenario model accepts future metadata but old JSON still works', () {
      final oldScenario = ScenarioModel.fromJson(
        <String, dynamic>{
          'id': 'old_chapter',
          'title': 'Old Chapter',
          'difficulty': 'Beginner',
          'theme': 'Basics',
          'story': 'Old story format.',
          'task': 'Choose wisely.',
          'choices': <Map<String, dynamic>>[
            {
              'text': 'Safe',
              'outcome': {'title': 'Safe', 'description': 'OK', 'moralLesson': 'Think.'},
              'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
            },
            {
              'text': 'Risky',
              'outcome': {'title': 'Risky', 'description': 'Oops', 'moralLesson': 'Avoid shortcuts.'},
              'scoreImpact': {'skill': -1, 'discipline': -1, 'ethics': -1, 'communication': 0, 'chaos': 2},
            },
          ],
        },
        role: role,
      );
      expect(oldScenario.contentPackId, 'core_roles_v23');
      expect(oldScenario.contentTier, 'free');
      expect(oldScenario.supportsOfflineCache, true);

      final newScenario = ScenarioModel.fromJson(
        <String, dynamic>{
          'id': 'doctor_future_safe',
          'title': 'Future Safe Chapter',
          'difficulty': 'Medium',
          'theme': 'Triage',
          'story': 'A patient needs careful communication.',
          'task': 'Choose safely.',
          'contentVersion': '23.0.0',
          'contentPackId': 'core_roles_v23',
          'assetVersion': '23.0.0',
          'assetPackId': 'base_visuals_v23',
          'rolePluginId': 'doctor_core',
          'localizationKey': 'role.doctor.chapter.future.title',
          'contentTier': 'free',
          'analyticsTags': ['doctor', 'safety'],
          'safetyReview': {
            'status': 'approved',
            'domains': ['medical'],
            'guardrails': ['No diagnosis'],
          },
          'multiplayer': {'mode': 'solo', 'enabled': false},
          'choices': <Map<String, dynamic>>[
            {
              'text': 'Escalate red flags.',
              'outcome': {'title': 'Safe', 'description': 'Escalated', 'moralLesson': 'Safety first.'},
              'scoreImpact': {'skill': 2, 'discipline': 1, 'ethics': 2, 'communication': 2, 'chaos': 0},
            },
            {
              'text': 'Guess confidently.',
              'outcome': {'title': 'Unsafe', 'description': 'Overreach', 'moralLesson': 'Do not diagnose.'},
              'scoreImpact': {'skill': -2, 'discipline': -1, 'ethics': -3, 'communication': -1, 'chaos': 3},
            },
          ],
        },
        role: role,
      );

      expect(newScenario.contentVersion, '23.0.0');
      expect(newScenario.assetPackId, 'base_visuals_v23');
      expect(newScenario.rolePluginId, 'doctor_core');
      expect(newScenario.localizationKey, 'role.doctor.chapter.future.title');
      expect(newScenario.safetyReview.isApproved, true);
      expect(newScenario.analyticsTags, contains('safety'));
      expect(newScenario.multiplayer.mode, MultiplayerMode.solo);
    });

    test('role plugin architecture allows new roles without changing core flow', () {
      final plugin = RolePluginModel.fromJson(const <String, dynamic>{
        'pluginId': 'lawyer_core',
        'roleId': 'lawyer',
        'displayName': 'Lawyer Core Plugin',
        'routeKey': 'default_role_flow',
        'contentPackId': 'legal_roles_v1',
        'enabled': true,
        'requiredFeatureFlags': ['story_mode'],
      });

      expect(plugin.roleId, 'lawyer');
      expect(plugin.routeKey, 'default_role_flow');
    });

    test('safety review pipeline reports publish readiness', () {
      final scenario = ScenarioModel.fromJson(
        <String, dynamic>{
          'id': 'doctor_reviewed',
          'title': 'Reviewed Safe Chapter',
          'difficulty': 'Beginner',
          'theme': 'Safety',
          'story': 'Educational content only.',
          'task': 'Escalate safely.',
          'contentVersion': '23.0.0',
          'safetyGuardrails': ['No diagnosis'],
          'safetyReview': {'status': 'approved', 'domains': ['medical']},
          'choices': <Map<String, dynamic>>[
            {
              'text': 'Escalate.',
              'outcome': {'title': 'Safe', 'description': 'Safe', 'moralLesson': 'Escalate.'},
              'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
            },
            {
              'text': 'Guess.',
              'outcome': {'title': 'Risk', 'description': 'Risk', 'moralLesson': 'Do not guess.'},
              'scoreImpact': {'skill': -1, 'discipline': -1, 'ethics': -1, 'communication': 0, 'chaos': 2},
            },
          ],
        },
        role: role,
      );

      final report = const ScenarioValidationPipeline().validate(scenario);
      expect(report.canPublish, true);
    });

    test('offline cache, premium, and progress placeholders are backward compatible', () {
      final cache = OfflineContentCacheService.instance;
      expect(cache.shouldUseBundledFallback(lastUpdated: null), true);
      expect(const PremiumContentService().canAccess(ContentAccessModel.free), true);
      expect(ContentAccessModel.fromJson(const <String, dynamic>{'tier': 'premium'}).tier, ContentAccessTier.premium);

      final oldProgress = ProgressSnapshotModel.fromJson(const <String, dynamic>{
        'version': 1,
        'progressByRole': {},
      });
      expect(oldProgress.contentCacheState.activeContentPackId, 'core_roles_v23');
      expect(oldProgress.featureFlagOverrides, isEmpty);
    });

    test('safety review model supports review workflow statuses', () {
      final review = SafetyReviewModel.fromJson(const <String, dynamic>{
        'status': 'needs_changes',
        'domains': ['privacy'],
        'guardrails': ['No personal data exposure'],
        'notes': 'Clarify data-handling language.',
      });

      expect(review.status, SafetyReviewStatus.needsChanges);
      expect(review.isApproved, false);
      expect(review.guardrails, contains('No personal data exposure'));
    });
  });
}
