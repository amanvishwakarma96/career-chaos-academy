# Security Policy

## Supported status

The repository is an advanced prototype and has not completed an external penetration test. Security issues should be handled privately and must not be posted in public issue trackers.

## Reporting a vulnerability

Report vulnerabilities directly to the repository owner or organization security contact. Include:

- Affected area and version/commit.
- Reproduction steps.
- Expected and actual behavior.
- Security impact.
- Suggested mitigation, when available.

Do not include real user data, production credentials, access tokens, or exploit details in a public issue.

## Secret handling

Never commit:

- `.env` files.
- Access, refresh, admin, or API tokens.
- Passwords, OTPs, private keys, keystores, or signing credentials.
- Firebase service accounts or payment-provider secrets.
- Production database exports.
- Runtime audit logs, analytics events, interview reports, voice conversations, certificates, or team sessions.

Development defaults in `.env.example` are placeholders only and must be replaced in every shared or deployed environment.

## Production security gates

Before production release:

- Replace in-memory sessions and rate limiting with a shared managed store.
- Migrate runtime JSON persistence to a managed database with encryption and backups.
- Use TLS everywhere and restrictive CORS allowlists.
- Use HTTP-only, Secure, SameSite cookies for admin web sessions where applicable.
- Rotate and centrally manage secrets.
- Complete dependency scanning, static analysis, penetration testing, and restore drills.
- Implement user data export, deletion, and anonymization.
- Validate payment receipts and provider webhooks server-side.
- Review AI, voice, and professional-content safety controls.

See `docs/phase35_production_deployment_checklist.md` for the complete checklist.
