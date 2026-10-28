#!/usr/bin/env bash
# test.sh - Automated tests for the diagnostic-tool Docker image
# Usage: ./test.sh
# Exit codes: 0 = all tests passed, 1 = one or more tests failed

set -u

IMAGE="${IMAGE:-diagnostic-tool}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0

# run_case <name> <expected exit code> <text expected in output> <command...>
run_case() {
    local name="$1" expected_code="$2" expected_text="$3"
    shift 3

    local output code
    output=$("$@" 2>&1)
    code=$?

    if [[ $code -eq $expected_code ]] && grep -qi -- "$expected_text" <<< "$output"; then
        echo "PASS: $name"
        PASS=$((PASS+1))
    else
        echo "FAIL: $name (expected exit $expected_code with '$expected_text', got exit $code)"
        echo "$output" | sed 's/^/    /'
        FAIL=$((FAIL+1))
    fi
}

echo "======================================"
echo " diagnostic-tool Docker image tests"
echo "======================================"

echo "Building image '$IMAGE'..."
if ! docker build -t "$IMAGE" . >/dev/null 2>&1; then
    echo "FAIL: docker build failed"
    exit 1
fi
echo

# Valid commands
run_case "help shows usage"                0 "Usage"            docker run --rm "$IMAGE" help
run_case "no command defaults to help"     0 "Usage"            docker run --rm "$IMAGE"
run_case "system shows hostname"           0 "Hostname"         docker run --rm "$IMAGE" system
run_case "system shows kernel version"     0 "Kernel"           docker run --rm "$IMAGE" system
run_case "disk shows usage"                0 "Use%"             docker run --rm "$IMAGE" disk

# Invalid commands and input
run_case "invalid command returns 2"       2 "unknown command"  docker run --rm "$IMAGE" invalid-command
run_case "network without host returns 2"  2 "missing host"     docker run --rm "$IMAGE" network
run_case "network with bad host returns 2" 2 "invalid hostname" docker run --rm "$IMAGE" network "bad host!"
run_case "disk with missing path returns 2" 2 "does not exist"  docker run --rm "$IMAGE" disk /nope
run_case "system with extra args returns 2" 2 "no arguments"    docker run --rm "$IMAGE" system extra

# Container health check
run_case "health check reports healthy"    0 "HEALTHY"          docker run --rm --entrypoint /app/health-check.sh "$IMAGE"

echo
echo "======================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================"

[[ $FAIL -eq 0 ]]
