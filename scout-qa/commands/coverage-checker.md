---
description: Run the coverage-checker agent directly
---

# /scout:coverage-checker

Invoke the **coverage-checker** agent directly. Runs tests with coverage and cross-references with git diff to report only changed-line coverage.

## Usage
```
/scout:coverage-checker          # Coverage for changed lines
/scout:coverage-checker all      # Full project coverage
```

## Steps

1. Parse `$ARGUMENTS`:
   - No arguments → scope to **changed lines**
   - `all` → report **full project** coverage

2. Invoke the **coverage-checker** agent.
3. Present coverage report and chain offers.
