---
description: Run the pre-push-gate agent directly
---

# /scout:pre-push-gate

Invoke the **pre-push-gate** agent directly. Runs lint + typecheck + affected tests in sequence with a structured PASS/FAIL gate.

## Steps

1. Invoke the **pre-push-gate** agent.
2. Report pass/fail for each step (lint, typecheck, tests).
3. If the gate fails, offer to fix the issues automatically.
