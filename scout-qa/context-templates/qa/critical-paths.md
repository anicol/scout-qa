# Critical Paths

Code areas that are business-critical and must have test coverage. Changes to these files get extra scrutiny from Scout QA agents.

## High Priority (must have tests)
<!-- List glob patterns for your most critical code -->
- `src/auth/**` — Authentication and session management
- `src/api/payments/**` — Payment processing
- [Add your critical paths here]

## Medium Priority (should have tests)
- `src/api/**` — All API endpoints
- `src/models/**` — Data models and business logic
- [Add more paths]

## Known Fragile Areas
<!-- Code that breaks often or is hard to test -->
- [e.g., "src/integrations/stripe.ts — depends on external API, use mocks"]
- [e.g., "src/utils/date.ts — timezone edge cases"]

## Excluded from Coverage Requirements
<!-- Code that's OK to skip -->
- `src/migrations/**` — Auto-generated
- `src/types/**` — Type definitions only
- `scripts/**` — One-off scripts
