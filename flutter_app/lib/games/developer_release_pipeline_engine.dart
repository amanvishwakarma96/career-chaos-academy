import '../models/developer_session_model.dart';

enum DeveloperReleaseStage {
  source,
  build,
  unitTests,
  securityScan,
  staging,
  production,
}

enum DeveloperReleaseStageStatus {
  queued,
  running,
  passed,
  failed,
  awaitingApproval,
}

extension DeveloperReleaseStageX on DeveloperReleaseStage {
  String get id {
    switch (this) {
      case DeveloperReleaseStage.source:
        return 'pipeline_source';
      case DeveloperReleaseStage.build:
        return 'pipeline_build';
      case DeveloperReleaseStage.unitTests:
        return 'pipeline_tests';
      case DeveloperReleaseStage.securityScan:
        return 'pipeline_security';
      case DeveloperReleaseStage.staging:
        return 'pipeline_staging';
      case DeveloperReleaseStage.production:
        return 'pipeline_production';
    }
  }

  String get label {
    switch (this) {
      case DeveloperReleaseStage.source:
        return 'SOURCE';
      case DeveloperReleaseStage.build:
        return 'BUILD';
      case DeveloperReleaseStage.unitTests:
        return 'TESTS';
      case DeveloperReleaseStage.securityScan:
        return 'SECURITY';
      case DeveloperReleaseStage.staging:
        return 'STAGING';
      case DeveloperReleaseStage.production:
        return 'PRODUCTION';
    }
  }

  double get durationSeconds {
    switch (this) {
      case DeveloperReleaseStage.source:
        return 1.2;
      case DeveloperReleaseStage.build:
        return 3.0;
      case DeveloperReleaseStage.unitTests:
        return 4.0;
      case DeveloperReleaseStage.securityScan:
        return 5.0;
      case DeveloperReleaseStage.staging:
        return 2.5;
      case DeveloperReleaseStage.production:
        return 3.5;
    }
  }
}

enum DeveloperReleaseControl {
  start,
  boostRunners,
  retryFailed,
  approveProduction,
  rollback,
}

extension DeveloperReleaseControlX on DeveloperReleaseControl {
  String get label {
    switch (this) {
      case DeveloperReleaseControl.start:
        return 'START';
      case DeveloperReleaseControl.boostRunners:
        return '+ RUNNER';
      case DeveloperReleaseControl.retryFailed:
        return 'RETRY';
      case DeveloperReleaseControl.approveProduction:
        return 'APPROVE';
      case DeveloperReleaseControl.rollback:
        return 'ROLLBACK';
    }
  }
}

class DeveloperReleaseControlOutcome {
  const DeveloperReleaseControlOutcome({
    required this.message,
    required this.accepted,
    required this.disciplined,
  });

  final String message;
  final bool accepted;
  final bool disciplined;
}

class DeveloperReleasePipelineEngine {
  DeveloperReleasePipelineEngine({required this.modifier})
      : _feed = <String>[
          'RELEASE • Commit candidate is waiting for pipeline execution.',
          'WINDOW • ${modifier.label}: ${modifier.briefing}',
        ] {
    for (final stage in DeveloperReleaseStage.values) {
      statuses[stage] = DeveloperReleaseStageStatus.queued;
      progress[stage] = 0;
    }
  }

  final DeveloperIncidentModifier modifier;
  final Map<DeveloperReleaseStage, DeveloperReleaseStageStatus> statuses =
      <DeveloperReleaseStage, DeveloperReleaseStageStatus>{};
  final Map<DeveloperReleaseStage, double> progress =
      <DeveloperReleaseStage, double>{};
  final List<String> _feed;

  int runnerCapacity = 1;
  int chaos = 0;
  int releaseHealth = 100;
  int elapsedSeconds = 0;
  bool started = false;
  bool completed = false;
  bool failed = false;
  bool runnerBoostUsed = false;
  int rollbackCount = 0;

  double _secondAccumulator = 0;
  int _eventCursor = 0;
  int _unitTestAttempts = 0;
  int _productionAttempts = 0;

  static const List<String> _normalEvents = <String>[
    'CI • Runner heartbeat healthy.',
    'RELEASE • Artifact checksum registered.',
    'OPS • Staging capacity available.',
    'CI • Cache warm; no infrastructure blocker detected.',
  ];

  static const List<String> _noiseEvents = <String>[
    'NOISE • Old staging alert reopened and auto-closed.',
    'NOISE • Dependency bot posted a non-blocking update.',
    'NOISE • Unrelated dashboard latency warning cleared itself.',
    'SIGNAL • Release pipeline remains the active priority.',
  ];

  List<String> get feed => List<String>.unmodifiable(_feed);
  bool get isComplete => completed;
  bool get isFailed => failed;

  int get runningCount => statuses.values
      .where((status) => status == DeveloperReleaseStageStatus.running)
      .length;

  Set<DeveloperReleaseStage> get passedStages => statuses.entries
      .where((entry) => entry.value == DeveloperReleaseStageStatus.passed)
      .map((entry) => entry.key)
      .toSet();

  DeveloperReleaseStage? get failedStage {
    for (final stage in DeveloperReleaseStage.values) {
      if (statuses[stage] == DeveloperReleaseStageStatus.failed) {
        return stage;
      }
    }
    return null;
  }

  String get currentObjective {
    if (completed) {
      return 'Release complete. Production rollout is healthy.';
    }
    if (failed) {
      return 'Release health reached zero. End the run and review the release report.';
    }
    if (!started) {
      return 'Start the release pipeline.';
    }
    final failedNow = failedStage;
    if (failedNow != null) {
      if (failedNow == DeveloperReleaseStage.production) {
        return 'Production canary failed. Roll back before retrying the rollout.';
      }
      return '${failedNow.label} failed. Retry the failed job.';
    }
    if (statuses[DeveloperReleaseStage.production] ==
        DeveloperReleaseStageStatus.awaitingApproval) {
      return 'All gates are green. Approve the production rollout.';
    }
    if (runningCount > 0) {
      return runnerCapacity == 1 &&
              statuses[DeveloperReleaseStage.build] ==
                  DeveloperReleaseStageStatus.passed &&
              (statuses[DeveloperReleaseStage.unitTests] ==
                      DeveloperReleaseStageStatus.queued ||
                  statuses[DeveloperReleaseStage.securityScan] ==
                      DeveloperReleaseStageStatus.queued)
          ? 'Jobs are queued behind one runner. Add a runner to parallelize at a small stability cost.'
          : 'Pipeline is processing automatically. Watch the gates and release health.';
    }
    return 'Pipeline is preparing the next eligible stage.';
  }

  DeveloperReleaseControlOutcome applyControl(DeveloperReleaseControl control) {
    switch (control) {
      case DeveloperReleaseControl.start:
        return _start();
      case DeveloperReleaseControl.boostRunners:
        return _boostRunners();
      case DeveloperReleaseControl.retryFailed:
        return _retryFailed();
      case DeveloperReleaseControl.approveProduction:
        return _approveProduction();
      case DeveloperReleaseControl.rollback:
        return _rollback();
    }
  }

  void update(double dt) {
    if (!started || completed || failed || dt <= 0) {
      return;
    }

    _autoStartEligibleStages();
    final running = DeveloperReleaseStage.values
        .where(
          (stage) =>
              statuses[stage] == DeveloperReleaseStageStatus.running,
        )
        .toList(growable: false);
    final speed = 1 / modifier.processingMultiplier;
    for (final stage in running) {
      final next = (progress[stage] ?? 0) +
          (dt * speed / stage.durationSeconds);
      progress[stage] = next.clamp(0.0, 1.0);
      if (next >= 1) {
        _finishStage(stage);
      }
    }

    _autoStartEligibleStages();
    _secondAccumulator += dt;
    while (_secondAccumulator >= 1) {
      _secondAccumulator -= 1;
      _tickSecond();
    }
  }

  DeveloperReleaseControlOutcome _start() {
    if (started) {
      return const DeveloperReleaseControlOutcome(
        message: 'Pipeline is already running.',
        accepted: false,
        disciplined: true,
      );
    }
    started = true;
    _feed.add('CI • Pipeline started. Source checkout queued.');
    _autoStartEligibleStages();
    _trimFeed();
    return const DeveloperReleaseControlOutcome(
      message: 'Pipeline started. Eligible jobs will now process automatically.',
      accepted: true,
      disciplined: true,
    );
  }

  DeveloperReleaseControlOutcome _boostRunners() {
    if (!started) {
      return const DeveloperReleaseControlOutcome(
        message: 'Start the pipeline before allocating extra runner capacity.',
        accepted: false,
        disciplined: true,
      );
    }
    if (runnerBoostUsed) {
      return const DeveloperReleaseControlOutcome(
        message: 'Extra runner is already allocated.',
        accepted: false,
        disciplined: true,
      );
    }
    runnerBoostUsed = true;
    runnerCapacity = 2;
    chaos += 1;
    releaseHealth -= 2;
    _clampHealth();
    _feed.add(
      'CAPACITY • Extra runner allocated. Parallelism increased; +1 chaos, -2 release health.',
    );
    _autoStartEligibleStages();
    _trimFeed();
    return const DeveloperReleaseControlOutcome(
      message: 'Second runner online. Independent jobs can now run in parallel.',
      accepted: true,
      disciplined: true,
    );
  }

  DeveloperReleaseControlOutcome _retryFailed() {
    final stage = failedStage;
    if (stage == null) {
      return const DeveloperReleaseControlOutcome(
        message: 'No failed job is waiting for retry.',
        accepted: false,
        disciplined: true,
      );
    }
    if (stage == DeveloperReleaseStage.production) {
      return const DeveloperReleaseControlOutcome(
        message: 'Production failed. Roll back the canary before another approval.',
        accepted: false,
        disciplined: true,
      );
    }
    statuses[stage] = DeveloperReleaseStageStatus.queued;
    progress[stage] = 0;
    _feed.add('RETRY • ${stage.label} returned to the runnable queue.');
    _autoStartEligibleStages();
    _trimFeed();
    return DeveloperReleaseControlOutcome(
      message: '${stage.label} retry queued.',
      accepted: true,
      disciplined: true,
    );
  }

  DeveloperReleaseControlOutcome _approveProduction() {
    final status = statuses[DeveloperReleaseStage.production];
    if (status != DeveloperReleaseStageStatus.awaitingApproval) {
      chaos += 2;
      releaseHealth -= 5;
      _clampHealth();
      _feed.add(
        'BLOCKED • Production approval attempted before all release gates were green.',
      );
      _trimFeed();
      return const DeveloperReleaseControlOutcome(
        message: 'Approval blocked. Build, tests, security and staging must be green first.',
        accepted: false,
        disciplined: false,
      );
    }
    statuses[DeveloperReleaseStage.production] =
        DeveloperReleaseStageStatus.running;
    progress[DeveloperReleaseStage.production] = 0;
    _productionAttempts += 1;
    _feed.add(
      'APPROVAL • Production canary approved. Rollout is now processing automatically.',
    );
    _trimFeed();
    return const DeveloperReleaseControlOutcome(
      message: 'Production canary approved. Watch release health while rollout advances.',
      accepted: true,
      disciplined: true,
    );
  }

  DeveloperReleaseControlOutcome _rollback() {
    final status = statuses[DeveloperReleaseStage.production];
    if (status != DeveloperReleaseStageStatus.failed &&
        status != DeveloperReleaseStageStatus.running) {
      chaos += 1;
      _feed.add('NOOP • Rollback requested with no active or failed production rollout.');
      _trimFeed();
      return const DeveloperReleaseControlOutcome(
        message: 'Nothing in production requires rollback right now.',
        accepted: false,
        disciplined: false,
      );
    }

    statuses[DeveloperReleaseStage.production] =
        DeveloperReleaseStageStatus.awaitingApproval;
    progress[DeveloperReleaseStage.production] = 0;
    rollbackCount += 1;
    chaos += 1;
    releaseHealth += 15;
    _clampHealth();
    _feed.add(
      'ROLLBACK • Canary reverted. Production gate reopened for a safer retry.',
    );
    _trimFeed();
    return const DeveloperReleaseControlOutcome(
      message: 'Rollback complete. Review health, then approve a new canary when ready.',
      accepted: true,
      disciplined: true,
    );
  }

  void _autoStartEligibleStages() {
    if (!started || completed || failed) {
      return;
    }

    _startIfEligible(
      DeveloperReleaseStage.source,
      const <DeveloperReleaseStage>[],
    );
    _startIfEligible(
      DeveloperReleaseStage.build,
      const <DeveloperReleaseStage>[DeveloperReleaseStage.source],
    );
    _startIfEligible(
      DeveloperReleaseStage.unitTests,
      const <DeveloperReleaseStage>[DeveloperReleaseStage.build],
    );
    _startIfEligible(
      DeveloperReleaseStage.securityScan,
      const <DeveloperReleaseStage>[DeveloperReleaseStage.build],
    );
    _startIfEligible(
      DeveloperReleaseStage.staging,
      const <DeveloperReleaseStage>[
        DeveloperReleaseStage.unitTests,
        DeveloperReleaseStage.securityScan,
      ],
    );

    if (statuses[DeveloperReleaseStage.staging] ==
            DeveloperReleaseStageStatus.passed &&
        statuses[DeveloperReleaseStage.production] ==
            DeveloperReleaseStageStatus.queued) {
      statuses[DeveloperReleaseStage.production] =
          DeveloperReleaseStageStatus.awaitingApproval;
      _feed.add(
        'GATE • Staging is green. Production is waiting for your approval.',
      );
      _trimFeed();
    }
  }

  void _startIfEligible(
    DeveloperReleaseStage stage,
    List<DeveloperReleaseStage> dependencies,
  ) {
    if (statuses[stage] != DeveloperReleaseStageStatus.queued ||
        runningCount >= runnerCapacity) {
      return;
    }
    final ready = dependencies.every(
      (dependency) =>
          statuses[dependency] == DeveloperReleaseStageStatus.passed,
    );
    if (!ready) {
      return;
    }
    statuses[stage] = DeveloperReleaseStageStatus.running;
    _feed.add('RUNNING • ${stage.label} started on a CI runner.');
    _trimFeed();
  }

  void _finishStage(DeveloperReleaseStage stage) {
    if (stage == DeveloperReleaseStage.unitTests &&
        modifier.failsFirstValidTest &&
        _unitTestAttempts == 0) {
      _unitTestAttempts += 1;
      statuses[stage] = DeveloperReleaseStageStatus.failed;
      releaseHealth -= 4;
      chaos += 1;
      _clampHealth();
      _feed.add(
        'FAILED • TESTS hit a flaky network-retry failure. A manual retry is required.',
      );
      _trimFeed();
      return;
    }

    if (stage == DeveloperReleaseStage.production &&
        modifier == DeveloperIncidentModifier.trafficSpike &&
        _productionAttempts == 1 &&
        rollbackCount == 0) {
      statuses[stage] = DeveloperReleaseStageStatus.failed;
      releaseHealth -= 28;
      chaos += 3;
      _clampHealth();
      _feed.add(
        'CANARY FAIL • Traffic spike exposed unhealthy rollout behavior. Rollback required.',
      );
      _trimFeed();
      return;
    }

    statuses[stage] = DeveloperReleaseStageStatus.passed;
    progress[stage] = 1;
    _feed.add('PASSED • ${stage.label} gate is green.');
    _trimFeed();

    if (stage == DeveloperReleaseStage.production) {
      completed = true;
      releaseHealth = 100;
      _feed.add(
        'RELEASE • Production rollout reached 100%. Release health is stable.',
      );
      _trimFeed();
    }
  }

  void _tickSecond() {
    elapsedSeconds += 1;

    if (modifier.addsEscalationChaos && elapsedSeconds % 6 == 0) {
      chaos += 1;
      _feed.add(
        'ESCALATION • Stakeholders request another release update. +1 chaos.',
      );
    }

    if (modifier.addsNoisyAlerts && elapsedSeconds % 4 == 0) {
      _feed.add(_noiseEvents[_eventCursor % _noiseEvents.length]);
      _eventCursor += 1;
    } else if (elapsedSeconds % 7 == 0) {
      _feed.add(_normalEvents[_eventCursor % _normalEvents.length]);
      _eventCursor += 1;
    }

    if (modifier == DeveloperIncidentModifier.hotfixWindow &&
        elapsedSeconds % 5 == 0) {
      releaseHealth -= 2;
      _feed.add('WINDOW • Hotfix window pressure costs 2 release health.');
    }

    if (modifier == DeveloperIncidentModifier.trafficSpike &&
        statuses[DeveloperReleaseStage.production] ==
            DeveloperReleaseStageStatus.running) {
      releaseHealth -= 4;
    }

    _clampHealth();
    _trimFeed();
    if (releaseHealth <= 0) {
      failed = true;
      _feed.add('FAILED • Release health reached zero. Pipeline run aborted.');
      _trimFeed();
    }
  }

  void _clampHealth() {
    if (releaseHealth < 0) {
      releaseHealth = 0;
    } else if (releaseHealth > 100) {
      releaseHealth = 100;
    }
  }

  void _trimFeed() {
    while (_feed.length > 9) {
      _feed.removeAt(0);
    }
  }
}
