const crypto = require('crypto');
const { config } = require('./config');

const SENSITIVE_KEYS = new Set([
  'password', 'token', 'authorization', 'secret', 'apiKey', 'api_key', 'email', 'phone',
  'mobile', 'address', 'otp', 'refreshToken', 'refresh_token', 'accessToken', 'access_token',
]);

const ROLE_PERMISSIONS = {
  super_admin: ['*'],
  content_admin: [
    'content:read', 'content:write', 'content:publish', 'content:moderate', 'ai:review',
    'audit:read', 'security:read', 'monitoring:read', 'backup:create',
  ],
  trainer_admin: [
    'content:read', 'organization:manage', 'reports:export', 'analytics:read',
    'audit:read', 'security:read', 'monitoring:read',
  ],
  auditor: ['audit:read', 'security:read', 'monitoring:read', 'content:read'],
};

const PATH_PERMISSION_RULES = [
  { match: /^\/api\/admin\/login$/, permission: 'public' },
  { match: /^\/api\/admin\/audit-logs$/, permission: 'audit:read' },
  { match: /^\/api\/admin\/security/, permission: 'security:read' },
  { match: /^\/api\/admin\/error-events$/, permission: 'monitoring:read' },
  { match: /^\/api\/admin\/backups\/?$/, permission: (method) => method === 'POST' ? 'backup:create' : 'security:read' },
  { match: /^\/api\/admin\/backups\/[^/]+\/restore$/, permission: 'backup:restore' },
  { match: /^\/api\/admin\/content-moderation/, permission: 'content:moderate' },
  { match: /^\/api\/admin\/scenario-packs\/[^/]+\/(publish|unpublish)$/, permission: 'content:publish' },
  { match: /^\/api\/admin\/scenarios\/[^/]+\/(publish|unpublish)$/, permission: 'content:publish' },
  { match: /^\/api\/admin\/scenario-packs/, permission: (method) => method === 'GET' ? 'content:read' : 'content:write' },
  { match: /^\/api\/admin\/roles/, permission: (method) => method === 'GET' ? 'content:read' : 'content:write' },
  { match: /^\/api\/admin\/chapters/, permission: 'content:write' },
  { match: /^\/api\/admin\/scenarios/, permission: (method) => method === 'GET' ? 'content:read' : 'content:publish' },
  { match: /^\/api\/admin\/ai-reviews/, permission: 'ai:review' },
  { match: /^\/api\/admin\/adaptive-drafts/, permission: 'content:moderate' },
  { match: /^\/api\/admin\/analytics/, permission: 'analytics:read' },
  { match: /^\/api\/admin\//, permission: 'content:read' },
];

function getPermissions(role) {
  return ROLE_PERMISSIONS[role] || [];
}

function hasPermission(session, permission) {
  if (!permission || permission === 'public') return true;
  const permissions = Array.isArray(session.permissions) ? session.permissions : getPermissions(session.role);
  return permissions.includes('*') || permissions.includes(permission);
}

function permissionForRequest(pathname, method) {
  for (const rule of PATH_PERMISSION_RULES) {
    if (rule.match.test(pathname)) {
      return typeof rule.permission === 'function' ? rule.permission(method) : rule.permission;
    }
  }
  return pathname.startsWith('/api/admin') ? 'content:read' : 'public';
}

function hashValue(value) {
  return crypto.createHash('sha256').update(String(value || '')).digest('hex');
}

function redactValue(key, value, depth = 0) {
  const normalizedKey = String(key || '').toLowerCase();
  if (SENSITIVE_KEYS.has(normalizedKey) || [...SENSITIVE_KEYS].some((item) => normalizedKey.includes(item.toLowerCase()))) {
    return '[redacted]';
  }
  if (depth > 4) return '[max-depth]';
  if (Array.isArray(value)) return value.slice(0, 25).map((item) => redactValue(key, item, depth + 1));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([childKey, childValue]) => [childKey, redactValue(childKey, childValue, depth + 1)]));
  }
  if (typeof value === 'string') {
    return value
      .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[redacted-email]')
      .replace(/\b(?:\+?\d[\d\s-]{7,}\d)\b/g, '[redacted-phone]')
      .slice(0, config.maxStoredTextLength || 2000);
  }
  return value;
}

function sanitizeForAudit(details = {}) {
  return redactValue('details', details);
}

function inspectPromptAbuse(input = {}) {
  const raw = typeof input === 'string' ? input : JSON.stringify(input || {});
  const lower = raw.toLowerCase();
  const patterns = [
    { key: 'prompt_injection', severity: 'high', terms: ['ignore previous instructions', 'system prompt', 'developer message', 'reveal hidden', 'jailbreak'] },
    { key: 'credential_exfiltration', severity: 'high', terms: ['dump token', 'steal password', 'api key', 'session cookie', 'refresh token'] },
    { key: 'evidence_hiding', severity: 'high', terms: ['delete logs', 'hide evidence', 'cover tracks', 'bypass audit'] },
    { key: 'unsafe_professional_advice', severity: 'medium', terms: ['prescribe dosage', 'guaranteed profit', 'forge document', 'fake certificate'] },
  ];
  const matches = patterns.filter((pattern) => pattern.terms.some((term) => lower.includes(term)));
  return {
    blocked: matches.some((match) => match.severity === 'high'),
    status: matches.length ? 'needs_review' : 'safe',
    matches: matches.map(({ key, severity }) => ({ key, severity })),
    safeMessage: matches.length
      ? 'This content needs human review because it may request unsafe, abusive, or out-of-scope behavior.'
      : 'No prompt abuse pattern detected.',
  };
}

function validateBodyShape(pathname, method, body) {
  const errors = [];
  if (['POST', 'PUT', 'PATCH'].includes(method)) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      errors.push('Request body must be a JSON object.');
    }
  }

  if (pathname === '/api/admin/login') {
    if (typeof body.username !== 'string' || !body.username.trim()) errors.push('username is required.');
    if (typeof body.password !== 'string' || !body.password) errors.push('password is required.');
  }
  if (pathname === '/api/analytics/events') {
    if (typeof body.eventType !== 'string' || !body.eventType.trim()) errors.push('eventType is required.');
    if (body.durationSeconds !== undefined && (!Number.isFinite(Number(body.durationSeconds)) || Number(body.durationSeconds) < 0)) {
      errors.push('durationSeconds must be a non-negative number.');
    }
  }
  if (pathname === '/api/voice/character-chat') {
    if (typeof body.message !== 'string' || !body.message.trim()) errors.push('message is required.');
    if (!body.scenarioContext || typeof body.scenarioContext !== 'object') errors.push('scenarioContext is required.');
  }
  if (pathname === '/api/admin/content-moderation') {
    if (method === 'POST' && typeof body.title !== 'string') errors.push('title is required for moderation items.');
  }
  return { valid: errors.length === 0, errors };
}

function createSecurityHeaders(requestId) {
  return {
    'X-Request-Id': requestId,
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    'Content-Security-Policy': "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; connect-src 'self'",
  };
}

class InMemoryRateLimiter {
  constructor() {
    this.buckets = new Map();
  }

  check({ key, limit, windowMs }) {
    const now = Date.now();
    const current = this.buckets.get(key);
    if (!current || current.resetAt <= now) {
      this.buckets.set(key, { count: 1, resetAt: now + windowMs });
      return { allowed: true, remaining: Math.max(0, limit - 1), resetAt: now + windowMs };
    }
    current.count += 1;
    if (current.count > limit) {
      return { allowed: false, remaining: 0, resetAt: current.resetAt };
    }
    return { allowed: true, remaining: Math.max(0, limit - current.count), resetAt: current.resetAt };
  }
}

module.exports = {
  ROLE_PERMISSIONS,
  getPermissions,
  hasPermission,
  permissionForRequest,
  hashValue,
  sanitizeForAudit,
  inspectPromptAbuse,
  validateBodyShape,
  createSecurityHeaders,
  InMemoryRateLimiter,
};
