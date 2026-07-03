# Phase 35 Privacy and Data Retention Rules

Career Chaos Academy should collect only the data needed to deliver learning progress, enterprise assignments, certificates, and safety review.

## Do not store in logs or audit details
- Raw passwords
- Access tokens, refresh tokens, admin tokens, OTPs, API keys, or secrets
- Emails and phone numbers in admin aggregate views
- Full raw stack traces in prototype error records
- Unredacted free-text where users may paste sensitive personal information

## Allowed operational records
- Role/chapter progress
- Scenario decisions and score outcomes
- Certificate verification records
- Organization assignment progress
- Privacy-safe analytics events when analytics are enabled
- Admin audit events with sensitive fields redacted
- Content moderation status and safety notes

## User controls
- Analytics can be disabled.
- Aggregate sharing can be disabled.
- User data export, deletion, and anonymization must be implemented before production launch.

## Retention defaults
- Runtime learning data: retain while account is active.
- Audit logs: retain according to security policy, default 365 days.
- Backups: retain in rolling windows and verify deletion after retention window.
- Error events: retain only enough for support and stability triage; store stack hash instead of raw trace.

## Admin visibility
Admin dashboards should show aggregated progress, trends, and moderation state. They should not expose raw user IDs, names, contact details, answers, tokens, or secrets unless there is a specific support workflow and authorization gate.
