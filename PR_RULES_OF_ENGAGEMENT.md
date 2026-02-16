# Pull Request Rules of Engagement

How to propose PRs in this repository (human or AI-assisted).

Goal: improve script quality and user experience while respecting contributors and minimizing PR/issue noise.

---

## PR gate (author checklist)

Only open a PR if all are true:

- [ ] Objective + reproducible; low-risk + clearly scoped; clear user benefit; quick to review
- [ ] Tight scope: one theme; minimal diff; no accidental formatting churn
- [ ] Consolidated per “Consolidation & scope (no spam)”
- [ ] Tracking follows the Issue policy below (link if exists; otherwise “No issue (direct PR)”)
- [ ] PR body includes required content below
- [ ] Contributor tags (if any) are confirmed GitHub handles only
- [ ] You can explain every change in your own words

## Issue policy (pragmatic)

- Link an existing Issue when one exists (use closing keywords like `Closes #42` / `Fixes #15` / `Resolves #108`; cross-repo: `Fixes owner/repository#123`).
- Direct PRs are fine for clear, low-risk fixes (including AI-assisted). Don’t open an Issue just to restate the PR.
- Open an Issue first when you need discussion/triage: uncertain report, behavior change, design/API decision, broad refactor.
- If confidence is low, start with an Issue — not a PR.

Good direct-PR candidates (when clear + low-risk):

- Broken launcher or path reference.
- Documentation references a file that does not exist.
- UI script docs instruct command-line execution when the script requires UI context.
- Broken links, typos, wrong paths.

## Tone (required)

- Be respectful and collaborative; thank original contributors where relevant.
- Be non-alarmist; assume current behavior may be intentional (legacy/version constraints).
- Be explicit about uncertainty (you may be wrong); ask maintainers to validate intent.
- Describe user impact and risk clearly (prefer substance over style).

Avoid: "critical flaw", "broken design", "bad code"  
Prefer: "alignment", "clarification", "worth investigation", "may be intentional due to legacy/version constraints"

## Consolidation & scope (no spam)

This is a public repository. AI tools can surface the same pattern across dozens of files. **Do not open a separate PR or Issue for every instance.**

- **One pattern = one thread.** If 30 files are affected, describe the pattern once (Issue and/or PR) and list all affected locations in one place.
- Group related changes by a single theme.
- Maximum **3 open PRs** per author at a time (excludes drafts).
- Do not open broad speculative cleanup PRs.

Applies to Issues and PRs.

Non-goals (scope limits):

- Do not rewrite large script sets in one PR.
- Do not make speculative behavior changes without maintainer validation.
- Do not mix unrelated fixes in one PR.

## Required PR body content

PRs missing required items may be returned.

### AI disclosure (required for AI-assisted PRs)

A human name on a PR does not mean a human performed the analysis. Omitting AI involvement when AI did the substantive work is misrepresentation.

Place this **at the top** of every AI-assisted PR body:

> **AI Disclosure:** This PR was opened by [Your Name]. The analysis and proposed changes were generated with AI assistance. I reviewed the findings, verified [specific verification], and take responsibility for this submission.
>
> This may be a red herring. The current behavior may be intentional due to legacy or version-specific constraints. Treat this as a suggestion for investigation, not a definitive defect report.

### Tracking

- `Fixes #123` (if applicable), or
- `No issue (direct PR)`

### Show changes (required)

Use before/after code blocks (or a diff) so reviewers can see the actual difference without opening files:

**Before:**
```ruby
path = 'results/output'
```

**After:**
```ruby
path = File.join(__dir__, 'results', 'output')
```

Or:

```diff
- path = 'results/output'
+ path = File.join(__dir__, 'results', 'output')
```

### Verification evidence (required)

Include proof that the change is valid. PRs without evidence will be returned.

- **Code/path issues:** show the file reference and what it resolves to.
- **Script changes:** terminal output or screenshot showing before/after behavior.
- **Documentation fixes:** link to the specific file/line in the repo.

### Contributor tagging rules

- Tag only confirmed GitHub handles.
- Do not guess usernames.
- If handle mapping is uncertain, ask maintainers to confirm.
- Prefer tagging current maintainers and confirmed original authors of affected files.
- Do not tag the Issue opener by default. Tag them only if they are also a maintainer or an original author of an affected file.

## PR body template (copy + fill in)

~~~markdown
> (If AI-assisted) Paste the **AI Disclosure** block from this document at the very top.

## Tracking
- Fixes #[number] (if applicable)
- No issue (direct PR)

## Summary
[One-sentence description of the observed problem.]

## Changes
**Before:**
```[language]
[existing code]
```

**After:**
```[language]
[proposed code]
```

## Why This May Be Intentional
[Explain possible reasons the current behavior is correct.]

## Evidence
[Screenshots, terminal output, or file/line links.]

## Impact & Risk
[Scope and risk level: Low / Medium / High]

## Files Changed
- `path/to/file1`
- `path/to/file2`

## Maintainer Validation
Requesting review from @[maintainer] (thanks for the original work).
~~~

## Review workflow

When reviewing:

1. Confirm AI disclosure is present and at the top (if applicable).
2. Confirm tracking is correct. If no issue is linked, confirm the PR is self-contained.
3. Review by PR theme, not file order.
4. Confirm changed-file allowlist.
5. Validate each change is objective and low-risk.
6. Confirm before/after code blocks match the actual diff.
7. Confirm evidence is included.
8. Confirm no accidental formatting churn.
9. Confirm tagging follows policy: affected-file originators/maintainers only, not the Issue opener by default.
