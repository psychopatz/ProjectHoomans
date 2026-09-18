#!/usr/bin/env bash

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "$HARNESS_DIR/../.." && pwd)"
VENV_DIR="$HARNESS_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
BOOTSTRAP_PYTHON="${PNC_HARNESS_PYTHON:-python3}"

if ! command -v "$BOOTSTRAP_PYTHON" >/dev/null 2>&1; then
    echo "semantic harness: Python executable not found: $BOOTSTRAP_PYTHON" >&2
    exit 2
fi

if ! "$BOOTSTRAP_PYTHON" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
    echo "semantic harness: Python 3.10 or newer is required" >&2
    exit 2
fi

if [ ! -x "$VENV_PYTHON" ]; then
    if [ -e "$VENV_DIR" ]; then
        echo "semantic harness: incomplete venv at $VENV_DIR; remove it or repair it, then retry" >&2
        exit 2
    fi
    echo "semantic harness: creating venv at $VENV_DIR"
    "$BOOTSTRAP_PYTHON" -m venv "$VENV_DIR"
fi

if [ ! -x "$VENV_PYTHON" ]; then
    echo "semantic harness: venv Python is unavailable: $VENV_PYTHON" >&2
    exit 2
fi

HARNESS_ARGS=("$@")
has_repository=0
for argument in "${HARNESS_ARGS[@]}"; do
    if [ "$argument" = "--repository" ]; then
        has_repository=1
        break
    fi
done
if [ "$has_repository" -eq 0 ]; then
    HARNESS_ARGS=(--repository "$REPOSITORY_ROOT" "${HARNESS_ARGS[@]}")
fi

cd "$REPOSITORY_ROOT"
if [ -n "${PYTHONPATH:-}" ]; then
    export PYTHONPATH="$REPOSITORY_ROOT:$PYTHONPATH"
else
    export PYTHONPATH="$REPOSITORY_ROOT"
fi

if [ "${1:-}" = "--test" ]; then
    shift
    exec "$VENV_PYTHON" "$REPOSITORY_ROOT/tests/run_tests.py" "$@"
fi

exec "$VENV_PYTHON" -m tools.semantic_harness.app "${HARNESS_ARGS[@]}"
