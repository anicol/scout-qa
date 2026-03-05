# Test Frameworks

<!-- This file is auto-populated by /scout:init. Override values if needed. -->

## Test Runner
- **Framework:** [Auto-detected: Jest | Vitest | Pytest | Go test | RSpec]
- **Test command:** [Auto-detected: `npx jest --verbose` | `pytest -v` | `go test -v ./...`]
- **Coverage command:** [Auto-detected: `npx jest --coverage` | `pytest --cov`]
- **Config file:** [Auto-detected: `jest.config.ts` | `vitest.config.ts` | `pyproject.toml`]

## Lint
- **Tool:** [Auto-detected: ESLint | Ruff | golangci-lint | RuboCop | None]
- **Command:** [Auto-detected: `npx eslint .` | `ruff check .`]

## Type Check
- **Tool:** [Auto-detected: TypeScript | MyPy | Pyright | None]
- **Command:** [Auto-detected: `npx tsc --noEmit` | `mypy .`]

## Custom Overrides
<!-- Uncomment and modify if auto-detection gets it wrong -->
# test_command: "npm run test:unit -- --verbose"
# coverage_command: "npm run test:coverage"
# lint_command: "npm run lint"
# typecheck_command: "npm run typecheck"

## Test File Patterns
<!-- Where do tests live? Uncomment if non-standard. -->
# test_dirs:
#   - "tests/"
#   - "__tests__/"
#   - "spec/"
# test_pattern: "*.test.{ts,tsx}"
