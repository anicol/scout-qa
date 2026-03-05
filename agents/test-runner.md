---
name: test-runner
description: "Smart test runner that auto-detects frameworks, runs tests (all or affected), and returns structured results with pass/fail per test, timing, and actionable error details."
tools: [Read, Grep, Glob, Bash, Write]
skills: [qa-context-loader, failure-patterns]
requires:
  context_optional:
    - qa/test-strategy.md
    - qa/frameworks.md
---

# Test Runner

## Purpose
Run tests intelligently — detect the framework, select the right tests, execute them, and produce clean structured results with actionable error information.

## Modes

This agent supports two modes controlled by the invoking command:

- **all** — Run the full test suite
- **affected** — Run only tests affected by the current git diff

## Workflow

### Step 1: Load Context
Run the `qa-context-loader` skill. Use the detected framework and test command.

If `context/qa/frameworks.md` exists and specifies a custom test command, use that instead of the auto-detected one.

### Step 2: Determine Which Tests to Run

**If mode is "all":**
Skip to Step 3 with the full test command.

**If mode is "affected":**

1. Get the current diff:
   ```bash
   git diff --name-only HEAD~1
   ```
   If on a feature branch, diff against the default branch instead:
   ```bash
   git diff --name-only $(git merge-base HEAD main)
   ```

2. Filter to source files only (exclude test files, config, docs, assets).

3. For each changed source file, find related test files:
   - Exact name match: `src/auth.ts` → look for `src/auth.test.ts`, `src/auth.spec.ts`, `__tests__/auth.test.ts`
   - Directory-level tests: if `src/api/users.py` changed → look for `tests/test_api_users.py`, `tests/api/test_users.py`
   - Import-based: grep test files for imports of the changed module names

4. Also include any test files that were directly changed in the diff.

5. If no related test files found, fall back to running all tests and note why.

6. Build a targeted test command:
   - **Jest/Vitest:** `npx jest --testPathPattern='(auth|users)' --verbose`
   - **Pytest:** `pytest tests/test_auth.py tests/test_users.py -v`
   - **Go:** `go test ./pkg/auth/... ./pkg/users/...`
   - **RSpec:** `bundle exec rspec spec/auth_spec.rb spec/users_spec.rb`

### Step 3: Run Tests

Execute the test command with verbose output enabled. Use a timeout of 5 minutes.

```bash
# Example for Jest
npx jest --verbose --no-coverage 2>&1

# Example for Pytest
pytest -v --tb=short 2>&1

# Example for Go
go test -v ./... 2>&1
```

Capture the full output.

### Step 4: Parse Results

Parse the test output to extract structured results. The format varies by framework:

**Jest/Vitest output patterns:**
- `✓ test name (Xms)` or `PASS` → passed
- `✕ test name` or `FAIL` → failed
- `○ test name` or `skipped` → skipped
- Summary line: `Tests: X passed, Y failed, Z total`

**Pytest output patterns:**
- `PASSED` → passed
- `FAILED` → failed
- `SKIPPED` → skipped
- Summary line: `X passed, Y failed, Z skipped`

**Go test output patterns:**
- `--- PASS:` → passed
- `--- FAIL:` → failed
- `--- SKIP:` → skipped

For each failed test, extract:
- Test name
- File path (if available)
- Error message
- Relevant stack trace (first 10 lines)
- Expected vs actual values (if assertion failure)

Then **categorize each failure** using the `failure-patterns` skill:
- **test_bug** — broken imports, wrong mocks, syntax errors in tests. Fix the test.
- **flaky** — timeouts, connection refused, network errors. Consider retry or mocking.
- **real_bug** — assertion failures with specific value mismatches. Investigate source code.
- **unknown** — no pattern matched. Needs manual investigation.

Include the category and confidence in the report.

### Step 5: Report Results

Present a clear summary:

```
Test Results
============

Framework: Jest | Vitest | Pytest | Go test
Mode: all | affected (X of Y test files)
Duration: Xs

Passed: 24
Failed: 2
Skipped: 1

Failed Tests:
  1. test_user_authentication (tests/test_auth.py:45)
     Category: real_bug (high confidence)
     AssertionError: expected status 200, got 401
     The login endpoint returns 401 when valid credentials are provided.

  2. test_payment_webhook (tests/test_payments.py:112)
     Category: flaky (high confidence)
     ConnectionRefusedError: [Errno 61] Connection refused
     External service dependency — consider mocking the HTTP call.
```

### Step 6: Update State

Update `context/qa/agent-state.json`:
- Set `last_run` timestamp and increment `run_count`
- Set `last_summary` (e.g., "24 passed, 2 failed, 1 skipped")
- Log `actions_taken`: `{ action: "run-tests", description: "Ran 24 affected tests (Jest)" }`
- **Create signals** for persistent issues:
  - If a test fails that also failed in the previous run → `{ type: "persistent-failure", severity: "high" }`
  - If a flaky test is detected → `{ type: "flaky-test", severity: "medium" }`
  - If no test files found for changed source files → `{ type: "new-untested-code", severity: "medium" }`
- Mark previously active signals as `resolved` if the issue is fixed
- Add newly identified flaky patterns to `flaky_tests`

### Step 7: Ask for Feedback

After presenting results, ask:
> "Was this test run useful? (Yes / Partially / No)"

Record the response in `feedback[]` with timestamp. If the user provides a note, record that too. If the user skips, don't persist anything.

### Step 8: Chain Offers

Based on failure categories:
- **real_bug** failures: "These tests may have caught real bugs. Want me to investigate the source code and fix them?"
- **test_bug** failures: "These are test setup issues (bad imports, wrong mocks). Want me to fix the tests?"
- **flaky** failures: "These look flaky (network/timeout). Want to mark them as known flaky and add proper mocks?"
- **All passed**: "All clear. Want to check coverage on your changes? (`/scout:coverage`)"
- **Mixed categories**: Prioritize real_bug first, then test_bug, then flaky.

### Error Handling
- Test command not found → suggest installing the framework, offer to check package.json/pyproject.toml
- Tests hang or timeout → kill after 5 minutes, report which tests were still running
- No test files found → suggest running `/scout:init` and `/scout:write-tests`
