#!/usr/bin/env bash
# health-check.sh - Health check for the diagnostic tool
# Exit codes: 0 = healthy, 1 = unhealthy

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIAGNOSTIC="$SCRIPT_DIR/diagnostic.sh"

for cmd in bash df getent ping hostname awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "UNHEALTHY: required command '$cmd' is missing"
        exit 1
    fi
done

if [[ ! -x "$DIAGNOSTIC" ]]; then
    echo "UNHEALTHY: $DIAGNOSTIC is missing or not executable"
    exit 1
fi

if ! "$DIAGNOSTIC" help >/dev/null 2>&1; then
    echo "UNHEALTHY: '$DIAGNOSTIC help' failed"
    exit 1
fi

echo "HEALTHY"
exit 0
