enum DeveloperIncidentAction {
  inspectLogs,
  reproduceBug,
  patchState,
  runTests,
  openPullRequest,
  deployFix,
}

extension DeveloperIncidentActionX on DeveloperIncidentAction {
  String get id {
    switch (this) {
      case DeveloperIncidentAction.inspectLogs:
        return 'inspect_logs';
      case DeveloperIncidentAction.reproduceBug:
        return 'reproduce_bug';
      case DeveloperIncidentAction.patchState:
        return 'patch_state';
      case DeveloperIncidentAction.runTests:
        return 'run_tests';
      case DeveloperIncidentAction.openPullRequest:
        return 'open_pr';
      case DeveloperIncidentAction.deployFix:
        return 'deploy_fix';
    }
  }

  String get label {
    switch (this) {
      case DeveloperIncidentAction.inspectLogs:
        return 'Inspect logs';
      case DeveloperIncidentAction.reproduceBug:
        return 'Reproduce bug';
      case DeveloperIncidentAction.patchState:
        return 'Patch state';
      case DeveloperIncidentAction.runTests:
        return 'Run tests';
      case DeveloperIncidentAction.openPullRequest:
        return 'Open PR';
      case DeveloperIncidentAction.deployFix:
        return 'Deploy fix';
    }
  }

  String get shortLabel {
    switch (this) {
      case DeveloperIncidentAction.inspectLogs:
        return 'LOGS';
      case DeveloperIncidentAction.reproduceBug:
        return 'REPRO';
      case DeveloperIncidentAction.patchState:
        return 'PATCH';
      case DeveloperIncidentAction.runTests:
        return 'TEST';
      case DeveloperIncidentAction.openPullRequest:
        return 'PR';
      case DeveloperIncidentAction.deployFix:
        return 'DEPLOY';
    }
  }

  double get processingSeconds {
    switch (this) {
      case DeveloperIncidentAction.inspectLogs:
        return 1.0;
      case DeveloperIncidentAction.reproduceBug:
        return 1.2;
      case DeveloperIncidentAction.patchState:
        return 1.6;
      case DeveloperIncidentAction.runTests:
        return 1.5;
      case DeveloperIncidentAction.openPullRequest:
        return 1.1;
      case DeveloperIncidentAction.deployFix:
        return 1.8;
    }
  }
}

class DeveloperIncidentActionOutcome {
  const DeveloperIncidentActionOutcome({
    required this.message,
    required this.completed,
    required this.disciplined,
  });

  final String message;
  final bool completed;
  final bool disciplined;
}

class DeveloperIncidentEngine {
  DeveloperIncidentEngine()
      : _feed = <String>[
          'MONITOR • Login success rate falling. UI sessions remain stuck.',
          'CLIENT • “Spinner is still spinning. Any update?”',
        ];

  static const List<String> _ambientEvents = <String>[
    'MONITOR • API latency normal. Problem likely sits after the response.',
    'QA • Last user in test dataset reproduces the endless spinner.',
    'CLIENT • Escalation timer started. Production health is drifting down.',
    'SENIOR • Evidence first. Shortcuts create second incidents.',
    'MONITOR • Auth endpoint still returns 200. UI state remains suspicious.',
  ];

  final Set<DeveloperIncidentAction> completedActions =
      <DeveloperIncidentAction>{};
  final List<String> _feed;

  int health = 86;
  int chaos = 0;
  int elapsedSeconds = 0;
  bool stabilized = false;
  bool outage = false;
  int _ambientCursor = 0;

  List<String> get feed => List<String>.unmodifiable(_feed);

  bool get isComplete => stabilized;
  bool get isFailed => outage;

  DeveloperIncidentAction get recommendedAction {
    if (!completedActions.contains(DeveloperIncidentAction.inspectLogs)) {
      return DeveloperIncidentAction.inspectLogs;
    }
    if (!completedActions.contains(DeveloperIncidentAction.reproduceBug)) {
      return DeveloperIncidentAction.reproduceBug;
    }
    if (!completedActions.contains(DeveloperIncidentAction.patchState)) {
      return DeveloperIncidentAction.patchState;
    }
    if (!completedActions.contains(DeveloperIncidentAction.runTests)) {
      return DeveloperIncidentAction.runTests;
    }
    if (!completedActions.contains(DeveloperIncidentAction.openPullRequest)) {
      return DeveloperIncidentAction.openPullRequest;
    }
    return DeveloperIncidentAction.deployFix;
  }

  String get currentTask {
    if (stabilized) {
      return 'Production stabilized. Incident contained.';
    }
    if (outage) {
      return 'Production health hit zero. Generate the incident report.';
    }
    switch (recommendedAction) {
      case DeveloperIncidentAction.inspectLogs:
        return 'New task: inspect production logs for evidence.';
      case DeveloperIncidentAction.reproduceBug:
        return 'New task: reproduce the stuck loading state.';
      case DeveloperIncidentAction.patchState:
        return 'New task: patch the broken loading-state transition.';
      case DeveloperIncidentAction.runTests:
        return 'New task: run regression tests before release.';
      case DeveloperIncidentAction.openPullRequest:
        return 'New task: open a reviewed pull request.';
      case DeveloperIncidentAction.deployFix:
        return 'New task: deploy the verified fix and watch health recover.';
    }
  }

  void tick() {
    if (stabilized || outage) {
      return;
    }

    elapsedSeconds += 1;

    if (elapsedSeconds % 3 == 0) {
      health -= 1;
      _clampHealth();
    }

    if (elapsedSeconds % 5 == 0) {
      _feed.add(_ambientEvents[_ambientCursor % _ambientEvents.length]);
      _ambientCursor += 1;
      _trimFeed();
    }

    if (health <= 0) {
      outage = true;
      _feed.add('OUTAGE • Production health reached zero. Incident failed.');
      _trimFeed();
    }
  }

  DeveloperIncidentActionOutcome resolve(DeveloperIncidentAction action) {
    if (stabilized) {
      return const DeveloperIncidentActionOutcome(
        message: 'Incident is already contained.',
        completed: false,
        disciplined: true,
      );
    }
    if (outage) {
      return const DeveloperIncidentActionOutcome(
        message: 'Production is already down. Finish the incident report.',
        completed: false,
        disciplined: false,
      );
    }
    if (completedActions.contains(action)) {
      final message = '${action.label} is already complete. Move to the next task.';
      _feed.add('WORKFLOW • $message');
      _trimFeed();
      return DeveloperIncidentActionOutcome(
        message: message,
        completed: false,
        disciplined: true,
      );
    }

    switch (action) {
      case DeveloperIncidentAction.inspectLogs:
        return _complete(
          action,
          healthDelta: 1,
          message:
              'Logs inspected: API returns 200, but isLoading never clears after the response.',
        );
      case DeveloperIncidentAction.reproduceBug:
        if (!completedActions.contains(DeveloperIncidentAction.inspectLogs)) {
          return _risky(
            action,
            healthDelta: -2,
            chaosDelta: 2,
            message:
                'You reproduced blindly without evidence. It worked, but the incident got noisier.',
          );
        }
        return _complete(
          action,
          healthDelta: 2,
          message:
              'Bug reproduced on the last-user edge case. The broken state transition is confirmed.',
        );
      case DeveloperIncidentAction.patchState:
        if (!completedActions.contains(DeveloperIncidentAction.reproduceBug)) {
          return _risky(
            action,
            healthDelta: -4,
            chaosDelta: 4,
            message:
                'Patch rejected by reality: you changed code before reproducing the failure.',
          );
        }
        return _complete(
          action,
          healthDelta: 4,
          message:
              'Patch applied locally: loading now clears after the async response is handled.',
        );
      case DeveloperIncidentAction.runTests:
        if (!completedActions.contains(DeveloperIncidentAction.patchState)) {
          return _risky(
            action,
            healthDelta: -2,
            chaosDelta: 3,
            message:
                'Tests fail because there is no valid patch yet. Production pressure increases.',
          );
        }
        return _complete(
          action,
          healthDelta: 5,
          message:
              'Regression suite passes: first user, last user, refresh and retry all green.',
        );
      case DeveloperIncidentAction.openPullRequest:
        if (!completedActions.contains(DeveloperIncidentAction.runTests)) {
          return _risky(
            action,
            healthDelta: -2,
            chaosDelta: 3,
            message:
                'PR blocked: no test evidence attached. Reviewer sends it back.',
          );
        }
        return _complete(
          action,
          healthDelta: 3,
          message:
              'PR opened with reproduction notes, test evidence and rollback instructions.',
        );
      case DeveloperIncidentAction.deployFix:
        final ready = completedActions.contains(DeveloperIncidentAction.patchState) &&
            completedActions.contains(DeveloperIncidentAction.runTests) &&
            completedActions.contains(DeveloperIncidentAction.openPullRequest);
        if (!ready) {
          return _risky(
            action,
            healthDelta: -18,
            chaosDelta: 7,
            message:
                'Unsafe deploy bounced. Rollback triggered automatically; health dropped hard.',
          );
        }
        completedActions.add(action);
        stabilized = true;
        health = 100;
        _feed.add('DEPLOY • Verified fix released. Login health recovered to 100%.');
        _feed.add('MONITOR • Incident contained. No manual submit required inside the arena.');
        _trimFeed();
        return const DeveloperIncidentActionOutcome(
          message: 'Deploy complete. Production stabilized automatically.',
          completed: true,
          disciplined: true,
        );
    }
  }

  DeveloperIncidentActionOutcome _complete(
    DeveloperIncidentAction action, {
    required int healthDelta,
    required String message,
  }) {
    completedActions.add(action);
    health += healthDelta;
    _clampHealth();
    _feed.add('DONE • ${action.label}: $message');
    _trimFeed();
    return DeveloperIncidentActionOutcome(
      message: message,
      completed: true,
      disciplined: true,
    );
  }

  DeveloperIncidentActionOutcome _risky(
    DeveloperIncidentAction action, {
    required int healthDelta,
    required int chaosDelta,
    required String message,
  }) {
    health += healthDelta;
    chaos += chaosDelta;
    _clampHealth();
    _feed.add('RISK • ${action.label}: $message');
    _trimFeed();
    if (health <= 0) {
      outage = true;
      _feed.add('OUTAGE • Production health reached zero. Incident failed.');
      _trimFeed();
    }
    return DeveloperIncidentActionOutcome(
      message: message,
      completed: false,
      disciplined: false,
    );
  }

  void _clampHealth() {
    if (health < 0) {
      health = 0;
    } else if (health > 100) {
      health = 100;
    }
  }

  void _trimFeed() {
    while (_feed.length > 8) {
      _feed.removeAt(0);
    }
  }
}
