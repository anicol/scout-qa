---
description: Check QA readiness — framework detection, context files, tools, agent health, and feedback trends
---

# /scout:doctor

Diagnostic command that checks everything Scout QA needs to work.

## Steps

### 1. Framework Detection
Run framework detection (from `qa-context-loader`). Report:
- Detected test framework and version
- Test command that would be used
- Coverage command available
- Whether the test command actually works (run it with `--help` or `--version`)

### 2. Context Files
Check `context/qa/` for all 10 files:

| File | Purpose | Impact if Missing |
|------|---------|-------------------|
| `test-strategy.md` | Testing philosophy | test-writer produces generic tests |
| `conventions.md` | Naming, assertions, mocking | test-writer won't match your style |
| `critical-paths.md` | High-risk code areas | risk-analyzer uses defaults only |
| `coverage-policy.md` | Coverage thresholds | coverage-checker can't enforce tiers |
| `ownership.md` | Who owns which code | no ownership routing |
| `frameworks.md` | Framework config | relies on auto-detection |
| `risk-config.yaml` | Risk weights | uses default weights |
| `autonomy.yaml` | Agent permissions | defaults to all autonomous |
| `learnings/what-works.md` | Proven patterns | agents don't learn from history |
| `learnings/what-doesnt.md` | Anti-patterns | agents repeat known mistakes |

For each file: **Ready** (>50 words, <3 placeholders), **Needs work** (mostly placeholders), or **Missing**.

### 3. Tooling
Check for:
- `which node` / `which python3` / `which go` / `which ruby` — runtime
- Lint tool available and working
- Type checker available and working
- Coverage tool installed
- `which git` — git available
- `which gh` — GitHub CLI (for PR operations)

### 4. Test Infrastructure
- Count total test files in the project
- Count source files without corresponding test files
- Estimate overall test coverage (by file count, not line count)

### 5. Git Hooks
Check if Scout hooks are installed:
- `.git/hooks/pre-commit` — contains "Scout QA"?
- `.git/hooks/pre-push` — contains "Scout QA"?
- `.claude/settings.local.json` — contains Scout Claude Code hooks?

### 6. Agent State
Read `context/qa/agent-state.json` if it exists:
- Per-agent: last run, run count, last summary
- Active signals (count and top 3 by severity)
- Known flaky tests
- Feedback trends: per-agent average rating (Yes=1, Partially=0.5, No=0)
- Actions taken (total count)

### 7. Output Report

```
Scout QA Health Check
=====================

Framework:
  Detected .................. Jest 29.7 via package.json
  Test command .............. npx jest --verbose
  Coverage command .......... npx jest --coverage
  Status .................... OK (test command verified)

Tooling:
  Runtime ................... Node 20.11.0
  Lint ...................... ESLint 8.56 (npx eslint)
  Type Check ................ TypeScript 5.3 (npx tsc --noEmit)
  Coverage .................. Built-in (Jest)
  Git ....................... 2.43.0
  GitHub CLI ................ 2.40.0

Context Files (10):
  test-strategy.md .......... Ready (180 words, 0 placeholders)
  conventions.md ............ Needs work (12 words, 8 placeholders)
  critical-paths.md ......... Needs work (15 words, 5 placeholders)
  coverage-policy.md ........ Missing
  ownership.md .............. Missing
  frameworks.md ............. Ready (auto-detected)
  risk-config.yaml .......... Ready (defaults)
  autonomy.yaml ............. Ready (defaults)
  learnings/what-works.md ... Missing
  learnings/what-doesnt.md .. Missing

  Score: 4/10 files ready (fill in conventions.md and critical-paths.md for biggest impact)

Git Hooks:
  Pre-commit ................ Not installed
  Pre-push .................. Not installed
  Claude Code hooks ......... Not installed

  Run /scout:install-hooks to wire into git pipeline.

Test Infrastructure:
  Test files ................ 47
  Source files .............. 128
  Files without tests ....... 81 (63%)

Agent State:
  risk-analyzer ............. Last run: 1h ago (3 runs) — Score 7/10
  test-runner ............... Last run: 2h ago (5 runs) — 24 passed, 0 failed
  coverage-checker .......... Never run
  test-writer ............... Never run
  pre-push-gate ............. Last run: 1d ago (3 runs) — PASS

  Active Signals: 2
    [HIGH] untested-critical-path: src/auth/login.ts has no tests
    [MEDIUM] flaky-test: test_payment_webhook (ConnectionRefused)

  Feedback: 8 ratings (avg 0.81 — agents are useful)
  Actions: 14 total logged

Overall: READY (with gaps)
  Priority: Fill in conventions.md → install hooks → run /scout:full-check
```

### 8. Suggest Next Action
- If framework not detected → "Can't detect your test framework. Create `context/qa/frameworks.md` manually or run `/scout:init`."
- If no context files → "Run `/scout:init` to set up context files."
- If context files have placeholders → suggest the highest-impact file to fill (priority: critical-paths > conventions > test-strategy > coverage-policy > ownership > learnings)
- If hooks not installed → "Run `/scout:install-hooks` to wire into git pipeline."
- If agents have low feedback scores → "Agent [name] has low feedback (0.3). Consider tuning context files or risk-config.yaml."
- If everything is ready → "All good. Try `/scout:full-check` to run the complete pipeline."
