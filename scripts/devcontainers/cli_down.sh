#!/usr/bin/env bash
set -euo pipefail

echo "=== devcontainer down: start ==="

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

COMPOSE_FILE="${COMPOSE_FILE:-docker/compose.yaml}"

echo "compose: $COMPOSE_FILE"
echo "=== docker compose down (keep volumes) ==="
docker compose -f "$COMPOSE_FILE" down --remove-orphans

echo "=== devcontainer down: done ==="
