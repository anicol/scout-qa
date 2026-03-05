---
name: risk-analyzer
description: "Scores the risk of current changes (1-10) using a structured algorithm. Categorizes files, detects security/payment code, matches critical paths, and factors in change size."
tools: [Read, Grep, Glob, Bash]
skills: [qa-context-loader]
requires:
  context_optional:
    - qa/critical-paths.md
    - qa/risk-config.yaml
---

# Risk Analyzer

## Purpose
Score how risky the current changes are on a 1-10 scale. Not a vibe check — a deterministic, multi-factor algorithm that categorizes files, detects sensitive code patterns, checks critical paths, and factors in change size. This gives you a structured risk assessment before deciding how much QA attention to invest.

## Why This Exists
Claude Code can look at a diff and give you an opinion. This agent gives you a **repeatable, structured score** with weighted factors, so you can make consistent decisions about QA investment. A 2/10 docs change doesn't need the same testing as a 9/10 auth + payments change.

## Workflow

### Step 1: Load Context
Run the `qa-context-loader` skill.

Read `context/qa/critical-paths.md` if it exists — extract glob patterns for high-priority and medium-priority code areas.

Read `context/qa/risk-config.yaml` if it exists — override default risk weights and thresholds.

### Step 2: Get Changed Files

Get the full diff with stats:

```bash
git diff --numstat $(git merge-base HEAD main 2>/dev/null || echo HEAD~1) | head -200
```

Also get the file names with status:

```bash
git diff --name-status $(git merge-base HEAD main 2>/dev/null || echo HEAD~1) | head -200
```

Parse into a list of files with: `path`, `status` (A/M/D/R), `additions`, `deletions`.

If no changed files, return score 1 with `skip: true, skip_reason: "No files changed"`.

### Step 3: Categorize Files

Classify each changed file into exactly one category using these rules (first match wins):

| Category | Pattern |
|----------|---------|
| **infra** | `.github/`, `dockerfile`, `docker-compose`, `terraform`, `.gitlab-ci`, `jenkinsfile`, `render.yaml`, `vercel.json`, `netlify.toml`, `fly.toml`, CI/CD configs |
| **docs** | `*.md`, `docs/`, `*/docs/*` |
| **test** | `test`, `spec`, `__tests__`, `e2e`, `cypress`, `playwright` in path |
| **ui** | `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.html`, `*.css`, `*.scss` |
| **api** | `routes`, `controllers`, `handlers`, `views`, `api/`, `endpoints` in path |
| **config** | `*.json`, `*.yml`, `*.yaml`, `*.toml`, `*.env` |
| **logic** | Everything else (business logic, utilities, models) |

### Step 4: Check for Skip Condition

If the only categories with files are `infra`, `docs`, and/or `test` — no functional code changed. Return:
- Score: 1
- Skip: true
- Skip reason: "Only [infrastructure/documentation/test] changes — no functional code affected"

### Step 5: Calculate Risk Factors

Apply these factors sequentially. Each adds points to a raw score.

**Factor 1: Category-based scoring**

Default weights (overridable via `risk-config.yaml`):

| Category | Weight |
|----------|--------|
| api | 2.0 |
| logic | 1.5 |
| ui | 1.0 |
| config | 0.8 |
| infra | 0.3 |
| test | 0.1 |
| docs | 0.1 |

For each category: `points = min(weight * file_count * 0.5, 3.0)` (capped at 3 per category).

**Factor 2: Critical path matching**

If `context/qa/critical-paths.md` exists, extract glob patterns from the "High Priority" section. For each changed file matching a critical path pattern: +2.0 points per file.

If no context file, use these default critical patterns:
- `**/auth/**`, `**/authentication/**`, `**/login/**`
- `**/payment**`, `**/billing/**`, `**/checkout/**`

**Factor 3: Security-sensitive code**

Check each changed file against these patterns:
- `**/auth/**`, `**/authentication/**`, `**/authorization/**`
- `**/login/**`, `**/session/**`, `**/token/**`, `**/jwt/**`
- `**/oauth/**`, `**/password/**`, `**/credential**`
- `**/security/**`, `**/crypto/**`, `**/encrypt**`

If any match: `points = min(matching_count * 1.5, 3.0)`.

**Factor 4: Payment/financial code**

Check each changed file against:
- `**/payment**`, `**/billing/**`, `**/checkout/**`
- `**/stripe/**`, `**/paypal/**`, `**/subscription**`
- `**/invoice**`, `**/transaction**`

If any match: `points = min(matching_count * 2.0, 4.0)`.

**Factor 5: Change size**

```
total_changes = total_additions + total_deletions
large_threshold = 500  (overridable via risk-config.yaml)

if total_changes >= large_threshold:
    points = min((total_changes / large_threshold) * 1.0, 2.0)
```

**Factor 6: Many files changed**

```
if file_count >= 10:
    points = min((file_count / 10) * 0.5, 1.5)
```

### Step 6: Normalize Score

```
normalized = min(10, max(1, int(raw_score * 0.7) + 1))
```

Map to risk level:
- 1-3: **Low** — minimal QA needed
- 4-6: **Medium** — run affected tests, check coverage
- 7-8: **High** — full test suite, write tests for gaps, coverage analysis
- 9-10: **Critical** — full pipeline, manual review recommended

### Step 7: Report

```
Risk Analysis
=============

Score: 7/10 (High)

Factors:
  +1.50  3 api file(s) changed
  +1.50  2 logic file(s) changed
  +2.00  Critical path affected: src/auth/login.ts
  +1.50  Security-related code changed (1 file)
  +1.00  Large change (623 lines, +412/-211)

File Categories:
  API:    src/api/users.ts, src/api/payments.ts, src/api/auth.ts
  Logic:  src/services/billing.ts, src/utils/validate.ts
  UI:     src/components/LoginForm.tsx
  Config: .env.example

Critical Paths Affected:
  src/auth/login.ts (matches: **/auth/**)
  src/api/payments.ts (matches: **/payment**)

Recommendation:
  Risk 7/10 — run full test suite, check coverage on changed lines,
  and write tests for any uncovered auth/payment code before merging.
```

### Step 8: QA Recommendation

Based on the score, recommend specific actions:

| Score | Recommendation |
|-------|---------------|
| 1-3 | "Low risk. Run `/scout:test` to verify, then push." |
| 4-6 | "Medium risk. Run `/scout:test` and `/scout:coverage` before pushing." |
| 7-8 | "High risk. Run `/scout:full-check` for the complete QA pipeline." |
| 9-10 | "Critical risk. Run `/scout:full-check`. Consider manual review of security/payment changes." |

### Step 9: Update State

Update `context/qa/agent-state.json`:
- Set `last_run` timestamp and increment `run_count`
- Set `last_summary` (e.g., "Risk 7/10 (High) — auth + payment code changed")
- Store `last_score` and `last_level`
- Track `scores_history` (last 5 scores for trend)
- Log `actions_taken`: `{ action: "analyze-risk", description: "Score 7/10, 3 api + 2 logic files, auth critical path" }`
- **Create signals:**
  - If score jumped 4+ points from previous run → `{ type: "risk-score-spike", severity: "high" }`
  - If critical path affected but no tests exist for it → `{ type: "untested-critical-path", severity: "critical" }`
  - If security or payment code changed → `{ type: "sensitive-code-changed", severity: "high" }`

### Step 10: Ask for Feedback

After presenting results, ask:
> "Was this risk assessment accurate? (Yes / Partially / No)"

Record in `feedback[]`. If "No", ask what was wrong and record. Persistent "No" feedback on risk scores suggests the weights in `risk-config.yaml` need tuning — offer to adjust them.
