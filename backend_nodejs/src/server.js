const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { URL } = require('url');
const { config } = require('./config');
const { DataStore } = require('./dataStore');
const { validateChapter } = require('./validation');
const {
  InMemoryRateLimiter,
  createSecurityHeaders,
  getPermissions,
  hasPermission,
  inspectPromptAbuse,
  permissionForRequest,
  sanitizeForAudit,
  validateBodyShape,
} = require('./security');

const store = new DataStore();
const sessions = new Map();
const rateLimiter = new InMemoryRateLimiter();

function getRequestId(res) {
  if (!res.requestId) res.requestId = crypto.randomUUID();
  return res.requestId;
}

function sendJson(res, statusCode, body, extraHeaders = {}) {
  const json = JSON.stringify(body, null, 2);
  res.writeHead(statusCode, {
    ...createSecurityHeaders(getRequestId(res)),
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(json),
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,X-Admin-Token,Authorization,X-Request-Id',
    ...extraHeaders,
  });
  res.end(json);
}

function sendText(res, statusCode, body, contentType = 'text/plain; charset=utf-8', extraHeaders = {}) {
  res.writeHead(statusCode, {
    ...createSecurityHeaders(getRequestId(res)),
    'Content-Type': contentType,
    'Content-Length': Buffer.byteLength(body),
    'Access-Control-Allow-Origin': '*',
    ...extraHeaders,
  });
  res.end(body);
}

function notFound(res) {
  sendJson(res, 404, { error: 'Not found' });
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let totalBytes = 0;
    req.on('data', (chunk) => {
      totalBytes += chunk.length;
      if (totalBytes > config.maxBodyBytes) {
        reject(Object.assign(new Error('Request body is too large.'), { statusCode: 413 }));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString('utf8');
      let parsed = {};
      if (raw.trim()) {
        try {
          parsed = JSON.parse(raw);
        } catch (error) {
          reject(Object.assign(new Error('Invalid JSON body.'), { statusCode: 400 }));
          return;
        }
      }
      const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
      const validation = validateBodyShape(cleanPathname(url.pathname), req.method || 'GET', parsed);
      if (!validation.valid) {
        reject(Object.assign(new Error('Request validation failed.'), { statusCode: 400, validation }));
        return;
      }
      resolve(parsed);
    });
    req.on('error', reject);
  });
}

function cleanPathname(pathname) {
  return pathname.replace(/\/+$/, '') || '/';
}

function getParam(pathname, pattern) {
  const pathParts = cleanPathname(pathname).split('/').filter(Boolean);
  const patternParts = pattern.split('/').filter(Boolean);
  if (pathParts.length !== patternParts.length) return null;
  const params = {};
  for (let i = 0; i < patternParts.length; i += 1) {
    if (patternParts[i].startsWith(':')) {
      params[patternParts[i].slice(1)] = decodeURIComponent(pathParts[i]);
    } else if (patternParts[i] !== pathParts[i]) {
      return null;
    }
  }
  return params;
}

function getAdminToken(req) {
  const bearer = req.headers.authorization || '';
  if (bearer.toLowerCase().startsWith('bearer ')) return bearer.slice(7).trim();
  return req.headers['x-admin-token'] || '';
}

function requireAdmin(req, res, pathname, method) {
  const token = getAdminToken(req);
  const session = sessions.get(token);
  if (!session) {
    sendJson(res, 401, { error: 'Admin token is missing or invalid.' });
    return null;
  }
  if (Date.parse(session.expiresAt) <= Date.now()) {
    sessions.delete(token);
    sendJson(res, 401, { error: 'Admin token expired. Please login again.' });
    return null;
  }
  const requiredPermission = permissionForRequest(pathname, method);
  if (!hasPermission(session, requiredPermission)) {
    store.addAudit(session.username, 'admin_access_denied', pathname, { requiredPermission, role: session.role });
    sendJson(res, 403, { error: 'Admin role is not allowed to access this action.', requiredPermission, role: session.role });
    return null;
  }
  return session;
}

function createToken(username) {
  const seed = `${username}:${Date.now()}:${config.adminTokenSecret}:${crypto.randomUUID()}`;
  return crypto.createHash('sha256').update(seed).digest('hex');
}

function getClientIp(req) {
  return (req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown').toString().split(',')[0].trim();
}

function enforceRateLimit(req, res, pathname) {
  const isAuth = pathname === '/api/admin/login';
  const key = `${getClientIp(req)}:${isAuth ? 'auth' : pathname.split('/').slice(0, 3).join('/')}`;
  const result = rateLimiter.check({
    key,
    limit: isAuth ? config.authRateLimitMaxRequests : config.rateLimitMaxRequests,
    windowMs: config.rateLimitWindowMs,
  });
  if (!result.allowed) {
    sendJson(res, 429, { error: 'Too many requests. Please retry later.', resetAt: new Date(result.resetAt).toISOString() }, {
      'Retry-After': String(Math.ceil((result.resetAt - Date.now()) / 1000)),
    });
    return false;
  }
  return true;
}

function sendStatic(req, res, pathname) {
  const normalized = pathname === '/admin' || pathname === '/admin/'
    ? '/admin/index.html'
    : pathname;
  const target = path.normalize(path.join(config.publicDir, normalized));
  if (!target.startsWith(config.publicDir)) {
    return sendJson(res, 403, { error: 'Forbidden' });
  }
  if (!fs.existsSync(target) || fs.statSync(target).isDirectory()) {
    return notFound(res);
  }
  const ext = path.extname(target).toLowerCase();
  const type = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'text/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
  }[ext] || 'application/octet-stream';
  sendText(res, 200, fs.readFileSync(target), type);
}

async function handleApi(req, res, url) {
  const pathname = cleanPathname(url.pathname);
  const method = req.method || 'GET';
  let params;

  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type,X-Admin-Token,Authorization,X-Request-Id',
    });
    return res.end();
  }

  if (method === 'GET' && pathname === '/api/health') {
    return sendJson(res, 200, {
      name: 'Career Chaos Academy Node.js API',
      status: 'ok',
      timestamp: new Date().toISOString(),
      requestId: getRequestId(res),
    });
  }

  if (method === 'GET' && pathname === '/api/security/policy') {
    return sendJson(res, 200, store.getSecurityPolicy());
  }

  if (method === 'GET' && pathname === '/api/privacy/retention-rules') {
    return sendJson(res, 200, store.getPrivacyRetentionRules());
  }

  if (method === 'POST' && pathname === '/api/errors/report') {
    const body = await parseBody(req);
    return sendJson(res, 201, store.recordErrorEvent({ ...body, requestId: getRequestId(res) }));
  }

  if (method === 'GET' && pathname === '/api/roles') {
    return sendJson(res, 200, store.getRoles());
  }

  if (method === 'GET' && pathname === '/api/characters') {
    return sendJson(res, 200, store.getCharacters());
  }

  if (method === 'GET' && pathname === '/api/professional/skill-maps') {
    return sendJson(res, 200, store.getProfessionalSkillMaps());
  }

  if (method === 'GET' && pathname === '/api/activities') {
    return sendJson(res, 200, store.getActivities());
  }

  if (method === 'GET' && pathname === '/api/audio/manifest') {
    return sendJson(res, 200, store.getAudioManifest());
  }

  if (method === 'GET' && pathname === '/api/voice/profiles') {
    return sendJson(res, 200, store.getVoiceProfiles());
  }

  params = getParam(pathname, '/api/users/:userId/voice-settings');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getVoiceSettings(params.userId));
  }
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.saveVoiceSettings(params.userId, body));
  }

  params = getParam(pathname, '/api/users/:userId/voice-conversations');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getCharacterConversations(params.userId));
  }

  if (method === 'POST' && pathname === '/api/voice/character-chat') {
    const body = await parseBody(req);
    const promptSafety = inspectPromptAbuse(body.message || body);
    if (promptSafety.blocked) {
      store.addAudit(body.userId || 'anonymous', 'ai_prompt_abuse_blocked', body.characterId || 'character-chat', promptSafety);
    }
    return sendJson(res, 200, store.generateCharacterChatReply({ ...body, promptSafety }));
  }

  if (method === 'POST' && pathname === '/api/voice/tts-placeholder') {
    const body = await parseBody(req);
    return sendJson(res, 200, store.synthesizeVoicePlaceholder(body));
  }

  if (method === 'POST' && pathname === '/api/voice/stt-placeholder') {
    const body = await parseBody(req);
    return sendJson(res, 200, store.transcribeSpeechPlaceholder(body));
  }

  if (method === 'GET' && pathname === '/api/mentors') {
    return sendJson(res, 200, store.getMentors());
  }

  if (method === 'GET' && pathname === '/api/career-coach/styles') {
    return sendJson(res, 200, store.getCoachStyles());
  }

  if (method === 'GET' && pathname === '/api/career-coach/roadmaps') {
    return sendJson(res, 200, store.getCareerRoadmaps());
  }

  if (method === 'GET' && pathname === '/api/skill-trees') {
    return sendJson(res, 200, store.getSkillTrees());
  }

  if (method === 'GET' && pathname === '/api/scenario-packs') {
    return sendJson(res, 200, store.getScenarioPackCatalog());
  }

  params = getParam(pathname, '/api/scenario-packs/:packId');
  if (method === 'GET' && params) {
    const pack = store.getScenarioPack(params.packId);
    return pack ? sendJson(res, 200, pack) : notFound(res);
  }

  params = getParam(pathname, '/api/scenario-packs/:packId/download');
  if (method === 'GET' && params) {
    const pack = store.getScenarioPack(params.packId);
    if (!pack) return notFound(res);
    return sendJson(res, 200, { pack, offline: pack.offline || {}, downloadedAt: new Date().toISOString() });
  }


  if (method === 'GET' && pathname === '/api/adaptive/prompt-template') {
    return sendJson(res, 200, {
      version: 'adaptive_story_v1',
      template: store.getAdaptivePromptTemplate(),
      publishPolicy: 'Drafts must be reviewed by an admin before they can become playable content.',
    });
  }

  if (method === 'POST' && pathname === '/api/adaptive/drafts') {
    const body = await parseBody(req);
    const promptSafety = inspectPromptAbuse(body);
    if (promptSafety.blocked) {
      return sendJson(res, 400, { error: 'Adaptive prompt blocked by abuse protection.', promptSafety });
    }
    const draft = store.createAdaptiveStoryDraft({ ...body, promptSafety }, 'adaptive_story_engine');
    return sendJson(res, 201, draft);
  }


  if (method === 'GET' && pathname === '/api/config/feature-flags') {
    return sendJson(res, 200, store.getFeatureFlags());
  }

  if (method === 'GET' && pathname === '/api/monetization/feature-state') {
    return sendJson(res, 200, store.getMonetizationFeatureState());
  }

  if (method === 'GET' && pathname === '/api/monetization/products') {
    return sendJson(res, 200, store.getProductCatalog());
  }

  params = getParam(pathname, '/api/monetization/premium-preview/:productId');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getPremiumPreview({ productId: params.productId, userId: url.searchParams.get('userId') || 'anonymous' }));
  }

  params = getParam(pathname, '/api/users/:userId/entitlements');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getUserEntitlements(params.userId));
  }

  params = getParam(pathname, '/api/users/:userId/entitlements/check');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.checkEntitlement(params.userId, body));
  }

  params = getParam(pathname, '/api/users/:userId/purchases/placeholder');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.createPurchasePlaceholder(params.userId, body, 'purchase_placeholder'));
  }

  params = getParam(pathname, '/api/users/:userId/subscriptions/placeholder');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.createPurchasePlaceholder(params.userId, body, 'subscription_placeholder'));
  }

  params = getParam(pathname, '/api/users/:userId/certificates/payment-placeholder');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.createPurchasePlaceholder(params.userId, body, 'certificate_payment_placeholder'));
  }

  params = getParam(pathname, '/api/users/:userId/corporate-license/placeholder');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.createPurchasePlaceholder(params.userId, body, 'corporate_license_placeholder'));
  }

  params = getParam(pathname, '/api/users/:userId/purchases/restore');
  if (method === 'POST' && params) {
    return sendJson(res, 200, store.restorePurchasesPlaceholder(params.userId));
  }


  if (method === 'GET' && pathname === '/api/analytics/catalog') {
    return sendJson(res, 200, store.getAnalyticsCatalog());
  }

  if (method === 'POST' && pathname === '/api/analytics/events') {
    const body = await parseBody(req);
    return sendJson(res, 201, store.recordAnalyticsEvent(body));
  }

  params = getParam(pathname, '/api/users/:userId/analytics/events');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getAnalyticsEvents({ userId: params.userId, limit: Number(url.searchParams.get('limit') || 100) }));
  }

  params = getParam(pathname, '/api/users/:userId/analytics/dashboard');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getPersonalAnalyticsDashboard(params.userId));
  }

  params = getParam(pathname, '/api/users/:userId/analytics/settings');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getAnalyticsSettings(params.userId));
  }
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.saveAnalyticsSettings(params.userId, body));
  }

  if (method === 'GET' && pathname === '/api/config/remote-defaults') {
    return sendJson(res, 200, store.getRemoteConfigDefaults());
  }

  if (method === 'GET' && pathname === '/api/content/manifest') {
    return sendJson(res, 200, store.getContentManifest());
  }

  if (method === 'GET' && pathname === '/api/assets/manifest-version') {
    return sendJson(res, 200, store.getAssetManifestVersion());
  }

  if (method === 'GET' && pathname === '/api/role-plugins') {
    return sendJson(res, 200, store.getRolePlugins());
  }

  if (method === 'GET' && pathname === '/api/offline-cache/strategy') {
    return sendJson(res, 200, store.getOfflineCacheStrategy());
  }

  if (method === 'GET' && pathname === '/api/safety-review/workflow') {
    return sendJson(res, 200, store.getSafetyReviewWorkflow());
  }

  if (method === 'GET' && pathname === '/api/scenario-validation/pipeline') {
    return sendJson(res, 200, store.getScenarioValidationPipelineSummary());
  }

  const i18nParams = getParam(pathname, '/api/i18n/:locale');
  if (method === 'GET' && i18nParams) {
    return sendJson(res, 200, store.getLocalization(i18nParams.locale));
  }

  params = getParam(pathname, '/api/roles/:roleId/chapters');
  if (method === 'GET' && params) {
    const chapters = store.getChaptersByRole(params.roleId);
    return chapters ? sendJson(res, 200, chapters) : notFound(res);
  }

  params = getParam(pathname, '/api/chapters/:chapterId/scenario');
  if (method === 'GET' && params) {
    const scenario = store.getScenarioByChapter(params.chapterId);
    return scenario ? sendJson(res, 200, scenario) : notFound(res);
  }

  params = getParam(pathname, '/api/users/:userId/progress');
  if (method === 'GET' && params) {
    return sendJson(res, 200, { userId: params.userId, progress: store.getProgress(params.userId) });
  }
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    const progress = store.saveProgress(params.userId, body.progress || body);
    return sendJson(res, 200, { userId: params.userId, progress });
  }

  if (method === 'GET' && pathname === '/api/badges') {
    return sendJson(res, 200, store.getBadges());
  }

  params = getParam(pathname, '/api/users/:userId/scores');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    const saved = store.saveScore(params.userId, body);
    return sendJson(res, 201, saved);
  }



  if (method === 'GET' && pathname === '/api/interview/questions') {
    return sendJson(res, 200, store.getInterviewQuestionBank(url.searchParams.get('roleId') || ''));
  }

  params = getParam(pathname, '/api/interview/questions/:roleId');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getInterviewQuestionBank(params.roleId));
  }

  if (method === 'POST' && pathname === '/api/interview/feedback') {
    const body = await parseBody(req);
    return sendJson(res, 200, store.generateInterviewFeedback(body));
  }

  params = getParam(pathname, '/api/users/:userId/interview-reports');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getInterviewReports(params.userId));
  }
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 201, store.saveInterviewReport(params.userId, body));
  }

  if (method === 'GET' && pathname === '/api/assessments') {
    return sendJson(res, 200, store.getAssessmentCatalog(url.searchParams.get('roleId') || ''));
  }

  params = getParam(pathname, '/api/assessments/:roleId');
  if (method === 'GET' && params) {
    const assessment = store.getAssessmentForRole(params.roleId);
    return assessment ? sendJson(res, 200, { assessment }) : notFound(res);
  }

  if (method === 'POST' && pathname === '/api/assessment-sessions') {
    const body = await parseBody(req);
    return sendJson(res, 201, store.createAssessmentSession(body));
  }

  params = getParam(pathname, '/api/assessment-sessions/:sessionId');
  if (method === 'GET' && params) {
    const session = store.getAssessmentSession(params.sessionId);
    return session ? sendJson(res, 200, { session }) : notFound(res);
  }

  params = getParam(pathname, '/api/assessment-sessions/:sessionId/answer');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.submitAssessmentAnswer(params.sessionId, body));
  }

  params = getParam(pathname, '/api/assessment-sessions/:sessionId/complete');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.completeAssessmentSession(params.sessionId, body));
  }

  params = getParam(pathname, '/api/users/:userId/certificates');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getCertificateRecords(params.userId));
  }

  params = getParam(pathname, '/api/certificates/:verificationId/pdf');
  if (method === 'GET' && params) {
    const pdf = store.renderCertificatePdf(params.verificationId);
    return pdf ? sendText(res, 200, pdf, 'application/pdf') : notFound(res);
  }

  params = getParam(pathname, '/api/certificates/:verificationId');
  if (method === 'GET' && params) {
    const certificate = store.getCertificateByVerificationId(params.verificationId);
    return certificate ? sendJson(res, 200, { certificate }) : notFound(res);
  }


  if (method === 'GET' && pathname === '/api/organizations') {
    return sendJson(res, 200, store.getOrganizations());
  }

  if (method === 'POST' && pathname === '/api/organizations') {
    const body = await parseBody(req);
    return sendJson(res, 201, store.createOrganization(body));
  }

  params = getParam(pathname, '/api/organizations/:organizationId');
  if (method === 'GET' && params) {
    const organization = store.getOrganization(params.organizationId);
    return organization ? sendJson(res, 200, { organization }) : notFound(res);
  }

  params = getParam(pathname, '/api/organizations/:organizationId/batches');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getBatches(params.organizationId));
  }
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 201, store.createBatch(params.organizationId, body));
  }

  params = getParam(pathname, '/api/organizations/:organizationId/assignments');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getAssignments(params.organizationId));
  }
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 201, store.createAssignment(params.organizationId, body));
  }

  params = getParam(pathname, '/api/organizations/:organizationId/progress');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.recordTraineeProgress(params.organizationId, body));
  }

  params = getParam(pathname, '/api/organizations/:organizationId/dashboard');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getOrganizationDashboard(params.organizationId));
  }

  params = getParam(pathname, '/api/organizations/:organizationId/reports/export');
  if (method === 'GET' && params) {
    const report = store.exportOrganizationReport(params.organizationId, url.searchParams.get('format') || 'json');
    return sendText(res, 200, report.body, report.contentType);
  }

  params = getParam(pathname, '/api/organizations/:organizationId/scenario-packs');
  if (method === 'GET' && params) {
    return sendJson(res, 200, store.getOrganizationScenarioPacks(params.organizationId));
  }

  if (method === 'GET' && pathname === '/api/team-sessions') {
    return sendJson(res, 200, store.getTeamSessions());
  }

  if (method === 'POST' && pathname === '/api/team-sessions') {
    const body = await parseBody(req);
    return sendJson(res, 201, store.createTeamSession(body));
  }

  if (method === 'POST' && pathname === '/api/team-sessions/join') {
    const body = await parseBody(req);
    return sendJson(res, 200, store.joinTeamSession(body.roomCode || body.code, body));
  }

  params = getParam(pathname, '/api/team-sessions/code/:roomCode');
  if (method === 'GET' && params) {
    const session = store.getTeamSessionByCode(params.roomCode);
    return session ? sendJson(res, 200, session) : notFound(res);
  }

  params = getParam(pathname, '/api/team-sessions/:sessionId');
  if (method === 'GET' && params) {
    const session = store.getTeamSession(params.sessionId);
    return session ? sendJson(res, 200, session) : notFound(res);
  }

  params = getParam(pathname, '/api/team-sessions/:sessionId/select-role');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.selectTeamRole(params.sessionId, body));
  }

  params = getParam(pathname, '/api/team-sessions/:sessionId/start');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.startTeamSession(params.sessionId, body));
  }

  params = getParam(pathname, '/api/team-sessions/:sessionId/decisions');
  if (method === 'POST' && params) {
    const body = await parseBody(req);
    return sendJson(res, 200, store.submitTeamDecision(params.sessionId, body));
  }

  if (method === 'POST' && pathname === '/api/admin/login') {
    const body = await parseBody(req);
    if (body.username === config.adminUsername && body.password === config.adminPassword) {
      const token = createToken(body.username);
      const role = body.role && getPermissions(body.role).length ? body.role : 'super_admin';
      const createdAt = new Date();
      const expiresAt = new Date(createdAt.getTime() + config.adminTokenTtlMinutes * 60 * 1000);
      const session = { username: body.username, role, permissions: getPermissions(role), createdAt: createdAt.toISOString(), expiresAt: expiresAt.toISOString(), tokenHash: crypto.createHash('sha256').update(token).digest('hex') };
      sessions.set(token, session);
      store.addAudit(body.username, 'admin_login_success', 'admin-session', { role, expiresAt: session.expiresAt });
      return sendJson(res, 200, { token, username: body.username, role, expiresAt: session.expiresAt, permissions: session.permissions });
    }
    store.addAudit(body.username || 'unknown', 'admin_login_failed', 'admin-login', { requestId: getRequestId(res) });
    return sendJson(res, 401, { error: 'Invalid admin credentials.' });
  }

  if (pathname.startsWith('/api/admin')) {
    const admin = requireAdmin(req, res, pathname, method);
    if (!admin) return;



    if (method === 'GET' && pathname === '/api/admin/security/status') {
      return sendJson(res, 200, store.getSecurityStatus({ activeAdminSessions: sessions.size }));
    }

    if (method === 'GET' && pathname === '/api/admin/analytics/dashboard') {
      return sendJson(res, 200, store.getAdminAnalyticsDashboard());
    }

    if (method === 'POST' && pathname === '/api/admin/security/prompt-inspect') {
      const body = await parseBody(req);
      const result = inspectPromptAbuse(body.prompt || body);
      store.addAudit(admin.username, 'ai_prompt_inspected', 'security-prompt-inspect', result);
      return sendJson(res, 200, result);
    }

    if (method === 'GET' && pathname === '/api/admin/content-moderation') {
      return sendJson(res, 200, store.getContentModerationQueue());
    }

    if (method === 'POST' && pathname === '/api/admin/content-moderation') {
      const body = await parseBody(req);
      return sendJson(res, 201, store.createContentModerationItem(body, admin.username));
    }

    params = getParam(pathname, '/api/admin/content-moderation/:itemId/approve');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      return sendJson(res, 200, store.setContentModerationStatus(params.itemId, 'approved', body.notes || '', admin.username));
    }

    params = getParam(pathname, '/api/admin/content-moderation/:itemId/reject');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      return sendJson(res, 200, store.setContentModerationStatus(params.itemId, 'rejected', body.notes || '', admin.username));
    }

    if (method === 'GET' && pathname === '/api/admin/backups') {
      return sendJson(res, 200, store.getBackupRecords());
    }

    if (method === 'POST' && pathname === '/api/admin/backups') {
      return sendJson(res, 201, store.createBackup(admin.username));
    }

    params = getParam(pathname, '/api/admin/backups/:backupId/restore');
    if (method === 'POST' && params) {
      return sendJson(res, 200, store.restoreBackup(params.backupId, admin.username));
    }

    if (method === 'GET' && pathname === '/api/admin/error-events') {
      return sendJson(res, 200, store.getErrorEvents());
    }

    if (method === 'GET' && pathname === '/api/admin/monetization/products') {
      return sendJson(res, 200, store.getProductCatalog({ includeInactive: true }));
    }

    if (method === 'GET' && pathname === '/api/admin/scenario-packs') {
      return sendJson(res, 200, store.getScenarioPackCatalog({ includeUnpublished: true }));
    }

    if (method === 'POST' && pathname === '/api/admin/scenario-packs') {
      const body = await parseBody(req);
      return sendJson(res, 201, store.upsertScenarioPack(body, admin.username));
    }

    params = getParam(pathname, '/api/admin/scenario-packs/:packId');
    if ((method === 'PUT' || method === 'POST') && params) {
      const body = await parseBody(req);
      return sendJson(res, 200, store.upsertScenarioPack({ ...body, id: params.packId }, admin.username));
    }

    params = getParam(pathname, '/api/admin/scenario-packs/:packId/preview');
    if (method === 'GET' && params) {
      const pack = store.getScenarioPack(params.packId, { includeUnpublished: true });
      return pack ? sendJson(res, 200, pack) : notFound(res);
    }

    params = getParam(pathname, '/api/admin/scenario-packs/:packId/publish');
    if (method === 'POST' && params) {
      try {
        return sendJson(res, 200, store.setScenarioPackPublishState(params.packId, true, admin.username));
      } catch (error) {
        return sendJson(res, error.statusCode || 400, { error: error.message, validation: error.validation });
      }
    }

    params = getParam(pathname, '/api/admin/scenario-packs/:packId/unpublish');
    if (method === 'POST' && params) {
      return sendJson(res, 200, store.setScenarioPackPublishState(params.packId, false, admin.username));
    }

    params = getParam(pathname, '/api/admin/scenario-packs/:packId/reviews');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      return sendJson(res, 201, store.createScenarioPackReview(params.packId, body, admin.username));
    }

    if (method === 'GET' && pathname === '/api/admin/scenario-pack-reviews') {
      return sendJson(res, 200, store.getScenarioPackReviews());
    }

    if (method === 'GET' && pathname === '/api/admin/roles') {
      return sendJson(res, 200, store.getRoles({ includeUnpublished: true }));
    }

    if (method === 'GET' && pathname === '/api/admin/adaptive-drafts') {
      return sendJson(res, 200, store.getAdaptiveStoryDrafts());
    }

    params = getParam(pathname, '/api/admin/adaptive-drafts/:draftId/approve');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      const draft = store.setAdaptiveStoryDraftStatus(
        params.draftId,
        'approved_for_manual_publish',
        body.notes || '',
        admin.username,
      );
      return sendJson(res, 200, draft);
    }

    params = getParam(pathname, '/api/admin/adaptive-drafts/:draftId/reject');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      const draft = store.setAdaptiveStoryDraftStatus(
        params.draftId,
        'rejected',
        body.notes || '',
        admin.username,
      );
      return sendJson(res, 200, draft);
    }

    if (method === 'POST' && pathname === '/api/admin/roles') {
      const body = await parseBody(req);
      const role = store.upsertRole(body, admin.username);
      return sendJson(res, 201, role);
    }

    params = getParam(pathname, '/api/admin/roles/:roleId');
    if (method === 'PUT' && params) {
      const body = await parseBody(req);
      const role = store.upsertRole({ ...body, id: params.roleId }, admin.username);
      return sendJson(res, 200, role);
    }

    params = getParam(pathname, '/api/admin/roles/:roleId/chapters');
    if (method === 'GET' && params) {
      const chapters = store.getChaptersByRole(params.roleId, { includeUnpublished: true });
      return chapters ? sendJson(res, 200, chapters) : notFound(res);
    }
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      const chapter = store.upsertChapter(params.roleId, body, admin.username);
      return sendJson(res, 201, chapter);
    }

    params = getParam(pathname, '/api/admin/chapters/:chapterId/scenario');
    if (method === 'PUT' && params) {
      const body = await parseBody(req);
      const found = store.findChapter(params.chapterId, { includeUnpublished: true });
      if (!found) return notFound(res);
      const validation = validateChapter({ ...body, id: params.chapterId, roleName: found.roleScenario.role.name });
      if (!validation.valid) return sendJson(res, 400, { error: 'Invalid scenario.', validation });
      const nextChapter = { ...body, id: params.chapterId, isPublished: body.isPublished === true };
      const index = found.roleScenario.chapters.findIndex((item) => item.id === params.chapterId);
      found.roleScenario.chapters[index] = nextChapter;
      store.saveRoleScenario(found.roleScenario, found.roleScenario.__fileName);
      store.addAudit(admin.username, 'scenario_updated', params.chapterId, { title: body.title });
      return sendJson(res, 200, nextChapter);
    }

    params = getParam(pathname, '/api/admin/scenarios/:scenarioId/preview');
    if (method === 'GET' && params) {
      const scenario = store.getScenarioByChapter(params.scenarioId, { includeUnpublished: true });
      return scenario ? sendJson(res, 200, scenario) : notFound(res);
    }

    params = getParam(pathname, '/api/admin/scenarios/:scenarioId/publish');
    if (method === 'POST' && params) {
      try {
        return sendJson(res, 200, store.setPublishState(params.scenarioId, true, admin.username));
      } catch (error) {
        return sendJson(res, error.statusCode || 400, { error: error.message, validation: error.validation });
      }
    }

    params = getParam(pathname, '/api/admin/scenarios/:scenarioId/unpublish');
    if (method === 'POST' && params) {
      return sendJson(res, 200, store.setPublishState(params.scenarioId, false, admin.username));
    }

    if (method === 'POST' && pathname === '/api/admin/ai-reviews') {
      const body = await parseBody(req);
      const promptSafety = inspectPromptAbuse(body);
      if (promptSafety.blocked) {
        return sendJson(res, 400, { error: 'AI review blocked by prompt abuse protection.', promptSafety });
      }
      return sendJson(res, 201, store.createAiReview({ ...body, promptSafety }, admin.username));
    }

    if (method === 'GET' && pathname === '/api/admin/ai-reviews') {
      return sendJson(res, 200, store.getAiReviews());
    }

    params = getParam(pathname, '/api/admin/ai-reviews/:reviewId/approve');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      return sendJson(res, 200, store.setAiReviewStatus(params.reviewId, 'approved', body.notes || '', admin.username));
    }

    params = getParam(pathname, '/api/admin/ai-reviews/:reviewId/reject');
    if (method === 'POST' && params) {
      const body = await parseBody(req);
      return sendJson(res, 200, store.setAiReviewStatus(params.reviewId, 'rejected', body.notes || '', admin.username));
    }

    if (method === 'GET' && pathname === '/api/admin/audit-logs') {
      return sendJson(res, 200, store.getAuditLogs());
    }
  }

  return notFound(res);
}

const server = http.createServer(async (req, res) => {
  res.requestId = req.headers['x-request-id'] || crypto.randomUUID();
  const startedAt = Date.now();
  try {
    const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
    if (url.pathname.startsWith('/api/')) {
      if (!enforceRateLimit(req, res, cleanPathname(url.pathname))) return;
      const result = await handleApi(req, res, url);
      if (Date.now() - startedAt > 3000) {
        store.addAudit('system', 'slow_request_observed', cleanPathname(url.pathname), { durationMs: Date.now() - startedAt, requestId: getRequestId(res) });
      }
      return result;
    }
    if (url.pathname === '/' || url.pathname.startsWith('/admin')) {
      return sendStatic(req, res, url.pathname === '/' ? '/admin/index.html' : url.pathname);
    }
    return sendStatic(req, res, url.pathname);
  } catch (error) {
    if (config.crashMonitoringEnabled) {
      store.recordErrorEvent({
        requestId: getRequestId(res),
        source: 'backend',
        message: error.message || 'Unexpected server error.',
        stack: error.stack,
        statusCode: error.statusCode || 500,
      });
    }
    return sendJson(res, error.statusCode || 500, {
      error: error.message || 'Unexpected server error.',
      validation: error.validation,
      requestId: getRequestId(res),
    });
  }
});

if (require.main === module) {
  server.listen(config.port, config.host, () => {
    console.log(`Career Chaos Academy Node.js API running at http://${config.host}:${config.port}`);
    console.log(`Admin panel: http://localhost:${config.port}/admin/`);
  });
}

module.exports = { server, store };
