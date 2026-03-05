---
description: QA health dashboard — test results, coverage trends, and agent activity
---

# /scout:status

Quick health snapshot of your project's QA state.

## Steps

### 1. Load State
Read `context/qa/agent-state.json`. If it doesn't exist, say "No QA data yet. Run `/scout:test` to get started."

### 2. Agent Activity
For each agent, show last run time and summary:
```
Agent Activity:
  test-runner ........... 2h ago (12 runs) — 24 passed, 0 failed
  coverage-checker ...... 1d ago (3 runs)  — 85% changed-line coverage
  test-writer ........... 3d ago (1 run)   — wrote 7 tests, 6 passing
  pre-push-gate ......... 30m ago (8 runs) — PASS
```

### 3. Current Quality
From the most recent agent runs:
- Last test result (pass/fail counts)
- Last coverage on changed lines
- Last pre-push gate result
- Known flaky tests count

### 4. Quality Score
Compute a simple score:
- **GREEN** — last tests all passed, coverage >80% on changed lines, pre-push passed
- **YELLOW** — some tests failing or coverage 50-80%, or pre-push hasn't run recently
- **RED** — many test failures, coverage <50%, or pre-push failed last time

```
Quality: GREEN
  ✓ All 24 tests passing
  ✓ 85% coverage on changed lines
  ✓ Pre-push gate passed
  ⚠ 2 known flaky tests (tracked)
```

### 5. Suggested Actions
1-3 context-aware suggestions based on the data.
