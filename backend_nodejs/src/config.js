const path = require('path');

const rootDir = path.resolve(__dirname, '..');

const config = {
  port: Number(process.env.PORT || 5085),
  host: process.env.HOST || '0.0.0.0',
  adminUsername: process.env.ADMIN_USERNAME || 'admin',
  adminPassword: process.env.ADMIN_PASSWORD || 'ChangeMe@123',
  adminTokenSecret: process.env.ADMIN_TOKEN_SECRET || 'career-chaos-dev-secret',
  adminTokenTtlMinutes: Number(process.env.ADMIN_TOKEN_TTL_MINUTES || 120),
  maxBodyBytes: Number(process.env.MAX_BODY_BYTES || 1048576),
  maxStoredTextLength: Number(process.env.MAX_STORED_TEXT_LENGTH || 2000),
  rateLimitWindowMs: Number(process.env.RATE_LIMIT_WINDOW_MS || 60000),
  rateLimitMaxRequests: Number(process.env.RATE_LIMIT_MAX_REQUESTS || 120),
  authRateLimitMaxRequests: Number(process.env.AUTH_RATE_LIMIT_MAX_REQUESTS || 10),
  crashMonitoringEnabled: process.env.CRASH_MONITORING_ENABLED !== 'false',
  retentionDays: Number(process.env.RETENTION_DAYS || 365),
  rootDir,
  scenarioDir: path.join(rootDir, 'data', 'scenarios'),
  runtimeDir: path.join(rootDir, 'data', 'runtime'),
  backupDir: path.join(rootDir, 'data', 'runtime', 'backups'),
  publicDir: path.join(rootDir, 'public'),
};

module.exports = { config };
