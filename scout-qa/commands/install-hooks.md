---
description: Install git hooks and Claude Code hooks for automatic QA on commit and push
---

# /scout:install-hooks

Wire Scout QA into your git pipeline. Installs git hooks (pre-commit, pre-push) and Claude Code hooks (auto-test after edits) so QA runs automatically without thinking about it.

## Usage
```
/scout:install-hooks             # Install everything
/scout:install-hooks --git-only  # Only git hooks (pre-commit + pre-push)
/scout:install-hooks --uninstall # Remove all Scout hooks
```

## What Gets Installed

### 1. Git Pre-Commit Hook (`.git/hooks/pre-commit`)
- Runs lint on staged files only
- Fast — no AI, no tests, sub-second
- Auto-detects: ESLint, Ruff, golangci-lint, RuboCop
- Skip: `git commit --no-verify`

### 2. Git Pre-Push Hook (`.git/hooks/pre-push`)
- Runs the full quality gate before push: lint + typecheck + affected tests
- Two modes:
  - **Fast** (default): Direct tool execution, no AI needed
  - **Smart**: Full Claude Code pipeline with risk analysis (`export SCOUT_MODE=smart`)
- Skip: `git push --no-verify`

### 3. Claude Code Hooks (`.claude/settings.local.json`)
- **Auto-test on edit**: After Claude edits a source file, automatically runs the corresponding test file
- **Post-commit QA suggestion**: After `git commit` via Bash, suggests running `/scout:test`
- **Session QA reminder**: When Claude stops after writing code, reminds about the QA pipeline

## Steps

### Step 1: Check Prerequisites

Verify:
- Current directory is a git repository (`git rev-parse --git-dir`)
- `.git/hooks/` directory exists
- No existing Scout hooks that would be overwritten (if found, ask before replacing)

### Step 2: Install Git Hooks

Copy hook scripts from the plugin's `hooks/` directory:

```bash
# Pre-commit hook
cp "${CLAUDE_PLUGIN_ROOT}/hooks/pre-commit.sh" .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Pre-push hook
cp "${CLAUDE_PLUGIN_ROOT}/hooks/pre-push.sh" .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

**If existing hooks are found**, do NOT overwrite. Instead:
- Read the existing hook
- If it's a Scout hook (contains "Scout QA"), replace it
- If it's a different hook (Husky, custom), append Scout as an additional step or ask the user

**If Husky is detected** (`node_modules/.husky/` or `.husky/` exists):
- Instead of writing to `.git/hooks/`, create Husky hook files:
  ```bash
  npx husky add .husky/pre-commit "$(cat ${CLAUDE_PLUGIN_ROOT}/hooks/pre-commit.sh)"
  npx husky add .husky/pre-push "$(cat ${CLAUDE_PLUGIN_ROOT}/hooks/pre-push.sh)"
  ```
- Or if using Husky v9+, write to `.husky/pre-commit` and `.husky/pre-push`

**If lefthook is detected** (`lefthook.yml`):
- Append Scout hooks to the existing config instead of writing shell scripts

### Step 3: Install Claude Code Hooks (unless --git-only)

Read `.claude/settings.local.json` if it exists. Merge in the Scout hooks:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/post-edit-test.sh\"",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.command // empty' | grep -q 'git commit' && echo '[Scout QA] Commit detected. Run /scout:test to check affected tests.' || exit 0"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if this conversation involved editing source code files (not test files, not config, not docs). If yes, respond with: '[Scout QA] Source code was modified. Consider running /scout:test or /scout:pre-push before pushing.' If no source code was edited, respond with nothing."
          }
        ]
      }
    ]
  }
}
```

Write to `.claude/settings.local.json` (gitignored, local-only). If the file exists, merge hooks arrays — don't overwrite existing hooks.

### Step 4: Verify Installation

Run each hook in dry-run mode:
```bash
# Test pre-commit
bash .git/hooks/pre-commit --dry-run 2>/dev/null || echo "Pre-commit installed (will run on next commit)"

# Test pre-push
bash .git/hooks/pre-push --dry-run 2>/dev/null || echo "Pre-push installed (will run on next push)"
```

### Step 5: Report

```
Scout QA Hooks Installed
========================

Git Hooks:
  .git/hooks/pre-commit ............ Installed (lint on staged files)
  .git/hooks/pre-push .............. Installed (quality gate before push)

Claude Code Hooks:
  PostToolUse (Edit/Write) ......... Auto-run affected tests after edits
  PostToolUse (Bash/git commit) .... Suggest /scout:test after commits
  Stop ............................. QA reminder after code changes

Pre-Push Mode: fast (direct tools, no AI)
  Switch to smart mode: export SCOUT_MODE=smart

Skip any hook: --no-verify
  git commit --no-verify
  git push --no-verify
```

## Uninstall

If `$ARGUMENTS` contains `--uninstall`:

1. Remove Scout git hooks (only if they contain "Scout QA" marker):
   ```bash
   grep -q "Scout QA" .git/hooks/pre-commit && rm .git/hooks/pre-commit
   grep -q "Scout QA" .git/hooks/pre-push && rm .git/hooks/pre-push
   ```

2. Remove Scout entries from `.claude/settings.local.json` (remove hooks that reference `scout` or `SCOUT`).

3. Report what was removed.
