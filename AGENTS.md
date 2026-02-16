# AGENTS.md

Purpose: guide AI coding agents working in this repository.
This file complements existing docs and should route agents to canonical sources instead of duplicating them.

## Scope

- Prefer practical, reviewable, verifiable changes.
- Keep contributor intent and existing structure intact.
- Optimize for maintainer review efficiency (clear scope, clear evidence, minimal churn).
- If confidence is low, follow the issue-first path defined in `PR_RULES_OF_ENGAGEMENT.md`.

## Read First (required order)

1. `README.md`
2. `PR_RULES_OF_ENGAGEMENT.md`
3. `CODE_OF_CONDUCT.md`

If editing InfoWorks ICM Ruby, load these before generating code:

1. `01 InfoWorks ICM/01 Ruby/03 Context/InfoWorks_ICM_Ruby_Lessons_Learned.md`
2. `01 InfoWorks ICM/01 Ruby/03 Context/InfoWorks_ICM_Ruby_Pattern_Reference.md`

## Repository Orientation

Top-level product areas:

- `01 InfoWorks ICM`
- `02 InfoAsset Manager`
- `03 ICMLive`
- `04 InfoWorks WS Pro`
- `05 InfoWater Pro`
- `06 XPSWMM`

Common conventions:

- Script folders often use numbered names (`0001 - ...`).
- Preserve existing naming and execution-mode conventions.

## PR and Collaboration Rules

Follow `PR_RULES_OF_ENGAGEMENT.md` exactly. Key reminders:

- One pattern = one Issue + one PR (no repetitive PR/Issue spam).
- AI-assisted PRs require AI disclosure at the top of the PR body.
- Link every PR to Issue(s), except documented small-fix exceptions.
- Provide verification evidence for each change.
- Use respectful, non-alarmist language.

If any reminder here conflicts with `PR_RULES_OF_ENGAGEMENT.md`, the PR rules document is authoritative.

## Documentation Policy

- Prefer updating existing authoritative docs over creating new docs.
- Link to canonical sources instead of copying policy text.
- Keep doc updates focused and avoid parallel "rule" files that conflict.

## Product-Specific Cautions

- InfoAsset Manager Ruby mode conventions (`UI`, `IE`, `UIIE`) are documented in:
  `02 InfoAsset Manager/01 Ruby/README.md`
- ICM/SWMM table and prefix compatibility (`hw_`, `sw_`, `hw_sw`) is documented in:
  `01 InfoWorks ICM/02 SQL/02 SWMM/README_SWMM.md`

## Critical InfoWorks ICM Ruby Guardrails

Before editing Ruby in `01 InfoWorks ICM`, follow context docs above.
Minimum requirements:

- Treat InfoWorks collections as custom collections unless proven otherwise.
- Prefer documented path handling patterns compatible with UI and Exchange.
- Ensure object/structure writes and transaction/commit flow match repo patterns.
- Respect UI-only vs Exchange-only API boundaries.

## Path and Output Safety

- Avoid introducing new hardcoded local machine paths unless explicitly required.
- Prefer script-relative/configurable paths when compatible with runtime context.
- Do not assume workflow-managed branches or generated artifacts should be edited.

## Verification Standard

Before claiming completion:

- Re-check changes against `PR_RULES_OF_ENGAGEMENT.md`.
- Provide concrete evidence (before/after behavior, path resolution, doc reference).
- State uncertainty explicitly where full validation is not possible.

## Agent Conduct

- Never push to remote unless explicitly asked by the user.
- Never include unrelated file churn in a focused change.
- Keep changes minimal, explainable, and easy to review quickly.
