# AGENTS.md

Purpose: guide AI coding agents in this repository.
This file is an agent routing layer and should stay concise. Canonical policy remains in existing docs.

## Canonical Sources (always load first)

1. `README.md`
2. `PR_RULES_OF_ENGAGEMENT.md`
3. `CODE_OF_CONDUCT.md`

If guidance conflicts, the contribution policy is authoritative for PR/Issue behavior.

## Operating Principles

- Prefer practical, minimal, reviewable changes.
- Preserve contributor intent and local conventions.
- If confidence is low, use the issue-first path defined in the contribution policy.

## Context Discovery Rule (all products)

Before editing any file:

1. Identify the target product area and read the nearest product-level README.
2. Read the nearest script/folder README for local usage and constraints.
3. If present, load local context guides (for example `Instructions.md`, `03 Context/`, `Notes/`) before code generation.
4. Apply naming/execution/runtime rules defined in that area only.

## Contribution Workflow

- Follow the contribution policy checklist before proposing PR-ready output.
- Keep one change theme per branch/PR and consolidate repeated patterns.
- Prefer updating existing docs and linking canonical sources over creating parallel policy docs.

## Path and Runtime Safety

- Avoid introducing new machine-specific hardcoded paths unless explicitly required.
- Verify UI vs Exchange/CLI/runtime assumptions against local docs before changing behavior.

## Verification and Reporting

- Provide concise, review-oriented verification evidence (changed files, behavior impact, validation method).
- State uncertainty explicitly when full validation is not possible.

## Agent Conduct

- Never push to remote unless explicitly asked by the user.
