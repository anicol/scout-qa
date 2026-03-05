---
description: Run tests — auto-detects framework, runs all or affected tests, returns structured results
---

# /scout:test

Run the project's test suite with automatic framework detection.

## Usage
```
/scout:test              # Run affected tests only (default)
/scout:test all          # Run full test suite
/scout:test [file]       # Run a specific test file
```

## Steps

1. Parse `$ARGUMENTS`:
   - No arguments or empty → mode: **affected** (only tests related to current changes)
   - `all` → mode: **all** (full suite)
   - A file path → mode: **specific** (run that file only)

2. Invoke the **test-runner** agent with the determined mode.
   - For "affected" mode, the agent diffs against the default branch and only runs relevant tests.
   - For "all" mode, the agent runs the full test command.
   - For "specific" mode, the agent runs only the specified file.

3. After the agent completes, present the results and chain offers.
