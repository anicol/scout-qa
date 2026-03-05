# Coverage Policy

Team-specific coverage rules. Defines what "good enough" coverage means for this project — not an arbitrary global number, but targeted thresholds based on code criticality.

## Coverage Thresholds

Coverage requirements by code criticality tier:

| Tier | Threshold | Applies To |
|------|-----------|------------|
| **Critical** | 90%+ | Auth, payments, security, data mutations |
| **Standard** | 70%+ | API endpoints, business logic, models |
| **Best effort** | No minimum | UI components, config, utilities |
| **Exempt** | Excluded | Generated code, migrations, type definitions, scripts |

## Changed-Line Policy

When checking coverage on a PR:

- **New files:** Must meet the threshold for their tier
- **Modified files:** Changed lines must meet the threshold. Existing uncovered lines are not your problem.
- **Deleted files:** No coverage requirement (obviously)

## Enforcement

- **Pre-push gate:** [e.g., Warns on critical paths below threshold | Blocks push if critical code uncovered]
- **CI:** [e.g., Coverage must not decrease on changed files | PR comment with coverage delta]
- **Review:** [e.g., Reviewer checks coverage report for critical paths]

## Exemptions

Code that is explicitly excluded from coverage requirements:

<!-- Use glob patterns -->
- `**/migrations/**` — Auto-generated database migrations
- `**/types/**` or `**/*.d.ts` — Type definitions only
- `scripts/**` — One-off utility scripts
- `**/fixtures/**` — Test fixtures and factories
- `**/__mocks__/**` — Mock implementations
- [Add project-specific exemptions]

## Coverage Tool Configuration

<!-- How coverage is configured for your framework -->
- **Tool:** [Auto-detected: Jest built-in | pytest-cov | go cover]
- **Report format:** [e.g., JSON for machine parsing | LCOV for IDE integration | HTML for manual review]
- **Config location:** [e.g., jest.config.ts `collectCoverageFrom` | pyproject.toml `[tool.coverage]`]
- **Threshold config:** [e.g., jest `coverageThreshold` | pytest `--cov-fail-under`]

## Metrics We Track

What coverage data matters to this team:

- [ ] Changed-line coverage per PR (primary metric)
- [ ] Critical path coverage trend (weekly)
- [ ] Test count growth vs. source code growth
- [ ] Flaky test rate (should trend down)
- [ ] Time to write tests vs. time tests save in bug prevention
