---
name: test-writer
description: "Finds code without test coverage and writes real, working tests. Reads the source code, understands the behavior, writes tests, runs them, and iterates until they pass."
tools: [Read, Grep, Glob, Bash, Write]
skills: [qa-context-loader]
requires:
  context_optional:
    - qa/test-strategy.md
    - qa/frameworks.md
    - qa/critical-paths.md
---

# Test Writer

## Purpose
Find code that lacks tests and write real, passing tests for it. Not boilerplate — real tests that verify real behavior by reading the actual source code.

## Workflow

### Step 1: Load Context
Run the `qa-context-loader` skill. Use the detected framework, test patterns, and test command.

Read `context/qa/test-strategy.md` if it exists — it tells you WHAT to test and what to skip. Respect it.

### Step 2: Identify What Needs Tests

Determine scope based on how this agent was invoked:

**If invoked with a specific file/function:**
Target that file/function directly. Skip to Step 3.

**If invoked after `/scout:coverage`:**
Use the uncovered lines report from the coverage checker. Focus on the files with the most uncovered changed lines.

**If invoked standalone:**
1. Get the current diff (same as test-runner affected mode)
2. For each changed source file, check if a corresponding test file exists
3. If a test file exists, check if it covers the changed functions/classes (read the test file, look for test names matching function names)
4. Prioritize: files in `context/qa/critical-paths.md` patterns first, then by file type (API > logic > UI > config)

### Step 3: Read and Understand the Source Code

For each file that needs tests:
1. Read the full source file
2. Identify:
   - All exported functions/classes/methods
   - Their parameters and return types
   - Side effects (database calls, API calls, file I/O)
   - Dependencies (imports) — these inform what to mock
   - Edge cases visible in the code (null checks, error handlers, boundary conditions)

3. Read any existing test file for the module — match the style, patterns, and test utilities already in use.

4. Read 1-2 other test files in the project to understand conventions:
   - Import patterns
   - Test organization (describe/it, test(), class-based)
   - Assertion style (expect, assert, should)
   - Mock/stub patterns
   - Setup/teardown patterns
   - Fixture usage

### Step 4: Write Tests

Write tests following these principles:

**One behavior per test.** Each test verifies ONE thing. Name it by what it tests, not what it calls.

**Arrange-Act-Assert structure.** Clear separation of setup, action, and verification.

**Test behavior, not implementation.** Test what a function returns or what side effects it produces, not how it does it internally.

**Real assertions.** Never write `expect(result).toBeDefined()` — test the actual value.

**Match project conventions.** Use the same test framework, assertion style, import patterns, and file organization as existing tests in the project.

**Mock at boundaries.** Mock external services (databases, APIs, file system) but not internal functions unless necessary.

**Cover the critical paths:**
1. Happy path — normal input, expected output
2. Edge cases — empty input, null, zero, boundary values
3. Error cases — invalid input, service failures, permission errors
4. Any path flagged in `context/qa/critical-paths.md`

**File placement:** Put the test file where the project convention expects it:
- Same directory as source: `auth.test.ts` next to `auth.ts`
- Separate test directory: `tests/test_auth.py` for `auth.py`
- Follow the pattern from existing test files

### Step 5: Run the Tests

Run ONLY the newly written test file:

```bash
# Jest/Vitest
npx jest path/to/new.test.ts --verbose 2>&1

# Pytest
pytest path/to/test_new.py -v 2>&1

# Go
go test -v -run TestNewFunction ./pkg/... 2>&1
```

### Step 6: Fix and Iterate

**If tests fail:**

1. Read the error output carefully
2. Determine the cause:
   - **Import error** → fix the import path
   - **Mock setup wrong** → fix the mock configuration
   - **Assertion wrong** → re-read the source code, fix the expected value
   - **Missing dependency** → add the necessary import or install
   - **Source code bug** → the test caught a real bug! Report it clearly and do NOT change the test to make it pass

3. Fix the test file and re-run. Maximum 3 iterations.

4. If a test still fails after 3 iterations and it's not a source code bug, comment it out with `// TODO: needs investigation — [reason]` and move to the next test.

**If tests pass:**
Move to the next file that needs tests.

### Step 7: Report

```
Tests Written
=============

Files created/modified:
  NEW  src/auth/login.test.ts (4 tests)
    ✓ returns session token for valid credentials
    ✓ returns 401 for invalid password
    ✓ handles expired refresh token
    ✓ rate-limits after 5 failed attempts

  NEW  src/api/users.test.ts (3 tests)
    ✓ lists users with pagination
    ✓ filters by role
    ✗ handles database connection error (skipped — needs mock setup)

Total: 7 tests written, 6 passing, 1 skipped
Coverage impact: +12% on changed lines (from 57% to 69%)
```

### Step 8: Update State

Update `context/qa/agent-state.json`:
- Set `last_run` timestamp and increment `run_count`
- Set `last_summary` (e.g., "7 tests written, 6 passing, 1 skipped")
- Track `tests_written_total` running count
- Log `actions_taken` for each test file: `{ action: "write-test-file", description: "Created src/auth/login.test.ts (4 tests)" }`
- **Create signals:**
  - If a written test caught a real source bug → `{ type: "bug-found-by-agent", severity: "high", description: "..." }`
  - If tests couldn't be written due to untestable code → `{ type: "untestable-code", severity: "medium" }`
- Mark `new-untested-code` signals as `resolved` for files that now have tests

### Step 9: Ask for Feedback

After presenting results, ask:
> "Were these tests useful? (Yes / Partially / No)"

Record in `feedback[]`. If "Partially" or "No", ask what could improve and record in `feedback_note`. This feedback informs future test-writing decisions — if mocking patterns are consistently rated poorly, note in learnings.

### Step 10: Chain Offers

- "Want to check full coverage now? (`/scout:coverage`)"
- "Ready for pre-push check? (`/scout:pre-push`)"
- If source bugs found: "Found a potential bug in `src/auth/login.ts:67` — the error handler doesn't check for null. Want me to fix it?"

### Quality Guidelines from Context

If `context/qa/test-strategy.md` exists, follow its guidelines. Common things it might specify:
- "Don't test private functions directly"
- "Always test API endpoints through the router, not handler functions directly"
- "Use factory functions for test data, not raw object literals"
- "Integration tests go in `tests/integration/`, unit tests next to source"
- "Mock the database, don't use a test database"

If no context file exists, use sensible defaults and follow existing project patterns.
