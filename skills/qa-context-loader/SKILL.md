---
name: qa-context-loader
description: Detects test framework, loads QA context files, reads agent state and learnings before agent execution
user-invocable: false
---

# QA Context Loader

Before performing your primary task, detect the project's test infrastructure and load QA context.

## Steps

### 1. Detect Test Framework

Check for test framework indicators in order. Stop at the first match.

**Node.js / TypeScript:**
- Read `package.json` in project root. Check `devDependencies` and `scripts`:
  - `vitest` in deps or `vitest` in scripts → **Vitest** (`npx vitest run`, coverage: `npx vitest run --coverage`)
  - `jest` in deps or `jest` in scripts → **Jest** (`npx jest`, coverage: `npx jest --coverage`)
  - `mocha` in deps → **Mocha** (`npx mocha`)
- Check for config files: `vitest.config.ts`, `jest.config.js`, `jest.config.ts`, `.mocharc.yml`

**Python:**
- Read `pyproject.toml` or `setup.cfg`. Check for:
  - `pytest` in dependencies or `[tool.pytest]` section → **Pytest** (`pytest`, coverage: `pytest --cov`)
  - `unittest` patterns → **Unittest** (`python -m unittest discover`)
- Check for `conftest.py`, `pytest.ini`

**Go:**
- Check for `go.mod` → **Go test** (`go test ./...`, coverage: `go test -coverprofile=coverage.out ./...`)

**Rust:**
- Check for `Cargo.toml` → **Cargo test** (`cargo test`)

**Ruby:**
- Check for `Gemfile`. Check for:
  - `rspec` in Gemfile → **RSpec** (`bundle exec rspec`, coverage via `simplecov`)
  - `minitest` → **Minitest** (`bundle exec ruby -Itest`)

Record the detected framework, test command, and coverage command.

### 2. Detect Test File Patterns

Based on the framework, identify where tests live:
- Glob for `**/*.test.{ts,tsx,js,jsx}`, `**/*.spec.{ts,tsx,js,jsx}` (JS/TS)
- Glob for `**/test_*.py`, `**/*_test.py` (Python)
- Glob for `**/*_test.go` (Go)
- Glob for `**/*_spec.rb` (Ruby)

Count total test files found.

### 3. Detect Lint and Type Check Tools

**Linting:**
- `eslint` in package.json deps → `npx eslint .`
- `ruff` in pyproject.toml → `ruff check .`
- `golangci-lint` installed → `golangci-lint run`
- `rubocop` in Gemfile → `bundle exec rubocop`

**Type checking:**
- `typescript` in package.json deps → `npx tsc --noEmit`
- `mypy` in pyproject.toml → `mypy .`
- `pyright` in pyproject.toml → `pyright`

Record detected tools or "none detected."

### 4. Load QA Context Files

Look for `context/qa/` directory in the project root.

**If it exists**, read all present files in this order:

| File | Purpose | Required By |
|------|---------|-------------|
| `test-strategy.md` | Testing philosophy, what to test vs skip | test-writer |
| `conventions.md` | Naming, placement, assertion style, mock patterns, quality bar | test-writer |
| `critical-paths.md` | Business-critical code paths with glob patterns | risk-analyzer, coverage-checker |
| `coverage-policy.md` | Coverage thresholds by tier, changed-line policy, exemptions | coverage-checker |
| `ownership.md` | Who owns test coverage for which code areas, team maturity | test-writer, coverage-checker |
| `frameworks.md` | Custom framework config overrides (auto-populated by /scout:init) | all agents |
| `risk-config.yaml` | Risk weights per category, large change threshold | risk-analyzer |
| `learnings/what-works.md` | QA patterns proven effective | all agents |
| `learnings/what-doesnt.md` | QA anti-patterns proven to fail | all agents |

For each file:
- **Ready** — >50 words, <3 placeholder patterns
- **Needs work** — exists but mostly placeholders
- **Missing** — file not found

Check for placeholder patterns (`[placeholder]`, `[e.g.,`, `[Add `). Note files that need filling.

**If it doesn't exist**, proceed with auto-detected defaults. Note that `/scout:init` can scaffold context files.

### 5. Load Learnings

If `context/qa/learnings/what-works.md` exists, read it. Extract patterns relevant to the current agent's task:
- **test-runner:** Risk detection patterns, flaky test management
- **coverage-checker:** Coverage strategy learnings
- **test-writer:** Test writing patterns, mocking strategies
- **pre-push-gate:** Process learnings
- **risk-analyzer:** Risk detection patterns

If `context/qa/learnings/what-doesnt.md` exists, read it. Note anti-patterns to avoid.

If neither exists, proceed without learnings. Note that filling these in improves agent quality over time.

### 6. Load Agent State

Read `context/qa/agent-state.json` if it exists. The state file tracks:

**Per agent:**
- `last_run` — ISO 8601 timestamp
- `run_count` — total executions
- `last_summary` — one-line result from last run

**Signals** — detected issues that persist across sessions:
- `id` — unique identifier (format: `{type}-{identifier}-{date}`)
- `type` — signal category (see below)
- `severity` — Critical / High / Medium / Low
- `description` — human-readable explanation
- `detected_at` — when first detected
- `status` — `active` / `resolved` / `dismissed`

Signal types for QA agents:
- `coverage-declining` — coverage trend is going down
- `untested-critical-path` — critical path code has no tests
- `persistent-failure` — same test failing across multiple runs
- `flaky-test` — test that passes/fails non-deterministically
- `risk-score-spike` — risk score jumped significantly
- `new-untested-code` — new source files without corresponding tests

**Actions taken** — log of all executed actions:
- `timestamp`, `action` (e.g., `run-tests`, `write-test-file`, `run-coverage`), `description`

**Feedback** — user ratings on agent usefulness:
- `timestamp`, `rating` (Yes / Partially / No), `feedback_note` (optional)

For the current agent:
- Extract `last_run`, `run_count`, `last_summary`
- Identify `active` signals (don't re-alert on same signal)
- Identify `dismissed` signals (skip entirely)
- Review `feedback` history (note patterns — if a signal type is consistently rated "No", deprioritize it)
- Review `flaky_tests` list

If the file does not exist, note this is a first run.

### 7. Load Autonomy Config

Read `context/qa/autonomy.yaml` if it exists. For the current agent, summarize which action types are `autonomous`, `requires_approval`, or `disabled`. Default all actions to `autonomous` (QA actions are safe — they read/run, not deploy).

### 8. Summarize

Before proceeding with the primary task, briefly report:
- Detected framework and test command
- Number of test files found
- Lint/typecheck tools detected
- Context file status (present/missing/needs-work per file)
- Learnings loaded (count of patterns from what-works + what-doesnt)
- Agent state (last run, active signals, known flaky tests)
- Autonomy config (action permissions for current agent)
