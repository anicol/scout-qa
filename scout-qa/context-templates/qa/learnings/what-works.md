# What Works — QA Learnings

Patterns proven effective in this project's QA. Updated after retrospectives and agent feedback. All agents read this to reinforce good practices.

## Test Writing

- [e.g., "Testing API endpoints through the router (not handler functions directly) catches middleware bugs"]
- [e.g., "Factory functions for test data eliminate brittle tests that break when models change"]
- [e.g., "Testing error paths catches more real bugs than happy-path-only tests"]
- [Add patterns that have caught real bugs in your codebase]

## Coverage Strategy

- [e.g., "80% coverage on changed lines is the sweet spot — higher causes diminishing returns"]
- [e.g., "Covering auth and payment code at 95%+ has prevented 3 production incidents"]
- [e.g., "Ignoring coverage on generated code and type definitions reduces noise"]
- [Add coverage strategies that have proven effective]

## Risk Detection

- [e.g., "Changes touching both auth and API files are consistently higher risk than the score suggests"]
- [e.g., "Config-only changes that touch environment variables need more scrutiny than default weight"]
- [e.g., "PRs with 10+ files but low line count are usually refactors — lower risk than scored"]
- [Add risk patterns you've observed]

## Flaky Test Management

- [e.g., "Mocking HTTP calls with MSW eliminated 90% of network-related flakiness"]
- [e.g., "Replacing sleep(2000) with waitFor() fixed all timing flakes"]
- [e.g., "Running database tests with transaction rollback instead of truncation fixed race conditions"]
- [Add flaky test solutions that worked]

## Process

- [e.g., "Running /scout:pre-push before every push caught 2 bugs per week on average"]
- [e.g., "Filling in critical-paths.md properly made risk scores much more useful"]
- [e.g., "Reviewing agent-written tests before committing improves test quality significantly"]
- [Add process learnings]
