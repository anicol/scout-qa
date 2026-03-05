# Test Strategy — [Your Project Name]

## Testing Philosophy
<!-- What's your approach to testing? What do you value most? -->
[e.g., "We prioritize testing business-critical paths and API contracts. We don't test simple CRUD or UI styling."]

## What to Test
- [API endpoints — test request/response contracts]
- [Business logic — test calculations, validations, state transitions]
- [Authentication/authorization — test access control]
- [Data transformations — test input/output mapping]

## What NOT to Test
<!-- Equally important. Tells the agent what to skip. -->
- [Simple getters/setters]
- [Framework-generated code (migrations, boilerplate)]
- [CSS/styling]
- [Third-party library internals]

## Test Data Conventions
- [Use factory functions for creating test data, not raw objects]
- [Use realistic but fake data (e.g., test@example.com, not real emails)]
- [Seed data lives in `tests/fixtures/` or `tests/factories/`]

## Mocking Rules
- [Mock external APIs and databases at the boundary]
- [Don't mock internal functions — test them through public interfaces]
- [Use dependency injection where possible instead of patching]

## Test Organization
- [Unit tests: next to source files (`auth.test.ts` next to `auth.ts`)]
- [Integration tests: in `tests/integration/`]
- [E2E tests: in `tests/e2e/` or `cypress/`]

## CI Requirements
- [All tests must pass before merge]
- [Coverage must not decrease on changed files]
- [New API endpoints must have tests]
