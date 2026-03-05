---
description: One-stop quality gate — runs lint, type checking, and affected tests before pushing
---

# /scout:pre-push

Run every quality check in one command. Clear pass/fail gate.

## Usage
```
/scout:pre-push          # Run lint + typecheck + affected tests
```

## Steps

1. Invoke the **pre-push-gate** agent.

2. The agent runs lint, type checking, and affected tests in sequence, reporting pass/fail for each.

3. If the gate fails, offer to fix the issues automatically.
