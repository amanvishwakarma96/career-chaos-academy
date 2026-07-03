const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { config } = require('./config');
const { validateRoleScenario, validateChapter, validateScenarioPack } = require('./validation');
const { hashValue, inspectPromptAbuse, sanitizeForAudit } = require('./security');

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function readJson(filePath, fallback) {
  try {
    if (!fs.existsSync(filePath)) return fallback;
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (_) {
    return fallback;
  }
}

function writeJson(filePath, value) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2));
}


function defaultProgress() {
  return {
    version: 14,
    progressByRole: {},
    totalScore: { skill: 0, discipline: 0, ethics: 0, communication: 0, chaos: 0 },
    totalXp: 0,
    badges: [],
    activeFlagsByRole: {},
    completedCleanupMissions: {},
    roleReputation: {},
    miniGameAttempts: {},
    roleEndings: {},
    storyFlagsByRole: {},
    relationshipScoresByRole: {},
    delayedConsequencesByRole: {},
    activityHistory: [],
    activityStreak: { currentStreak: 0, longestStreak: 0, lastCompletionDate: null },
    activityXp: 0,
    flameMiniGameHistory: [],
    flameMiniGameXp: 0,
    flameMiniGameScore: { skill: 0, discipline: 0, ethics: 0, communication: 0, chaos: 0 },
    audioSettings: { muted: false, musicVolume: 0.45, sfxVolume: 0.7, voiceVolume: 0.75 },
    mentorPreference: { selectedMentorId: 'balanced_coach', roastModeEnabled: false },
    contentCacheState: { activeContentPackId: 'core_roles_v23', activeContentVersion: '23.0.0', lastUpdatedAt: null },
    featureFlagOverrides: {},
    userBehaviorSummary: {
      shortcutChoiceCount: 0,
      ethicalChoiceCount: 0,
      repeatedFailureCount: 0,
      strongSkills: [],
      weakSkills: [],
      preferredRoles: [],
      completedChaptersByRole: {},
      failedMiniGamesByRole: {},
      behaviorPatterns: [],
      lastUpdatedAt: null
    },
    adaptiveStoryDraftIds: [],
    skillTreeProgressByRole: {},
    cachedScenarioPackIds: [],
    scenarioPackHistory: [],
    voiceSettings: {
      voiceEnabled: false,
      subtitlesAlwaysOn: true,
      languageMode: 'english',
      textToSpeechProvider: 'placeholder',
      speechToTextProvider: 'placeholder',
      fallbackToText: true,
      voiceVolume: 0.75,
      selectedVoiceProfileId: 'senior_dev_mentor_voice',
      updatedAt: null,
    },
    careerCoachState: {
      preference: { selectedStyleId: 'calm_teacher', roastModeEnabled: false },
      skillProfile: { topStrengths: [], weakAreas: [], skillScores: {}, preferredRoles: [], completedChapters: 0, completedActivities: 0, failedMiniGames: 0, updatedAt: null },
      weeklyPlan: { title: 'Weekly Career Chaos Plan', focusAreas: [], dailySteps: [], nextRoleId: '', nextChapterId: '', nextActivityId: '', roadmapSuggestions: [], safetyNote: '', generatedAt: null },
      lastAdvice: '',
      updatedAt: null
    },
    };
}

function normalizeStringArrayMap(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  const result = {};
  for (const [key, item] of Object.entries(value)) {
    if (Array.isArray(item)) result[key] = item.filter((x) => typeof x === 'string');
  }
  return result;
}

function normalizePlainObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function normalizeBehaviorSummary(value) {
  const fallback = {
    shortcutChoiceCount: 0,
    ethicalChoiceCount: 0,
    repeatedFailureCount: 0,
    strongSkills: [],
    weakSkills: [],
    preferredRoles: [],
    completedChaptersByRole: {},
    failedMiniGamesByRole: {},
    behaviorPatterns: [],
    lastUpdatedAt: null,
  };
  if (!value || typeof value !== 'object' || Array.isArray(value)) return fallback;
  return {
    ...fallback,
    shortcutChoiceCount: Number.isFinite(value.shortcutChoiceCount) && value.shortcutChoiceCount >= 0 ? value.shortcutChoiceCount : 0,
    ethicalChoiceCount: Number.isFinite(value.ethicalChoiceCount) && value.ethicalChoiceCount >= 0 ? value.ethicalChoiceCount : 0,
    repeatedFailureCount: Number.isFinite(value.repeatedFailureCount) && value.repeatedFailureCount >= 0 ? value.repeatedFailureCount : 0,
    strongSkills: Array.isArray(value.strongSkills) ? value.strongSkills.filter((x) => typeof x === 'string') : [],
    weakSkills: Array.isArray(value.weakSkills) ? value.weakSkills.filter((x) => typeof x === 'string') : [],
    preferredRoles: Array.isArray(value.preferredRoles) ? value.preferredRoles.filter((x) => typeof x === 'string') : [],
    completedChaptersByRole: normalizePlainObject(value.completedChaptersByRole),
    failedMiniGamesByRole: normalizePlainObject(value.failedMiniGamesByRole),
    behaviorPatterns: Array.isArray(value.behaviorPatterns) ? value.behaviorPatterns.filter((x) => typeof x === 'string') : [],
    lastUpdatedAt: typeof value.lastUpdatedAt === 'string' ? value.lastUpdatedAt : null,
  };
}

function normalizeActivityHistory(value) {
  if (!Array.isArray(value)) return [];
  return value.filter((item) => item && typeof item === 'object').slice(0, 100);
}


function normalizeFlameMiniGameHistory(value) {
  if (!Array.isArray(value)) return [];
  return value.filter((item) => item && typeof item === 'object').slice(0, 100);
}

function normalizeActivityStreak(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return { currentStreak: 0, longestStreak: 0, lastCompletionDate: null };
  }
  return {
    currentStreak: Number.isFinite(value.currentStreak) && value.currentStreak >= 0 ? value.currentStreak : 0,
    longestStreak: Number.isFinite(value.longestStreak) && value.longestStreak >= 0 ? value.longestStreak : 0,
    lastCompletionDate: typeof value.lastCompletionDate === 'string' ? value.lastCompletionDate : null,
  };
}


function normalizeMentorPreference(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return { selectedMentorId: 'balanced_coach', roastModeEnabled: false };
  }
  return {
    selectedMentorId: typeof value.selectedMentorId === 'string' && value.selectedMentorId.trim()
      ? value.selectedMentorId.trim()
      : 'balanced_coach',
    roastModeEnabled: value.roastModeEnabled === true,
  };
}

function normalizeAudioSettings(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return { muted: false, musicVolume: 0.45, sfxVolume: 0.7, voiceVolume: 0.75 };
  }
  function vol(key, fallback) {
    return Number.isFinite(value[key]) && value[key] >= 0 && value[key] <= 1 ? value[key] : fallback;
  }
  return {
    muted: typeof value.muted === 'boolean' ? value.muted : false,
    musicVolume: vol('musicVolume', 0.45),
    sfxVolume: vol('sfxVolume', 0.7),
    voiceVolume: vol('voiceVolume', 0.75),
  };
}

function normalizeLanguageMode(value, fallback = 'english') {
  const mode = typeof value === 'string' ? value.trim().toLowerCase() : '';
  return ['english', 'hinglish', 'hindi'].includes(mode) ? mode : fallback;
}

function normalizeVoiceSettings(value) {
  const fallback = defaultProgress().voiceSettings;
  if (!value || typeof value !== 'object' || Array.isArray(value)) return fallback;
  const volume = Number.isFinite(value.voiceVolume) && value.voiceVolume >= 0 && value.voiceVolume <= 1
    ? value.voiceVolume
    : fallback.voiceVolume;
  return {
    voiceEnabled: value.voiceEnabled === true,
    subtitlesAlwaysOn: value.subtitlesAlwaysOn !== false,
    languageMode: normalizeLanguageMode(value.languageMode, fallback.languageMode),
    textToSpeechProvider: safeString(value.textToSpeechProvider, fallback.textToSpeechProvider),
    speechToTextProvider: safeString(value.speechToTextProvider, fallback.speechToTextProvider),
    fallbackToText: value.fallbackToText !== false,
    voiceVolume: volume,
    selectedVoiceProfileId: safeString(value.selectedVoiceProfileId, fallback.selectedVoiceProfileId),
    updatedAt: typeof value.updatedAt === 'string' ? value.updatedAt : null,
  };
}


function normalizeCareerCoachState(value) {
  const fallback = defaultProgress().careerCoachState;
  if (!value || typeof value !== 'object' || Array.isArray(value)) return fallback;
  const preference = value.preference && typeof value.preference === 'object' && !Array.isArray(value.preference)
    ? {
        selectedStyleId: typeof value.preference.selectedStyleId === 'string' && value.preference.selectedStyleId.trim() ? value.preference.selectedStyleId.trim() : 'calm_teacher',
        roastModeEnabled: value.preference.roastModeEnabled === true,
      }
    : fallback.preference;
  return {
    ...fallback,
    ...value,
    preference,
    skillProfile: value.skillProfile && typeof value.skillProfile === 'object' && !Array.isArray(value.skillProfile) ? { ...fallback.skillProfile, ...value.skillProfile } : fallback.skillProfile,
    weeklyPlan: value.weeklyPlan && typeof value.weeklyPlan === 'object' && !Array.isArray(value.weeklyPlan) ? { ...fallback.weeklyPlan, ...value.weeklyPlan } : fallback.weeklyPlan,
    lastAdvice: typeof value.lastAdvice === 'string' ? value.lastAdvice : '',
    updatedAt: typeof value.updatedAt === 'string' ? value.updatedAt : null,
  };
}

function normalizeProgress(progress) {
  const base = defaultProgress();
  const source = progress && typeof progress === 'object' && !Array.isArray(progress) ? progress : {};
  return {
    ...base,
    ...source,
    version: 14,
    progressByRole: source.progressByRole && typeof source.progressByRole === 'object' ? source.progressByRole : {},
    totalScore: source.totalScore && typeof source.totalScore === 'object' ? { ...base.totalScore, ...source.totalScore } : base.totalScore,
    totalXp: Number.isFinite(source.totalXp) && source.totalXp >= 0 ? source.totalXp : 0,
    badges: Array.isArray(source.badges) ? source.badges.filter((x) => typeof x === 'string') : [],
    activeFlagsByRole: normalizeStringArrayMap(source.activeFlagsByRole),
    completedCleanupMissions: normalizeStringArrayMap(source.completedCleanupMissions),
    roleReputation: source.roleReputation && typeof source.roleReputation === 'object' ? source.roleReputation : {},
    miniGameAttempts: source.miniGameAttempts && typeof source.miniGameAttempts === 'object' ? source.miniGameAttempts : {},
    roleEndings: source.roleEndings && typeof source.roleEndings === 'object' ? source.roleEndings : {},
    storyFlagsByRole: normalizeStringArrayMap(source.storyFlagsByRole),
    relationshipScoresByRole: source.relationshipScoresByRole && typeof source.relationshipScoresByRole === 'object' ? source.relationshipScoresByRole : {},
    delayedConsequencesByRole: normalizeStringArrayMap(source.delayedConsequencesByRole),
    activityHistory: normalizeActivityHistory(source.activityHistory),
    activityStreak: normalizeActivityStreak(source.activityStreak),
    activityXp: Number.isFinite(source.activityXp) && source.activityXp >= 0 ? source.activityXp : 0,
    flameMiniGameHistory: normalizeFlameMiniGameHistory(source.flameMiniGameHistory),
    flameMiniGameXp: Number.isFinite(source.flameMiniGameXp) && source.flameMiniGameXp >= 0 ? source.flameMiniGameXp : 0,
    flameMiniGameScore: source.flameMiniGameScore && typeof source.flameMiniGameScore === 'object'
      ? { ...base.flameMiniGameScore, ...source.flameMiniGameScore }
      : base.flameMiniGameScore,
    audioSettings: normalizeAudioSettings(source.audioSettings),
    mentorPreference: normalizeMentorPreference(source.mentorPreference),
    contentCacheState: source.contentCacheState && typeof source.contentCacheState === 'object' ? { ...base.contentCacheState, ...source.contentCacheState } : base.contentCacheState,
    featureFlagOverrides: source.featureFlagOverrides && typeof source.featureFlagOverrides === 'object' ? source.featureFlagOverrides : {},
    userBehaviorSummary: normalizeBehaviorSummary(source.userBehaviorSummary),
    adaptiveStoryDraftIds: Array.isArray(source.adaptiveStoryDraftIds) ? source.adaptiveStoryDraftIds.filter((x) => typeof x === 'string') : [],
    voiceSettings: normalizeVoiceSettings(source.voiceSettings),
    careerCoachState: normalizeCareerCoachState(source.careerCoachState),
    skillTreeProgressByRole: normalizePlainObject(source.skillTreeProgressByRole),
    cachedScenarioPackIds: Array.isArray(source.cachedScenarioPackIds) ? source.cachedScenarioPackIds.filter((x) => typeof x === 'string') : [],
    scenarioPackHistory: Array.isArray(source.scenarioPackHistory) ? source.scenarioPackHistory.filter((item) => item && typeof item === 'object').slice(0, 100) : [],
  };
}


function containsUnsafeAdaptiveAdvice(value) {
  const text = JSON.stringify(value || {}).toLowerCase();
  const unsafe = [
    'prescribe ',
    'dosage',
    'guaranteed return',
    'ignore safety',
    'hide evidence',
    'skip inspection',
    'discriminate',
    'diagnose ',
  ];
  return unsafe.some((item) => text.includes(item));
}


function randomRoomCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i += 1) {
    code += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return code;
}

function numberOrZero(value) {
  return Number.isFinite(value) ? value : 0;
}

function clampMetric(value) {
  return Math.max(0, Math.min(100, Math.round(numberOrZero(value))));
}

function emptyTeamScore() {
  return {
    collaboration: 0,
    communication: 0,
    speed: 100,
    accuracy: 0,
    ethics: 0,
  };
}

function safeObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function safeString(value, fallback = '') {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

function scoreImpactFromChoice(choice) {
  const raw = safeObject(choice && choice.scoreImpact);
  return {
    skill: numberOrZero(raw.skill),
    discipline: numberOrZero(raw.discipline),
    ethics: numberOrZero(raw.ethics),
    communication: numberOrZero(raw.communication),
    chaos: numberOrZero(raw.chaos),
  };
}

function readStringArray(value) {
  return Array.isArray(value) ? value.filter((item) => typeof item === 'string' && item.trim()).map((item) => item.trim()) : [];
}


function uniqueStrings(values) {
  return Array.from(new Set(readStringArray(values)));
}

function containsUnsafeConversationAdvice(value) {
  const text = String(value || '').toLowerCase();
  const unsafe = [
    'prescribe',
    'dosage',
    'self harm',
    'suicide',
    'kill myself',
    'hide evidence',
    'delete logs',
    'bypass safety',
    'ignore safety',
    'fake certificate',
    'guaranteed return',
    'discriminate',
    'hack into',
    'steal data',
    'share password',
    'medical diagnosis',
  ];
  return unsafe.some((item) => text.includes(item));
}

function isOutOfScenarioMemoryRequest(value) {
  const text = String(value || '').toLowerCase();
  const memoryRequests = ['remember this forever', 'store my personal', 'what do you know about me', 'use my private', 'outside this scenario'];
  return memoryRequests.some((item) => text.includes(item));
}

function languageLabel(mode) {
  return {
    english: 'English',
    hinglish: 'Hinglish',
    hindi: 'Hindi',
  }[normalizeLanguageMode(mode)] || 'English';
}

function localizedBoundaryReply({ languageMode, characterName, scenarioTitle, userMessage }) {
  const mode = normalizeLanguageMode(languageMode);
  const trimmed = safeString(userMessage, 'your response');
  if (mode === 'hindi') {
    return `${characterName}: मैं सिर्फ इस scenario (${scenarioTitle}) के context में guide कर सकता/सकती हूँ. आपका point "${trimmed.slice(0, 80)}" है; safe next step है evidence check करना, stakeholder को update देना, और risky shortcut avoid करना.`;
  }
  if (mode === 'hinglish') {
    return `${characterName}: Main sirf is scenario (${scenarioTitle}) ke context mein help karunga. Aapka point "${trimmed.slice(0, 80)}" hai; safe next step hai evidence check karo, stakeholder ko update do, aur risky shortcut avoid karo.`;
  }
  return `${characterName}: I can stay inside this scenario (${scenarioTitle}). For "${trimmed.slice(0, 80)}", the safest next step is to verify evidence, communicate with the right stakeholder, and avoid risky shortcuts.`;
}

function localizedBlockedReply(languageMode) {
  const mode = normalizeLanguageMode(languageMode);
  if (mode === 'hindi') {
    return 'मैं unsafe या professional boundary तोड़ने वाली सलाह नहीं दे सकता/सकती. इस scenario में safe learning path चुनें: evidence collect करें, senior/trainer को escalate करें, और policy follow करें.';
  }
  if (mode === 'hinglish') {
    return 'Main unsafe ya professional boundary todne wali advice nahi de sakta. Is scenario mein safe learning path choose karo: evidence collect karo, senior/trainer ko escalate karo, aur policy follow karo.';
  }
  return 'I cannot provide unsafe advice or guidance that breaks professional boundaries. In this scenario, choose the safe learning path: collect evidence, escalate to the right senior/trainer, and follow policy.';
}

function normalizeRole(value, fallback = 'trainee') {
  const role = safeString(value, fallback).toLowerCase();
  return ['platform_admin', 'org_admin', 'trainer', 'trainee', 'individual'].includes(role) ? role : fallback;
}

function requireOrgRole(payload = {}, allowed = []) {
  const role = normalizeRole(payload.actorRole || payload.role, 'individual');
  if (!allowed.includes(role)) {
    const error = new Error(`Role ${role} is not allowed for this organization action.`);
    error.statusCode = 403;
    throw error;
  }
  return role;
}

function normalizeDueDate(value, fallbackDays = 14) {
  const raw = safeString(value);
  const parsed = raw ? new Date(raw) : null;
  if (parsed && !Number.isNaN(parsed.getTime())) return parsed.toISOString();
  return new Date(Date.now() + (fallbackDays * 24 * 60 * 60 * 1000)).toISOString();
}

function clampPercent(value) {
  return Math.max(0, Math.min(100, Math.round(numberOrZero(value))));
}

function csvEscape(value) {
  const text = String(value ?? '');
  return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}


const ANALYTICS_EVENT_TYPES = [
  'chapter_started',
  'chapter_completed',
  'choice_selected',
  'mini_game_attempt',
  'time_spent',
  'role_progress',
  'skill_improvement',
];

const ANALYTICS_BLOCKED_KEYS = [
  'email',
  'phone',
  'mobile',
  'password',
  'token',
  'secret',
  'address',
  'location',
  'ip',
  'name',
  'displayName',
  'message',
  'answer',
  'freeText',
  'transcript',
];

function anonymizeUserId(userId) {
  return crypto.createHash('sha256').update(safeString(userId, 'anonymous')).digest('hex').slice(0, 16);
}

function isAnalyticsBlockedKey(key) {
  const normalized = String(key || '').toLowerCase();
  return ANALYTICS_BLOCKED_KEYS.some((blocked) => normalized.includes(String(blocked).toLowerCase()));
}

function sanitizeAnalyticsValue(value, depth = 0) {
  if (depth > 2) return '[redacted_depth]';
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') return value.slice(0, 120);
  if (typeof value === 'number') return Number.isFinite(value) ? value : 0;
  if (typeof value === 'boolean') return value;
  if (Array.isArray(value)) {
    return value.slice(0, 20).map((item) => sanitizeAnalyticsValue(item, depth + 1));
  }
  if (typeof value === 'object') {
    const result = {};
    for (const [key, item] of Object.entries(value)) {
      if (isAnalyticsBlockedKey(key)) continue;
      result[key] = sanitizeAnalyticsValue(item, depth + 1);
    }
    return result;
  }
  return String(value).slice(0, 120);
}

function sanitizeAnalyticsMetadata(value) {
  const source = safeObject(value);
  const sanitized = {};
  for (const [key, item] of Object.entries(source)) {
    if (isAnalyticsBlockedKey(key)) continue;
    sanitized[key] = sanitizeAnalyticsValue(item);
  }
  return sanitized;
}

function normalizeAnalyticsSettings(value) {
  const source = safeObject(value);
  return {
    enabled: source.enabled !== false,
    shareAggregateWithAdmin: source.shareAggregateWithAdmin !== false,
    retentionDays: Number.isFinite(source.retentionDays) && source.retentionDays >= 1 && source.retentionDays <= 365 ? Math.round(source.retentionDays) : 90,
    updatedAt: typeof source.updatedAt === 'string' ? source.updatedAt : null,
  };
}

function normalizeAnalyticsEventType(value) {
  const type = safeString(value, 'time_spent').toLowerCase();
  return ANALYTICS_EVENT_TYPES.includes(type) ? type : 'time_spent';
}

function analyticsEmptySkillMap() {
  return { skill: 0, discipline: 0, ethics: 0, communication: 0, chaos_control: 0 };
}

const MONETIZATION_PRODUCT_TYPES = [
  'scenario_pack',
  'subscription',
  'certificate',
  'corporate_license',
  'feature_unlock',
];

const MONETIZATION_PRICE_TYPES = [
  'free',
  'premium',
  'subscription',
  'payment_placeholder',
  'license_placeholder',
];

function normalizeMonetizationProductType(value) {
  const type = safeString(value, 'feature_unlock').toLowerCase();
  return MONETIZATION_PRODUCT_TYPES.includes(type) ? type : 'feature_unlock';
}

function normalizeMonetizationPriceType(value) {
  const type = safeString(value, 'free').toLowerCase();
  return MONETIZATION_PRICE_TYPES.includes(type) ? type : 'free';
}

function flagEnabled(flags, key, fallback = false) {
  const list = Array.isArray(flags && flags.flags) ? flags.flags : [];
  const flag = list.find((item) => item && item.key === key);
  return flag ? flag.enabled === true : fallback;
}

function normalizeProduct(product = {}) {
  const raw = safeObject(product);
  const priceType = normalizeMonetizationPriceType(raw.priceType);
  const productType = normalizeMonetizationProductType(raw.productType || raw.type);
  const id = safeString(raw.id, slugify(`${productType}_${raw.title || crypto.randomUUID()}`));
  return {
    id,
    title: safeString(raw.title, 'Untitled Product'),
    description: safeString(raw.description),
    productType,
    priceType,
    currency: safeString(raw.currency, 'INR'),
    amountMinor: Math.max(0, Math.round(numberOrZero(raw.amountMinor || raw.priceMinor))),
    billingPeriod: safeString(raw.billingPeriod),
    isActive: raw.isActive !== false,
    featureFlag: safeString(raw.featureFlag, 'monetization_system'),
    entitlementKey: safeString(raw.entitlementKey, `entitlement.${id}`),
    contentIds: uniqueStrings(raw.contentIds),
    scenarioPackIds: uniqueStrings(raw.scenarioPackIds),
    roleIds: uniqueStrings(raw.roleIds),
    preview: safeObject(raw.preview),
    developmentModeNoPaymentRequired: raw.developmentModeNoPaymentRequired !== false,
  };
}

function normalizeEntitlement(entitlement = {}) {
  const raw = safeObject(entitlement);
  return {
    id: safeString(raw.id, crypto.randomUUID()),
    userId: safeString(raw.userId, 'anonymous'),
    productId: safeString(raw.productId),
    entitlementKey: safeString(raw.entitlementKey),
    contentIds: uniqueStrings(raw.contentIds),
    scenarioPackIds: uniqueStrings(raw.scenarioPackIds),
    source: safeString(raw.source, 'development_placeholder'),
    active: raw.active !== false,
    grantedAt: safeString(raw.grantedAt, new Date().toISOString()),
    expiresAt: safeString(raw.expiresAt),
    verificationNote: safeString(raw.verificationNote, 'Development placeholder entitlement; replace with app-store/server receipt validation before production.'),
  };
}

function entitlementIsActive(entitlement) {
  if (!entitlement || entitlement.active === false) return false;
  if (!entitlement.expiresAt) return true;
  const expiry = new Date(entitlement.expiresAt).getTime();
  return Number.isFinite(expiry) && expiry > Date.now();
}

function productMatchesContent(product, payload = {}) {
  const contentId = safeString(payload.contentId || payload.packId || payload.scenarioPackId);
  const productId = safeString(payload.productId);
  const entitlementKey = safeString(payload.entitlementKey);
  const roleId = safeString(payload.roleId);
  if (productId && product.id === productId) return true;
  if (entitlementKey && product.entitlementKey === entitlementKey) return true;
  if (contentId && product.contentIds.includes(contentId)) return true;
  if (contentId && product.scenarioPackIds.includes(contentId)) return true;
  if (roleId && product.roleIds.includes(roleId) && product.priceType === 'free') return true;
  return false;
}

function entitlementMatchesContent(entitlement, payload = {}) {
  const contentId = safeString(payload.contentId || payload.packId || payload.scenarioPackId);
  const productId = safeString(payload.productId);
  const entitlementKey = safeString(payload.entitlementKey);
  if (productId && entitlement.productId === productId) return true;
  if (entitlementKey && entitlement.entitlementKey === entitlementKey) return true;
  if (contentId && entitlement.contentIds.includes(contentId)) return true;
  if (contentId && entitlement.scenarioPackIds.includes(contentId)) return true;
  return false;
}

function teamMetricBreakdown(scoreImpact, elapsedSeconds) {
  const speedPenalty = Math.max(0, Math.floor(numberOrZero(elapsedSeconds) / 15));
  return {
    communication: (scoreImpact.communication * 10) + Math.max(0, scoreImpact.discipline * 2),
    accuracy: ((scoreImpact.skill + scoreImpact.discipline) * 8) - Math.max(0, scoreImpact.chaos * 5),
    ethics: (scoreImpact.ethics * 12) - Math.max(0, scoreImpact.chaos * 6),
    speed: Math.max(0, 24 - speedPenalty),
  };
}

function redactAssessmentAnswers(assessment) {
  if (!assessment || typeof assessment !== 'object' || Array.isArray(assessment)) return assessment;
  return {
    ...assessment,
    questions: Array.isArray(assessment.questions)
      ? assessment.questions.map((question) => {
          const { correctIndex, ...safeQuestion } = question;
          return safeQuestion;
        })
      : [],
  };
}

function certificateVerificationId(roleId) {
  const prefix = safeString(roleId, 'role')
    .replace(/[^a-z0-9]/gi, '')
    .slice(0, 4)
    .toUpperCase() || 'ROLE';
  const year = new Date().getUTCFullYear();
  const token = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `CCA-${prefix}-${year}-${token}`;
}

function pdfEscape(value) {
  return String(value || '')
    .replace(/\\/g, '\\\\')
    .replace(/\(/g, '\\(')
    .replace(/\)/g, '\\)')
    .replace(/[\r\n]+/g, ' ');
}

function buildCertificatePdf(certificate) {
  const lines = [
    'Career Chaos Academy',
    'Certificate of Completion',
    `This certifies that ${certificate.recipientName}`,
    `has passed the ${certificate.roleName} Final Certification Assessment`,
    `Score: ${certificate.totalScore}%`,
    `Verification ID: ${certificate.verificationId}`,
    `Issued: ${certificate.issuedAt}`,
    'Verify this certificate through the Career Chaos Academy certificate API.',
  ];
  const textCommands = [
    'BT',
    '/F1 24 Tf',
    '70 760 Td',
    `(${pdfEscape(lines[0])}) Tj`,
    '/F1 18 Tf',
    '0 -40 Td',
    `(${pdfEscape(lines[1])}) Tj`,
    '/F1 13 Tf',
    '0 -54 Td',
    `(${pdfEscape(lines[2])}) Tj`,
    '0 -26 Td',
    `(${pdfEscape(lines[3])}) Tj`,
    '0 -40 Td',
    `(${pdfEscape(lines[4])}) Tj`,
    '0 -26 Td',
    `(${pdfEscape(lines[5])}) Tj`,
    '0 -26 Td',
    `(${pdfEscape(lines[6])}) Tj`,
    '/F1 10 Tf',
    '0 -52 Td',
    `(${pdfEscape(lines[7])}) Tj`,
    'ET',
  ].join('\n');
  const stream = `q\n2 w\n40 40 515 760 re S\n${textCommands}\nQ`;
  const objects = [
    '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
    '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
    '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n',
    '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
    `5 0 obj\n<< /Length ${Buffer.byteLength(stream, 'utf8')} >>\nstream\n${stream}\nendstream\nendobj\n`,
  ];
  let pdf = '%PDF-1.4\n';
  const offsets = [0];
  for (const object of objects) {
    offsets.push(Buffer.byteLength(pdf, 'utf8'));
    pdf += object;
  }
  const xrefOffset = Buffer.byteLength(pdf, 'utf8');
  pdf += `xref\n0 ${objects.length + 1}\n`;
  pdf += '0000000000 65535 f \n';
  for (let i = 1; i <= objects.length; i += 1) {
    pdf += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  }
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF\n`;
  return Buffer.from(pdf, 'utf8');
}

function slugify(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '') || crypto.randomUUID();
}

class DataStore {
  constructor() {
    ensureDir(config.runtimeDir);
    this.progressFile = path.join(config.runtimeDir, 'progress.json');
    this.scoreFile = path.join(config.runtimeDir, 'scores.json');
    this.badgeFile = path.join(config.runtimeDir, 'badges.json');
    this.characterFile = path.join(config.rootDir, 'data', 'characters', 'characters.json');
    this.professionalSkillMapFile = path.join(config.rootDir, 'data', 'professional', 'role_skill_maps.json');
    this.activityFile = path.join(config.rootDir, 'data', 'activities', 'activities.json');
    this.audioManifestFile = path.join(config.rootDir, 'data', 'audio', 'audio_manifest.json');
    this.mentorFile = path.join(config.rootDir, 'data', 'mentors', 'mentors.json');
    this.coachStylesFile = path.join(config.rootDir, 'data', 'career_coach', 'coach_styles.json');
    this.careerRoadmapsFile = path.join(config.rootDir, 'data', 'career_coach', 'career_roadmaps.json');
    this.skillTreesFile = path.join(config.rootDir, 'data', 'skill_trees', 'skill_trees.json');
    this.scenarioPacksFile = path.join(config.rootDir, 'data', 'scenario_packs', 'packs.json');
    this.scenarioPackReviewsFile = path.join(config.runtimeDir, 'scenario_pack_reviews.json');
    this.teamSessionsFile = path.join(config.runtimeDir, 'team_sessions.json');
    this.interviewQuestionBankFile = path.join(config.rootDir, 'data', 'interview', 'question_banks.json');
    this.interviewReportsFile = path.join(config.runtimeDir, 'interview_reports.json');
    this.assessmentCatalogFile = path.join(config.rootDir, 'data', 'assessments', 'role_assessments.json');
    this.assessmentSessionsFile = path.join(config.runtimeDir, 'assessment_sessions.json');
    this.certificateRecordsFile = path.join(config.runtimeDir, 'certificate_records.json');
    this.organizationsFile = path.join(config.runtimeDir, 'organizations.json');
    this.voiceProfilesFile = path.join(config.rootDir, 'data', 'voice', 'voice_profiles.json');
    this.voiceConversationFile = path.join(config.runtimeDir, 'voice_conversations.json');
    this.analyticsEventsFile = path.join(config.runtimeDir, 'learning_analytics_events.json');
    this.analyticsSettingsFile = path.join(config.runtimeDir, 'learning_analytics_settings.json');
    this.monetizationProductsFile = path.join(config.rootDir, 'data', 'monetization', 'products.json');
    this.monetizationEntitlementsFile = path.join(config.runtimeDir, 'monetization_entitlements.json');
    this.featureFlagsFile = path.join(config.rootDir, 'data', 'config', 'feature_flags.json');
    this.remoteConfigDefaultsFile = path.join(config.rootDir, 'data', 'config', 'remote_config_defaults.json');
    this.contentManifestFile = path.join(config.rootDir, 'data', 'config', 'content_manifest.json');
    this.assetManifestVersionFile = path.join(config.rootDir, 'data', 'config', 'asset_manifest_version.json');
    this.rolePluginsFile = path.join(config.rootDir, 'data', 'config', 'role_plugins.json');
    this.localizationEnFile = path.join(config.rootDir, 'data', 'i18n', 'en.json');
    this.auditFile = path.join(config.runtimeDir, 'audit_logs.json');
    this.reviewFile = path.join(config.runtimeDir, 'ai_reviews.json');
    this.adaptiveDraftFile = path.join(config.runtimeDir, 'adaptive_story_drafts.json');
    this.adaptivePromptTemplateFile = path.join(config.rootDir, 'data', 'adaptive', 'adaptive_story_prompt_template.md');
    this.contentModerationFile = path.join(config.runtimeDir, 'content_moderation_queue.json');
    this.errorEventsFile = path.join(config.runtimeDir, 'error_events.json');
    this.backupManifestFile = path.join(config.backupDir, 'manifest.json');
  }

  loadRoleScenarioFiles() {
    ensureDir(config.scenarioDir);
    return fs
      .readdirSync(config.scenarioDir)
      .filter((name) => name.endsWith('.json'))
      .sort()
      .map((name) => {
        const filePath = path.join(config.scenarioDir, name);
        const json = readJson(filePath, null);
        return { name, filePath, json };
      })
      .filter((item) => item.json);
  }

  loadCatalog({ includeUnpublished = false } = {}) {
    const roleFiles = this.loadRoleScenarioFiles();
    const catalog = [];
    for (const item of roleFiles) {
      const result = validateRoleScenario(item.json);
      if (!result.valid) continue;
      const roleScenario = structuredClone(item.json);
      roleScenario.__fileName = item.name;
      if (!includeUnpublished && roleScenario.role.isPublished === false) continue;
      roleScenario.chapters = roleScenario.chapters.filter((chapter) => {
        if (includeUnpublished) return true;
        return chapter.isPublished !== false;
      });
      if (roleScenario.chapters.length > 0 || includeUnpublished) {
        catalog.push(roleScenario);
      }
    }
    return catalog;
  }

  getCharacters() {
    return readJson(this.characterFile, { version: 1, characters: [] });
  }

  getProfessionalSkillMaps() {
    return readJson(this.professionalSkillMapFile, { version: 1, roles: [] });
  }

  getActivities() {
    return readJson(this.activityFile, { version: 1, activities: [] });
  }

  getAudioManifest() {
    return readJson(this.audioManifestFile, {
      version: 1,
      backgroundMusic: [],
      soundEffects: [],
      voice: [],
    });
  }

  getMentors() {
    return readJson(this.mentorFile, { version: 1, mentors: [] });
  }

  getCoachStyles() {
    return readJson(this.coachStylesFile, { version: 1, styles: [] });
  }

  getCareerRoadmaps() {
    return readJson(this.careerRoadmapsFile, { version: 1, roadmaps: [] });
  }

  getSkillTrees() {
    return readJson(this.skillTreesFile, { version: 1, skillTrees: [] });
  }


  getFeatureFlags() {
    return readJson(this.featureFlagsFile, { version: 1, flags: [] });
  }

  getRemoteConfigDefaults() {
    return readJson(this.remoteConfigDefaultsFile, { version: 1, values: {} });
  }

  getContentManifest() {
    return readJson(this.contentManifestFile, { contentPackId: 'core_roles_v23', version: '23.0.0', roleIds: [] });
  }

  getAssetManifestVersion() {
    return readJson(this.assetManifestVersionFile, { assetPackId: 'base_visuals_v23', version: '23.0.0', assetVersions: {} });
  }

  getRolePlugins() {
    return readJson(this.rolePluginsFile, { version: 1, plugins: [] });
  }

  getLocalization(locale = 'en') {
    if (locale !== 'en') return {};
    return readJson(this.localizationEnFile, {});
  }

  getOfflineCacheStrategy() {
    return {
      contentPackId: 'core_roles_v23',
      version: '23.0.0',
      staleAfterDays: 30,
      allowBundledFallback: true,
      allowRemoteRefresh: false,
      checksumRequiredBeforeActivation: true,
    };
  }

  getSafetyReviewWorkflow() {
    return {
      statuses: ['draft', 'pending', 'approved', 'rejected', 'needs_changes'],
      requiredDomains: ['medical', 'engineering', 'legal_safe_feedback', 'privacy', 'professional_learning'],
      publishRule: 'Safety-sensitive content must be approved before production publishing.',
    };
  }

  getScenarioValidationPipelineSummary() {
    return {
      stages: ['json_schema', 'score_balance', 'professional_safety', 'asset_reference', 'localization_key', 'publish_gate'],
      blocksPublishOn: ['invalid_json', 'missing_choices', 'unsafe_professional_advice', 'rejected_safety_review'],
    };
  }


  getAdaptivePromptTemplate() {
    if (fs.existsSync(this.adaptivePromptTemplateFile)) {
      return fs.readFileSync(this.adaptivePromptTemplateFile, 'utf8');
    }
    return 'Generate draft-only Career Chaos Academy adaptive story JSON. mustNotAutoPublish=true and requiresAdminReview=true are mandatory.';
  }

  getAdaptiveStoryDrafts() {
    return readJson(this.adaptiveDraftFile, []);
  }

  createAdaptiveStoryDraft(payload, actor = 'adaptive_story_engine') {
    const items = this.getAdaptiveStoryDrafts();
    if (containsUnsafeAdaptiveAdvice(payload.generatedJson || payload)) {
      const error = new Error('Adaptive story draft contains unsafe professional advice and cannot be stored.');
      error.statusCode = 400;
      throw error;
    }
    const draft = {
      id: payload.id || crypto.randomUUID(),
      roleId: typeof payload.roleId === 'string' ? payload.roleId : 'developer',
      title: typeof payload.title === 'string' ? payload.title : 'Adaptive Side Mission Draft',
      status: 'draft_pending_admin_review',
      safetyStatus: 'requires_professional_safety_review',
      promptVersion: payload.promptVersion || 'adaptive_story_v1',
      generatedJson: payload.generatedJson && typeof payload.generatedJson === 'object' ? payload.generatedJson : {},
      createdBy: actor,
      createdAt: new Date().toISOString(),
      reviewedAt: null,
      reviewNotes: '',
    };
    draft.generatedJson.mustNotAutoPublish = true;
    draft.generatedJson.requiresAdminReview = true;
    items.unshift(draft);
    writeJson(this.adaptiveDraftFile, items.slice(0, 250));
    this.addAudit(actor, 'adaptive_story_draft_created', draft.id, { roleId: draft.roleId });
    return draft;
  }

  setAdaptiveStoryDraftStatus(draftId, status, notes = '', actor = 'admin') {
    const allowed = new Set(['approved_for_manual_publish', 'rejected', 'needs_changes']);
    if (!allowed.has(status)) {
      const error = new Error('Unsupported adaptive draft status.');
      error.statusCode = 400;
      throw error;
    }
    const items = this.getAdaptiveStoryDrafts();
    const draft = items.find((item) => item.id === draftId);
    if (!draft) {
      const error = new Error('Adaptive story draft not found.');
      error.statusCode = 404;
      throw error;
    }
    draft.status = status;
    draft.reviewNotes = notes;
    draft.reviewedAt = new Date().toISOString();
    draft.reviewedBy = actor;
    if (draft.generatedJson && typeof draft.generatedJson === 'object') {
      draft.generatedJson.mustNotAutoPublish = true;
      draft.generatedJson.requiresManualPublish = true;
    }
    writeJson(this.adaptiveDraftFile, items);
    this.addAudit(actor, `adaptive_story_draft_${status}`, draftId, { notes });
    return draft;
  }


  getScenarioPackCatalog({ includeUnpublished = false } = {}) {
    const catalog = readJson(this.scenarioPacksFile, { version: 1, packs: [] });
    const packs = Array.isArray(catalog.packs) ? catalog.packs : [];
    return {
      ...catalog,
      packs: packs.filter((pack) => includeUnpublished || pack.isPublished === true),
    };
  }

  getScenarioPack(packId, { includeUnpublished = false } = {}) {
    const catalog = this.getScenarioPackCatalog({ includeUnpublished });
    return catalog.packs.find((pack) => pack.id === packId) || null;
  }

  saveScenarioPackCatalog(catalog) {
    writeJson(this.scenarioPacksFile, catalog);
    return catalog;
  }

  upsertScenarioPack(payload, actor = 'admin') {
    const catalog = readJson(this.scenarioPacksFile, { version: 1, packs: [] });
    if (!Array.isArray(catalog.packs)) catalog.packs = [];
    const id = slugify(payload.id || payload.title || crypto.randomUUID());
    const existing = catalog.packs.find((pack) => pack.id === id) || {};
    const pack = {
      ...existing,
      ...payload,
      id,
      title: payload.title || existing.title || 'Untitled Scenario Pack',
      roleId: payload.roleId || existing.roleId || 'developer',
      roleName: payload.roleName || existing.roleName || 'Developer',
      difficulty: payload.difficulty || existing.difficulty || 'Beginner',
      creator: payload.creator || existing.creator || { id: actor, name: actor, displayName: actor, verified: false },
      version: payload.version || existing.version || '1.0.0',
      priceType: payload.priceType || existing.priceType || 'free',
      safetyStatus: payload.safetyStatus || existing.safetyStatus || 'draft',
      reviewStatus: payload.reviewStatus || existing.reviewStatus || 'draft',
      isPublished: payload.isPublished === true,
      isFeatured: payload.isFeatured === true,
      isDownloadable: payload.isDownloadable !== false,
      supportsOfflineCache: payload.supportsOfflineCache !== false,
      chapters: Array.isArray(payload.chapters) ? payload.chapters : (Array.isArray(existing.chapters) ? existing.chapters : []),
      safetyReview: payload.safetyReview || existing.safetyReview || { status: 'draft', domains: ['professional_learning'], guardrails: [] },
      compatibility: payload.compatibility || existing.compatibility || { minAppVersion: '1.0.0', requiredFeatureFlags: ['scenario_marketplace'], schemaVersion: 'scenario_pack_v1' },
      rating: payload.rating || existing.rating || { average: 0, count: 0, userRating: 0 },
      reviews: Array.isArray(payload.reviews) ? payload.reviews : (Array.isArray(existing.reviews) ? existing.reviews : []),
      offline: payload.offline || existing.offline || { cacheStrategy: 'downloadable_json_pack', estimatedSizeKb: 0, checksum: '', supportsDeltaUpdate: false },
      updatedAt: new Date().toISOString(),
    };
    const validation = validateScenarioPack(pack);
    if (!validation.valid && pack.isPublished) {
      const error = new Error('Invalid scenario pack cannot be saved as published.');
      error.validation = validation;
      error.statusCode = 400;
      throw error;
    }
    const index = catalog.packs.findIndex((item) => item.id === id);
    if (index >= 0) catalog.packs[index] = pack;
    else catalog.packs.unshift(pack);
    writeJson(this.scenarioPacksFile, catalog);
    this.addAudit(actor, 'scenario_pack_upserted', id, { title: pack.title, isPublished: pack.isPublished });
    return pack;
  }

  setScenarioPackPublishState(packId, isPublished, actor = 'admin') {
    const catalog = readJson(this.scenarioPacksFile, { version: 1, packs: [] });
    const pack = Array.isArray(catalog.packs) ? catalog.packs.find((item) => item.id === packId) : null;
    if (!pack) {
      const error = new Error('Scenario pack not found.');
      error.statusCode = 404;
      throw error;
    }
    if (isPublished) {
      const validation = validateScenarioPack({ ...pack, isPublished: true });
      if (!validation.valid) {
        const error = new Error('Invalid content cannot be published.');
        error.statusCode = 400;
        error.validation = validation;
        throw error;
      }
    }
    pack.isPublished = Boolean(isPublished);
    pack.updatedAt = new Date().toISOString();
    writeJson(this.scenarioPacksFile, catalog);
    this.addAudit(actor, isPublished ? 'scenario_pack_published' : 'scenario_pack_unpublished', packId, {});
    return pack;
  }

  createScenarioPackReview(packId, payload = {}, actor = 'admin') {
    const pack = this.getScenarioPack(packId, { includeUnpublished: true });
    if (!pack) {
      const error = new Error('Scenario pack not found.');
      error.statusCode = 404;
      throw error;
    }
    const items = readJson(this.scenarioPackReviewsFile, []);
    const review = {
      id: crypto.randomUUID(),
      packId,
      status: payload.status || 'pending',
      safetyStatus: payload.safetyStatus || pack.safetyStatus || 'pending',
      notes: payload.notes || '',
      reviewedBy: actor,
      createdAt: new Date().toISOString(),
    };
    items.unshift(review);
    writeJson(this.scenarioPackReviewsFile, items.slice(0, 500));
    this.addAudit(actor, 'scenario_pack_review_created', packId, review);
    return review;
  }

  getScenarioPackReviews() {
    return readJson(this.scenarioPackReviewsFile, []);
  }



  getInterviewQuestionBank(roleId = '') {
    const bank = readJson(this.interviewQuestionBankFile, { version: 1, rubric: {}, questions: [] });
    const safeRoleId = safeString(roleId);
    const questions = Array.isArray(bank.questions) ? bank.questions : [];
    const filtered = safeRoleId ? questions.filter((question) => question && question.roleId === safeRoleId) : questions;
    return {
      version: bank.version || 1,
      rounds: Array.isArray(bank.rounds) ? bank.rounds : ['technical', 'behavioral', 'situation'],
      rubric: safeObject(bank.rubric),
      questions: filtered,
    };
  }

  generateInterviewFeedback(payload = {}) {
    const question = safeObject(payload.question);
    const answer = safeString(payload.answer);
    if (!question.id || !answer) {
      const error = new Error('Question and answer are required for interview feedback.');
      error.statusCode = 400;
      throw error;
    }
    const expectedKeywords = readStringArray(question.expectedKeywords);
    const normalized = answer.toLowerCase();
    const words = normalized.split(/\s+/).filter(Boolean);
    const matchedKeywords = expectedKeywords.filter((keyword) => normalized.includes(keyword.toLowerCase()));
    const missingKeywords = expectedKeywords.filter((keyword) => !matchedKeywords.includes(keyword)).slice(0, 5);
    const hasAny = (items) => items.some((item) => normalized.includes(item));
    const rubricScores = {
      clarity: Math.min(20, (hasAny(['first', 'then', 'because', 'after', 'finally', 'result', 'impact']) ? 12 : 4) + (words.length >= 25 ? 6 : 0)),
      roleKnowledge: Math.min(25, matchedKeywords.length * 4 + (words.length >= 35 ? 7 : 2)),
      evidence: Math.min(20, hasAny(['log', 'metric', 'data', 'evidence', 'document', 'steps', 'test', 'review']) ? 14 : 5),
      communication: Math.min(15, hasAny(['communicate', 'stakeholder', 'client', 'team', 'manager', 'explain', 'align']) ? 15 : 7),
      ethics: Math.min(20, hasAny(['safe', 'risk', 'ethic', 'policy', 'compliance', 'fair', 'patient', 'privacy']) ? 18 : 8),
    };
    const score = Object.values(rubricScores).reduce((sum, value) => sum + value, 0);
    const strengths = [];
    if (rubricScores.clarity >= 14) strengths.push('Clear answer structure');
    if (rubricScores.roleKnowledge >= 16) strengths.push('Good role-specific thinking');
    if (rubricScores.evidence >= 14) strengths.push('Uses evidence or verification');
    if (rubricScores.communication >= 12) strengths.push('Stakeholder-aware communication');
    if (rubricScores.ethics >= 15) strengths.push('Strong safety and ethics awareness');
    if (matchedKeywords.length > 0) strengths.push(`Covered key terms: ${matchedKeywords.slice(0, 3).join(', ')}`);
    const improvementTips = [];
    if (words.length < 35) improvementTips.push('Expand the answer with a concrete example, action, and result.');
    if (missingKeywords.length > 0) improvementTips.push(`Include missing role keywords: ${missingKeywords.join(', ')}.`);
    if (rubricScores.evidence < 12) improvementTips.push('Add proof: logs, test cases, patient notes, site records, metrics, or documented constraints.');
    if (rubricScores.communication < 10) improvementTips.push('Mention who you would inform and how you would align the team/client/stakeholder.');
    if (rubricScores.ethics < 14) improvementTips.push('Call out safety, fairness, policy, privacy, or professional boundaries explicitly.');
    const aiSummary = score >= 80
      ? 'AI feedback: Interview-ready answer with strong professional signals.'
      : score >= 60
        ? 'AI feedback: Good base answer. Add proof, trade-offs, and concise structure.'
        : 'AI feedback: Needs more structure, role-specific process, and safety-aware reasoning.';
    return {
      questionId: question.id,
      answer,
      score,
      rubricScores,
      strengths: strengths.length > 0 ? strengths : ['You attempted the question and can now improve it.'],
      improvementTips: improvementTips.length > 0 ? improvementTips : ['Good attempt. Retry with tighter structure and one measurable result.'],
      matchedKeywords,
      missingKeywords,
      aiSummary,
      retryPrompt: `Retry this answer in 60–90 seconds using STAR format and include: ${missingKeywords.slice(0, 3).join(', ')}.`,
      createdAt: new Date().toISOString(),
    };
  }

  getInterviewReports(userId) {
    const safeUserId = safeString(userId);
    const data = readJson(this.interviewReportsFile, { version: 1, reports: [] });
    const reports = Array.isArray(data.reports) ? data.reports : [];
    return {
      version: data.version || 1,
      reports: safeUserId ? reports.filter((report) => report && report.userId === safeUserId) : reports,
    };
  }

  saveInterviewReport(userId, payload = {}) {
    const safeUserId = safeString(userId || payload.userId, 'local-user');
    const now = new Date().toISOString();
    const data = readJson(this.interviewReportsFile, { version: 1, reports: [] });
    const reports = Array.isArray(data.reports) ? data.reports : [];
    const report = {
      id: safeString(payload.id, crypto.randomUUID()),
      userId: safeUserId,
      roleId: safeString(payload.roleId),
      roleName: safeString(payload.roleName, 'Career Role'),
      totalScore: clampMetric(payload.totalScore),
      readinessLevel: safeString(payload.readinessLevel, 'Needs Practice'),
      feedbackItems: Array.isArray(payload.feedbackItems) ? payload.feedbackItems : [],
      strengths: readStringArray(payload.strengths),
      improvementAreas: readStringArray(payload.improvementAreas),
      nextSteps: readStringArray(payload.nextSteps),
      savedAt: safeString(payload.savedAt, now),
    };
    data.version = 1;
    data.reports = [report, ...reports.filter((item) => item && item.id !== report.id)].slice(0, 500);
    writeJson(this.interviewReportsFile, data);
    this.addAudit(safeUserId, 'interview_report_saved', report.id, { roleId: report.roleId, totalScore: report.totalScore });
    return report;
  }

  getAssessmentCatalog(roleId = '') {
    const catalog = readJson(this.assessmentCatalogFile, { version: 1, certificateTemplate: {}, assessments: [] });
    const safeRoleId = safeString(roleId);
    const assessments = Array.isArray(catalog.assessments) ? catalog.assessments : [];
    const filtered = safeRoleId ? assessments.filter((assessment) => assessment && assessment.roleId === safeRoleId) : assessments;
    return {
      version: catalog.version || 1,
      certificateTemplate: safeObject(catalog.certificateTemplate),
      assessments: filtered,
    };
  }

  getAssessmentForRole(roleId) {
    const catalog = this.getAssessmentCatalog(roleId);
    return catalog.assessments[0] || null;
  }

  getAssessmentSessions() {
    return readJson(this.assessmentSessionsFile, { version: 1, sessions: [] });
  }

  saveAssessmentSessions(data) {
    const normalized = data && typeof data === 'object' && Array.isArray(data.sessions)
      ? data
      : { version: 1, sessions: [] };
    normalized.version = 1;
    writeJson(this.assessmentSessionsFile, normalized);
    return normalized;
  }

  getAssessmentSession(sessionId) {
    const data = this.getAssessmentSessions();
    return data.sessions.find((session) => session.id === sessionId) || null;
  }

  createAssessmentSession(payload = {}) {
    const roleId = safeString(payload.roleId);
    const assessment = this.getAssessmentForRole(roleId);
    if (!assessment) {
      const error = new Error('Role-wise assessment not found.');
      error.statusCode = 404;
      throw error;
    }
    const now = new Date();
    const timeLimitSeconds = Number.isFinite(assessment.timeLimitSeconds) && assessment.timeLimitSeconds > 0
      ? assessment.timeLimitSeconds
      : 900;
    const userId = safeString(payload.userId, 'local-user');
    const session = {
      id: crypto.randomUUID(),
      userId,
      displayName: safeString(payload.displayName, 'Career Chaos Learner'),
      roleId: assessment.roleId,
      roleName: assessment.roleName,
      assessmentId: assessment.id,
      status: 'in_progress',
      timeLimitSeconds,
      startedAt: now.toISOString(),
      expiresAt: new Date(now.getTime() + timeLimitSeconds * 1000).toISOString(),
      answers: [],
      practicalScore: null,
      result: null,
      certificate: null,
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    };
    const data = this.getAssessmentSessions();
    data.sessions = [session, ...data.sessions.filter((item) => item && item.id !== session.id)].slice(0, 500);
    this.saveAssessmentSessions(data);
    this.addAudit(userId, 'assessment_session_started', session.id, { roleId: assessment.roleId, assessmentId: assessment.id });
    return { session, assessment: redactAssessmentAnswers(assessment) };
  }

  submitAssessmentAnswer(sessionId, payload = {}) {
    const data = this.getAssessmentSessions();
    const session = data.sessions.find((item) => item.id === sessionId);
    if (!session) {
      const error = new Error('Assessment session not found.');
      error.statusCode = 404;
      throw error;
    }
    if (session.status !== 'in_progress') {
      const error = new Error('Completed assessment session cannot accept new answers.');
      error.statusCode = 400;
      throw error;
    }
    const assessment = this.getAssessmentForRole(session.roleId);
    if (!assessment) {
      const error = new Error('Assessment content not found for session role.');
      error.statusCode = 404;
      throw error;
    }
    const questionId = safeString(payload.questionId);
    const selectedIndex = Number.isInteger(payload.selectedIndex) ? payload.selectedIndex : -1;
    const question = (Array.isArray(assessment.questions) ? assessment.questions : []).find((item) => item.id === questionId);
    if (!question) {
      const error = new Error('Assessment question not found.');
      error.statusCode = 404;
      throw error;
    }
    if (!Array.isArray(question.options) || selectedIndex < 0 || selectedIndex >= question.options.length) {
      const error = new Error('Selected answer is invalid.');
      error.statusCode = 400;
      throw error;
    }
    const existing = Array.isArray(session.answers) ? session.answers.filter((item) => item.questionId !== questionId) : [];
    const answer = {
      questionId,
      selectedIndex,
      isCorrect: selectedIndex === question.correctIndex,
      earnedPoints: selectedIndex === question.correctIndex ? numberOrZero(question.points) : 0,
      maxPoints: numberOrZero(question.points),
      roundType: safeString(question.roundType, 'technical'),
      skillId: safeString(question.skillId),
      answeredAt: new Date().toISOString(),
    };
    session.answers = [...existing, answer];
    session.updatedAt = answer.answeredAt;
    this.saveAssessmentSessions(data);
    this.addAudit(session.userId, 'assessment_answer_submitted', session.id, { questionId, isCorrect: answer.isCorrect });
    return { session, answer, assessment: redactAssessmentAnswers(assessment) };
  }

  completeAssessmentSession(sessionId, payload = {}) {
    const data = this.getAssessmentSessions();
    const session = data.sessions.find((item) => item.id === sessionId);
    if (!session) {
      const error = new Error('Assessment session not found.');
      error.statusCode = 404;
      throw error;
    }
    const assessment = this.getAssessmentForRole(session.roleId);
    if (!assessment) {
      const error = new Error('Assessment content not found for session role.');
      error.statusCode = 404;
      throw error;
    }
    if (session.status === 'completed') {
      return { session, assessment: redactAssessmentAnswers(assessment), certificate: session.certificate || null };
    }
    if (Array.isArray(payload.answers)) {
      for (const item of payload.answers) {
        const question = (assessment.questions || []).find((questionItem) => questionItem.id === item.questionId);
        if (question && Number.isInteger(item.selectedIndex)) {
          const existing = Array.isArray(session.answers) ? session.answers.filter((answer) => answer.questionId !== question.id) : [];
          existing.push({
            questionId: question.id,
            selectedIndex: item.selectedIndex,
            isCorrect: item.selectedIndex === question.correctIndex,
            earnedPoints: item.selectedIndex === question.correctIndex ? numberOrZero(question.points) : 0,
            maxPoints: numberOrZero(question.points),
            roundType: safeString(question.roundType, 'technical'),
            skillId: safeString(question.skillId),
            answeredAt: new Date().toISOString(),
          });
          session.answers = existing;
        }
      }
    }
    if (Number.isFinite(payload.practicalScore)) {
      session.practicalScore = clampMetric(payload.practicalScore);
    } else if (!Number.isFinite(session.practicalScore)) {
      session.practicalScore = 0;
    }
    const result = this.calculateAssessmentResult(assessment, session);
    session.status = 'completed';
    session.result = result;
    session.updatedAt = new Date().toISOString();
    let certificate = null;
    if (result.passed) {
      certificate = this.createCertificateRecord({
        userId: session.userId,
        displayName: safeString(payload.displayName, session.displayName),
        roleId: assessment.roleId,
        roleName: assessment.roleName,
        assessmentId: assessment.id,
        assessmentTitle: assessment.title,
        sessionId: session.id,
        totalScore: result.totalScore,
        skillIds: readStringArray(assessment.skillIds),
        templateId: safeString(assessment.certificateTemplateId, 'career_chaos_certificate_v1'),
      });
      session.certificate = certificate;
    }
    this.saveAssessmentSessions(data);
    this.addAudit(session.userId, 'assessment_session_completed', session.id, { roleId: assessment.roleId, passed: result.passed, totalScore: result.totalScore });
    return { session, assessment: redactAssessmentAnswers(assessment), certificate };
  }

  calculateAssessmentResult(assessment, session) {
    const questions = Array.isArray(assessment.questions) ? assessment.questions : [];
    const answers = Array.isArray(session.answers) ? session.answers : [];
    const answerMap = new Map(answers.map((answer) => [answer.questionId, answer]));
    let earned = 0;
    let possible = 0;
    const roundBuckets = {};
    for (const question of questions) {
      const roundType = safeString(question.roundType, 'technical');
      if (!roundBuckets[roundType]) roundBuckets[roundType] = { earned: 0, possible: 0 };
      const maxPoints = numberOrZero(question.points);
      const answer = answerMap.get(question.id);
      possible += maxPoints;
      roundBuckets[roundType].possible += maxPoints;
      if (answer && answer.isCorrect === true) {
        earned += maxPoints;
        roundBuckets[roundType].earned += maxPoints;
      }
    }
    const questionScore = possible > 0 ? Math.round((earned / possible) * 100) : 0;
    const practicalScore = clampMetric(session.practicalScore);
    const totalScore = clampMetric((questionScore * 0.8) + (practicalScore * 0.2));
    const roundScores = {};
    for (const [key, bucket] of Object.entries(roundBuckets)) {
      roundScores[key] = bucket.possible > 0 ? Math.round((bucket.earned / bucket.possible) * 100) : 0;
    }
    roundScores.practicalMiniGame = practicalScore;
    const now = new Date();
    const expiresAt = new Date(session.expiresAt || 0);
    const timedOut = Boolean(session.expiresAt) && now.getTime() > expiresAt.getTime();
    const answeredAll = questions.every((question) => answerMap.has(question.id));
    const minimumPassingScore = numberOrZero(assessment.minimumPassingScore || 70);
    const minimumPracticalScore = numberOrZero(assessment.minimumPracticalScore || 60);
    const minimumEthicsScore = numberOrZero(assessment.minimumEthicsScore || 60);
    const passed = answeredAll
      && !timedOut
      && totalScore >= minimumPassingScore
      && practicalScore >= minimumPracticalScore
      && (roundScores.ethics || 0) >= minimumEthicsScore;
    const improvementTips = [];
    if (!answeredAll) improvementTips.push('Answer every role-wise assessment question before retrying certification.');
    if (timedOut) improvementTips.push('Complete the timed assessment before the countdown expires.');
    if (totalScore < minimumPassingScore) improvementTips.push(`Raise total score to at least ${minimumPassingScore}%. Review weak skill nodes and replay related chapters.`);
    if (practicalScore < minimumPracticalScore) improvementTips.push(`Improve the practical mini-game score to at least ${minimumPracticalScore}%.`);
    if ((roundScores.ethics || 0) < minimumEthicsScore) improvementTips.push('Improve ethics and safety decisions before a certificate can be issued.');
    if (improvementTips.length === 0) improvementTips.push('Passed. Save and share the certificate verification ID.');
    return {
      totalScore,
      questionScore,
      practicalScore,
      roundScores,
      answeredQuestionCount: answers.length,
      totalQuestionCount: questions.length,
      minimumPassingScore,
      minimumPracticalScore,
      minimumEthicsScore,
      timedOut,
      passed,
      resultLabel: passed ? 'Passed' : 'Failed',
      improvementTips,
      completedAt: new Date().toISOString(),
    };
  }

  getCertificateRecords(userId = '') {
    const safeUserId = safeString(userId);
    const data = readJson(this.certificateRecordsFile, { version: 1, certificates: [] });
    const certificates = Array.isArray(data.certificates) ? data.certificates : [];
    return {
      version: data.version || 1,
      certificates: safeUserId ? certificates.filter((certificate) => certificate && certificate.userId === safeUserId) : certificates,
    };
  }

  getCertificateByVerificationId(verificationId) {
    const id = safeString(verificationId).toUpperCase();
    if (!id) return null;
    const data = this.getCertificateRecords();
    return data.certificates.find((certificate) => String(certificate.verificationId || '').toUpperCase() === id) || null;
  }

  createCertificateRecord(payload = {}) {
    const data = readJson(this.certificateRecordsFile, { version: 1, certificates: [] });
    const certificates = Array.isArray(data.certificates) ? data.certificates : [];
    let verificationId = certificateVerificationId(payload.roleId);
    while (certificates.some((item) => item && item.verificationId === verificationId)) {
      verificationId = certificateVerificationId(payload.roleId);
    }
    const issuedAt = new Date().toISOString();
    const certificate = {
      id: crypto.randomUUID(),
      verificationId,
      userId: safeString(payload.userId, 'local-user'),
      recipientName: safeString(payload.displayName, 'Career Chaos Learner'),
      roleId: safeString(payload.roleId),
      roleName: safeString(payload.roleName, 'Career Role'),
      assessmentId: safeString(payload.assessmentId),
      assessmentTitle: safeString(payload.assessmentTitle, 'Final Certification Assessment'),
      assessmentSessionId: safeString(payload.sessionId),
      totalScore: clampMetric(payload.totalScore),
      skillIds: readStringArray(payload.skillIds),
      templateId: safeString(payload.templateId, 'career_chaos_certificate_v1'),
      issuer: 'Career Chaos Academy',
      status: 'valid',
      issuedAt,
      pdfPath: `/api/certificates/${verificationId}/pdf`,
      verificationPath: `/api/certificates/${verificationId}`,
    };
    data.version = 1;
    data.certificates = [certificate, ...certificates.filter((item) => item && item.verificationId !== verificationId)].slice(0, 1000);
    writeJson(this.certificateRecordsFile, data);
    this.addAudit(certificate.userId, 'certificate_issued', certificate.verificationId, { roleId: certificate.roleId, totalScore: certificate.totalScore });
    return certificate;
  }

  renderCertificatePdf(verificationId) {
    const certificate = this.getCertificateByVerificationId(verificationId);
    if (!certificate) return null;
    return buildCertificatePdf(certificate);
  }

  getTeamSessions() {
    return readJson(this.teamSessionsFile, { version: 1, sessions: [] });
  }

  saveTeamSessions(data) {
    const normalized = data && typeof data === 'object' && Array.isArray(data.sessions)
      ? data
      : { version: 1, sessions: [] };
    writeJson(this.teamSessionsFile, normalized);
    return normalized;
  }

  getTeamSession(sessionId) {
    const data = this.getTeamSessions();
    return data.sessions.find((session) => session.id === sessionId) || null;
  }

  getTeamSessionByCode(roomCode) {
    const code = safeString(roomCode).toUpperCase();
    if (!code) return null;
    const data = this.getTeamSessions();
    return data.sessions.find((session) => String(session.roomCode || '').toUpperCase() === code) || null;
  }

  buildDefaultTeamScenario({ roleId, chapterId } = {}) {
    let found = null;
    if (chapterId) {
      found = this.findChapter(chapterId);
    }
    if (!found && roleId) {
      const roleScenario = this.getRoleScenario(roleId);
      if (roleScenario && roleScenario.chapters.length > 0) {
        found = { roleScenario, chapter: roleScenario.chapters[0] };
      }
    }
    if (!found) {
      const firstRole = this.loadCatalog()[0];
      if (firstRole && firstRole.chapters.length > 0) {
        found = { roleScenario: firstRole, chapter: firstRole.chapters[0] };
      }
    }
    if (!found) {
      const error = new Error('No published scenario is available for team simulation.');
      error.statusCode = 400;
      throw error;
    }
    const chapter = found.chapter;
    return {
      roleId: found.roleScenario.role.id,
      chapterId: chapter.id,
      title: chapter.title,
      story: chapter.story || chapter.scenario || '',
      task: chapter.task || 'Choose the best team decision.',
      choices: Array.isArray(chapter.choices)
        ? chapter.choices.map((choice, index) => ({ index, text: choice.text || `Choice ${index + 1}` }))
        : [],
    };
  }

  buildTeamRolePool() {
    return this.getRoles().map((role) => ({
      id: role.id,
      name: role.name,
      iconKey: role.iconKey || 'work',
      description: role.description || '',
    }));
  }

  createTeamSession(payload = {}) {
    const data = this.getTeamSessions();
    let roomCode = randomRoomCode();
    while (data.sessions.some((session) => session.roomCode === roomCode)) {
      roomCode = randomRoomCode();
    }

    const scenario = this.buildDefaultTeamScenario({ roleId: payload.roleId, chapterId: payload.chapterId });
    const hostUserId = safeString(payload.hostUserId || payload.userId, `host_${Date.now()}`);
    const hostDisplayName = safeString(payload.hostDisplayName || payload.displayName, 'Host Player');
    const now = new Date().toISOString();
    const maxRounds = Number.isInteger(payload.maxRounds) && payload.maxRounds > 0 ? Math.min(payload.maxRounds, 5) : 1;
    const session = {
      id: crypto.randomUUID(),
      roomCode,
      joinLink: `/team/join/${roomCode}`,
      title: safeString(payload.title, 'Team Simulation Room'),
      mode: 'turn_based_team',
      status: 'lobby',
      hostUserId,
      scenario,
      rolePool: this.buildTeamRolePool(),
      participants: [{
        userId: hostUserId,
        displayName: hostDisplayName,
        selectedRoleId: '',
        isHost: true,
        joinedAt: now,
        lastActiveAt: now,
      }],
      selectedRoles: {},
      turn: {
        currentParticipantId: '',
        currentTurnIndex: 0,
        roundIndex: 0,
        maxRounds,
        status: 'waiting_for_roles',
        startedAt: null,
      },
      decisions: [],
      teamFlags: [],
      roleImpacts: {},
      teamScore: emptyTeamScore(),
      debrief: null,
      createdAt: now,
      updatedAt: now,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString(),
    };
    data.sessions.unshift(session);
    data.sessions = data.sessions.slice(0, 250);
    this.saveTeamSessions(data);
    this.addAudit(hostUserId, 'team_session_created', session.id, { roomCode, chapterId: scenario.chapterId });
    return session;
  }

  joinTeamSession(roomCode, payload = {}) {
    const data = this.getTeamSessions();
    const code = safeString(roomCode || payload.roomCode).toUpperCase();
    const session = data.sessions.find((item) => String(item.roomCode || '').toUpperCase() === code);
    if (!session) {
      const error = new Error('Team room not found.');
      error.statusCode = 404;
      throw error;
    }
    if (session.status === 'completed') {
      const error = new Error('Completed team room cannot be joined.');
      error.statusCode = 400;
      throw error;
    }
    const userId = safeString(payload.userId, `player_${Date.now()}`);
    const displayName = safeString(payload.displayName, `Player ${session.participants.length + 1}`);
    const now = new Date().toISOString();
    let participant = session.participants.find((item) => item.userId === userId);
    if (!participant) {
      participant = {
        userId,
        displayName,
        selectedRoleId: '',
        isHost: false,
        joinedAt: now,
        lastActiveAt: now,
      };
      session.participants.push(participant);
    } else {
      participant.displayName = displayName;
      participant.lastActiveAt = now;
    }
    session.updatedAt = now;
    this.saveTeamSessions(data);
    this.addAudit(userId, 'team_session_joined', session.id, { roomCode: code });
    return session;
  }

  selectTeamRole(sessionId, payload = {}) {
    const data = this.getTeamSessions();
    const session = data.sessions.find((item) => item.id === sessionId);
    if (!session) {
      const error = new Error('Team session not found.');
      error.statusCode = 404;
      throw error;
    }
    if (session.status !== 'lobby') {
      const error = new Error('Roles can only be changed before the team scenario starts.');
      error.statusCode = 400;
      throw error;
    }
    const userId = safeString(payload.userId);
    const roleId = safeString(payload.roleId);
    const participant = session.participants.find((item) => item.userId === userId);
    if (!participant) {
      const error = new Error('Participant must join the room before selecting a role.');
      error.statusCode = 400;
      throw error;
    }
    const roleExists = Array.isArray(session.rolePool) && session.rolePool.some((role) => role.id === roleId);
    if (!roleExists) {
      const error = new Error('Selected role is not available for this room.');
      error.statusCode = 400;
      throw error;
    }
    const taken = session.participants.find((item) => item.userId !== userId && item.selectedRoleId === roleId);
    if (taken) {
      const error = new Error('This role is already selected by another teammate.');
      error.statusCode = 409;
      throw error;
    }
    participant.selectedRoleId = roleId;
    participant.lastActiveAt = new Date().toISOString();
    session.selectedRoles[userId] = roleId;
    session.turn.status = 'ready_to_start';
    session.updatedAt = participant.lastActiveAt;
    this.saveTeamSessions(data);
    this.addAudit(userId, 'team_role_selected', sessionId, { roleId });
    return session;
  }

  startTeamSession(sessionId, payload = {}) {
    const data = this.getTeamSessions();
    const session = data.sessions.find((item) => item.id === sessionId);
    if (!session) {
      const error = new Error('Team session not found.');
      error.statusCode = 404;
      throw error;
    }
    if (session.status === 'completed') return session;
    const selectedParticipants = this.teamTurnParticipants(session);
    if (selectedParticipants.length < 1) {
      const error = new Error('At least one participant must select a role before starting.');
      error.statusCode = 400;
      throw error;
    }
    session.status = 'in_progress';
    session.turn.status = 'active';
    session.turn.currentTurnIndex = Math.min(session.turn.currentTurnIndex || 0, selectedParticipants.length - 1);
    session.turn.currentParticipantId = selectedParticipants[session.turn.currentTurnIndex].userId;
    session.turn.startedAt = new Date().toISOString();
    session.updatedAt = session.turn.startedAt;
    this.saveTeamSessions(data);
    this.addAudit(safeString(payload.userId, session.hostUserId), 'team_session_started', sessionId, {});
    return session;
  }

  teamTurnParticipants(session) {
    return (Array.isArray(session.participants) ? session.participants : [])
      .filter((item) => safeString(item.selectedRoleId))
      .sort((a, b) => String(a.joinedAt || '').localeCompare(String(b.joinedAt || '')));
  }

  submitTeamDecision(sessionId, payload = {}) {
    const data = this.getTeamSessions();
    const session = data.sessions.find((item) => item.id === sessionId);
    if (!session) {
      const error = new Error('Team session not found.');
      error.statusCode = 404;
      throw error;
    }
    if (session.status === 'lobby') {
      this.startTeamSession(sessionId, { userId: payload.userId });
      return this.submitTeamDecision(sessionId, payload);
    }
    if (session.status === 'completed') return session;

    const participants = this.teamTurnParticipants(session);
    if (participants.length < 1) {
      const error = new Error('No participant has selected a role.');
      error.statusCode = 400;
      throw error;
    }
    const userId = safeString(payload.userId);
    const currentParticipant = participants[session.turn.currentTurnIndex % participants.length];
    if (currentParticipant.userId !== userId) {
      const error = new Error('It is not this participant’s turn.');
      error.statusCode = 409;
      throw error;
    }

    const found = this.findChapter(session.scenario.chapterId);
    if (!found) {
      const error = new Error('Team scenario chapter was not found.');
      error.statusCode = 404;
      throw error;
    }
    const choices = Array.isArray(found.chapter.choices) ? found.chapter.choices : [];
    const choiceIndex = Number.isInteger(payload.choiceIndex) ? payload.choiceIndex : -1;
    const choice = choices[choiceIndex];
    if (!choice) {
      const error = new Error('Invalid team decision choice.');
      error.statusCode = 400;
      throw error;
    }

    const now = new Date();
    const startedAt = session.turn.startedAt ? new Date(session.turn.startedAt) : now;
    const elapsedSeconds = Math.max(0, Math.round((now.getTime() - startedAt.getTime()) / 1000));
    const outcome = safeObject(choice.outcome);
    const scoreImpact = scoreImpactFromChoice(choice);
    const affectedRoles = [
      ...readStringArray(outcome.affectedRoles),
      ...readStringArray(outcome.affectsRoles),
      ...readStringArray(outcome.teamAffectedRoles),
    ];
    const otherSelectedRoles = participants
      .filter((item) => item.userId !== userId)
      .map((item) => item.selectedRoleId)
      .filter(Boolean);
    const finalAffectedRoles = Array.from(new Set(affectedRoles.length > 0 ? affectedRoles : otherSelectedRoles));
    const setFlags = readStringArray(outcome.setFlags);
    const clearFlags = readStringArray(outcome.clearFlags);
    const roleId = currentParticipant.selectedRoleId;
    const decision = {
      id: crypto.randomUUID(),
      roundIndex: session.turn.roundIndex || 0,
      turnIndex: session.turn.currentTurnIndex || 0,
      userId,
      displayName: currentParticipant.displayName || 'Player',
      roleId,
      choiceIndex,
      choiceText: choice.text || `Choice ${choiceIndex + 1}`,
      outcomeTitle: safeString(outcome.title, 'Team consequence'),
      outcomeSummary: safeString(outcome.description || outcome.consequenceSummary, 'Your decision changed the team state.'),
      scoreImpact,
      affectedRoles: finalAffectedRoles,
      setFlags,
      clearFlags,
      createdAt: now.toISOString(),
      elapsedSeconds,
    };
    session.decisions.push(decision);
    const flags = new Set(Array.isArray(session.teamFlags) ? session.teamFlags : []);
    for (const flag of setFlags) flags.add(flag);
    for (const flag of clearFlags) flags.delete(flag);
    session.teamFlags = Array.from(flags).sort();

    if (!session.roleImpacts || typeof session.roleImpacts !== 'object' || Array.isArray(session.roleImpacts)) {
      session.roleImpacts = {};
    }
    for (const affectedRole of finalAffectedRoles) {
      if (!Array.isArray(session.roleImpacts[affectedRole])) session.roleImpacts[affectedRole] = [];
      session.roleImpacts[affectedRole].push(`${currentParticipant.displayName || roleId} chose: ${decision.choiceText}`);
    }

    session.teamScore = this.calculateTeamScore(session);
    const nextTurnIndex = (session.turn.currentTurnIndex || 0) + 1;
    if (nextTurnIndex >= participants.length) {
      session.turn.currentTurnIndex = 0;
      session.turn.roundIndex = (session.turn.roundIndex || 0) + 1;
    } else {
      session.turn.currentTurnIndex = nextTurnIndex;
    }
    if ((session.turn.roundIndex || 0) >= (session.turn.maxRounds || 1)) {
      session.status = 'completed';
      session.turn.status = 'completed';
      session.turn.currentParticipantId = '';
      session.debrief = this.buildTeamDebrief(session);
    } else {
      const refreshedParticipants = this.teamTurnParticipants(session);
      session.turn.status = 'active';
      session.turn.currentParticipantId = refreshedParticipants[session.turn.currentTurnIndex % refreshedParticipants.length].userId;
      session.turn.startedAt = now.toISOString();
    }
    session.updatedAt = now.toISOString();
    this.saveTeamSessions(data);
    this.addAudit(userId, 'team_decision_submitted', sessionId, { choiceIndex, roleId, affectedRoles: finalAffectedRoles });
    return session;
  }

  calculateTeamScore(session) {
    const decisions = Array.isArray(session.decisions) ? session.decisions : [];
    const participants = this.teamTurnParticipants(session);
    const selectedRoles = new Set(participants.map((item) => item.selectedRoleId).filter(Boolean));
    let communication = 0;
    let accuracy = 0;
    let ethics = 0;
    let speed = 0;
    let crossRoleMoments = 0;
    for (const decision of decisions) {
      const breakdown = teamMetricBreakdown(safeObject(decision.scoreImpact), decision.elapsedSeconds);
      communication += breakdown.communication;
      accuracy += breakdown.accuracy;
      ethics += breakdown.ethics;
      speed += breakdown.speed;
      if (Array.isArray(decision.affectedRoles) && decision.affectedRoles.length > 0) crossRoleMoments += 1;
    }
    const decisionCount = Math.max(1, decisions.length);
    const collaboration = (selectedRoles.size * 18) + (decisions.length * 7) + (crossRoleMoments * 10);
    return {
      collaboration: clampMetric(collaboration),
      communication: clampMetric(communication / decisionCount + (participants.length > 1 ? 8 : 0)),
      speed: clampMetric(speed / decisionCount),
      accuracy: clampMetric(accuracy / decisionCount),
      ethics: clampMetric(ethics / decisionCount),
    };
  }

  buildTeamDebrief(session) {
    const score = session.teamScore || emptyTeamScore();
    const total = Math.round((score.collaboration + score.communication + score.speed + score.accuracy + score.ethics) / 5);
    const decisions = Array.isArray(session.decisions) ? session.decisions : [];
    const keyMoments = decisions.map((decision) => ({
      roleId: decision.roleId,
      displayName: decision.displayName,
      choiceText: decision.choiceText,
      affectedRoles: decision.affectedRoles || [],
      outcomeSummary: decision.outcomeSummary,
    }));
    const recommendations = [];
    if (score.collaboration < 60) recommendations.push('Invite multiple roles to contribute before the scenario ends.');
    if (score.communication < 60) recommendations.push('Explain trade-offs clearly before choosing a high-impact option.');
    if (score.accuracy < 60) recommendations.push('Use evidence, constraints, and role expertise before committing.');
    if (score.ethics < 60) recommendations.push('Avoid shortcuts that improve speed but create safety, privacy, or fairness risk.');
    if (recommendations.length === 0) recommendations.push('Strong team run. Increase difficulty or add one more role next time.');
    return {
      appearedAt: new Date().toISOString(),
      total,
      summary: total >= 75
        ? 'The team handled the chaos with balanced collaboration and professional decision-making.'
        : 'The team completed the simulation, but the debrief shows clear improvement areas.',
      scoreBreakdown: score,
      keyMoments,
      roleImpacts: session.roleImpacts || {},
      teamFlags: session.teamFlags || [],
      recommendations,
    };
  }


  getVoiceProfiles() {
    return readJson(this.voiceProfilesFile, {
      version: 1,
      subtitleFirst: true,
      supportedLanguages: ['english', 'hinglish', 'hindi'],
      textToSpeech: { provider: 'placeholder', status: 'future_ready' },
      speechToText: { provider: 'placeholder', status: 'future_ready' },
      profiles: [],
    });
  }

  getVoiceConversationData() {
    return readJson(this.voiceConversationFile, { version: 1, settingsByUser: {}, conversations: [] });
  }

  saveVoiceConversationData(data) {
    const normalized = data && typeof data === 'object'
      ? {
          version: 1,
          settingsByUser: safeObject(data.settingsByUser),
          conversations: Array.isArray(data.conversations) ? data.conversations : [],
        }
      : { version: 1, settingsByUser: {}, conversations: [] };
    writeJson(this.voiceConversationFile, normalized);
    return normalized;
  }

  defaultVoiceSettings() {
    return normalizeVoiceSettings({});
  }

  getVoiceSettings(userId = 'local-user') {
    const safeUserId = safeString(userId, 'local-user');
    const data = this.getVoiceConversationData();
    const saved = safeObject(data.settingsByUser[safeUserId]);
    return {
      userId: safeUserId,
      settings: normalizeVoiceSettings(saved),
      supportedLanguages: ['english', 'hinglish', 'hindi'],
      subtitlePolicy: 'subtitles_always_visible_even_when_voice_is_disabled',
    };
  }

  saveVoiceSettings(userId = 'local-user', payload = {}) {
    const safeUserId = safeString(userId, 'local-user');
    const data = this.getVoiceConversationData();
    const settings = normalizeVoiceSettings({
      ...safeObject(payload.settings),
      ...payload,
      updatedAt: new Date().toISOString(),
    });
    data.settingsByUser[safeUserId] = settings;
    this.saveVoiceConversationData(data);
    this.addAudit(safeUserId, 'voice_settings_saved', safeUserId, { languageMode: settings.languageMode, voiceEnabled: settings.voiceEnabled });
    return {
      userId: safeUserId,
      settings,
      supportedLanguages: ['english', 'hinglish', 'hindi'],
      subtitlePolicy: 'subtitles_always_visible_even_when_voice_is_disabled',
    };
  }

  synthesizeVoicePlaceholder(payload = {}) {
    const text = safeString(payload.text || payload.subtitle || payload.message);
    const profileId = safeString(payload.voiceProfileId || payload.profileId, 'senior_dev_mentor_voice');
    const languageMode = normalizeLanguageMode(payload.languageMode);
    return {
      status: 'placeholder',
      provider: 'text_to_speech_placeholder',
      voiceProfileId: profileId,
      languageMode,
      audioUrl: null,
      subtitles: text ? [text] : [],
      fallbackToText: true,
      message: 'TTS provider is not connected yet. Subtitles are the source of truth and text fallback is active.',
      createdAt: new Date().toISOString(),
    };
  }

  transcribeSpeechPlaceholder(payload = {}) {
    const transcript = safeString(payload.fallbackText || payload.transcript || payload.text);
    return {
      status: 'placeholder',
      provider: 'speech_to_text_placeholder',
      transcript,
      confidence: transcript ? 0.5 : 0,
      fallbackToText: true,
      message: 'STT provider is not connected yet. Text input fallback is active.',
      createdAt: new Date().toISOString(),
    };
  }

  getCharacterConversations(userId = 'local-user') {
    const safeUserId = safeString(userId, 'local-user');
    const data = this.getVoiceConversationData();
    return {
      version: data.version || 1,
      conversations: data.conversations.filter((item) => item && item.userId === safeUserId),
    };
  }

  generateCharacterChatReply(payload = {}) {
    const userId = safeString(payload.userId, 'local-user');
    const characterId = safeString(payload.characterId, 'senior_dev_mentor');
    const userMessage = safeString(payload.message || payload.inputText || payload.answer);
    if (!userMessage) {
      const error = new Error('Message is required for AI character chat.');
      error.statusCode = 400;
      throw error;
    }
    const settings = normalizeVoiceSettings(payload.voiceSettings || this.getVoiceSettings(userId).settings);
    const languageMode = normalizeLanguageMode(payload.languageMode || settings.languageMode);
    const profiles = this.getVoiceProfiles();
    const profile = (profiles.profiles || []).find((item) => item.characterId === characterId || item.id === characterId) || (profiles.profiles || [])[0] || {};
    const characters = this.getCharacters();
    const character = (characters.characters || []).find((item) => item.id === characterId) || {};
    const characterName = safeString(profile.displayName || character.displayName, 'Career Chaos Character');
    const scenarioContext = safeObject(payload.scenarioContext);
    const scenarioId = safeString(scenarioContext.scenarioId || scenarioContext.chapterId || payload.scenarioId, 'prototype_scenario');
    const scenarioTitle = safeString(scenarioContext.scenarioTitle || scenarioContext.title || payload.scenarioTitle, 'Career Chaos practice scenario');
    const roleId = safeString(scenarioContext.roleId || payload.roleId, 'developer');
    const promptSafety = payload.promptSafety || inspectPromptAbuse(userMessage);
    const blocked = containsUnsafeConversationAdvice(userMessage) || promptSafety.blocked === true;
    const outOfBoundary = isOutOfScenarioMemoryRequest(userMessage);
    const replyText = blocked
      ? localizedBlockedReply(languageMode)
      : localizedBoundaryReply({ languageMode, characterName, scenarioTitle, userMessage });
    const turn = {
      id: crypto.randomUUID(),
      userId,
      characterId,
      characterName,
      roleId,
      scenarioId,
      scenarioTitle,
      languageMode,
      inputText: sanitizeForAudit({ message: userMessage }).message,
      replyText,
      subtitles: [replyText],
      voice: {
        enabled: settings.voiceEnabled === true,
        provider: 'text_to_speech_placeholder',
        audioUrl: null,
        fallbackToText: true,
      },
      safety: {
        status: blocked ? 'blocked' : 'safe',
        blocked,
        reason: blocked ? 'unsafe_advice_or_prompt_abuse_filter' : outOfBoundary ? 'scenario_memory_boundary' : 'scenario_context_ok',
        promptSafety,
      },
      memoryBoundary: {
        scenarioBound: true,
        noPersistentPersonalMemory: true,
        allowedContext: ['roleId', 'scenarioId', 'scenarioTitle', 'currentUserMessage'],
        notice: 'Character memory is limited to the active scenario turn. Personal memory is not stored by this prototype.',
      },
      subtitlePolicy: 'subtitles_always_visible',
      createdAt: new Date().toISOString(),
    };
    const data = this.getVoiceConversationData();
    data.conversations = [turn, ...data.conversations.filter((item) => item && item.id !== turn.id)].slice(0, 1000);
    this.saveVoiceConversationData(data);
    this.addAudit(userId, blocked ? 'character_chat_blocked' : 'character_chat_replied', turn.id, { characterId, scenarioId, languageMode });
    return {
      turn,
      profile,
      languageLabel: languageLabel(languageMode),
      fallbackToText: true,
      subtitlesAlwaysOn: true,
    };
  }


  getOrganizationData() {
    return readJson(this.organizationsFile, { version: 1, organizations: [], batches: [], assignments: [], progress: [] });
  }

  saveOrganizationData(data) {
    const normalized = data && typeof data === 'object'
      ? {
          version: 1,
          organizations: Array.isArray(data.organizations) ? data.organizations : [],
          batches: Array.isArray(data.batches) ? data.batches : [],
          assignments: Array.isArray(data.assignments) ? data.assignments : [],
          progress: Array.isArray(data.progress) ? data.progress : [],
        }
      : { version: 1, organizations: [], batches: [], assignments: [], progress: [] };
    writeJson(this.organizationsFile, normalized);
    return normalized;
  }

  getOrganizations() {
    const data = this.getOrganizationData();
    return {
      version: data.version || 1,
      organizations: data.organizations.map((organization) => this.enrichOrganization(organization, data)),
    };
  }

  enrichOrganization(organization, data = this.getOrganizationData()) {
    const orgId = safeString(organization.id);
    return {
      ...organization,
      batches: data.batches.filter((batch) => batch.organizationId === orgId),
      assignments: data.assignments.filter((assignment) => assignment.organizationId === orgId),
    };
  }

  getOrganization(organizationId) {
    const orgId = safeString(organizationId);
    const data = this.getOrganizationData();
    const organization = data.organizations.find((item) => item && item.id === orgId);
    return organization ? this.enrichOrganization(organization, data) : null;
  }

  createOrganization(payload = {}) {
    const role = normalizeRole(payload.actorRole || payload.role, 'org_admin');
    if (!['platform_admin', 'org_admin', 'trainer', 'individual'].includes(role)) {
      requireOrgRole({ actorRole: role }, ['platform_admin', 'org_admin']);
    }
    const data = this.getOrganizationData();
    const now = new Date().toISOString();
    const name = safeString(payload.name, 'Career Chaos Training Organization');
    const id = safeString(payload.id, `org_${slugify(name)}_${crypto.randomBytes(3).toString('hex')}`);
    if (data.organizations.some((organization) => organization.id === id)) {
      const error = new Error('Organization ID already exists.');
      error.statusCode = 409;
      throw error;
    }
    const actorUserId = safeString(payload.actorUserId || payload.createdByUserId, 'org-admin');
    const organization = {
      id,
      name,
      type: safeString(payload.type, 'college'),
      industry: safeString(payload.industry, 'education'),
      status: 'active',
      adminUserIds: uniqueStrings([actorUserId, ...(Array.isArray(payload.adminUserIds) ? payload.adminUserIds : [])]),
      trainerUserIds: uniqueStrings(payload.trainerUserIds || []),
      traineeUserIds: uniqueStrings(payload.traineeUserIds || []),
      customScenarioPackIds: uniqueStrings(payload.customScenarioPackIds || payload.scenarioPackIds || []),
      rbac: {
        roles: ['org_admin', 'trainer', 'trainee', 'individual'],
        permissions: {
          org_admin: ['manage_batches', 'assign_training', 'view_dashboard', 'export_reports', 'manage_custom_packs'],
          trainer: ['create_batches', 'assign_training', 'view_dashboard', 'export_reports'],
          trainee: ['complete_assigned_training'],
          individual: ['solo_mode_only'],
        },
      },
      createdByUserId: actorUserId,
      createdAt: now,
      updatedAt: now,
    };
    data.organizations.unshift(organization);
    this.saveOrganizationData(data);
    this.addAudit(actorUserId, 'organization_created', organization.id, { name: organization.name, type: organization.type });
    return { organization: this.enrichOrganization(organization, data), rbac: organization.rbac };
  }

  createBatch(organizationId, payload = {}) {
    requireOrgRole(payload, ['platform_admin', 'org_admin', 'trainer']);
    const data = this.getOrganizationData();
    const organization = data.organizations.find((item) => item && item.id === organizationId);
    if (!organization) {
      const error = new Error('Organization not found.');
      error.statusCode = 404;
      throw error;
    }
    const now = new Date().toISOString();
    const title = safeString(payload.title, 'Career Chaos Training Batch');
    const batch = {
      id: safeString(payload.id, `batch_${slugify(title)}_${crypto.randomBytes(3).toString('hex')}`),
      organizationId,
      title,
      roleFocus: safeString(payload.roleFocus || payload.roleId, 'all_roles'),
      status: 'active',
      trainerUserIds: uniqueStrings(payload.trainerUserIds || [payload.actorUserId || 'trainer']),
      traineeUserIds: uniqueStrings(payload.traineeUserIds || []),
      startsAt: normalizeDueDate(payload.startsAt || now, 0),
      dueDate: normalizeDueDate(payload.dueDate, 14),
      createdAt: now,
      updatedAt: now,
    };
    data.batches.unshift(batch);
    organization.trainerUserIds = uniqueStrings([...(organization.trainerUserIds || []), ...batch.trainerUserIds]);
    organization.traineeUserIds = uniqueStrings([...(organization.traineeUserIds || []), ...batch.traineeUserIds]);
    organization.updatedAt = now;
    this.saveOrganizationData(data);
    this.addAudit(safeString(payload.actorUserId, 'trainer'), 'organization_batch_created', batch.id, { organizationId, traineeCount: batch.traineeUserIds.length });
    return { batch, organization: this.enrichOrganization(organization, data) };
  }

  getBatches(organizationId) {
    const data = this.getOrganizationData();
    return { version: 1, batches: data.batches.filter((batch) => batch.organizationId === organizationId) };
  }

  createAssignment(organizationId, payload = {}) {
    requireOrgRole(payload, ['platform_admin', 'org_admin', 'trainer']);
    const data = this.getOrganizationData();
    const organization = data.organizations.find((item) => item && item.id === organizationId);
    if (!organization) {
      const error = new Error('Organization not found.');
      error.statusCode = 404;
      throw error;
    }
    const batchId = safeString(payload.batchId);
    const batch = data.batches.find((item) => item && item.organizationId === organizationId && item.id === batchId);
    if (!batch) {
      const error = new Error('Batch not found for organization.');
      error.statusCode = 404;
      throw error;
    }
    const scenarioPackId = safeString(payload.scenarioPackId);
    if (scenarioPackId) {
      const pack = this.getScenarioPack(scenarioPackId);
      if (!pack && !(organization.customScenarioPackIds || []).includes(scenarioPackId)) {
        const error = new Error('Scenario pack is not available for this organization.');
        error.statusCode = 404;
        throw error;
      }
      if (!(organization.customScenarioPackIds || []).includes(scenarioPackId)) {
        organization.customScenarioPackIds = uniqueStrings([...(organization.customScenarioPackIds || []), scenarioPackId]);
      }
    }
    const now = new Date().toISOString();
    const title = safeString(payload.title, 'Assigned Scenario Pack');
    const assignment = {
      id: safeString(payload.id, `assignment_${slugify(title)}_${crypto.randomBytes(3).toString('hex')}`),
      organizationId,
      batchId,
      title,
      roleId: safeString(payload.roleId || batch.roleFocus, 'developer'),
      scenarioPackId,
      requiredChapterIds: uniqueStrings(payload.requiredChapterIds || []),
      dueDate: normalizeDueDate(payload.dueDate || batch.dueDate, 10),
      status: 'assigned',
      assignedByUserId: safeString(payload.assignedByUserId || payload.actorUserId, 'trainer'),
      createdAt: now,
      updatedAt: now,
    };
    data.assignments.unshift(assignment);
    organization.updatedAt = now;
    this.saveOrganizationData(data);
    this.addAudit(assignment.assignedByUserId, 'organization_assignment_created', assignment.id, { organizationId, batchId, scenarioPackId });
    return { assignment, organization: this.enrichOrganization(organization, data) };
  }

  getAssignments(organizationId) {
    const data = this.getOrganizationData();
    return { version: 1, assignments: data.assignments.filter((assignment) => assignment.organizationId === organizationId) };
  }

  recordTraineeProgress(organizationId, payload = {}) {
    requireOrgRole(payload, ['platform_admin', 'org_admin', 'trainer', 'trainee']);
    const data = this.getOrganizationData();
    const organization = data.organizations.find((item) => item && item.id === organizationId);
    if (!organization) {
      const error = new Error('Organization not found.');
      error.statusCode = 404;
      throw error;
    }
    const batchId = safeString(payload.batchId);
    const assignmentId = safeString(payload.assignmentId);
    const assignment = data.assignments.find((item) => item && item.organizationId === organizationId && item.id === assignmentId && item.batchId === batchId);
    if (!assignment) {
      const error = new Error('Assignment not found for trainee progress.');
      error.statusCode = 404;
      throw error;
    }
    const userId = safeString(payload.userId, 'trainee');
    const now = new Date().toISOString();
    const progressPercent = clampPercent(payload.progressPercent);
    const completedChapterIds = uniqueStrings(payload.completedChapterIds || []);
    const dueDate = new Date(assignment.dueDate || 0);
    const isOverdue = dueDate.getTime() > 0 && Date.now() > dueDate.getTime() && progressPercent < 100;
    const existing = data.progress.find((item) => item && item.organizationId === organizationId && item.assignmentId === assignmentId && item.userId === userId);
    const progress = {
      id: existing ? existing.id : crypto.randomUUID(),
      organizationId,
      batchId,
      assignmentId,
      userId,
      displayName: safeString(payload.displayName, userId),
      completedChapterIds,
      progressPercent,
      score: clampPercent(payload.score),
      status: progressPercent >= 100 ? 'completed' : progressPercent > 0 ? 'in_progress' : 'not_started',
      isOverdue,
      completedAt: progressPercent >= 100 ? safeString(payload.completedAt, now) : null,
      updatedAt: now,
    };
    data.progress = [progress, ...data.progress.filter((item) => !(item && item.organizationId === organizationId && item.assignmentId === assignmentId && item.userId === userId))];
    organization.traineeUserIds = uniqueStrings([...(organization.traineeUserIds || []), userId]);
    organization.updatedAt = now;
    this.saveOrganizationData(data);
    this.addAudit(userId, 'organization_training_progress_saved', assignmentId, { organizationId, batchId, progressPercent, score: progress.score });
    return { progress, dashboard: this.getOrganizationDashboard(organizationId) };
  }

  getOrganizationDashboard(organizationId) {
    const data = this.getOrganizationData();
    const organization = data.organizations.find((item) => item && item.id === organizationId);
    if (!organization) {
      const error = new Error('Organization not found.');
      error.statusCode = 404;
      throw error;
    }
    const batches = data.batches.filter((batch) => batch.organizationId === organizationId);
    const assignments = data.assignments.filter((assignment) => assignment.organizationId === organizationId);
    const progress = data.progress.filter((item) => item.organizationId === organizationId);
    const completedCount = progress.filter((item) => item.status === 'completed').length;
    const overdueCount = progress.filter((item) => item.isOverdue === true).length;
    const averageProgress = progress.length ? Math.round(progress.reduce((sum, item) => sum + clampPercent(item.progressPercent), 0) / progress.length) : 0;
    const averageScore = progress.length ? Math.round(progress.reduce((sum, item) => sum + clampPercent(item.score), 0) / progress.length) : 0;
    return {
      organizationId,
      organizationName: organization.name,
      generatedAt: new Date().toISOString(),
      summary: {
        batchCount: batches.length,
        traineeCount: uniqueStrings([...(organization.traineeUserIds || []), ...batches.flatMap((batch) => batch.traineeUserIds || [])]).length,
        assignmentCount: assignments.length,
        completedCount,
        overdueCount,
        averageProgress,
        averageScore,
      },
      batches,
      assignments,
      progress,
      customScenarioPackIds: organization.customScenarioPackIds || [],
      rbac: organization.rbac,
    };
  }

  exportOrganizationReport(organizationId, format = 'json') {
    const dashboard = this.getOrganizationDashboard(organizationId);
    if (String(format).toLowerCase() === 'csv') {
      const lines = [
        ['organizationId', 'organizationName', 'batchCount', 'traineeCount', 'assignmentCount', 'completedCount', 'averageProgress', 'averageScore'].map(csvEscape).join(','),
        [dashboard.organizationId, dashboard.organizationName, dashboard.summary.batchCount, dashboard.summary.traineeCount, dashboard.summary.assignmentCount, dashboard.summary.completedCount, dashboard.summary.averageProgress, dashboard.summary.averageScore].map(csvEscape).join(','),
        '',
        ['userId', 'displayName', 'assignmentId', 'status', 'progressPercent', 'score', 'isOverdue', 'updatedAt'].map(csvEscape).join(','),
        ...dashboard.progress.map((item) => [item.userId, item.displayName, item.assignmentId, item.status, item.progressPercent, item.score, item.isOverdue, item.updatedAt].map(csvEscape).join(',')),
      ];
      return { contentType: 'text/csv; charset=utf-8', body: lines.join('\n') };
    }
    return { contentType: 'application/json; charset=utf-8', body: JSON.stringify({ reportType: 'organization_training_progress', ...dashboard }, null, 2) };
  }

  getOrganizationScenarioPacks(organizationId) {
    const organization = this.getOrganization(organizationId);
    if (!organization) {
      const error = new Error('Organization not found.');
      error.statusCode = 404;
      throw error;
    }
    const packIds = new Set(organization.customScenarioPackIds || []);
    const catalog = this.getScenarioPackCatalog({ includeUnpublished: false });
    return { version: 1, packs: (catalog.packs || []).filter((pack) => packIds.has(pack.id)) };
  }


  getAnalyticsCatalog() {
    return {
      version: 1,
      eventTypes: ANALYTICS_EVENT_TYPES,
      privacy: {
        defaultEnabled: true,
        canDisable: true,
        rawPersonalDataExcludedFromAdmin: true,
        blockedMetadataKeys: ANALYTICS_BLOCKED_KEYS,
        adminAggregationUsesUserHashOnly: true,
      },
      performance: {
        maxStoredEvents: 5000,
        aggregationMode: 'single_pass_runtime_summary',
        writeMode: 'append_and_cap_for_lightweight_storage',
      },
    };
  }

  getAnalyticsData() {
    const data = readJson(this.analyticsEventsFile, { version: 1, events: [] });
    return {
      version: 1,
      events: Array.isArray(data.events) ? data.events : [],
    };
  }

  saveAnalyticsData(data) {
    const normalized = {
      version: 1,
      events: Array.isArray(data.events) ? data.events.slice(0, 5000) : [],
    };
    writeJson(this.analyticsEventsFile, normalized);
    return normalized;
  }

  getAnalyticsSettingsData() {
    const data = readJson(this.analyticsSettingsFile, { version: 1, settingsByUser: {} });
    return {
      version: 1,
      settingsByUser: safeObject(data.settingsByUser),
    };
  }

  saveAnalyticsSettingsData(data) {
    const normalized = {
      version: 1,
      settingsByUser: safeObject(data.settingsByUser),
    };
    writeJson(this.analyticsSettingsFile, normalized);
    return normalized;
  }

  getAnalyticsSettings(userId) {
    const safeUserId = safeString(userId, 'anonymous');
    const data = this.getAnalyticsSettingsData();
    return {
      userId: safeUserId,
      settings: normalizeAnalyticsSettings(data.settingsByUser[safeUserId]),
      privacy: this.getAnalyticsCatalog().privacy,
    };
  }

  saveAnalyticsSettings(userId, payload = {}) {
    const safeUserId = safeString(userId, 'anonymous');
    const data = this.getAnalyticsSettingsData();
    const settings = normalizeAnalyticsSettings({
      ...safeObject(data.settingsByUser[safeUserId]),
      ...payload,
      updatedAt: new Date().toISOString(),
    });
    data.settingsByUser[safeUserId] = settings;
    this.saveAnalyticsSettingsData(data);
    this.addAudit(safeUserId, 'analytics_settings_saved', safeUserId, { enabled: settings.enabled, shareAggregateWithAdmin: settings.shareAggregateWithAdmin });
    return { userId: safeUserId, settings, privacy: this.getAnalyticsCatalog().privacy };
  }

  recordAnalyticsEvent(payload = {}) {
    const userId = safeString(payload.userId, 'anonymous');
    const settings = this.getAnalyticsSettings(userId).settings;
    if (settings.enabled === false) {
      return {
        skipped: true,
        reason: 'analytics_disabled_by_user',
        settings,
        privacy: this.getAnalyticsCatalog().privacy,
      };
    }

    const now = new Date().toISOString();
    const type = normalizeAnalyticsEventType(payload.eventType || payload.type || payload.name);
    const scoreDelta = safeObject(payload.scoreDelta || payload.scoreImpact || payload.skillDelta);
    const event = {
      id: safeString(payload.id, crypto.randomUUID()),
      eventType: type,
      userId,
      userHash: anonymizeUserId(userId),
      organizationId: safeString(payload.organizationId),
      roleId: safeString(payload.roleId, 'unknown_role'),
      chapterId: safeString(payload.chapterId),
      choiceId: safeString(payload.choiceId),
      miniGameId: safeString(payload.miniGameId),
      skillId: safeString(payload.skillId),
      durationSeconds: Math.max(0, Math.round(numberOrZero(payload.durationSeconds || payload.timeSpentSeconds))),
      scoreDelta: sanitizeAnalyticsMetadata(scoreDelta),
      metadata: sanitizeAnalyticsMetadata(payload.metadata || payload.parameters || {}),
      createdAt: safeString(payload.createdAt, now),
      privacy: {
        sanitized: true,
        rawPersonalTextStored: false,
        adminVisibleUserHashOnly: true,
      },
    };

    const data = this.getAnalyticsData();
    data.events.unshift(event);
    this.saveAnalyticsData({ ...data, events: data.events.slice(0, 5000) });
    this.addAudit(userId, 'analytics_event_logged', event.id, { eventType: event.eventType, roleId: event.roleId, chapterId: event.chapterId });
    return { event, skipped: false, settings, privacy: this.getAnalyticsCatalog().privacy };
  }

  getAnalyticsEvents({ userId = '', limit = 100 } = {}) {
    const data = this.getAnalyticsData();
    const safeLimit = Math.max(1, Math.min(500, Math.round(numberOrZero(limit) || 100)));
    const events = safeString(userId)
      ? data.events.filter((event) => event && event.userId === userId)
      : data.events;
    return { version: 1, events: events.slice(0, safeLimit) };
  }

  getPersonalAnalyticsDashboard(userId) {
    const safeUserId = safeString(userId, 'anonymous');
    const settings = this.getAnalyticsSettings(safeUserId).settings;
    const events = this.getAnalyticsData().events.filter((event) => event && event.userId === safeUserId);
    const summary = this.buildAnalyticsSummary(events);
    return {
      userId: safeUserId,
      generatedAt: new Date().toISOString(),
      analyticsEnabled: settings.enabled,
      privacy: {
        personalDashboardUsesOwnEventsOnly: true,
        sensitiveMetadataFiltered: true,
        canDisableAnalytics: true,
      },
      summary,
      roleProgress: summary.roleProgress,
      skillImprovement: summary.skillImprovement,
      recentEvents: events.slice(0, 25),
      performance: {
        eventCount: events.length,
        aggregationMode: 'single_pass',
        appPerformanceImpact: 'low_local_append_with_capped_history',
      },
    };
  }

  getAdminAnalyticsDashboard() {
    const settings = this.getAnalyticsSettingsData().settingsByUser;
    const allowedEvents = this.getAnalyticsData().events.filter((event) => {
      const userSettings = normalizeAnalyticsSettings(settings[event.userId]);
      return userSettings.enabled !== false && userSettings.shareAggregateWithAdmin !== false;
    });
    const summary = this.buildAnalyticsSummary(allowedEvents);
    const users = new Set(allowedEvents.map((event) => event.userHash).filter(Boolean));
    const eventCountsByType = {};
    const roleCounts = {};
    const organizationCounts = {};
    for (const event of allowedEvents) {
      eventCountsByType[event.eventType] = (eventCountsByType[event.eventType] || 0) + 1;
      if (event.roleId) roleCounts[event.roleId] = (roleCounts[event.roleId] || 0) + 1;
      if (event.organizationId) organizationCounts[event.organizationId] = (organizationCounts[event.organizationId] || 0) + 1;
    }
    return {
      generatedAt: new Date().toISOString(),
      summary: {
        totalEvents: allowedEvents.length,
        activeLearnerCount: users.size,
        totalChapterStarts: summary.totalChapterStarts,
        totalChapterCompletions: summary.totalChapterCompletions,
        totalChoiceSelections: summary.totalChoiceSelections,
        totalMiniGameAttempts: summary.totalMiniGameAttempts,
        totalTimeSpentSeconds: summary.totalTimeSpentSeconds,
        averageCompletionPerRole: summary.averageCompletionPerRole,
      },
      eventCountsByType,
      roleCounts,
      organizationCounts,
      roleProgress: summary.roleProgress,
      skillImprovement: summary.skillImprovement,
      privacy: {
        rawUserIdsExposed: false,
        namesEmailsAnswersExcluded: true,
        aggregateOnly: true,
        userHashUsedOnlyForCounting: true,
      },
      performance: {
        eventCount: allowedEvents.length,
        aggregationMode: 'single_pass',
        maxStoredEvents: 5000,
        appPerformanceImpact: 'low; analytics can be disabled per user',
      },
    };
  }

  buildAnalyticsSummary(events = []) {
    const roleProgress = {};
    const skillImprovement = analyticsEmptySkillMap();
    let totalTimeSpentSeconds = 0;
    let totalChapterStarts = 0;
    let totalChapterCompletions = 0;
    let totalChoiceSelections = 0;
    let totalMiniGameAttempts = 0;

    for (const event of events) {
      const roleId = safeString(event.roleId, 'unknown_role');
      if (!roleProgress[roleId]) {
        roleProgress[roleId] = {
          roleId,
          chapterStarts: 0,
          chapterCompletions: 0,
          choices: 0,
          miniGameAttempts: 0,
          timeSpentSeconds: 0,
          progressPercent: 0,
          lastActiveAt: null,
        };
      }
      const role = roleProgress[roleId];
      role.lastActiveAt = !role.lastActiveAt || String(event.createdAt) > role.lastActiveAt ? event.createdAt : role.lastActiveAt;
      const duration = Math.max(0, Math.round(numberOrZero(event.durationSeconds)));
      totalTimeSpentSeconds += duration;
      role.timeSpentSeconds += duration;
      if (event.eventType === 'chapter_started') { totalChapterStarts += 1; role.chapterStarts += 1; }
      if (event.eventType === 'chapter_completed') { totalChapterCompletions += 1; role.chapterCompletions += 1; }
      if (event.eventType === 'choice_selected') { totalChoiceSelections += 1; role.choices += 1; }
      if (event.eventType === 'mini_game_attempt') { totalMiniGameAttempts += 1; role.miniGameAttempts += 1; }
      for (const [key, raw] of Object.entries(safeObject(event.scoreDelta))) {
        const normalized = key === 'chaos' ? 'chaos_control' : key;
        if (skillImprovement[normalized] === undefined) skillImprovement[normalized] = 0;
        skillImprovement[normalized] += numberOrZero(raw);
      }
    }

    for (const role of Object.values(roleProgress)) {
      const started = Math.max(1, role.chapterStarts);
      role.progressPercent = Math.max(0, Math.min(100, Math.round((role.chapterCompletions / started) * 100)));
    }
    const roleValues = Object.values(roleProgress);
    const averageCompletionPerRole = roleValues.length
      ? Math.round(roleValues.reduce((sum, role) => sum + role.progressPercent, 0) / roleValues.length)
      : 0;
    return {
      totalEvents: events.length,
      totalChapterStarts,
      totalChapterCompletions,
      totalChoiceSelections,
      totalMiniGameAttempts,
      totalTimeSpentSeconds,
      averageCompletionPerRole,
      roleProgress,
      skillImprovement,
    };
  }

  getRoles({ includeUnpublished = false } = {}) {
    return this.loadCatalog({ includeUnpublished }).map((roleScenario) => ({
      ...roleScenario.role,
      chapterCount: roleScenario.chapters.length,
    }));
  }

  getRoleScenario(roleId, { includeUnpublished = false } = {}) {
    return this.loadCatalog({ includeUnpublished }).find((item) => item.role.id === roleId) || null;
  }

  getChaptersByRole(roleId, { includeUnpublished = false } = {}) {
    const roleScenario = this.getRoleScenario(roleId, { includeUnpublished });
    if (!roleScenario) return null;
    return roleScenario.chapters.map((chapter, index) => ({
      id: chapter.id,
      roleId,
      index,
      title: chapter.title,
      difficulty: chapter.difficulty,
      theme: chapter.theme,
      hasMiniGame: Boolean(chapter.miniGame),
      isCleanupMission: chapter.isCleanupMission === true,
      isFinale: chapter.isFinale === true,
      prerequisites: chapter.prerequisites || [],
      consequenceFlags: chapter.consequenceFlags || [],
      blockedByFlags: chapter.blockedByFlags || [],
      requiredStoryFlags: chapter.requiredStoryFlags || [],
      blockedByStoryFlags: chapter.blockedByStoryFlags || [],
      requiredRelationshipMinimums: chapter.requiredRelationshipMinimums || null,
      endingRules: chapter.endingRules || [],
      roleMechanicType: chapter.roleMechanicType || null,
      learningObjective: chapter.learningObjective || '',
      skillLevel: chapter.skillLevel || null,
      workflowId: chapter.workflowId || null,
      skillTags: chapter.skillTags || [],
      realWorldConstraints: chapter.realWorldConstraints || [],
      practicalTakeaway: chapter.practicalTakeaway || '',
      contentVersion: chapter.contentVersion || roleScenario.contentVersion || '23.0.0',
      contentPackId: chapter.contentPackId || roleScenario.contentPackId || 'core_roles_v23',
      assetVersion: chapter.assetVersion || roleScenario.assetVersion || '23.0.0',
      assetPackId: chapter.assetPackId || roleScenario.assetPackId || 'base_visuals_v23',
      rolePluginId: chapter.rolePluginId || roleScenario.role.pluginId || `${roleId}_core`,
      contentTier: chapter.contentTier || 'free',
      safetyReview: chapter.safetyReview || { status: 'draft' },
      supportsOfflineCache: chapter.supportsOfflineCache !== false,
      analyticsTags: chapter.analyticsTags || [],
      isPublished: chapter.isPublished !== false,
      adaptiveDialogueInjections: chapter.adaptiveDialogueInjections || [],
      adaptiveDifficulty: chapter.adaptiveDifficulty || null,
      allowsAdaptiveSideMissions: chapter.allowsAdaptiveSideMissions === true,
      skillNodeIds: chapter.skillNodeIds || [],
    }));
  }

  findChapter(chapterId, { includeUnpublished = false } = {}) {
    for (const roleScenario of this.loadCatalog({ includeUnpublished })) {
      const chapter = roleScenario.chapters.find((item) => item.id === chapterId);
      if (chapter) return { roleScenario, chapter };
    }
    return null;
  }

  getScenarioByChapter(chapterId, { includeUnpublished = false } = {}) {
    const found = this.findChapter(chapterId, { includeUnpublished });
    if (!found) return null;
    return found.chapter;
  }

  saveRoleScenario(roleScenario, fileName) {
    const validation = validateRoleScenario(roleScenario);
    if (!validation.valid) {
      const error = new Error('Invalid role scenario content.');
      error.validation = validation;
      throw error;
    }
    const finalFileName = fileName || `${slugify(roleScenario.role.id || roleScenario.role.name)}.json`;
    const filePath = path.join(config.scenarioDir, finalFileName.endsWith('.json') ? finalFileName : `${finalFileName}.json`);
    writeJson(filePath, roleScenario);
    return { filePath, roleScenario };
  }

  upsertRole(rolePayload, actor = 'admin') {
    const roleId = slugify(rolePayload.id || rolePayload.name);
    const existing = this.getRoleScenario(roleId, { includeUnpublished: true });
    const roleScenario = existing || {
      role: {},
      chapters: [],
    };
    roleScenario.role = {
      id: roleId,
      name: rolePayload.name || rolePayload.id || roleId,
      description: rolePayload.description || 'New role awaiting description.',
      iconKey: rolePayload.iconKey || 'work',
      isPublished: rolePayload.isPublished === undefined ? true : Boolean(rolePayload.isPublished),
    };
    const saved = this.saveRoleScenario(roleScenario, existing?.__fileName || `${roleId}.json`);
    this.addAudit(actor, 'role_upserted', roleId, rolePayload);
    return saved.roleScenario.role;
  }

  upsertChapter(roleId, chapterPayload, actor = 'admin') {
    const roleScenario = this.getRoleScenario(roleId, { includeUnpublished: true });
    if (!roleScenario) {
      const error = new Error('Role not found.');
      error.statusCode = 404;
      throw error;
    }
    const chapterId = slugify(chapterPayload.id || `${roleId}_${chapterPayload.title}`);
    const chapter = {
      id: chapterId,
      title: chapterPayload.title || 'Untitled Chapter',
      difficulty: chapterPayload.difficulty || 'Beginner',
      theme: chapterPayload.theme || 'Professional decision-making',
      story: chapterPayload.story || chapterPayload.scenario || 'Story pending review.',
      task: chapterPayload.task || 'Choose the best professional response.',
      professionalLearningPoint: chapterPayload.professionalLearningPoint || '',
      safetyDisclaimer: chapterPayload.safetyDisclaimer,
      learningObjective: chapterPayload.learningObjective || '',
      skillLevel: chapterPayload.skillLevel || 'beginner',
      workflowId: chapterPayload.workflowId || '',
      skillTags: chapterPayload.skillTags || [],
      realWorldConstraints: chapterPayload.realWorldConstraints || [],
      safetyGuardrails: chapterPayload.safetyGuardrails || [],
      practicalTakeaway: chapterPayload.practicalTakeaway || '',
      safeExplanation: chapterPayload.safeExplanation || '',
      mentorFeedback: chapterPayload.mentorFeedback || '',
      contentVersion: chapterPayload.contentVersion || '23.0.0',
      contentPackId: chapterPayload.contentPackId || 'core_roles_v23',
      assetVersion: chapterPayload.assetVersion || '23.0.0',
      assetPackId: chapterPayload.assetPackId || 'base_visuals_v23',
      rolePluginId: chapterPayload.rolePluginId || `${roleId}_core`,
      localizationKey: chapterPayload.localizationKey || `role.${roleId}.chapter.${chapterId}.title`,
      contentTier: chapterPayload.contentTier || 'free',
      contentAccess: chapterPayload.contentAccess || undefined,
      safetyReview: chapterPayload.safetyReview || { status: 'draft', domains: ['professional_learning'], guardrails: [] },
      supportsOfflineCache: chapterPayload.supportsOfflineCache === undefined ? true : Boolean(chapterPayload.supportsOfflineCache),
      analyticsTags: chapterPayload.analyticsTags || [roleId],
      multiplayer: chapterPayload.multiplayer || { mode: 'solo', enabled: false },
      isPublished: chapterPayload.isPublished === undefined ? false : Boolean(chapterPayload.isPublished),
      scenes: chapterPayload.scenes || undefined,
      choices: chapterPayload.choices || [],
      miniGame: chapterPayload.miniGame || undefined,
      prerequisites: chapterPayload.prerequisites || [],
      consequenceFlags: chapterPayload.consequenceFlags || [],
      blockedByFlags: chapterPayload.blockedByFlags || [],
      requiredScoreMinimums: chapterPayload.requiredScoreMinimums || undefined,
      roleMechanicType: chapterPayload.roleMechanicType || undefined,
      isCleanupMission: chapterPayload.isCleanupMission === true,
      isFinale: chapterPayload.isFinale === true,
      storyFlags: chapterPayload.storyFlags || [],
      requiredStoryFlags: chapterPayload.requiredStoryFlags || [],
      blockedByStoryFlags: chapterPayload.blockedByStoryFlags || [],
      requiredRelationshipMinimums: chapterPayload.requiredRelationshipMinimums || undefined,
      endingRules: chapterPayload.endingRules || [],
      adaptiveDialogueInjections: chapterPayload.adaptiveDialogueInjections || [],
      adaptiveDifficulty: chapterPayload.adaptiveDifficulty || undefined,
      allowsAdaptiveSideMissions: chapterPayload.allowsAdaptiveSideMissions === true,
    };
    const validation = validateChapter({ ...chapter, roleName: roleScenario.role.name });
    if (!validation.valid) {
      const error = new Error('Invalid chapter.');
      error.validation = validation;
      throw error;
    }
    const index = roleScenario.chapters.findIndex((item) => item.id === chapterId);
    if (index >= 0) roleScenario.chapters[index] = chapter;
    else roleScenario.chapters.push(chapter);
    const saved = this.saveRoleScenario(roleScenario, roleScenario.__fileName);
    this.addAudit(actor, 'chapter_upserted', chapterId, chapterPayload);
    return saved.roleScenario.chapters.find((item) => item.id === chapterId);
  }

  setPublishState(chapterId, isPublished, actor = 'admin') {
    const found = this.findChapter(chapterId, { includeUnpublished: true });
    if (!found) {
      const error = new Error('Chapter not found.');
      error.statusCode = 404;
      throw error;
    }
    const chapter = found.chapter;
    const validation = validateChapter({ ...chapter, roleName: found.roleScenario.role.name });
    if (!validation.valid && isPublished) {
      const error = new Error('Invalid content cannot be published.');
      error.validation = validation;
      throw error;
    }
    if (isPublished) {
      const roleName = String(found.roleScenario.role.name || '').toLowerCase();
      const guardrails = Array.isArray(chapter.safetyGuardrails) ? chapter.safetyGuardrails : [];
      const sensitive = roleName.includes('doctor') || roleName.includes('engineer') || roleName.includes('hr') || guardrails.length > 0;
      const status = chapter.safetyReview && typeof chapter.safetyReview === 'object' ? chapter.safetyReview.status : '';
      if (sensitive && status !== 'approved') {
        const error = new Error('Safety-sensitive content must have approved safetyReview before publishing.');
        error.validation = { valid: false, errors: ['safetyReview.status must be approved for safety-sensitive content.'] };
        throw error;
      }
    }
    chapter.isPublished = Boolean(isPublished);
    this.saveRoleScenario(found.roleScenario, found.roleScenario.__fileName);
    this.addAudit(actor, isPublished ? 'chapter_published' : 'chapter_unpublished', chapterId, { isPublished });
    return chapter;
  }

  getProgress(userId) {
    const data = readJson(this.progressFile, {});
    return normalizeProgress(data[userId]);
  }

  saveProgress(userId, progress) {
    const data = readJson(this.progressFile, {});
    data[userId] = normalizeProgress(progress);
    writeJson(this.progressFile, data);
    return data[userId];
  }

  getMonetizationFeatureState() {
    const flags = this.getFeatureFlags();
    const catalog = readJson(this.monetizationProductsFile, { version: 1, developmentMode: {}, products: [] });
    const developmentMode = safeObject(catalog.developmentMode);
    return {
      enabled: flagEnabled(flags, 'monetization_system', false),
      developmentMode: {
        noPaymentRequired: developmentMode.noPaymentRequired !== false,
        environment: safeString(developmentMode.environment, 'development'),
        paymentProvider: safeString(developmentMode.paymentProvider, 'placeholder_only'),
      },
      featureFlag: 'monetization_system',
    };
  }

  getProductCatalog({ includeInactive = false } = {}) {
    const catalog = readJson(this.monetizationProductsFile, { version: 1, developmentMode: {}, products: [] });
    const products = Array.isArray(catalog.products) ? catalog.products.map(normalizeProduct) : [];
    return {
      version: catalog.version || 1,
      monetization: this.getMonetizationFeatureState(),
      products: products.filter((product) => includeInactive || product.isActive),
    };
  }

  findProduct(payload = {}) {
    const catalog = this.getProductCatalog({ includeInactive: false });
    const products = catalog.products || [];
    return products.find((product) => productMatchesContent(product, payload)) || null;
  }

  getEntitlementData() {
    const data = readJson(this.monetizationEntitlementsFile, { version: 1, entitlementsByUser: {} });
    return {
      version: 1,
      entitlementsByUser: safeObject(data.entitlementsByUser),
    };
  }

  saveEntitlementData(data) {
    const normalized = {
      version: 1,
      entitlementsByUser: safeObject(data.entitlementsByUser),
    };
    writeJson(this.monetizationEntitlementsFile, normalized);
    return normalized;
  }

  getUserEntitlements(userId = 'anonymous') {
    const safeUserId = safeString(userId, 'anonymous');
    const data = this.getEntitlementData();
    const entitlements = Array.isArray(data.entitlementsByUser[safeUserId])
      ? data.entitlementsByUser[safeUserId].map(normalizeEntitlement)
      : [];
    return {
      userId: safeUserId,
      entitlements,
      activeEntitlements: entitlements.filter(entitlementIsActive),
      monetization: this.getMonetizationFeatureState(),
    };
  }

  grantEntitlement(userId = 'anonymous', payload = {}, source = 'development_placeholder') {
    const safeUserId = safeString(userId, 'anonymous');
    const product = this.findProduct(payload) || normalizeProduct(payload.product || payload);
    const data = this.getEntitlementData();
    const current = Array.isArray(data.entitlementsByUser[safeUserId]) ? data.entitlementsByUser[safeUserId].map(normalizeEntitlement) : [];
    const entitlement = normalizeEntitlement({
      userId: safeUserId,
      productId: product.id,
      entitlementKey: product.entitlementKey,
      contentIds: product.contentIds,
      scenarioPackIds: product.scenarioPackIds,
      source,
      active: true,
      grantedAt: new Date().toISOString(),
      expiresAt: payload.expiresAt,
    });
    const next = [
      entitlement,
      ...current.filter((item) => !(item.productId === entitlement.productId && item.entitlementKey === entitlement.entitlementKey)),
    ];
    data.entitlementsByUser[safeUserId] = next.slice(0, 200);
    this.saveEntitlementData(data);
    this.addAudit(safeUserId, 'monetization_entitlement_granted', entitlement.id, { productId: entitlement.productId, source });
    return { userId: safeUserId, entitlement, entitlements: data.entitlementsByUser[safeUserId] };
  }

  checkEntitlement(userId = 'anonymous', payload = {}) {
    const safeUserId = safeString(userId, 'anonymous');
    const monetization = this.getMonetizationFeatureState();
    const contentTier = normalizeMonetizationPriceType(payload.contentTier || payload.priceType);
    const product = this.findProduct(payload);
    if (!monetization.enabled) {
      return {
        userId: safeUserId,
        allowed: true,
        locked: false,
        reason: 'monetization_disabled_by_feature_flag',
        product,
        monetization,
      };
    }
    if (contentTier === 'free' || (product && product.priceType === 'free')) {
      return {
        userId: safeUserId,
        allowed: true,
        locked: false,
        reason: 'free_content',
        product,
        monetization,
      };
    }
    const entitlements = this.getUserEntitlements(safeUserId).activeEntitlements;
    const matched = entitlements.find((entitlement) => entitlementMatchesContent(entitlement, payload));
    return {
      userId: safeUserId,
      allowed: Boolean(matched),
      locked: !matched,
      reason: matched ? 'active_entitlement_found' : 'premium_content_locked',
      product,
      entitlement: matched || null,
      monetization,
      preview: product ? product.preview : {},
    };
  }

  getPremiumPreview(payload = {}) {
    const product = this.findProduct(payload);
    if (!product) {
      const error = new Error('Product or premium content preview not found.');
      error.statusCode = 404;
      throw error;
    }
    const entitlementCheck = this.checkEntitlement(payload.userId || 'anonymous', {
      ...payload,
      productId: product.id,
      contentTier: product.priceType,
    });
    return {
      product,
      preview: product.preview,
      locked: entitlementCheck.locked,
      allowed: entitlementCheck.allowed,
      reason: entitlementCheck.reason,
      monetization: entitlementCheck.monetization,
    };
  }

  createPurchasePlaceholder(userId = 'anonymous', payload = {}, purchaseType = 'purchase_placeholder') {
    const safeUserId = safeString(userId, 'anonymous');
    const product = this.findProduct(payload);
    if (!product) {
      const error = new Error('Product not found for purchase placeholder.');
      error.statusCode = 404;
      throw error;
    }
    const monetization = this.getMonetizationFeatureState();
    if (!monetization.enabled) {
      return {
        userId: safeUserId,
        product,
        status: 'not_required',
        purchaseType,
        paymentRequired: false,
        entitlement: null,
        message: 'Monetization is disabled by feature flag, so content is accessible without purchase.',
        monetization,
      };
    }
    if (product.priceType === 'free') {
      return {
        userId: safeUserId,
        product,
        status: 'free_content',
        purchaseType,
        paymentRequired: false,
        entitlement: null,
        message: 'Free content does not require purchase.',
        monetization,
      };
    }
    if (monetization.developmentMode.noPaymentRequired) {
      const granted = this.grantEntitlement(safeUserId, { productId: product.id }, purchaseType);
      return {
        userId: safeUserId,
        product,
        status: 'development_entitlement_granted',
        purchaseType,
        paymentRequired: false,
        entitlement: granted.entitlement,
        message: 'Development mode uses a placeholder purchase; no payment was required.',
        monetization,
      };
    }
    return {
      userId: safeUserId,
      product,
      status: 'pending_external_payment_integration',
      purchaseType,
      paymentRequired: true,
      entitlement: null,
      message: 'Connect App Store / Play Billing / payment gateway and validate receipts before granting entitlement.',
      monetization,
    };
  }

  restorePurchasesPlaceholder(userId = 'anonymous') {
    const safeUserId = safeString(userId, 'anonymous');
    const data = this.getUserEntitlements(safeUserId);
    return {
      userId: safeUserId,
      restored: true,
      restoredCount: data.activeEntitlements.length,
      entitlements: data.activeEntitlements,
      message: 'Restore purchase placeholder returned locally stored development entitlements. Replace with receipt restore in production.',
      monetization: data.monetization,
    };
  }


  getSecurityPolicy() {
    return {
      version: 1,
      generatedAt: new Date().toISOString(),
      authentication: {
        adminTokens: 'Short-lived bearer/admin tokens stored server-side as session records and returned with expiry metadata.',
        tokenTtlMinutes: config.adminTokenTtlMinutes,
        requiredProductionEnv: ['ADMIN_USERNAME', 'ADMIN_PASSWORD', 'ADMIN_TOKEN_SECRET'],
      },
      secureStorage: {
        flutter: 'Use SecureTokenStorageService backed by flutter_secure_storage; fallback is development-only memory storage.',
        adminPanel: 'Use in-memory/session storage for prototype; production recommendation is HTTP-only secure same-site cookies.',
      },
      rateLimiting: {
        enabled: true,
        windowMs: config.rateLimitWindowMs,
        maxRequests: config.rateLimitMaxRequests,
        authMaxRequests: config.authRateLimitMaxRequests,
      },
      requestValidation: {
        enabled: true,
        maxBodyBytes: config.maxBodyBytes,
        rejectsInvalidJson: true,
        rejectsNonObjectWriteBodies: true,
      },
      rbac: {
        roles: ['super_admin', 'content_admin', 'trainer_admin', 'auditor'],
        permissionModel: 'Admin routes are protected by permission checks before handlers run.',
      },
      privacy: this.getPrivacyRetentionRules(),
      moderation: this.getContentModerationWorkflow(),
      monitoring: {
        crashMonitoringEnabled: config.crashMonitoringEnabled,
        errorEndpoint: '/api/errors/report',
        adminErrorDashboard: '/api/admin/error-events',
      },
    };
  }

  getContentModerationWorkflow() {
    return {
      statuses: ['pending_review', 'approved', 'rejected', 'needs_changes'],
      requiredFor: ['ai_generated_scenarios', 'scenario_packs', 'adaptive_story_drafts', 'voice_character_templates'],
      checks: ['professional_safety', 'prompt_abuse', 'privacy_leakage', 'unsafe_advice', 'copyright_or_plagiarism_risk'],
      publishRule: 'Content cannot be published until safety status is approved and prompt abuse status is safe.',
    };
  }

  getSecurityStatus(runtime = {}) {
    return {
      status: 'hardened_for_production_preparation',
      generatedAt: new Date().toISOString(),
      activeAdminSessions: runtime.activeAdminSessions || 0,
      secureHeadersEnabled: true,
      rateLimitingEnabled: true,
      requestValidationEnabled: true,
      rbacEnabled: true,
      auditLogsEnabled: true,
      moderationWorkflowExists: true,
      promptAbuseProtectionEnabled: true,
      backupRestoreStrategyExists: true,
      crashReportingEnabled: config.crashMonitoringEnabled,
      privacyRetentionRulesExists: true,
      productionChecklistComplete: fs.existsSync(path.join(config.rootDir, '..', 'docs', 'phase35_production_deployment_checklist.md')),
    };
  }

  getPrivacyRetentionRules() {
    return {
      version: 1,
      retentionDays: config.retentionDays,
      sensitiveDataPolicy: 'Do not store raw passwords, tokens, emails, phone numbers, OTPs, precise addresses, or unredacted free-text in audit/admin aggregate views.',
      analytics: {
        canBeDisabled: true,
        adminViewsAreAggregate: true,
        rawUserIdsInAdminDashboard: false,
      },
      deletionWorkflow: ['export_user_records', 'delete_or_anonymize_user_records', 'verify_backup_retention_window'],
      auditLogRetention: 'Keep recent audit events for security review; archive or delete after retention window based on org policy.',
      backups: {
        retention: 'Keep rolling encrypted production backups; this dev build stores JSON backup snapshots for validation only.',
        restoreRequiresPermission: 'backup:restore',
      },
    };
  }

  getContentModerationData() {
    const data = readJson(this.contentModerationFile, { version: 1, queue: [] });
    if (!Array.isArray(data.queue)) data.queue = [];
    return data;
  }

  saveContentModerationData(data) {
    writeJson(this.contentModerationFile, { version: 1, queue: Array.isArray(data.queue) ? data.queue.slice(0, 1000) : [] });
  }

  createContentModerationItem(payload = {}, actor = 'admin') {
    const promptSafety = inspectPromptAbuse(payload.prompt || payload.content || payload);
    const item = {
      id: crypto.randomUUID(),
      title: safeString(payload.title, 'Untitled moderation item'),
      contentType: safeString(payload.contentType, 'scenario_or_ai_content'),
      sourceId: safeString(payload.sourceId, ''),
      status: promptSafety.blocked ? 'needs_changes' : 'pending_review',
      safetyStatus: promptSafety.blocked ? 'blocked' : 'needs_human_review',
      promptSafety,
      content: sanitizeForAudit(payload.content || payload.preview || {}),
      submittedBy: safeString(actor, 'admin'),
      createdAt: new Date().toISOString(),
      reviewedAt: null,
      notes: '',
    };
    const data = this.getContentModerationData();
    data.queue.unshift(item);
    this.saveContentModerationData(data);
    this.addAudit(actor, 'content_moderation_item_created', item.id, { status: item.status, safetyStatus: item.safetyStatus, promptSafety });
    return item;
  }

  getContentModerationQueue() {
    const data = this.getContentModerationData();
    return { version: data.version || 1, workflow: this.getContentModerationWorkflow(), queue: data.queue };
  }

  setContentModerationStatus(itemId, status, notes = '', actor = 'admin') {
    const data = this.getContentModerationData();
    const item = data.queue.find((entry) => entry.id === itemId);
    if (!item) {
      const error = new Error('Content moderation item not found.');
      error.statusCode = 404;
      throw error;
    }
    item.status = status;
    item.safetyStatus = status === 'approved' ? 'approved' : status === 'rejected' ? 'rejected' : item.safetyStatus;
    item.notes = safeString(notes, '');
    item.reviewedBy = safeString(actor, 'admin');
    item.reviewedAt = new Date().toISOString();
    this.saveContentModerationData(data);
    this.addAudit(actor, `content_moderation_${status}`, itemId, { notes: item.notes });
    return item;
  }

  getErrorData() {
    const data = readJson(this.errorEventsFile, { version: 1, events: [] });
    if (!Array.isArray(data.events)) data.events = [];
    return data;
  }

  recordErrorEvent(payload = {}) {
    const data = this.getErrorData();
    const event = {
      id: crypto.randomUUID(),
      requestId: safeString(payload.requestId, ''),
      source: safeString(payload.source, 'unknown'),
      severity: safeString(payload.severity, Number(payload.statusCode || 0) >= 500 ? 'error' : 'warning'),
      message: safeString(payload.message, 'Unknown error').slice(0, 500),
      screen: safeString(payload.screen, ''),
      route: safeString(payload.route, ''),
      appVersion: safeString(payload.appVersion, ''),
      statusCode: Number.isFinite(Number(payload.statusCode)) ? Number(payload.statusCode) : null,
      stackHash: payload.stack ? hashValue(payload.stack).slice(0, 16) : null,
      metadata: sanitizeForAudit(payload.metadata || {}),
      createdAt: new Date().toISOString(),
    };
    data.events.unshift(event);
    writeJson(this.errorEventsFile, { version: 1, events: data.events.slice(0, 1000) });
    return { recorded: true, event };
  }

  getErrorEvents() {
    const data = this.getErrorData();
    return {
      version: data.version || 1,
      privacy: { stackTracesStored: false, stackHashOnly: true, sensitiveFieldsRedacted: true },
      events: data.events,
    };
  }

  backupRuntimeFiles() {
    return [
      this.progressFile,
      this.scoreFile,
      this.auditFile,
      this.reviewFile,
      this.adaptiveDraftFile,
      this.teamSessionsFile,
      this.interviewReportsFile,
      this.assessmentSessionsFile,
      this.certificateRecordsFile,
      this.organizationsFile,
      this.voiceConversationFile,
      this.analyticsEventsFile,
      this.analyticsSettingsFile,
      this.monetizationEntitlementsFile,
      this.contentModerationFile,
      this.errorEventsFile,
    ];
  }

  getBackupRecords() {
    ensureDir(config.backupDir);
    const manifest = readJson(this.backupManifestFile, { version: 1, backups: [] });
    if (!Array.isArray(manifest.backups)) manifest.backups = [];
    return {
      version: manifest.version || 1,
      strategy: {
        schedule: 'Daily automated production backup recommended; manual dev snapshot endpoint available.',
        encryption: 'Use managed disk/database encryption and store keys outside the app runtime.',
        restoreDrill: 'Run restore test before every major release and after schema changes.',
        rpo: '24 hours for development, define stricter RPO for paid corporate tenants.',
        rto: '4 hours target for MVP production incident response.',
      },
      backups: manifest.backups,
    };
  }

  createBackup(actor = 'admin') {
    ensureDir(config.backupDir);
    const backupId = `backup_${Date.now()}_${crypto.randomUUID().slice(0, 8)}`;
    const snapshot = { id: backupId, createdAt: new Date().toISOString(), createdBy: safeString(actor, 'admin'), files: {} };
    for (const file of this.backupRuntimeFiles()) {
      if (fs.existsSync(file)) snapshot.files[path.relative(config.runtimeDir, file)] = readJson(file, null);
    }
    const target = path.join(config.backupDir, `${backupId}.json`);
    writeJson(target, snapshot);
    const manifest = this.getBackupRecords();
    const record = { id: backupId, createdAt: snapshot.createdAt, createdBy: snapshot.createdBy, fileCount: Object.keys(snapshot.files).length, restoreSupported: true };
    manifest.backups.unshift(record);
    writeJson(this.backupManifestFile, { version: 1, backups: manifest.backups.slice(0, 50) });
    this.addAudit(actor, 'backup_created', backupId, { fileCount: record.fileCount });
    return { backup: record, strategy: manifest.strategy };
  }

  restoreBackup(backupId, actor = 'admin') {
    const safeBackupId = safeString(backupId, '');
    const target = path.join(config.backupDir, `${safeBackupId}.json`);
    if (!target.startsWith(config.backupDir) || !fs.existsSync(target)) {
      const error = new Error('Backup not found.');
      error.statusCode = 404;
      throw error;
    }
    const snapshot = readJson(target, null);
    if (!snapshot || !snapshot.files || typeof snapshot.files !== 'object') {
      const error = new Error('Backup snapshot is invalid.');
      error.statusCode = 400;
      throw error;
    }
    let restored = 0;
    for (const [relativeFile, value] of Object.entries(snapshot.files)) {
      const destination = path.normalize(path.join(config.runtimeDir, relativeFile));
      if (!destination.startsWith(config.runtimeDir)) continue;
      writeJson(destination, value);
      restored += 1;
    }
    this.addAudit(actor, 'backup_restored', safeBackupId, { restored });
    return { restored: true, backupId: safeBackupId, restoredFiles: restored };
  }

  getBadges() {
    const existing = readJson(this.badgeFile, null);
    if (existing) return existing;
    return [
      { id: 'first_step', title: 'First Step', description: 'Complete your first chapter.', hint: 'Complete any Chapter 1.', icon: '🎯' },
      { id: 'calm_professional', title: 'Calm Professional', description: 'Build discipline and communication.', hint: 'Choose calm, process-driven outcomes.', icon: '🧘' },
      { id: 'chaos_controller', title: 'Chaos Controller', description: 'Reduce chaos through good choices.', hint: 'Avoid reckless decisions.', icon: '🛡️' },
      { id: 'mini_game_master', title: 'Mini-game Master', description: 'Complete a role mini-game.', hint: 'Finish a mini-game successfully.', icon: '🎮' },
      { id: 'daily_chaos_starter', title: 'Daily Chaos Starter', description: 'Complete a daily activity challenge.', hint: 'Open Activity Hub and finish a daily challenge.', icon: '📅' },
      { id: 'bug_hunt_pro', title: 'Bug Hunt Pro', description: 'Complete a QA bug hunt activity.', hint: 'Finish Bug Hunt: Login Safari.', icon: '🐞' },
      { id: 'cleanup_racer', title: 'Cleanup Racer', description: 'Complete a data cleanup race.', hint: 'Finish the Back Office cleanup race.', icon: '🧹' },
      { id: 'scope_negotiator', title: 'Scope Negotiator', description: 'Complete a client negotiation activity.', hint: 'Finish the PM negotiation activity.', icon: '🤝' },
      { id: 'safe_triage_thinker', title: 'Safe Triage Thinker', description: 'Complete a safe triage dilemma.', hint: 'Finish the doctor ethical dilemma activity.', icon: '🩺' },
      { id: 'ethical_feedback_quiz', title: 'Ethical Feedback Quizzer', description: 'Complete the HR feedback quiz activity.', hint: 'Finish the HR role quiz activity.', icon: '🧑‍💼' },
    ];
  }

  saveScore(userId, score) {
    const data = readJson(this.scoreFile, {});
    if (!Array.isArray(data[userId])) data[userId] = [];
    const item = { id: crypto.randomUUID(), createdAt: new Date().toISOString(), ...score };
    data[userId].push(item);
    writeJson(this.scoreFile, data);
    return item;
  }

  addAudit(actor, action, entityId, details = {}) {
    const items = readJson(this.auditFile, []);
    const audit = {
      id: crypto.randomUUID(),
      actor: safeString(actor, 'system'),
      actorHash: hashValue(actor || 'system').slice(0, 16),
      action,
      entityId,
      details: sanitizeForAudit(details),
      createdAt: new Date().toISOString(),
    };
    items.unshift(audit);
    writeJson(this.auditFile, items.slice(0, 500));
    return audit;
  }

  getAuditLogs() {
    return readJson(this.auditFile, []);
  }

  createAiReview(payload, actor = 'admin') {
    const items = readJson(this.reviewFile, []);
    const review = {
      id: crypto.randomUUID(),
      status: 'pending',
      submittedBy: actor,
      content: sanitizeForAudit(payload),
      promptSafety: payload.promptSafety || inspectPromptAbuse(payload),
      createdAt: new Date().toISOString(),
      reviewedAt: null,
      notes: '',
    };
    items.unshift(review);
    writeJson(this.reviewFile, items);
    this.addAudit(actor, 'ai_review_created', review.id, {});
    return review;
  }

  getAiReviews() {
    return readJson(this.reviewFile, []);
  }

  setAiReviewStatus(reviewId, status, notes = '', actor = 'admin') {
    const items = readJson(this.reviewFile, []);
    const review = items.find((item) => item.id === reviewId);
    if (!review) {
      const error = new Error('AI review not found.');
      error.statusCode = 404;
      throw error;
    }
    review.status = status;
    review.notes = notes;
    review.reviewedAt = new Date().toISOString();
    writeJson(this.reviewFile, items);
    this.addAudit(actor, `ai_review_${status}`, reviewId, { notes });
    return review;
  }
}

module.exports = {
  DataStore,
  readJson,
  writeJson,
};
