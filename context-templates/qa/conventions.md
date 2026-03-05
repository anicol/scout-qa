# Test Conventions

How tests are written in this project. Agents match these conventions when writing new tests.

## Naming

- **Test files:** [e.g., `{source}.test.ts` next to source | `test_{source}.py` in `tests/`]
- **Test names:** [e.g., "should {expected behavior} when {condition}" | "test_{function}_{scenario}"]
- **Describe blocks:** [e.g., group by class/module | group by feature | flat list]

## File Placement

- **Unit tests:** [e.g., same directory as source | `tests/unit/`]
- **Integration tests:** [e.g., `tests/integration/` | `__tests__/integration/`]
- **E2E tests:** [e.g., `tests/e2e/` | `cypress/` | `playwright/`]
- **Fixtures/factories:** [e.g., `tests/fixtures/` | `tests/factories/` | `__mocks__/`]

## Assertion Style

- **Library:** [e.g., Jest expect | Chai assert | pytest assert | testify assert]
- **Preferred pattern:**
  ```
  [e.g., expect(result).toEqual(expected)
   NOT expect(result).toBeDefined()]
  ```
- **Real values only:** Always assert specific values. Never assert just `toBeDefined()`, `toBeTruthy()`, or `not.toBeNull()`.

## Mocking

- **What to mock:** [e.g., external APIs, databases, file system, time/dates]
- **What NOT to mock:** [e.g., internal functions, utility helpers, pure logic]
- **Mock library:** [e.g., jest.mock | unittest.mock | gomock | testdouble]
- **Mock pattern:**
  ```
  [e.g., Dependency injection preferred over monkey-patching
   Use factory functions to create mock objects
   Mock at the boundary, not deep inside]
  ```
- **API mocks:** [e.g., MSW for HTTP | nock | responses | httptest]

## Setup / Teardown

- **Database:** [e.g., in-memory SQLite | test transactions that rollback | Docker test DB]
- **Shared state:** [e.g., beforeEach resets state | each test is fully isolated]
- **Test data:** [e.g., factory functions | fixture files | inline builders]
- **Cleanup:** [e.g., afterEach clears mocks | automatic garbage collection]

## Quality Bar

What makes a test "good enough" to merge:

- [ ] Tests behavior, not implementation
- [ ] One logical assertion per test (multiple `expect` calls for one behavior is fine)
- [ ] Meaningful test name that describes the scenario
- [ ] No test interdependence (each test runs in isolation)
- [ ] Error cases covered (not just happy path)
- [ ] No sleeping/timing-based assertions (use waitFor, polling, or mocks)
- [ ] Deterministic — same result every run

## Anti-Patterns We Reject

<!-- Tests that violate these get flagged -->
- [e.g., Testing private methods directly]
- [e.g., Snapshot tests for logic (only for UI rendering)]
- [e.g., Tests that depend on execution order]
- [e.g., Mocking the thing being tested]
- [e.g., Tests with no assertions (just "doesn't throw")]
- [e.g., Hardcoded dates/times instead of relative or frozen time]
