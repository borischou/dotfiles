#!/usr/bin/env bash
# Pre-commit hook: auto-detect test framework and run tests before commit.
# Install: ln -sf ~/.claude/hooks/pre-commit-test.sh <project>/.git/hooks/pre-commit
set -euo pipefail

# Ensure homebrew bin is in PATH (git hooks get a minimal environment)
for brew_prefix in /opt/homebrew/bin /usr/local/bin; do
    [[ -d "$brew_prefix" && ":$PATH:" != *":$brew_prefix:"* ]] && export PATH="$brew_prefix:$PATH"
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[pre-commit]${NC} $*"; }
warn()  { echo -e "${YELLOW}[pre-commit]${NC} $*"; }
fail()  { echo -e "${RED}[pre-commit]${NC} $*"; exit 1; }

# Find project root (git toplevel)
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || fail "Not in a git repository"
cd "$ROOT"

# Resolve python command (prefer python3, fallback python)
PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PYTHON="$cmd"
        break
    fi
done

# Auto-detect test framework and run
run_tests() {
    # 1. Python: pytest
    if [[ -f "pyproject.toml" || -f "pytest.ini" || -f "setup.cfg" || -f "requirements.txt" ]]; then
        if [[ -n "$PYTHON" ]] && "$PYTHON" -c "import pytest" &>/dev/null; then
            info "Detected pytest (via $PYTHON)"
            "$PYTHON" -m pytest --tb=short -q "$@"
            return $?
        fi
    fi

    # 2. Node.js: package.json scripts.test
    if [[ -f "package.json" ]]; then
        local test_script
        test_script=$("$PYTHON" -c "import json; d=json.load(open('package.json')); print(d.get('scripts',{}).get('test',''))" 2>/dev/null || echo "")
        if [[ -n "$test_script" && "$test_script" != "echo \"Error: no test specified\" && exit 1" ]]; then
            if [[ -f "pnpm-lock.yaml" ]]; then
                info "Detected pnpm test"
                pnpm test
            elif [[ -f "yarn.lock" ]]; then
                info "Detected yarn test"
                yarn test
            else
                info "Detected npm test"
                npm test
            fi
            return $?
        fi
    fi

    # 3. Makefile with test target
    if [[ -f "Makefile" ]] && grep -q '^test:' Makefile; then
        info "Detected make test"
        make test
        return $?
    fi

    # 4. Rust: cargo
    if [[ -f "Cargo.toml" ]]; then
        info "Detected cargo test"
        cargo test
        return $?
    fi

    # 5. Go
    if [[ -f "go.mod" ]]; then
        info "Detected go test"
        go test ./...
        return $?
    fi

    # 6. Java: Gradle / Maven
    if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
        info "Detected gradle test"
        ./gradlew test
        return $?
    fi
    if [[ -f "pom.xml" ]]; then
        info "Detected maven test"
        mvn test
        return $?
    fi

    # 7. Bash: bats
    if compgen -G "tests/*.bats" &>/dev/null || compgen -G "test/*.bats" &>/dev/null; then
        if command -v bats &>/dev/null; then
            info "Detected bats"
            bats tests/*.bats 2>/dev/null || bats test/*.bats
            return $?
        else
            warn "Found .bats files but bats is not installed, skipping (brew install bats-core)"
            return 0
        fi
    fi

    # No test framework found
    warn "No test framework detected, skipping tests"
    return 0
}

info "Running tests before commit..."
if run_tests; then
    info "Tests passed"
else
    fail "Tests failed — commit aborted. Fix the failures and try again."
fi
