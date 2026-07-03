# Runtime data

The backend creates development runtime JSON files in this directory for progress, sessions, reports, analytics, certificates, moderation, audit logs, and other mutable state.

These files are intentionally ignored by Git because they may contain user- or admin-related data and are not source-controlled fixtures.

For production, replace this JSON persistence layer with a managed database and encrypted backup strategy.
