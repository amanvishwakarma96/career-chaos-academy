import 'dart:convert';

import 'generated_content_validation_result.dart';

class GeneratedContentValidator {
  const GeneratedContentValidator._();

  static const GeneratedContentValidator instance = GeneratedContentValidator._();

  static const _supportedMiniGameTypes = <String>{
    'multiple_select',
    'code_fix',
    'match_pairs',
    'arrange_order',
    'data_cleanup',
    'decision_matrix',
  };

  static const _requiredScoreKeys = <String>{
    'skill',
    'discipline',
    'ethics',
    'communication',
    'chaos',
  };

  GeneratedContentValidationResult validate(String rawJson) {
    final issues = <GeneratedContentValidationIssue>[];
    final trimmed = rawJson.trim();

    if (trimmed.isEmpty) {
      return GeneratedContentValidationResult(
        rawJson: rawJson,
        normalizedJson: null,
        issues: const <GeneratedContentValidationIssue>[
          GeneratedContentValidationIssue(
            severity: GeneratedContentIssueSeverity.warning,
            path: r'$',
            message: 'Paste generated scenario JSON to start validation.',
          ),
        ],
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (error) {
      issues.add(
        GeneratedContentValidationIssue(
          severity: GeneratedContentIssueSeverity.error,
          path: r'$',
          message: 'Invalid JSON: ${error.message}',
        ),
      );
      return GeneratedContentValidationResult(
        rawJson: rawJson,
        normalizedJson: null,
        issues: issues,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      issues.add(
        const GeneratedContentValidationIssue(
          severity: GeneratedContentIssueSeverity.error,
          path: r'$',
          message: 'Root must be a JSON object with role and chapters.',
        ),
      );
      return GeneratedContentValidationResult(
        rawJson: rawJson,
        normalizedJson: null,
        issues: issues,
      );
    }

    final normalized = Map<String, dynamic>.from(decoded);
    _validateRoot(normalized, issues);

    final normalizedJson = issues.any((issue) => issue.isError)
        ? null
        : const JsonEncoder.withIndent('  ').convert(normalized);

    return GeneratedContentValidationResult(
      rawJson: rawJson,
      normalizedJson: normalizedJson,
      issues: List<GeneratedContentValidationIssue>.unmodifiable(issues),
    );
  }

  void _validateRoot(
    Map<String, dynamic> json,
    List<GeneratedContentValidationIssue> issues,
  ) {
    final role = _readMap(json['role']);
    if (role == null) {
      _error(issues, r'$.role', 'Missing role object.');
    } else {
      _requireString(role, 'id', r'$.role.id', issues);
      _requireString(role, 'name', r'$.role.name', issues);
      _requireString(role, 'description', r'$.role.description', issues);
      _requireString(role, 'iconKey', r'$.role.iconKey', issues);
    }

    final chapters = json['chapters'];
    if (chapters is! List || chapters.isEmpty) {
      _error(issues, r'$.chapters', 'chapters must be a non-empty list.');
      return;
    }

    for (var index = 0; index < chapters.length; index++) {
      final chapter = chapters[index];
      final path = r'$.chapters[' '$index' ']';
      if (chapter is! Map<String, dynamic>) {
        _error(issues, path, 'Chapter must be an object.');
        continue;
      }
      _normalizeAndValidateChapter(chapter, path, issues, role: role);
    }
  }

  void _normalizeAndValidateChapter(
    Map<String, dynamic> chapter,
    String path,
    List<GeneratedContentValidationIssue> issues, {
    required Map<String, dynamic>? role,
  }) {
    _requireString(chapter, 'id', '$path.id', issues);
    _requireString(chapter, 'title', '$path.title', issues);
    _requireString(chapter, 'difficulty', '$path.difficulty', issues);
    _requireString(chapter, 'theme', '$path.theme', issues);

    final story = _readString(chapter['story']);
    final scenario = _readString(chapter['scenario']);
    final hasScenes = _validateScenes(chapter['scenes'], '$path.scenes', issues);
    if (story == null && scenario == null && !hasScenes) {
      _error(
        issues,
        '$path.story',
        'Chapter must include story/scenario text or cinematic scenes with dialogue.',
      );
    } else {
      final fallbackStory = story ?? scenario ?? _firstSceneDialogue(chapter['scenes']);
      chapter['story'] = fallbackStory;
      chapter['scenario'] = scenario ?? fallbackStory;
    }

    _requireString(chapter, 'task', '$path.task', issues);
    _requireString(
      chapter,
      'professionalLearningPoint',
      '$path.professionalLearningPoint',
      issues,
    );
    _validateHumor(chapter, path, issues);
    _validateSafety(chapter, path, issues, role: role);
    _validateChoices(chapter['choices'], '$path.choices', issues);
    _validateMiniGame(chapter['miniGame'], '$path.miniGame', issues);
  }


  bool _validateScenes(
    Object? value,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    if (value == null) {
      return false;
    }
    if (value is! List) {
      _error(issues, path, 'scenes must be a list when provided.');
      return false;
    }
    var hasDialogue = false;
    for (var sceneIndex = 0; sceneIndex < value.length; sceneIndex++) {
      final scene = value[sceneIndex];
      final scenePath = '$path[$sceneIndex]';
      if (scene is! Map<String, dynamic>) {
        _error(issues, scenePath, 'Scene must be an object.');
        continue;
      }
      if (scene['backgroundImage'] != null && scene['backgroundImage'] is! String) {
        _error(issues, '$scenePath.backgroundImage', 'backgroundImage must be a string.');
      }
      if (scene['characterImage'] != null && scene['characterImage'] is! String) {
        _error(issues, '$scenePath.characterImage', 'characterImage must be a string.');
      }
      if (scene['soundEffect'] != null && scene['soundEffect'] is! String) {
        _error(issues, '$scenePath.soundEffect', 'soundEffect must be a string.');
      }
      if (scene['transitionType'] != null && scene['transitionType'] is! String) {
        _error(issues, '$scenePath.transitionType', 'transitionType must be a string.');
      }
      final dialogues = scene['dialogues'];
      if (dialogues is! List || dialogues.isEmpty) {
        _error(issues, '$scenePath.dialogues', 'Each cinematic scene needs dialogue lines.');
        continue;
      }
      for (var lineIndex = 0; lineIndex < dialogues.length; lineIndex++) {
        final line = dialogues[lineIndex];
        final linePath = '$scenePath.dialogues[$lineIndex]';
        if (line is! Map<String, dynamic>) {
          _error(issues, linePath, 'Dialogue line must be an object.');
          continue;
        }
        if (_readString(line['speaker']) == null) {
          _error(issues, '$linePath.speaker', 'speaker is required.');
        }
        if (_readString(line['text']) == null && _readString(line['dialogue']) == null) {
          _error(issues, '$linePath.text', 'text is required.');
        } else {
          hasDialogue = true;
        }
        if (line['emotion'] != null && line['emotion'] is! String) {
          _error(issues, '$linePath.emotion', 'emotion must be a string.');
        }
      }
    }
    return hasDialogue;
  }

  String? _firstSceneDialogue(Object? value) {
    if (value is! List) {
      return null;
    }
    for (final scene in value) {
      if (scene is! Map<String, dynamic>) {
        continue;
      }
      final dialogues = scene['dialogues'];
      if (dialogues is! List) {
        for (final line in dialogues) {
          if (line is Map<String, dynamic>) {
            final text = _readString(line['text']) ?? _readString(line['dialogue']);
            if (text != null) {
              return text;
            }
          }
        }
      }
    }
    return null;
  }

  void _validateChoices(
    Object? value,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    if (value is! List || value.length < 2) {
      _error(issues, path, 'Add at least 2 choices. Prefer 3 choices.');
      return;
    }

    if (value.length < 3) {
      _warning(issues, path, 'Three choices create a better game rhythm.');
    }

    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      final choicePath = '$path[$index]';
      if (item is! Map<String, dynamic>) {
        _error(issues, choicePath, 'Choice must be an object.');
        continue;
      }

      _requireString(item, 'text', '$choicePath.text', issues);
      _validateOutcome(item['outcome'], '$choicePath.outcome', issues);
      _validateScoreImpact(item['scoreImpact'], '$choicePath.scoreImpact', issues);
    }
  }

  void _validateOutcome(
    Object? value,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    final outcome = _readMap(value);
    if (outcome == null) {
      _error(issues, path, 'Outcome must be an object.');
      return;
    }

    _requireString(outcome, 'title', '$path.title', issues);
    _requireString(outcome, 'description', '$path.description', issues);
    _requireString(outcome, 'moralLesson', '$path.moralLesson', issues);
  }

  void _validateScoreImpact(
    Object? value,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    final score = _readMap(value);
    if (score == null) {
      _error(issues, path, 'scoreImpact must be an object.');
      return;
    }

    for (final key in _requiredScoreKeys) {
      final item = score[key];
      if (item is! num) {
        _error(issues, '$path.$key', 'Score key "$key" must be a number.');
      }
    }
  }

  void _validateMiniGame(
    Object? value,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    if (value == null) {
      return;
    }

    final miniGame = _readMap(value);
    if (miniGame == null) {
      _error(issues, path, 'miniGame must be an object when provided.');
      return;
    }

    _requireString(miniGame, 'id', '$path.id', issues);
    final type = _readString(miniGame['type']);
    if (type == null) {
      _error(issues, '$path.type', 'miniGame.type is required.');
      return;
    }
    if (!_supportedMiniGameTypes.contains(type)) {
      _error(issues, '$path.type', 'Unsupported mini-game type "$type".');
      return;
    }

    _requireString(miniGame, 'title', '$path.title', issues);
    _requireString(miniGame, 'instructions', '$path.instructions', issues);
    _requireString(miniGame, 'prompt', '$path.prompt', issues);
    _requireString(miniGame, 'hint', '$path.hint', issues);
    _requireString(miniGame, 'successMessage', '$path.successMessage', issues);
    _requireString(miniGame, 'failureMessage', '$path.failureMessage', issues);
    _validateScoreImpact(
      miniGame['successScoreImpact'],
      '$path.successScoreImpact',
      issues,
    );
    _validateScoreImpact(
      miniGame['failureScoreImpact'],
      '$path.failureScoreImpact',
      issues,
    );

    switch (type) {
      case 'multiple_select':
      case 'code_fix':
      case 'data_cleanup':
      case 'decision_matrix':
        _validateOptionsAndCorrectIds(miniGame, path, issues);
        break;
      case 'match_pairs':
        _validatePairs(miniGame['pairs'], '$path.pairs', issues);
        break;
      case 'arrange_order':
        _validateOrderItems(miniGame, path, issues);
        break;
    }
  }

  void _validateOptionsAndCorrectIds(
    Map<String, dynamic> miniGame,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    final options = miniGame['options'];
    if (options is! List || options.isEmpty) {
      _error(issues, '$path.options', 'This mini-game type needs options.');
      return;
    }

    final optionIds = <String>{};
    for (var index = 0; index < options.length; index++) {
      final option = options[index];
      final optionPath = '$path.options[$index]';
      if (option is! Map<String, dynamic>) {
        _error(issues, optionPath, 'Option must be an object.');
        continue;
      }
      final id = _readString(option['id']);
      if (id == null) {
        _error(issues, '$optionPath.id', 'Option id is required.');
      } else {
        optionIds.add(id);
      }
      _requireString(option, 'text', '$optionPath.text', issues);
    }

    _validateCorrectIds(
      miniGame['correctOptionIds'],
      '$path.correctOptionIds',
      optionIds,
      issues,
    );
  }

  void _validatePairs(
    Object? value,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    if (value is! List || value.isEmpty) {
      _error(issues, path, 'match_pairs needs a non-empty pairs list.');
      return;
    }

    for (var index = 0; index < value.length; index++) {
      final pair = value[index];
      final pairPath = '$path[$index]';
      if (pair is! Map<String, dynamic>) {
        _error(issues, pairPath, 'Pair must be an object.');
        continue;
      }
      _requireString(pair, 'leftId', '$pairPath.leftId', issues);
      _requireString(pair, 'leftText', '$pairPath.leftText', issues);
      _requireString(pair, 'rightId', '$pairPath.rightId', issues);
      _requireString(pair, 'rightText', '$pairPath.rightText', issues);
    }
  }

  void _validateOrderItems(
    Map<String, dynamic> miniGame,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    final orderItems = miniGame['orderItems'];
    if (orderItems is! List || orderItems.isEmpty) {
      _error(issues, '$path.orderItems', 'arrange_order needs orderItems.');
      return;
    }

    final ids = <String>{};
    for (var index = 0; index < orderItems.length; index++) {
      final item = orderItems[index];
      final itemPath = '$path.orderItems[$index]';
      if (item is! Map<String, dynamic>) {
        _error(issues, itemPath, 'Order item must be an object.');
        continue;
      }
      final id = _readString(item['id']);
      if (id == null) {
        _error(issues, '$itemPath.id', 'Order item id is required.');
      } else {
        ids.add(id);
      }
      _requireString(item, 'text', '$itemPath.text', issues);
    }

    _validateCorrectIds(
      miniGame['correctOrderIds'],
      '$path.correctOrderIds',
      ids,
      issues,
    );
  }

  void _validateCorrectIds(
    Object? value,
    String path,
    Set<String> validIds,
    List<GeneratedContentValidationIssue> issues,
  ) {
    if (value is! List || value.isEmpty) {
      _error(issues, path, 'Correct id list must be non-empty.');
      return;
    }

    for (final id in value) {
      if (id is! String || id.trim().isEmpty) {
        _error(issues, path, 'Correct id entries must be non-empty strings.');
      } else if (!validIds.contains(id)) {
        _error(issues, path, 'Correct id "$id" does not exist in available items.');
      }
    }
  }

  void _validateHumor(
    Map<String, dynamic> chapter,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    final combined = [
      chapter['title'],
      chapter['story'],
      chapter['scenario'],
      chapter['task'],
    ].whereType<String>().join(' ').toLowerCase();

    const humorSignals = <String>[
      'funny',
      'chaos',
      'dramatic',
      'samosa',
      'meme',
      'wild',
      'oops',
      'panic',
      'boss',
      'manager',
      'client',
      'disaster',
      'confused',
      'comedy',
    ];

    if (!humorSignals.any(combined.contains)) {
      _warning(
        issues,
        path,
        'Humor is not obvious. Add light workplace comedy without making the professional lesson unsafe.',
      );
    }
  }

  void _validateSafety(
    Map<String, dynamic> chapter,
    String path,
    List<GeneratedContentValidationIssue> issues, {
    required Map<String, dynamic>? role,
  }) {
    final roleName = _readString(role?['name'])?.toLowerCase() ?? '';
    final combined = [
      roleName,
      chapter['title'],
      chapter['theme'],
      chapter['story'],
      chapter['scenario'],
      chapter['task'],
      chapter['professionalLearningPoint'],
    ].whereType<String>().join(' ').toLowerCase();

    final isMedical = _containsAny(combined, const [
      'doctor',
      'medical',
      'medicine',
      'patient',
      'symptom',
      'hospital',
      'diagnosis',
      'prescription',
    ]);
    final isLegal = _containsAny(combined, const [
      'lawyer',
      'legal',
      'court',
      'contract',
      'lawsuit',
      'compliance',
    ]);
    final isFinancial = _containsAny(combined, const [
      'finance',
      'loan',
      'investment',
      'credit',
      'insurance',
      'tax',
      'bank',
    ]);

    if (isMedical || isLegal || isFinancial) {
      final disclaimer = _readString(chapter['safetyDisclaimer']);
      if (disclaimer == null) {
        _error(
          issues,
          '$path.safetyDisclaimer',
          'High-stakes content needs a safety disclaimer and safe action limits.',
        );
      }
    }

    if (isMedical) {
      _blockDangerousPattern(
        combined,
        issues,
        path,
        RegExp(r'\b\d+\s?(mg|ml|tablet|dose|capsule)s?\b'),
        'Medical content must not give dosage or prescription instructions.',
      );
      _blockDangerousWords(
        combined,
        issues,
        path,
        const ['prescribe ', 'diagnose as ', 'stop taking medicine'],
        'Medical content must avoid diagnosis or prescription. Use triage, documentation, escalation, and doctor consultation only.',
      );
    }

    if (isFinancial) {
      _blockDangerousWords(
        combined,
        issues,
        path,
        const ['guaranteed profit', 'risk-free return', 'sure shot', 'hide income'],
        'Financial content must avoid guaranteed returns or illegal shortcuts.',
      );
    }

    if (isLegal) {
      _blockDangerousWords(
        combined,
        issues,
        path,
        const ['definitely illegal', 'you will win', 'hide evidence', 'fake signature'],
        'Legal content must avoid legal conclusions or illegal instructions.',
      );
    }
  }

  bool _containsAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }

  void _blockDangerousPattern(
    String text,
    List<GeneratedContentValidationIssue> issues,
    String path,
    RegExp pattern,
    String message,
  ) {
    if (pattern.hasMatch(text)) {
      _error(issues, path, message);
    }
  }

  void _blockDangerousWords(
    String text,
    List<GeneratedContentValidationIssue> issues,
    String path,
    List<String> blockedTerms,
    String message,
  ) {
    if (blockedTerms.any(text.contains)) {
      _error(issues, path, message);
    }
  }

  String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  Map<String, dynamic>? _readMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  void _requireString(
    Map<String, dynamic> json,
    String key,
    String path,
    List<GeneratedContentValidationIssue> issues,
  ) {
    if (_readString(json[key]) == null) {
      _error(issues, path, 'Required non-empty string is missing.');
    }
  }

  void _error(
    List<GeneratedContentValidationIssue> issues,
    String path,
    String message,
  ) {
    issues.add(
      GeneratedContentValidationIssue(
        severity: GeneratedContentIssueSeverity.error,
        path: path,
        message: message,
      ),
    );
  }

  void _warning(
    List<GeneratedContentValidationIssue> issues,
    String path,
    String message,
  ) {
    issues.add(
      GeneratedContentValidationIssue(
        severity: GeneratedContentIssueSeverity.warning,
        path: path,
        message: message,
      ),
    );
  }
}
