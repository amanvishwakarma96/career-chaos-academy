enum DeveloperTaskFamily {
  liveIncident,
  releasePipeline,
  supportEscalation,
  performanceProfiling,
}

extension DeveloperTaskFamilyX on DeveloperTaskFamily {
  String get id {
    switch (this) {
      case DeveloperTaskFamily.liveIncident:
        return 'live_incident';
      case DeveloperTaskFamily.releasePipeline:
        return 'release_pipeline';
      case DeveloperTaskFamily.supportEscalation:
        return 'support_escalation';
      case DeveloperTaskFamily.performanceProfiling:
        return 'performance_profiling';
    }
  }

  String get label {
    switch (this) {
      case DeveloperTaskFamily.liveIncident:
        return 'Live Production Incident';
      case DeveloperTaskFamily.releasePipeline:
        return 'Release Pipeline';
      case DeveloperTaskFamily.supportEscalation:
        return 'Support Escalation';
      case DeveloperTaskFamily.performanceProfiling:
        return 'Performance Profiling';
    }
  }

  bool get isPlayable {
    switch (this) {
      case DeveloperTaskFamily.liveIncident:
      case DeveloperTaskFamily.releasePipeline:
        return true;
      case DeveloperTaskFamily.supportEscalation:
      case DeveloperTaskFamily.performanceProfiling:
        return false;
    }
  }
}

enum DeveloperIncidentModifier {
  trafficSpike,
  flakyTests,
  clientEscalation,
  noisyAlerts,
  hotfixWindow,
}

extension DeveloperIncidentModifierX on DeveloperIncidentModifier {
  String get id {
    switch (this) {
      case DeveloperIncidentModifier.trafficSpike:
        return 'traffic_spike';
      case DeveloperIncidentModifier.flakyTests:
        return 'flaky_tests';
      case DeveloperIncidentModifier.clientEscalation:
        return 'client_escalation';
      case DeveloperIncidentModifier.noisyAlerts:
        return 'noisy_alerts';
      case DeveloperIncidentModifier.hotfixWindow:
        return 'hotfix_window';
    }
  }

  String get label {
    switch (this) {
      case DeveloperIncidentModifier.trafficSpike:
        return 'Traffic Spike';
      case DeveloperIncidentModifier.flakyTests:
        return 'Flaky Test Suite';
      case DeveloperIncidentModifier.clientEscalation:
        return 'Client Escalation';
      case DeveloperIncidentModifier.noisyAlerts:
        return 'Noisy Alert Storm';
      case DeveloperIncidentModifier.hotfixWindow:
        return 'Hotfix Window';
    }
  }

  String get briefing {
    switch (this) {
      case DeveloperIncidentModifier.trafficSpike:
        return 'Traffic is climbing. Production health decays faster while you investigate.';
      case DeveloperIncidentModifier.flakyTests:
        return 'The regression suite is unstable. The first valid test run may fail and require a retry.';
      case DeveloperIncidentModifier.clientEscalation:
        return 'The client is escalating frequently. Delay adds extra chaos while the incident remains open.';
      case DeveloperIncidentModifier.noisyAlerts:
        return 'Monitoring is noisy. Extra non-blocking alerts will compete for your attention.';
      case DeveloperIncidentModifier.hotfixWindow:
        return 'A narrow release window is open. Actions process faster, but production degrades more aggressively.';
    }
  }

  int get startingHealth {
    switch (this) {
      case DeveloperIncidentModifier.trafficSpike:
        return 78;
      case DeveloperIncidentModifier.flakyTests:
        return 86;
      case DeveloperIncidentModifier.clientEscalation:
        return 82;
      case DeveloperIncidentModifier.noisyAlerts:
        return 86;
      case DeveloperIncidentModifier.hotfixWindow:
        return 80;
    }
  }

  int get healthDecayAmount {
    switch (this) {
      case DeveloperIncidentModifier.trafficSpike:
        return 2;
      case DeveloperIncidentModifier.hotfixWindow:
        return 2;
      case DeveloperIncidentModifier.flakyTests:
      case DeveloperIncidentModifier.clientEscalation:
      case DeveloperIncidentModifier.noisyAlerts:
        return 1;
    }
  }

  int get healthDecayEverySeconds {
    switch (this) {
      case DeveloperIncidentModifier.trafficSpike:
      case DeveloperIncidentModifier.clientEscalation:
        return 2;
      case DeveloperIncidentModifier.hotfixWindow:
        return 3;
      case DeveloperIncidentModifier.flakyTests:
      case DeveloperIncidentModifier.noisyAlerts:
        return 3;
    }
  }

  int get eventEverySeconds {
    switch (this) {
      case DeveloperIncidentModifier.clientEscalation:
      case DeveloperIncidentModifier.noisyAlerts:
        return 3;
      case DeveloperIncidentModifier.trafficSpike:
      case DeveloperIncidentModifier.hotfixWindow:
        return 4;
      case DeveloperIncidentModifier.flakyTests:
        return 5;
    }
  }

  double get processingMultiplier {
    switch (this) {
      case DeveloperIncidentModifier.hotfixWindow:
        return 0.72;
      case DeveloperIncidentModifier.trafficSpike:
        return 0.90;
      case DeveloperIncidentModifier.flakyTests:
      case DeveloperIncidentModifier.clientEscalation:
      case DeveloperIncidentModifier.noisyAlerts:
        return 1.0;
    }
  }

  bool get failsFirstValidTest => this == DeveloperIncidentModifier.flakyTests;
  bool get addsEscalationChaos => this == DeveloperIncidentModifier.clientEscalation;
  bool get addsNoisyAlerts => this == DeveloperIncidentModifier.noisyAlerts;
}

class DeveloperSessionPlan {
  static const String runIdPrefix = 'flame_bug_hunt_room';

  final DeveloperTaskFamily family;
  final DeveloperIncidentModifier modifier;

  const DeveloperSessionPlan({
    required this.family,
    required this.modifier,
  });

  String get runId => '$runIdPrefix|${family.id}|${modifier.id}';
  String get title => '${family.label} • ${modifier.label}';
}
