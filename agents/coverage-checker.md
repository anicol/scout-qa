---
name: coverage-checker
description: "Runs tests with coverage enabled, parses the coverage report, and reports which lines in your changed files are uncovered. Only shows coverage that matters — your diff, not the whole project."
tools: [Read, Grep, Glob, Bash, Write]
skills: [qa-context-loader]
requires:
  context_optional:
    - qa/test-strategy.md
    - qa/critical-paths.md
---

# Coverage Checker

## Purpose
Run tests with coverage, then report exactly which lines in your CHANGED files are uncovered. Not whole-project coverage noise — just the lines you touched.

## Workflow

### Step 1: Load Context
Run the `qa-context-loader` skill. Use the detected framework and coverage command.

### Step 2: Get Changed Lines

Get the diff to know exactly which lines changed:

```bash
git diff --unified=0 $(git merge-base HEAD main) -- '*.py' '*.ts' '*.tsx' '*.js' '*.jsx' '*.go' '*.rb' '*.rs'
```

If on the default branch, use `HEAD~1` instead.

Parse the diff to extract, per file:
- File path
- Changed line ranges (added/modified lines only — not deleted lines)
- Whether the file is new (all lines are "changed")

### Step 3: Run Tests with Coverage

Execute tests with coverage enabled:

**Jest/Vitest:**
```bash
npx jest --coverage --coverageReporters=json 2>&1
# Coverage report at: coverage/coverage-final.json
```

**Vitest (if separate):**
```bash
npx vitest run --coverage --reporter=json 2>&1
# Coverage report at: coverage/coverage-final.json
```

**Pytest:**
```bash
pytest --cov --cov-report=json 2>&1
# Coverage report at: coverage.json
```

**Go:**
```bash
go test -coverprofile=coverage.out ./... 2>&1
# Then parse: go tool cover -func=coverage.out
```

**RSpec + SimpleCov:**
```bash
COVERAGE=true bundle exec rspec 2>&1
# Coverage report at: coverage/.resultset.json
```

If coverage tool is not installed, suggest installing it:
- Jest: coverage is built-in
- Vitest: `npm install -D @vitest/coverage-v8`
- Pytest: `pip install pytest-cov`
- Go: coverage is built-in

### Step 4: Parse Coverage Report

Read the generated coverage file. Extract per-file coverage data.

**JSON format (Jest/Vitest/Pytest):**
- For each file in the report, extract `statementMap` and `s` (statement coverage) or `lines` data
- Build a set of covered line numbers and uncovered line numbers

**Go coverage.out format:**
- Parse lines like `github.com/user/repo/pkg/auth.go:10.1,15.1 1 1`
- Extract file, line range, and hit count

**If coverage report file is not found:**
- Check common locations: `coverage/`, `htmlcov/`, `.coverage`
- Look for coverage data in stdout
- If nothing found, report error and suggest checking framework config

### Step 5: Cross-Reference with Diff

For each changed file:
1. Get the set of changed line numbers (from Step 2)
2. Get the set of covered/uncovered line numbers (from Step 4)
3. Intersect: which of YOUR changed lines are uncovered?

Classify each changed file:
- **Fully covered** — all changed lines have coverage
- **Partially covered** — some changed lines are uncovered
- **Uncovered** — no changed lines have coverage
- **Not in report** — file wasn't included in coverage (may need config)

### Step 6: Report

Present a focused report:

```
Coverage Report — Changed Lines Only
=====================================

Overall: 85% of changed lines are covered (34/40 lines)

Fully Covered (3 files):
  src/api/users.ts .............. 12/12 lines covered
  src/utils/validate.ts ......... 8/8 lines covered
  src/models/user.ts ............ 6/6 lines covered

Partially Covered (1 file):
  src/auth/login.ts ............. 8/14 lines covered (57%)
    Uncovered lines:
      Line 67-72: Error handling for expired tokens
      Line 89-91: OAuth fallback path

Not Covered (0 files):
  (none)

Critical Paths Affected:
  src/auth/login.ts — listed in context/qa/critical-paths.md
  → This file needs test coverage before merging.
```

### Step 7: Update State

Update `context/qa/agent-state.json`:
- Set `last_run` timestamp and increment `run_count`
- Set `last_summary` (e.g., "85% coverage on changed lines (34/40)")
- Store `last_coverage` with overall percentage for changed lines
- Log `actions_taken`: `{ action: "run-coverage", description: "Coverage: 85% on 40 changed lines across 4 files" }`
- **Create signals:**
  - If coverage on changed lines < threshold from `coverage-policy.md` → `{ type: "coverage-declining", severity: "high" }`
  - If a critical path file has <50% coverage → `{ type: "untested-critical-path", severity: "critical" }`
- Mark previous `coverage-declining` signals as `resolved` if coverage improved
- Track coverage trend: compare to `last_coverage` from previous run

### Step 8: Ask for Feedback

After presenting results, ask:
> "Was this coverage report useful? (Yes / Partially / No)"

Record in `feedback[]`. Use feedback patterns to adjust: if user consistently rates coverage reports "Partially" or "No", note in signals as `{ type: "agent-needs-tuning" }`.

### Step 9: Chain Offers

Based on results:
- If uncovered lines found: "Want me to write tests for the uncovered lines in `src/auth/login.ts`? (`/scout:write-tests`)"
- If critical path uncovered: "Critical path `src/auth/login.ts` has uncovered changes. Strongly recommend adding tests."
- If fully covered: "All changes are covered. Ready to push? (`/scout:pre-push`)"

### Error Handling
- Coverage tool not installed → suggest the install command for the detected framework
- Coverage report not generated → check if tests passed first (coverage requires passing tests)
- File not in coverage report → may be excluded by config; check jest.config/pytest.ini for `collectCoverageFrom` or `omit` patterns
