#!/usr/bin/env bash
set -euo pipefail

echo "=== devcontainer reset: start ==="

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"

COMPOSE_FILE="${COMPOSE_FILE:-.devcontainer/compose.yaml}"

echo "compose: $COMPOSE_FILE"
echo "=== docker compose down -v (remove volumes) ==="
docker compose --env-file .devcontainer/.env -f "$COMPOSE_FILE" down -v --remove-orphans

echo "=== devcontainer reset: done ==="
echo "Next: ./scripts/devcontainers/clis/cli_rebuild.sh"
