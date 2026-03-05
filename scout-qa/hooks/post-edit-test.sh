#!/usr/bin/env bash
# Scout QA PostToolUse Hook — Auto-run affected tests after code edits
#
# This is a Claude Code hook (not a git hook). It fires after Claude edits
# source files and automatically runs the affected tests in the background.
#
# Reads JSON from stdin (Claude Code hook protocol).
# Outputs JSON to stdout to inject test results back into the conversation.

INPUT=$(cat)

# Extract the edited file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Skip if the edited file is a test file itself
if echo "$FILE_PATH" | grep -qiE '(test|spec|__tests__)'; then
    exit 0
fi

# Skip non-source files
if echo "$FILE_PATH" | grep -qiE '\.(md|json|ya?ml|css|scss|svg|png|jpg|lock)$'; then
    exit 0
fi

# Find the corresponding test file
BASENAME=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')
DIR=$(dirname "$FILE_PATH")

TEST_FILE=""

# JavaScript/TypeScript patterns
for pattern in "${DIR}/${BASENAME}.test.ts" "${DIR}/${BASENAME}.test.tsx" "${DIR}/${BASENAME}.spec.ts" "${DIR}/${BASENAME}.test.js" "${DIR}/__tests__/${BASENAME}.test.ts"; do
    if [ -f "$pattern" ]; then
        TEST_FILE="$pattern"
        break
    fi
done

# Python patterns
if [ -z "$TEST_FILE" ]; then
    for pattern in "tests/test_${BASENAME}.py" "test_${BASENAME}.py" "${DIR}/test_${BASENAME}.py"; do
        if [ -f "$pattern" ]; then
            TEST_FILE="$pattern"
            break
        fi
    done
fi

# Go patterns
if [ -z "$TEST_FILE" ]; then
    GO_TEST="${DIR}/${BASENAME}_test.go"
    if [ -f "$GO_TEST" ]; then
        TEST_FILE="$GO_TEST"
    fi
fi

if [ -z "$TEST_FILE" ]; then
    exit 0
fi

# Run the test and capture result (quick, targeted)
if echo "$TEST_FILE" | grep -qE '\.(ts|tsx|js|jsx)$'; then
    RESULT=$(npx jest "$TEST_FILE" --verbose --no-coverage 2>&1 | tail -5) || true
elif echo "$TEST_FILE" | grep -qE '\.py$'; then
    RESULT=$(pytest "$TEST_FILE" -v --tb=short 2>&1 | tail -5) || true
elif echo "$TEST_FILE" | grep -qE '\.go$'; then
    RESULT=$(go test -v -run "." "$(dirname "$TEST_FILE")/..." 2>&1 | tail -5) || true
fi

# Output result as a note (non-blocking)
if [ -n "$RESULT" ]; then
    echo "[Scout QA] Auto-ran tests for ${FILE_PATH}:"
    echo "$RESULT"
fi

exit 0
