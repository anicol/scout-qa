---
name: failure-patterns
description: Categorizes test failures as real_bug, test_bug, or flaky using heuristic pattern matching
user-invocable: false
---

# Failure Pattern Categorization

When test failures are encountered, classify each failure using these heuristic patterns. Check in order — first match wins.

## Category: test_bug

The test itself is broken (bad imports, wrong setup, stale mocks). Fix the test, not the source code.

**Indicators (check error message and output for these strings, case-insensitive):**

- `modulenotfounderror` — Python module import failure
- `no module named` — Python missing module
- `import error` — general import failure
- `cannot find module` — Node.js module resolution failure
- `module not found` — generic module not found
- `syntaxerror` — syntax error in test code
- `referenceerror` — undefined variable reference
- `undefined is not` — accessing property of undefined
- `is not a function` — calling non-function
- `is not defined` — using undeclared identifier
- `mock` combined with `not called` or `expected` — mock setup issue
- `jest.fn()` — Jest mock configuration error
- `expected mock` — mock expectation failure
- `fixture` combined with `not found` or `error` — test fixture problem
- `before` combined with `hook` or `setup` and `error` — setup hook failure
- `no such file or directory` — test referencing missing file
- `permission denied` — filesystem permission issue in test

## Category: flaky

Non-deterministic failure caused by environment, timing, or external dependencies. Usually passes on retry.

**Indicators:**

- `timeout` — operation timed out
- `timed out` — alternative timeout phrasing
- `econnrefused` — connection refused (external service down)
- `econnreset` — connection reset
- `network` combined with `error` — network failure
- `socket` combined with `error` or `hang up` — socket issue
- `connection refused` — explicit connection failure
- `epipe` — broken pipe
- `enotfound` — DNS resolution failure (BUT check test_bug first — `modulenotfounderror` contains this)
- `etimeout` — connection timeout
- `rate limit` — API rate limiting
- `too many requests` — HTTP 429
- `deadlock` — database deadlock
- `lock` combined with `timeout` — lock acquisition failure
- `resource temporarily unavailable` — OS resource exhaustion
- `flaky` or `intermittent` — explicitly marked as flaky

## Category: real_bug (potential)

The test may have caught an actual bug in the source code. These need investigation — don't auto-fix the test.

**Indicators:**

- `assertionerror` combined with `expected` and `got` or `actual` — assertion comparing values
- `expect(` combined with specific value mismatches — Jest/Vitest assertion
- `assert` combined with `!=` or `==` — Python assertion
- Status code mismatches: `expected 200` with `got 4` or `got 5` — wrong HTTP status
- `null` or `undefined` combined with `expected` and a specific value — null pointer issue
- `typeerror: cannot read` — accessing property of null/undefined (potential source bug)

**Important:** `real_bug` classification is a signal, not a certainty. Report it as "potential real bug — investigate" rather than a definitive categorization.

## Category: unknown

If no patterns match, classify as `unknown`. Report the raw error and suggest the user investigate.

## Confidence Levels

- **high** — Multiple indicators matched, or the indicator is very specific (e.g., `modulenotfounderror` for test_bug)
- **medium** — Single indicator matched, but it's a common pattern
- **low** — Weak signal (e.g., just `assert` without clear context)

## Usage

When reporting failures in any agent:

```
Failed Tests:
  1. test_user_login (tests/test_auth.py:45)
     Category: real_bug (high confidence)
     Error: AssertionError: expected status 200, got 401
     Suggestion: The login endpoint returns wrong status. Investigate the auth handler.

  2. test_payment_webhook (tests/test_payments.py:112)
     Category: flaky (high confidence)
     Error: ConnectionRefusedError: [Errno 61] Connection refused
     Suggestion: External service dependency. Consider mocking the HTTP call.

  3. test_import_feature (tests/test_feature.py:8)
     Category: test_bug (high confidence)
     Error: ModuleNotFoundError: No module named 'features.new_thing'
     Suggestion: The import path is wrong. Check the module name and location.
```
