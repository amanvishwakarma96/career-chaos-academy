function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function validateStringArray(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!Array.isArray(value)) {
    errors.push(`${path} must be an array when provided.`);
    return;
  }
  value.forEach((item, index) => {
    if (typeof item !== 'string') errors.push(`${path}[${index}] must be a string.`);
  });
}

function validateScoreImpact(score, path, errors) {
  if (score === undefined || score === null) return;
  if (!isObject(score)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  for (const key of ['skill', 'discipline', 'ethics', 'communication', 'chaos']) {
    if (score[key] !== undefined && typeof score[key] !== 'number') {
      errors.push(`${path}.${key} must be a number.`);
    }
  }
}

function validateReputationImpact(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  for (const key of ['trust', 'safety', 'professionalism', 'reliability', 'stakeholderConfidence']) {
    if (value[key] !== undefined && typeof value[key] !== 'number') {
      errors.push(`${path}.${key} must be a number.`);
    }
  }
}

function validateRelationshipImpact(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  for (const key of ['mentorTrust', 'clientTrust', 'teamTrust', 'publicReputation']) {
    if (value[key] !== undefined && typeof value[key] !== 'number') {
      errors.push(`${path}.${key} must be a number.`);
    }
  }
}


function validateAudioConfig(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  for (const key of ['backgroundMusic', 'bgm', 'music', 'soundEffect', 'sfx', 'voiceClip', 'voice', 'voiceOver', 'subtitle', 'caption']) {
    if (value[key] !== undefined && typeof value[key] !== 'string') {
      errors.push(`${path}.${key} must be a string when provided.`);
    }
  }
  for (const key of ['loopBackgroundMusic', 'loopBgm', 'stopBackgroundMusic', 'stopBgm']) {
    if (value[key] !== undefined && typeof value[key] !== 'boolean') {
      errors.push(`${path}.${key} must be a boolean when provided.`);
    }
  }
  for (const key of ['musicVolume', 'bgmVolume', 'sfxVolume', 'voiceVolume']) {
    if (value[key] !== undefined && (typeof value[key] !== 'number' || value[key] < 0 || value[key] > 1)) {
      errors.push(`${path}.${key} must be a number between 0 and 1 when provided.`);
    }
  }
}

function validateProfessionalFeedback(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  for (const key of ['mentorFeedback', 'safeExplanation', 'practicalTakeaway']) {
    if (value[key] !== undefined && typeof value[key] !== 'string') {
      errors.push(`${path}.${key} must be a string when provided.`);
    }
  }
}

function validateSafetyReview(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  const statuses = ['draft', 'pending', 'approved', 'rejected', 'needs_changes', 'needsChanges'];
  if (value.status !== undefined && !statuses.includes(value.status)) errors.push(`${path}.status is unsupported.`);
  for (const key of ['reviewedBy', 'reviewedAt', 'notes']) {
    if (value[key] !== undefined && typeof value[key] !== 'string') errors.push(`${path}.${key} must be a string when provided.`);
  }
  validateStringArray(value.domains, `${path}.domains`, errors);
  validateStringArray(value.guardrails, `${path}.guardrails`, errors);
}

function validateAccess(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  if (value.tier !== undefined && !['free', 'premium', 'creator_only', 'creatorOnly'].includes(value.tier)) errors.push(`${path}.tier is unsupported.`);
  if (value.isLockedPlaceholder !== undefined && typeof value.isLockedPlaceholder !== 'boolean') errors.push(`${path}.isLockedPlaceholder must be a boolean.`);
  if (value.unlockHint !== undefined && typeof value.unlockHint !== 'string') errors.push(`${path}.unlockHint must be a string.`);
}

function validateMultiplayer(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  if (value.mode !== undefined && !['solo', 'async_challenge', 'asyncChallenge', 'live_coop', 'liveCoop'].includes(value.mode)) errors.push(`${path}.mode is unsupported.`);
  if (value.enabled !== undefined && typeof value.enabled !== 'boolean') errors.push(`${path}.enabled must be a boolean.`);
  if (value.roomId !== undefined && typeof value.roomId !== 'string') errors.push(`${path}.roomId must be a string.`);
  validateStringArray(value.participantIds, `${path}.participantIds`, errors);
}


function validateAdaptiveDifficulty(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!isObject(value)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  for (const key of ['baseLevel', 'easierLevel', 'harderLevel']) {
    if (value[key] !== undefined && typeof value[key] !== 'string') errors.push(`${path}.${key} must be a string when provided.`);
  }
  validateStringArray(value.increaseWhenPatterns, `${path}.increaseWhenPatterns`, errors);
  validateStringArray(value.decreaseWhenPatterns, `${path}.decreaseWhenPatterns`, errors);
}

function validateAdaptiveDialogueInjections(value, path, errors) {
  if (value === undefined || value === null) return;
  if (!Array.isArray(value)) {
    errors.push(`${path} must be an array when provided.`);
    return;
  }
  value.forEach((item, index) => {
    const itemPath = `${path}[${index}]`;
    if (!isObject(item)) {
      errors.push(`${itemPath} must be an object.`);
      return;
    }
    for (const key of ['id', 'speaker', 'text', 'emotion', 'characterId']) {
      if (item[key] !== undefined && typeof item[key] !== 'string') errors.push(`${itemPath}.${key} must be a string when provided.`);
    }
    if (!hasText(item.id)) errors.push(`${itemPath}.id is required.`);
    if (!hasText(item.text)) errors.push(`${itemPath}.text is required.`);
    validateStringArray(item.requiredBehaviorPatterns, `${itemPath}.requiredBehaviorPatterns`, errors);
    validateStringArray(item.blockedBehaviorPatterns, `${itemPath}.blockedBehaviorPatterns`, errors);
    if (item.priority !== undefined && typeof item.priority !== 'number') errors.push(`${itemPath}.priority must be a number when provided.`);
  });
}

function validateOutcome(outcome, path, errors, { partial = false } = {}) {
  if (!isObject(outcome)) {
    errors.push(`${path} must be an object.`);
    return;
  }
  if (!partial || outcome.title !== undefined) {
    if (!hasText(outcome.title)) errors.push(`${path}.title is required.`);
  }
  if (!partial || outcome.description !== undefined) {
    if (!hasText(outcome.description)) errors.push(`${path}.description is required.`);
  }
  if (!partial || outcome.moralLesson !== undefined) {
    if (!hasText(outcome.moralLesson)) errors.push(`${path}.moralLesson is required.`);
  }
  validateStringArray(outcome.setFlags, `${path}.setFlags`, errors);
  validateStringArray(outcome.clearFlags, `${path}.clearFlags`, errors);
  validateStringArray(outcome.unlockCleanupMissionIds, `${path}.unlockCleanupMissionIds`, errors);
  validateReputationImpact(outcome.reputationImpact, `${path}.reputationImpact`, errors);
  validateStringArray(outcome.setStoryFlags, `${path}.setStoryFlags`, errors);
  validateStringArray(outcome.clearStoryFlags, `${path}.clearStoryFlags`, errors);
  validateRelationshipImpact(outcome.relationshipImpact, `${path}.relationshipImpact`, errors);
  validateStringArray(outcome.delayedConsequenceMessages, `${path}.delayedConsequenceMessages`, errors);
  if (outcome.nextChapterOverrideId !== undefined && typeof outcome.nextChapterOverrideId !== 'string') errors.push(`${path}.nextChapterOverrideId must be a string when provided.`);
  if (outcome.consequenceSummary !== undefined && typeof outcome.consequenceSummary !== 'string') errors.push(`${path}.consequenceSummary must be a string when provided.`);
  if (outcome.debrief !== undefined && !isObject(outcome.debrief)) errors.push(`${path}.debrief must be an object when provided.`);
  validateProfessionalFeedback(outcome.professionalFeedback, `${path}.professionalFeedback`, errors);
  validateStringArray(outcome.analyticsTags, `${path}.analyticsTags`, errors);
  for (const key of ['mentorFeedback', 'safeExplanation', 'practicalTakeaway']) {
    if (outcome[key] !== undefined && typeof outcome[key] !== 'string') errors.push(`${path}.${key} must be a string when provided.`);
  }
}

function validateMiniGame(miniGame, path, errors) {
  if (miniGame === undefined || miniGame === null) return;
  if (!isObject(miniGame)) {
    errors.push(`${path} must be an object when provided.`);
    return;
  }
  const supported = ['multiple_select', 'code_fix', 'match_pairs', 'arrange_order', 'data_cleanup', 'decision_matrix'];
  if (!supported.includes(miniGame.type)) errors.push(`${path}.type is unsupported.`);
  for (const key of ['id', 'title', 'instructions', 'prompt', 'hint', 'successMessage', 'failureMessage']) {
    if (!hasText(miniGame[key])) errors.push(`${path}.${key} is required.`);
  }
  if (['multiple_select', 'code_fix', 'data_cleanup', 'decision_matrix'].includes(miniGame.type)) {
    if (!Array.isArray(miniGame.options) || miniGame.options.length < 2) errors.push(`${path}.options must contain at least two options for ${miniGame.type}.`);
    if (!Array.isArray(miniGame.correctOptionIds) || miniGame.correctOptionIds.length < 1) errors.push(`${path}.correctOptionIds must contain at least one correct option id for ${miniGame.type}.`);
  }
  if (miniGame.type === 'match_pairs' && (!Array.isArray(miniGame.pairs) || miniGame.pairs.length < 1)) errors.push(`${path}.pairs must contain at least one pair for match_pairs.`);
  if (miniGame.type === 'arrange_order') {
    if (!Array.isArray(miniGame.orderItems) || miniGame.orderItems.length < 2) errors.push(`${path}.orderItems must contain at least two items for arrange_order.`);
    if (!Array.isArray(miniGame.correctOrderIds) || miniGame.correctOrderIds.length < 2) errors.push(`${path}.correctOrderIds must contain at least two ids for arrange_order.`);
  }
  validateScoreImpact(miniGame.successScoreImpact, `${path}.successScoreImpact`, errors);
  validateScoreImpact(miniGame.failureScoreImpact, `${path}.failureScoreImpact`, errors);
  if (miniGame.successConsequence) validateOutcome(miniGame.successConsequence, `${path}.successConsequence`, errors, { partial: true });
  if (miniGame.failureConsequence) validateOutcome(miniGame.failureConsequence, `${path}.failureConsequence`, errors, { partial: true });
  if (miniGame.skillLevel !== undefined && typeof miniGame.skillLevel !== 'string') errors.push(`${path}.skillLevel must be a string when provided.`);
  if (miniGame.workflowId !== undefined && typeof miniGame.workflowId !== 'string') errors.push(`${path}.workflowId must be a string when provided.`);
  validateStringArray(miniGame.skillTags, `${path}.skillTags`, errors);
  validateStringArray(miniGame.skillNodeIds, `${path}.skillNodeIds`, errors);
}

function validateScenes(value, path, errors) {
  if (value === undefined || value === null) return false;
  if (!Array.isArray(value)) {
    errors.push(`${path} must be an array when provided.`);
    return false;
  }
  let hasDialogueText = false;
  value.forEach((scene, sceneIndex) => {
    const scenePath = `${path}[${sceneIndex}]`;
    if (!isObject(scene)) {
      errors.push(`${scenePath} must be an object.`);
      return;
    }
    for (const key of ['id', 'title', 'backgroundImage', 'characterId', 'characterImage', 'soundEffect', 'transitionType']) {
      if (scene[key] !== undefined && typeof scene[key] !== 'string') errors.push(`${scenePath}.${key} must be a string when provided.`);
    }
    validateAudioConfig(scene.audio, `${scenePath}.audio`, errors);
    if (!Array.isArray(scene.dialogues) || scene.dialogues.length === 0) {
      errors.push(`${scenePath}.dialogues must contain at least one dialogue line.`);
      return;
    }
    scene.dialogues.forEach((line, lineIndex) => {
      const linePath = `${scenePath}.dialogues[${lineIndex}]`;
      if (!isObject(line)) {
        errors.push(`${linePath} must be an object.`);
        return;
      }
      if (!hasText(line.speaker)) errors.push(`${linePath}.speaker is required.`);
      if (!hasText(line.text) && !hasText(line.dialogue)) errors.push(`${linePath}.text is required.`);
      else hasDialogueText = true;
      for (const key of ['emotion', 'characterId', 'characterImage', 'soundEffect', 'voiceClip', 'subtitle']) {
        if (line[key] !== undefined && typeof line[key] !== 'string') errors.push(`${linePath}.${key} must be a string when provided.`);
      }
      validateAudioConfig(line.audio, `${linePath}.audio`, errors);
      validateStringArray(line.requiredStoryFlags, `${linePath}.requiredStoryFlags`, errors);
      validateStringArray(line.blockedByStoryFlags, `${linePath}.blockedByStoryFlags`, errors);
      validateRelationshipImpact(line.requiredRelationshipMinimums, `${linePath}.requiredRelationshipMinimums`, errors);
    });
  });
  return hasDialogueText;
}

function validateChapter(chapter, path = 'chapter') {
  const errors = [];
  if (!isObject(chapter)) return { valid: false, errors: [`${path} must be an object.`] };
  if (!hasText(chapter.id)) errors.push(`${path}.id is required.`);
  if (!hasText(chapter.title)) errors.push(`${path}.title is required.`);
  if (!hasText(chapter.difficulty)) errors.push(`${path}.difficulty is required.`);
  if (!hasText(chapter.theme)) errors.push(`${path}.theme is required.`);
  const hasCinematicScenes = validateScenes(chapter.scenes, `${path}.scenes`, errors);
  if (!hasText(chapter.story) && !hasText(chapter.scenario) && !hasCinematicScenes) errors.push(`${path}.story, ${path}.scenario, or ${path}.scenes with dialogue is required.`);
  if (!hasText(chapter.task)) errors.push(`${path}.task is required.`);

  for (const key of ['learningObjective', 'skillLevel', 'workflowId', 'practicalTakeaway', 'safeExplanation', 'mentorFeedback']) {
    if (chapter[key] !== undefined && typeof chapter[key] !== 'string') errors.push(`${path}.${key} must be a string when provided.`);
  }
  validateStringArray(chapter.skillTags, `${path}.skillTags`, errors);
  validateStringArray(chapter.skillNodeIds, `${path}.skillNodeIds`, errors);
  validateStringArray(chapter.realWorldConstraints, `${path}.realWorldConstraints`, errors);
  validateStringArray(chapter.safetyGuardrails, `${path}.safetyGuardrails`, errors);
  if (chapter.professionalContext !== undefined && !isObject(chapter.professionalContext)) errors.push(`${path}.professionalContext must be an object when provided.`);

  for (const key of ['contentVersion', 'contentPackId', 'assetVersion', 'assetPackId', 'rolePluginId', 'localizationKey', 'contentTier']) {
    if (chapter[key] !== undefined && typeof chapter[key] !== 'string') errors.push(`${path}.${key} must be a string when provided.`);
  }
  if (chapter.supportsOfflineCache !== undefined && typeof chapter.supportsOfflineCache !== 'boolean') errors.push(`${path}.supportsOfflineCache must be a boolean when provided.`);
  validateStringArray(chapter.analyticsTags, `${path}.analyticsTags`, errors);
  validateSafetyReview(chapter.safetyReview, `${path}.safetyReview`, errors);
  validateAccess(chapter.contentAccess, `${path}.contentAccess`, errors);
  validateMultiplayer(chapter.multiplayer, `${path}.multiplayer`, errors);

  validateStringArray(chapter.prerequisites, `${path}.prerequisites`, errors);
  validateStringArray(chapter.consequenceFlags, `${path}.consequenceFlags`, errors);
  validateStringArray(chapter.blockedByFlags, `${path}.blockedByFlags`, errors);
  validateStringArray(chapter.requiredStoryFlags, `${path}.requiredStoryFlags`, errors);
  validateStringArray(chapter.blockedByStoryFlags, `${path}.blockedByStoryFlags`, errors);
  if (chapter.storyFlags !== undefined && !Array.isArray(chapter.storyFlags)) errors.push(`${path}.storyFlags must be an array when provided.`);
  validateScoreImpact(chapter.requiredScoreMinimums, `${path}.requiredScoreMinimums`, errors);
  validateRelationshipImpact(chapter.requiredRelationshipMinimums, `${path}.requiredRelationshipMinimums`, errors);
  if (chapter.endingRules !== undefined && !Array.isArray(chapter.endingRules)) errors.push(`${path}.endingRules must be an array when provided.`);
  if (chapter.roleMechanicType !== undefined && typeof chapter.roleMechanicType !== 'string') errors.push(`${path}.roleMechanicType must be a string when provided.`);
  if (chapter.isCleanupMission !== undefined && typeof chapter.isCleanupMission !== 'boolean') errors.push(`${path}.isCleanupMission must be a boolean when provided.`);
  if (chapter.isFinale !== undefined && typeof chapter.isFinale !== 'boolean') errors.push(`${path}.isFinale must be a boolean when provided.`);

  if (!Array.isArray(chapter.choices) || chapter.choices.length < 2) {
    errors.push(`${path}.choices must contain at least two choices.`);
  } else {
    chapter.choices.forEach((choice, index) => {
      const choicePath = `${path}.choices[${index}]`;
      if (!isObject(choice)) {
        errors.push(`${choicePath} must be an object.`);
        return;
      }
      if (!hasText(choice.text)) errors.push(`${choicePath}.text is required.`);
      if (!isObject(choice.outcome)) errors.push(`${choicePath}.outcome is required.`);
      else validateOutcome(choice.outcome, `${choicePath}.outcome`, errors);
      validateScoreImpact(choice.scoreImpact, `${choicePath}.scoreImpact`, errors);
    });
  }
  validateMiniGame(chapter.miniGame, `${path}.miniGame`, errors);
  validateAdaptiveDialogueInjections(chapter.adaptiveDialogueInjections, `${path}.adaptiveDialogueInjections`, errors);
  validateAdaptiveDifficulty(chapter.adaptiveDifficulty, `${path}.adaptiveDifficulty`, errors);
  if (chapter.allowsAdaptiveSideMissions !== undefined && typeof chapter.allowsAdaptiveSideMissions !== 'boolean') errors.push(`${path}.allowsAdaptiveSideMissions must be a boolean when provided.`);
  return { valid: errors.length === 0, errors };
}

function validateRoleScenario(roleScenario) {
  const errors = [];
  if (!isObject(roleScenario)) return { valid: false, errors: ['roleScenario must be an object.'] };
  if (!isObject(roleScenario.role)) errors.push('role is required.');
  else {
    if (!hasText(roleScenario.role.id)) errors.push('role.id is required.');
    if (!hasText(roleScenario.role.name)) errors.push('role.name is required.');
    if (!hasText(roleScenario.role.description)) errors.push('role.description is required.');
    if (!hasText(roleScenario.role.iconKey)) errors.push('role.iconKey is required.');
  }
  if (!Array.isArray(roleScenario.chapters) || roleScenario.chapters.length === 0) errors.push('chapters must contain at least one chapter.');
  else roleScenario.chapters.forEach((chapter, index) => errors.push(...validateChapter(chapter, `chapters[${index}]`).errors));
  return { valid: errors.length === 0, errors };
}

function validateRoleSkillMaps(skillMaps) {
  const errors = [];
  if (!isObject(skillMaps)) return { valid: false, errors: ['role_skill_maps root must be an object.'] };
  if (!Array.isArray(skillMaps.roles)) return { valid: false, errors: ['role_skill_maps.roles must be an array.'] };
  skillMaps.roles.forEach((role, roleIndex) => {
    const path = `roles[${roleIndex}]`;
    if (!isObject(role)) {
      errors.push(`${path} must be an object.`);
      return;
    }
    if (!hasText(role.roleId)) errors.push(`${path}.roleId is required.`);
    if (!hasText(role.roleName)) errors.push(`${path}.roleName is required.`);
    if (!Array.isArray(role.skills) || role.skills.length < 3) errors.push(`${path}.skills must contain at least 3 skills.`);
    if (!Array.isArray(role.workflows) || role.workflows.length < 3) errors.push(`${path}.workflows must contain at least 3 workflows.`);
    if (!Array.isArray(role.glossary) || role.glossary.length < 1) errors.push(`${path}.glossary must contain at least 1 term.`);
    validateStringArray(role.safetyGuardrails, `${path}.safetyGuardrails`, errors);
  });
  return { valid: errors.length === 0, errors };
}


function validateScenarioPack(pack) {
  const errors = [];
  if (!isObject(pack)) return { valid: false, errors: ['scenario pack must be an object.'] };
  for (const key of ['id', 'title', 'roleId', 'roleName', 'difficulty', 'version', 'priceType', 'safetyStatus']) {
    if (!hasText(pack[key])) errors.push(`pack.${key} is required.`);
  }
  if (!['free', 'premium', 'paid', 'creator_only', 'creatorOnly'].includes(pack.priceType || '')) {
    errors.push('pack.priceType is unsupported.');
  }
  if (!['draft', 'pending', 'approved', 'rejected', 'needs_changes', 'needsChanges'].includes(pack.safetyStatus || '')) {
    errors.push('pack.safetyStatus is unsupported.');
  }
  if (pack.isPublished !== undefined && typeof pack.isPublished !== 'boolean') errors.push('pack.isPublished must be a boolean.');
  if (pack.isFeatured !== undefined && typeof pack.isFeatured !== 'boolean') errors.push('pack.isFeatured must be a boolean.');
  if (pack.isDownloadable !== undefined && typeof pack.isDownloadable !== 'boolean') errors.push('pack.isDownloadable must be a boolean.');
  validateSafetyReview(pack.safetyReview, 'pack.safetyReview', errors);
  if (pack.compatibility !== undefined && !isObject(pack.compatibility)) errors.push('pack.compatibility must be an object when provided.');
  if (pack.rating !== undefined && !isObject(pack.rating)) errors.push('pack.rating must be an object when provided.');
  if (!Array.isArray(pack.chapters)) {
    errors.push('pack.chapters must be an array.');
  } else {
    pack.chapters.forEach((chapter, index) => {
      errors.push(...validateChapter({ ...chapter, roleName: pack.roleName }, `pack.chapters[${index}]`).errors);
    });
  }
  if (pack.isPublished === true) {
    if (pack.safetyStatus !== 'approved') errors.push('published pack must have safetyStatus approved.');
    const safetyStatus = pack.safetyReview && typeof pack.safetyReview === 'object' ? pack.safetyReview.status : '';
    if (safetyStatus !== 'approved') errors.push('published pack must have safetyReview.status approved.');
    if (!Array.isArray(pack.chapters) || pack.chapters.length === 0) errors.push('published pack must contain at least one chapter.');
  }
  return { valid: errors.length === 0, errors };
}

module.exports = {
  validateChapter,
  validateRoleScenario,
  validateRoleSkillMaps,
  validateScenarioPack,
};
