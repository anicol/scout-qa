#!/usr/bin/env bash
# Scout QA Pre-Push Gate
# Installed by /scout:install-hooks
#
# Runs the full quality gate before pushing.
# Two modes:
#   SCOUT_MODE=fast  (default) — lint + typecheck + affected tests (no AI)
#   SCOUT_MODE=smart           — full Claude Code pipeline with risk analysis
#
# Skip with: git push --no-verify
# Configure: export SCOUT_MODE=smart

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

MODE="${SCOUT_MODE:-fast}"

echo ""
echo -e "${BOLD}${CYAN}Scout QA${NC}${BOLD} Pre-Push Gate${NC} (mode: ${MODE})"
echo -e "────────────────────────────────────"

# Detect the default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
MERGE_BASE=$(git merge-base HEAD "origin/${DEFAULT_BRANCH}" 2>/dev/null || echo "HEAD~1")

# Get changed files
CHANGED_FILES=$(git diff --name-only "$MERGE_BASE" 2>/dev/null || git diff --name-only HEAD~1)

if [ -z "$CHANGED_FILES" ]; then
    echo -e "${GREEN}No changes to check. Pushing.${NC}"
    exit 0
fi

FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
echo -e "  Changed files: ${FILE_COUNT}"
echo ""

# ============================================================
# SMART MODE — Use Claude Code for full agentic pipeline
# ============================================================

if [ "$MODE" = "smart" ]; then
    if ! command -v claude &>/dev/null; then
        echo -e "${YELLOW}Claude Code not found. Falling back to fast mode.${NC}"
        MODE="fast"
    else
        echo -e "  Running full QA pipeline via Claude Code..."
        echo ""

        RESULT=$(claude -p "Run /scout:full-check. At the very end of your response, output exactly SCOUT_GATE_PASS if everything passed, or SCOUT_GATE_FAIL if anything failed." \
            --output-format text \
            --max-turns 20 2>&1) || true

        echo "$RESULT"
        echo ""

        if echo "$RESULT" | grep -q "SCOUT_GATE_PASS"; then
            echo -e "${GREEN}${BOLD}Scout QA: Gate PASSED. Pushing.${NC}"
            exit 0
        else
            echo -e "${RED}${BOLD}Scout QA: Gate FAILED. Fix issues before pushing.${NC}"
            echo -e "  Run ${CYAN}/scout:full-check${NC} interactively for details."
            echo -e "  Skip with: ${YELLOW}git push --no-verify${NC}"
            exit 1
        fi
    fi
fi

# ============================================================
# FAST MODE — Direct tool execution (no AI)
# ============================================================

GATE_PASS=true
LINT_RESULT=""
TYPE_RESULT=""
TEST_RESULT=""

# --- Step 1: Lint ---

LINT_STATUS="SKIP"

# ESLint
if [ -f "package.json" ] && grep -q '"eslint"' package.json 2>/dev/null; then
    JS_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' || true)
    if [ -n "$JS_FILES" ]; then
        echo -e "  ${CYAN}Lint (ESLint)...${NC}"
        if echo "$JS_FILES" | xargs npx eslint --quiet 2>/dev/null; then
            LINT_STATUS="PASS"
        else
            LINT_STATUS="FAIL"
            GATE_PASS=false
        fi
    fi
elif [ -f "pyproject.toml" ] && command -v ruff &>/dev/null; then
    PY_FILES=$(echo "$CHANGED_FILES" | grep -E '\.py$' || true)
    if [ -n "$PY_FILES" ]; then
        echo -e "  ${CYAN}Lint (Ruff)...${NC}"
        if echo "$PY_FILES" | xargs ruff check --quiet 2>/dev/null; then
            LINT_STATUS="PASS"
        else
            LINT_STATUS="FAIL"
            GATE_PASS=false
        fi
    fi
elif [ -f "go.mod" ] && command -v golangci-lint &>/dev/null; then
    echo -e "  ${CYAN}Lint (golangci-lint)...${NC}"
    if golangci-lint run ./... --quiet 2>/dev/null; then
        LINT_STATUS="PASS"
    else
        LINT_STATUS="FAIL"
        GATE_PASS=false
    fi
fi

# --- Step 2: Type Check ---

TYPE_STATUS="SKIP"

# TypeScript
if [ -f "tsconfig.json" ] || ([ -f "package.json" ] && grep -q '"typescript"' package.json 2>/dev/null); then
    echo -e "  ${CYAN}Type Check (tsc)...${NC}"
    if npx tsc --noEmit 2>/dev/null; then
        TYPE_STATUS="PASS"
    else
        TYPE_STATUS="FAIL"
        GATE_PASS=false
    fi
# MyPy
elif [ -f "pyproject.toml" ] && command -v mypy &>/dev/null; then
    PY_FILES=$(echo "$CHANGED_FILES" | grep -E '\.py$' || true)
    if [ -n "$PY_FILES" ]; then
        echo -e "  ${CYAN}Type Check (mypy)...${NC}"
        if echo "$PY_FILES" | xargs mypy 2>/dev/null; then
            TYPE_STATUS="PASS"
        else
            TYPE_STATUS="FAIL"
            GATE_PASS=false
        fi
    fi
fi

# --- Step 3: Affected Tests ---

TEST_STATUS="SKIP"

# Detect test framework and find affected tests
SOURCE_FILES=$(echo "$CHANGED_FILES" | grep -vE '(test|spec|__tests__|\.md$|\.json$|\.ya?ml$|\.css$|\.scss$)' || true)

if [ -n "$SOURCE_FILES" ]; then
    # Jest / Vitest
    if [ -f "package.json" ] && (grep -q '"vitest"' package.json 2>/dev/null || grep -q '"jest"' package.json 2>/dev/null); then
        # Build test path pattern from changed files
        TEST_PATTERN=$(echo "$SOURCE_FILES" | sed 's|.*/||;s|\.[^.]*$||' | tr '\n' '|' | sed 's/|$//')
        if [ -n "$TEST_PATTERN" ]; then
            echo -e "  ${CYAN}Tests (affected)...${NC}"
            if grep -q '"vitest"' package.json 2>/dev/null; then
                TEST_CMD="npx vitest run --reporter=verbose"
            else
                TEST_CMD="npx jest --verbose --no-coverage"
            fi
            if $TEST_CMD --testPathPattern="($TEST_PATTERN)" 2>&1; then
                TEST_STATUS="PASS"
            else
                TEST_STATUS="FAIL"
                GATE_PASS=false
            fi
        fi

    # Pytest
    elif ([ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "conftest.py" ]) && command -v pytest &>/dev/null; then
        # Find corresponding test files
        TEST_FILES=""
        for src in $SOURCE_FILES; do
            basename=$(basename "$src" .py)
            found=$(find . -name "test_${basename}.py" -o -name "${basename}_test.py" 2>/dev/null | head -5)
            TEST_FILES="$TEST_FILES $found"
        done
        TEST_FILES=$(echo "$TEST_FILES" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        if [ -n "$(echo "$TEST_FILES" | tr -d ' ')" ]; then
            echo -e "  ${CYAN}Tests (affected)...${NC}"
            if pytest $TEST_FILES -v --tb=short 2>&1; then
                TEST_STATUS="PASS"
            else
                TEST_STATUS="FAIL"
                GATE_PASS=false
            fi
        fi

    # Go
    elif [ -f "go.mod" ]; then
        GO_DIRS=$(echo "$SOURCE_FILES" | grep -E '\.go$' | xargs -I{} dirname {} 2>/dev/null | sort -u | sed 's|^|./|;s|$|/...|')
        if [ -n "$GO_DIRS" ]; then
            echo -e "  ${CYAN}Tests (affected)...${NC}"
            if echo "$GO_DIRS" | xargs go test -v 2>&1; then
                TEST_STATUS="PASS"
            else
                TEST_STATUS="FAIL"
                GATE_PASS=false
            fi
        fi
    fi
fi

# --- Report ---

echo ""
echo -e "${BOLD}Pre-Push Check${NC}"
echo -e "══════════════"

print_status() {
    local name=$1 status=$2
    case $status in
        PASS) echo -e "  ${name} $(printf '.%.0s' {1..20}) ${GREEN}PASS${NC}" ;;
        FAIL) echo -e "  ${name} $(printf '.%.0s' {1..20}) ${RED}FAIL${NC}" ;;
        SKIP) echo -e "  ${name} $(printf '.%.0s' {1..20}) ${YELLOW}SKIP${NC}" ;;
    esac
}

print_status "Lint" "$LINT_STATUS"
print_status "Type Check" "$TYPE_STATUS"
print_status "Tests" "$TEST_STATUS"

echo ""

if [ "$GATE_PASS" = true ]; then
    echo -e "  ${GREEN}${BOLD}Gate: PASS — pushing.${NC}"
    exit 0
else
    echo -e "  ${RED}${BOLD}Gate: FAIL — fix issues before pushing.${NC}"
    echo ""
    echo -e "  Run ${CYAN}/scout:pre-push${NC} in Claude Code for details and auto-fix."
    echo -e "  Skip with: ${YELLOW}git push --no-verify${NC}"
    exit 1
fi
