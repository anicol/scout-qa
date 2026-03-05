#!/usr/bin/env bash
# Scout QA Pre-Commit Hook
# Installed by /scout:install-hooks
#
# Runs lint on staged files only. Fast — no AI, no tests.
# Skip with: git commit --no-verify

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Scout QA${NC} pre-commit check..."

# Get staged files (exclude deleted files)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=d)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${GREEN}No staged files.${NC}"
    exit 0
fi

ERRORS=0

# --- Detect and run linter ---

# Node.js (ESLint)
if [ -f "package.json" ] && grep -q '"eslint"' package.json 2>/dev/null; then
    JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' || true)
    if [ -n "$JS_FILES" ]; then
        echo -e "  Lint (ESLint): $(echo "$JS_FILES" | wc -l | tr -d ' ') files..."
        if ! echo "$JS_FILES" | xargs npx eslint --quiet 2>/dev/null; then
            echo -e "  ${RED}Lint: FAIL${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "  ${GREEN}Lint: PASS${NC}"
        fi
    fi
fi

# Python (Ruff)
if [ -f "pyproject.toml" ] && command -v ruff &>/dev/null; then
    PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)
    if [ -n "$PY_FILES" ]; then
        echo -e "  Lint (Ruff): $(echo "$PY_FILES" | wc -l | tr -d ' ') files..."
        if ! echo "$PY_FILES" | xargs ruff check --quiet 2>/dev/null; then
            echo -e "  ${RED}Lint: FAIL${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "  ${GREEN}Lint: PASS${NC}"
        fi
    fi
fi

# Go (golangci-lint)
if [ -f "go.mod" ] && command -v golangci-lint &>/dev/null; then
    GO_FILES=$(echo "$STAGED_FILES" | grep -E '\.go$' || true)
    if [ -n "$GO_FILES" ]; then
        echo -e "  Lint (golangci-lint)..."
        # golangci-lint needs package paths, not file paths
        GO_DIRS=$(echo "$GO_FILES" | xargs -I{} dirname {} | sort -u | sed 's|$|/...|')
        if ! echo "$GO_DIRS" | xargs golangci-lint run --quiet 2>/dev/null; then
            echo -e "  ${RED}Lint: FAIL${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "  ${GREEN}Lint: PASS${NC}"
        fi
    fi
fi

# Ruby (RuboCop)
if [ -f "Gemfile" ] && command -v rubocop &>/dev/null; then
    RB_FILES=$(echo "$STAGED_FILES" | grep -E '\.rb$' || true)
    if [ -n "$RB_FILES" ]; then
        echo -e "  Lint (RuboCop): $(echo "$RB_FILES" | wc -l | tr -d ' ') files..."
        if ! echo "$RB_FILES" | xargs bundle exec rubocop --force-exclusion 2>/dev/null; then
            echo -e "  ${RED}Lint: FAIL${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "  ${GREEN}Lint: PASS${NC}"
        fi
    fi
fi

# --- Result ---

if [ $ERRORS -gt 0 ]; then
    echo ""
    echo -e "${RED}Scout QA: Pre-commit FAILED.${NC} Fix lint errors before committing."
    echo -e "  Skip with: ${YELLOW}git commit --no-verify${NC}"
    exit 1
fi

echo -e "${GREEN}Scout QA: Pre-commit passed.${NC}"
exit 0
