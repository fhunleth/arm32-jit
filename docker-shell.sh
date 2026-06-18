#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p .docker-home

if [[ $# -eq 0 ]]; then
    set -- bash
fi

exec docker compose run --rm --service-ports \
    --user "$(id -u):$(id -g)" \
    -e HOME=/workspace/arm32-jit/.docker-home \
    dev "$@"
