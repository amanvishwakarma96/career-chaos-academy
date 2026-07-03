# Career Chaos Academy Adaptive Story Prompt Template v1

Generate a **draft-only** adaptive side mission for Career Chaos Academy.

Input context may include user behavior patterns, weak skills, strong skills, story flags, role reputation, relationship scores, failed mini-games, completed chapters, and preferred roles.

Output valid JSON only using the app scenario schema. Required fields:
- roleId
- title
- difficulty
- theme
- scenario/story
- choices
- outcomes
- moralLesson
- professionalLearningPoint
- scoreImpact
- safetyReview
- mustNotAutoPublish: true
- requiresAdminReview: true

Safety rules:
- Drafts must never auto-publish.
- Medical content must not diagnose, prescribe, recommend dosage, or replace a clinician.
- Legal/financial content must not provide legal conclusions, guaranteed returns, or regulated advice.
- Engineering/safety content must prioritize inspection, documentation, escalation, and qualified review.
- HR content must avoid discriminatory or protected-attribute advice.
- Humor must exaggerate professional mistakes, not trivialize unsafe outcomes.
