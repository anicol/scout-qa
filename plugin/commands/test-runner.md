---
description: Run the test-runner agent directly
---

# /scout:test-runner

Invoke the **test-runner** agent directly. Auto-detects framework, runs all or affected tests, categorizes failures.

## Usage
```
/scout:test-runner              # Run affected tests (default)
/scout:test-runner all          # Run full test suite
/scout:test-runner [file]       # Run a specific test file
```

## Steps

1. Parse `$ARGUMENTS`:
   - No arguments → mode: **affected**
   - `all` → mode: **all**
   - A file path → mode: **specific**

2. Invoke the **test-runner** agent with the determined mode.
3. Present results and chain offers.
