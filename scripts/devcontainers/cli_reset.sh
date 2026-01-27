#!/usr/bin/env bash
set -euo pipefail

echo "=== devcontainer reset: start ==="

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

COMPOSE_FILE="${COMPOSE_FILE:-docker/compose.yaml}"

echo "compose: $COMPOSE_FILE"
echo "=== docker compose down -v (remove volumes) ==="
docker compose -f "$COMPOSE_FILE" down -v --remove-orphans

echo "=== devcontainer reset: done ==="
echo "Next: ./scripts/devcontainers/cli_up.sh"
