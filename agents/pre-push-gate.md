---
name: pre-push-gate
description: "One-stop quality gate before pushing. Runs lint, type checking, and affected tests. Reports pass/fail for each step with clear fix instructions."
tools: [Read, Grep, Glob, Bash, Write]
skills: [qa-context-loader, failure-patterns]
requires:
  context_optional:
    - qa/test-strategy.md
    - qa/frameworks.md
---

# Pre-Push Gate

## Purpose
Run every quality check before you push — lint, type check, and affected tests — in one command. Clear pass/fail for each step with actionable fix instructions.

## Workflow

### Step 1: Load Context
Run the `qa-context-loader` skill. Use detected framework, lint, and typecheck tools.

### Step 2: Determine Changed Files

```bash
git diff --name-only $(git merge-base HEAD main) 2>/dev/null || git diff --name-only HEAD~1
```

Filter to source files (exclude test files, docs, config, assets for lint/typecheck scope).

If no changed files, report "No changes to check" and exit.

### Step 3: Run Lint (if available)

Run the detected linter scoped to changed files only:

**ESLint:**
```bash
npx eslint src/auth/login.ts src/api/users.ts 2>&1
```

**Ruff:**
```bash
ruff check src/auth/login.py src/api/users.py 2>&1
```

**golangci-lint:**
```bash
golangci-lint run ./pkg/auth/... ./pkg/api/... 2>&1
```

**RuboCop:**
```bash
bundle exec rubocop src/auth/login.rb src/api/users.rb 2>&1
```

If no linter detected, skip this step and note "No linter detected — skipping."

Parse output: count errors and warnings. Classify as PASS (0 errors) or FAIL.

### Step 4: Run Type Check (if available)

**TypeScript:**
```bash
npx tsc --noEmit 2>&1
```

Note: TypeScript type checking is project-wide (can't scope to files). This is expected.

**MyPy:**
```bash
mypy src/auth/login.py src/api/users.py 2>&1
```

**Pyright:**
```bash
pyright src/auth/login.py src/api/users.py 2>&1
```

If no type checker detected, skip and note "No type checker detected — skipping."

Parse output: count errors. Classify as PASS (0 errors) or FAIL.

### Step 5: Run Affected Tests

Use the same affected-test logic as the test-runner agent (mode: affected):
1. Map changed source files to test files
2. Run only those test files
3. Parse results into structured pass/fail

If no test files map to changed files, note "No affected tests found — all source changes are untested."

### Step 6: Report

Present a clear gate result:

```
Pre-Push Check
==============

  Lint .................. PASS (0 errors, 2 warnings)
  Type Check ............ PASS (0 errors)
  Affected Tests ........ FAIL (11 passed, 1 failed)

  Gate: FAIL — fix 1 test failure before pushing

Failed Test:
  test_user_authentication (tests/test_auth.py:45)
    AssertionError: expected status 200, got 401
    → The login endpoint returns 401 when valid credentials are provided.
```

Or if everything passes:

```
Pre-Push Check
==============

  Lint .................. PASS (0 errors, 0 warnings)
  Type Check ............ PASS (0 errors)
  Affected Tests ........ PASS (15 passed, 0 failed)

  Gate: PASS — safe to push
```

Gate logic:
- **PASS** — all steps pass (or skipped steps don't count against it)
- **FAIL** — any step has errors (warnings don't fail the gate)

### Step 7: Update State

Update `context/qa/agent-state.json`:
- Set `last_run` timestamp and increment `run_count`
- Set `last_summary` with gate result (e.g., "PASS — lint ok, types ok, 15 tests passed")
- Track `consecutive_passes` — how many times pre-push passed in a row
- Track `last_failure_reason` if it failed
- Log `actions_taken`: `{ action: "pre-push-gate", description: "PASS — lint(0 errors), types(0 errors), tests(15 passed)" }`
- **Create signals:**
  - If gate failed on same step 3+ times → `{ type: "persistent-failure", severity: "high", description: "Pre-push gate failing on [step] repeatedly" }`
  - If lint errors are in a file not owned by current developer (from `ownership.md`) → `{ type: "cross-ownership-issue", severity: "medium" }`

### Step 8: Next Steps

**If PASS:**
- "All clear. Push when ready."
- If there were lint warnings: "Consider fixing 2 lint warnings before pushing (non-blocking)."

**If FAIL — lint:**
- Show the specific lint errors with file and line
- "Want me to fix these lint errors?"

**If FAIL — type check:**
- Show the type errors
- "Want me to fix these type errors?"

**If FAIL — tests:**
- Show the failed tests
- "Want me to investigate and fix the failing test?"
- If failure looks like a test setup issue: "This looks like a test issue, not a code bug. Want me to fix the test?"
- If failure looks like a real bug: "This test may have caught a real bug. Want me to investigate?"

### Error Handling
- Tool not installed → skip that step, note it was skipped
- Tests timeout → kill after 5 minutes, report FAIL with timeout reason
- Permission errors → suggest checking file permissions
