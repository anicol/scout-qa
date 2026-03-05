# Scout QA

Agentic QA pipeline for Claude Code. Risk-scores your changes, runs the right tests, finds coverage gaps, writes missing tests, and gates your push — all automatically.

## What It Does

Scout QA is a Claude Code plugin with 5 agents that form an adaptive QA pipeline:

1. **Risk Analyzer** — Scores your changes 1-10 using file categorization, security/payment pattern detection, critical path matching, and change size
2. **Test Runner** — Auto-detects your framework, runs all or affected tests, categorizes failures as `real_bug` / `test_bug` / `flaky`
3. **Coverage Checker** — Reports coverage on your *changed lines only* — not a whole-project dump
4. **Test Writer** — Reads your source code and existing test conventions, writes tests that match your style
5. **Pre-Push Gate** — Lint + typecheck + affected tests. Clear PASS/FAIL that blocks bad pushes

The pipeline adapts to risk: a 2/10 docs change gets a quick test run. A 9/10 auth+payments change gets the full treatment.

## Quick Start

```bash
# Add the marketplace
claude plugin marketplace add anicol/scout-qa

# Install the plugin
claude plugin install scout-qa

# Initialize context files in your project (inside Claude Code)
/scout:init

# Wire into your git pipeline
/scout:install-hooks

# Push with confidence
git push origin feature/your-branch
```

## Commands

| Command | What It Does |
|---------|-------------|
| `/scout:init` | Scaffold `context/qa/` files, auto-detect framework |
| `/scout:risk` | Score risk of current changes (1-10) |
| `/scout:test [all\|file]` | Run tests (affected by default) |
| `/scout:coverage [all]` | Coverage report on changed lines |
| `/scout:write-tests [file\|--critical]` | Generate tests for uncovered code |
| `/scout:pre-push` | Quality gate (lint + types + tests) |
| `/scout:full-check` | Risk-adaptive full pipeline |
| `/scout:install-hooks` | Install git hooks + Claude Code hooks |
| `/scout:doctor` | Health check — framework, tools, context files |
| `/scout:status` | QA dashboard from agent state |

## Git Pipeline Integration

Three layers of automation, installed with `/scout:install-hooks`:

**Layer 1 — Claude Code Hooks (during coding)**
After Claude edits a source file, auto-runs the corresponding test. After `git commit`, suggests running tests.

**Layer 2 — Git Pre-Commit (every commit)**
Lints staged files only. Fast, no AI, sub-second.

**Layer 3 — Git Pre-Push (every push)**
- **Fast mode** (default): lint + typecheck + affected tests directly
- **Smart mode** (`export SCOUT_MODE=smart`): full Claude Code pipeline via `claude -p "/scout:full-check"`
- Skip: `git push --no-verify`

## Context Files

Scout QA uses project-specific context files to make agents smarter over time. Run `/scout:init` to scaffold them.

```
context/qa/
├── test-strategy.md           # Testing philosophy
├── conventions.md             # Naming, assertions, mocking, quality bar
├── critical-paths.md          # Business-critical code paths
├── coverage-policy.md         # Coverage thresholds by tier
├── ownership.md               # Who owns test coverage where
├── frameworks.md              # Framework config (auto-populated)
├── risk-config.yaml           # Risk weights and thresholds
├── autonomy.yaml              # Agent permission config
└── learnings/
    ├── what-works.md          # QA patterns proven effective
    └── what-doesnt.md         # QA anti-patterns to avoid
```

## Risk-Adaptive Pipeline

`/scout:full-check` adapts depth based on risk score:

| Risk Score | Pipeline Depth |
|-----------|---------------|
| 1-3 (Low) | Affected tests only |
| 4-6 (Medium) | Tests + changed-line coverage |
| 7-10 (High/Critical) | Tests + coverage + write tests for gaps + pre-push gate |

## Supported Frameworks

Auto-detected from your project files:

| Category | Supported |
|----------|-----------|
| Test | Jest, Vitest, Pytest, Go test, RSpec, Cargo test, Mocha, Minitest |
| Lint | ESLint, Ruff, golangci-lint, RuboCop |
| Types | TypeScript, MyPy, Pyright |

## How It Compares

| Capability | Vanilla Claude Code | With Scout QA |
|---|---|---|
| Risk scoring | Ad-hoc opinion | Deterministic 1-10 with weighted factors |
| Failure analysis | Describes the error | Classifies real_bug / test_bug / flaky |
| QA depth | Same effort always | Adapts to risk score |
| Coverage | Whole-project dump | Changed lines only |
| Test conventions | Re-learns each session | Persisted in context files |
| Flaky tests | Forgotten | Tracked across sessions |
| Quality gate | Manual | Structured PASS/FAIL on push |
| Git integration | None | Pre-commit + pre-push hooks |

## Project Structure

```
scout-qa/
├── .claude-plugin/plugin.json     # Plugin manifest
├── agents/                        # 5 QA agents
├── commands/                      # 10 slash commands
├── skills/                        # 2 reusable skills
├── hooks/                         # Git + Claude Code hook scripts
└── context-templates/qa/          # 10 context file templates
```

## License

MIT
