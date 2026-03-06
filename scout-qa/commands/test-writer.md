---
description: Run the test-writer agent directly
---

# /scout:test-writer

Invoke the **test-writer** agent directly. Reads source code and existing test conventions, writes tests that match your style, runs them, and iterates until they pass.

## Usage
```
/scout:test-writer                  # Write tests for uncovered changed files
/scout:test-writer src/auth.ts      # Write tests for a specific file
/scout:test-writer --critical       # Write tests for critical paths only
```

## Steps

1. Parse `$ARGUMENTS`:
   - No arguments → target all changed files that lack tests
   - A file path → target that specific file
   - `--critical` → only target files matching critical path patterns

2. Invoke the **test-writer** agent with the determined scope.
3. Present results and chain offers.
