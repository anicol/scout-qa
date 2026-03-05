---
description: Scaffold QA context files in your project
---

# /scout:init

Scaffold the `context/qa/` directory with QA context files, learnings, and autonomy config.

## Steps

1. **Check if `context/qa/` already exists.** If it exists and contains files, warn: "QA context directory already exists. Will only create missing files." If it doesn't exist, create it.

2. **Create the directory structure:**

```
context/qa/
├── test-strategy.md           # Testing philosophy
├── conventions.md             # Test naming, placement, assertion style, quality bar
├── critical-paths.md          # Business-critical code paths
├── coverage-policy.md         # Coverage thresholds by tier, exemptions
├── ownership.md               # Who owns test coverage for which code areas
├── frameworks.md              # Framework config (auto-populated)
├── risk-config.yaml           # Risk weights and thresholds
├── autonomy.yaml              # Agent permission config
└── learnings/
    ├── what-works.md          # QA patterns proven effective
    └── what-doesnt.md         # QA anti-patterns to avoid
```

3. **For each file**, read the corresponding template from `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/` and write a copy into the project's `context/qa/` directory. Skip any files that already exist.

4. **Auto-detect and pre-fill `frameworks.md`:**
   - Run the framework detection from `qa-context-loader`
   - If a framework is detected, fill in the detected values instead of placeholders
   - Include the test command, coverage command, and lint/typecheck tools found

5. **Add `context/qa/agent-state.json` to `.gitignore`.** Check if `.gitignore` exists:
   - If it exists, check if `context/qa/agent-state.json` is already listed. If not, append it.
   - If it doesn't exist, create `.gitignore` with `context/qa/agent-state.json`.
   - Do NOT create the state file itself — it is auto-created on first agent run.

6. **Output a summary:**

```
Scout QA initialized.

Created:
  context/qa/test-strategy.md ......... Template (fill in your testing philosophy)
  context/qa/conventions.md ........... Template (naming, placement, assertions, quality bar)
  context/qa/critical-paths.md ........ Template (list your high-risk code areas)
  context/qa/coverage-policy.md ....... Template (coverage thresholds and exemptions)
  context/qa/ownership.md ............. Template (who owns test coverage where)
  context/qa/frameworks.md ............ Auto-detected (Jest, npx tsc, ESLint)
  context/qa/risk-config.yaml ......... Defaults (standard risk weights)
  context/qa/autonomy.yaml ............ Defaults (all actions autonomous)
  context/qa/learnings/what-works.md .. Template (patterns that catch bugs)
  context/qa/learnings/what-doesnt.md . Template (anti-patterns to avoid)

Added to .gitignore:
  context/qa/agent-state.json

Next steps:
  1. Fill in context/qa/critical-paths.md — what code areas are business-critical?
  2. Fill in context/qa/conventions.md — how does your team write tests?
  3. Run /scout:risk to see your current risk score
  4. Run /scout:doctor to check readiness
```

## Template source mapping

| Target | Template source |
|--------|----------------|
| `context/qa/test-strategy.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/test-strategy.md` |
| `context/qa/conventions.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/conventions.md` |
| `context/qa/critical-paths.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/critical-paths.md` |
| `context/qa/coverage-policy.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/coverage-policy.md` |
| `context/qa/ownership.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/ownership.md` |
| `context/qa/frameworks.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/frameworks.md` |
| `context/qa/risk-config.yaml` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/risk-config.yaml` |
| `context/qa/autonomy.yaml` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/autonomy.yaml` |
| `context/qa/learnings/what-works.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/learnings/what-works.md` |
| `context/qa/learnings/what-doesnt.md` | `${CLAUDE_PLUGIN_ROOT}/context-templates/qa/learnings/what-doesnt.md` |
