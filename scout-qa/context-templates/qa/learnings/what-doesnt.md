# What Doesn't Work — QA Anti-Patterns

Patterns proven to fail or waste time. Updated after retrospectives and agent feedback. All agents read this to avoid repeating mistakes.

## Test Writing

- [e.g., "Snapshot tests for API responses — break on every minor change, never catch real bugs"]
- [e.g., "Testing implementation details (checking internal state, private methods) — breaks on every refactor"]
- [e.g., "Writing tests after the fact with no understanding of the code — produces weak assertions"]
- [Add patterns that wasted time in your codebase]

## Coverage Strategy

- [e.g., "Chasing 100% coverage on UI components — huge effort, catches almost nothing"]
- [e.g., "Whole-project coverage reports — too noisy, nobody reads them"]
- [e.g., "Excluding all config files from coverage — missed a critical env var validation bug"]
- [Add coverage strategies that backfired]

## Risk Detection

- [e.g., "Treating all 'large change' PRs as high risk — refactors score high but are actually safe"]
- [e.g., "Ignoring test-file-only changes — sometimes test changes mask source code issues"]
- [e.g., "Using default risk weights without customization — every project is different"]
- [Add risk detection false positives/negatives]

## Flaky Test Management

- [e.g., "Retrying flaky tests 3x instead of fixing them — just hides the problem longer"]
- [e.g., "Marking everything as 'known flaky' — erodes trust in the test suite"]
- [e.g., "Ignoring flaky tests in CI — they eventually mask real failures"]
- [Add flaky test approaches that failed]

## Process

- [e.g., "Skipping /scout:pre-push 'just this once' — the one time you skip is the one time it would have caught something"]
- [e.g., "Not filling in critical-paths.md — risk scores are useless without project-specific paths"]
- [e.g., "Auto-committing agent-written tests without review — produced tests that tested nothing"]
- [Add process failures]
