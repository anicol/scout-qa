# Test Ownership

Who is responsible for test coverage in each area of the codebase. Used by agents to route coverage requests, assign test-writing work, and identify gaps in ownership.

## Ownership Map

| Code Area | Owner | Backup | Coverage Status |
|-----------|-------|--------|----------------|
| [e.g., `src/auth/**`] | [e.g., @alice] | [e.g., @bob] | [e.g., Good (85%)] |
| [e.g., `src/api/payments/**`] | [e.g., @bob] | [e.g., @alice] | [e.g., Needs work (45%)] |
| [e.g., `src/api/users/**`] | [e.g., @carol] | [e.g., @alice] | [e.g., Good (78%)] |
| [e.g., `src/components/**`] | [e.g., @dave] | [e.g., @carol] | [e.g., Best effort] |
| [Add your code areas] | | | |

## Team QA Maturity

How mature is the team's QA practice? This affects how aggressive agent recommendations are.

**Level:** [Choose one]

- **Starting out** — Few or no tests. Agents should suggest high-impact tests only (critical paths, API contracts). Don't overwhelm.
- **Building** — Some test coverage. Agents should actively suggest coverage improvements and enforce pre-push checks.
- **Solid** — Good coverage on critical paths. Agents focus on maintaining quality, catching regressions, and optimizing flaky tests.
- **Advanced** — Comprehensive test suite. Agents focus on edge cases, performance testing patterns, and coverage trend analysis.

## Rotation / On-Call

<!-- If your team rotates QA responsibility -->
- **Current rotation:** [e.g., @alice is QA lead this sprint]
- **Rotation schedule:** [e.g., weekly, per-sprint, permanent ownership]
- **On-call QA:** [e.g., whoever is on-call also triages flaky tests]

## New Code Policy

When new code is added:

- **New modules:** [e.g., Must have tests before merge | Must have tests within 1 sprint]
- **New API endpoints:** [e.g., Must have request/response contract tests]
- **New business logic:** [e.g., Must have unit tests covering happy path + error cases]
- **New UI components:** [e.g., Best effort, no strict requirement]

## Knowledge Gaps

Code areas where nobody fully understands the test requirements:

- [e.g., "Legacy payment integration — original author left, mocking strategy unclear"]
- [e.g., "Real-time websocket handlers — no established test pattern yet"]
- [e.g., "Third-party OAuth flow — hard to test without real credentials"]

These areas need extra caution from agents — prefer conservative test writing and flag for human review.
