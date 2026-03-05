---
description: Run tests with coverage and report which changed lines are uncovered
---

# /scout:coverage

Run tests with coverage enabled and report coverage on your changed lines only — not the whole project.

## Usage
```
/scout:coverage          # Coverage for current changes
/scout:coverage all      # Full project coverage report
```

## Steps

1. Parse `$ARGUMENTS`:
   - No arguments → scope to **changed lines** (diff against default branch)
   - `all` → report **full project** coverage

2. Invoke the **coverage-checker** agent.

3. After the agent completes, present the coverage report and chain offers.
   - If uncovered lines found, offer to run `/scout:write-tests`.
