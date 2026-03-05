---
description: Full QA pipeline — risk analysis, test, coverage, write tests for gaps, pre-push gate
---

# /scout:full-check

Run the complete QA pipeline end-to-end. Risk score determines how deep the pipeline goes.

## Usage
```
/scout:full-check        # Run full pipeline (adapts depth to risk)
/scout:full-check --deep # Force full depth regardless of risk
```

## Steps

Sequential multi-agent orchestration. Each step feeds into the next. The pipeline adapts based on risk — low-risk changes get a lighter check, high-risk changes get the full treatment.

### 1. Risk Analysis

Invoke the **risk-analyzer** agent. Score the changes (1-10).

If `skip: true` (docs/infra/test-only changes):
- Report: "Only [infrastructure/docs/test] changes. Skipping QA pipeline."
- Skip to Step 5 (summary) with a minimal report.

Risk score determines pipeline depth:
- **1-3 (Low):** Run steps 2 + 5 only (affected tests + summary)
- **4-6 (Medium):** Run steps 2 + 3 + 5 (tests + coverage + summary)
- **7-10 (High/Critical):** Run all steps (tests + coverage + write tests + pre-push + summary)
- **`--deep` flag:** Run all steps regardless of risk score

### 2. Run Affected Tests

Invoke the **test-runner** agent in **affected** mode.

- If tests fail with **real_bug** category: Stop pipeline. Report failures. Offer to investigate.
- If tests fail with **test_bug** category: Offer to fix tests and continue.
- If tests fail with **flaky** category: Note them and continue.
- If all tests pass: Continue to next step.

### 3. Check Coverage (if risk >= 4 or --deep)

Invoke the **coverage-checker** agent on changed lines.

Report uncovered areas. Flag any files matching critical paths from `context/qa/critical-paths.md`.

### 4. Write Tests for Gaps (if risk >= 7 or --deep)

If uncovered lines were found in step 3, ask: "Want to write tests for the gaps?"

- If yes: Invoke **test-writer** for uncovered files, prioritizing critical paths.
- If no: Continue to step 5.

If the risk score is 9-10 (Critical): Recommend writing tests without asking.

### 5. Pre-Push Gate (if risk >= 7 or --deep)

Invoke **pre-push-gate** for final lint + typecheck + test validation.

### 6. Summary

```
Full QA Check Complete
======================

  Risk Score ........... 7/10 (High) — auth + payment code changed
  Pipeline Depth ....... Full (all steps run)

  1. Tests .............. PASS (24 passed, 1 flaky)
  2. Coverage ........... 85% on changed lines
  3. Tests Written ...... 4 new tests (all passing, +12% coverage)
  4. Pre-Push Gate ...... PASS (lint ok, types ok, tests ok)

  Critical Paths:
    src/auth/login.ts .... covered (was 57%, now 85%)
    src/api/payments.ts .. covered

  Flaky Tests (tracked):
    test_payment_webhook — ConnectionRefusedError

  Result: Ready to push.
```

Or for low-risk:

```
Full QA Check Complete
======================

  Risk Score ........... 2/10 (Low) — UI-only changes
  Pipeline Depth ....... Light (tests only)

  1. Tests .............. PASS (8 affected tests passed)

  Result: Ready to push.
```
