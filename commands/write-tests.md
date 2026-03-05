---
description: Find untested code and write real, passing tests for it
---

# /scout:write-tests

Find code that lacks test coverage and write real, working tests for it.

## Usage
```
/scout:write-tests                  # Write tests for all uncovered changed files
/scout:write-tests src/auth.ts      # Write tests for a specific file
/scout:write-tests --critical       # Write tests for critical paths only
```

## Steps

1. Parse `$ARGUMENTS`:
   - No arguments → target all changed files that lack tests
   - A file path → target that specific file
   - `--critical` → only target files matching `context/qa/critical-paths.md` patterns

2. Invoke the **test-writer** agent with the determined scope.

3. After the agent completes, offer:
   - `/scout:coverage` to verify the new tests improve coverage
   - `/scout:pre-push` to run the full quality gate
