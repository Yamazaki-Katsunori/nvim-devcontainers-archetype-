#!/usr/bin/env bash
set -euo pipefail

echo "=== devcontainer up: start ==="

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

WORKSPACE_DIR="${WORKSPACE_DIR:-.}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-$HOME/.config/nvim}"
MAX_WAIT="${MAX_WAIT:-600}"
LOG_FILE="${LOG_FILE:-/tmp/devcontainer-up.log}"

if [[ ! -f "./.devcontainer/devcontainer.json" ]]; then
  echo "ERROR: ./.devcontainer/devcontainer.json not found" >&2
  exit 1
fi

if [[ ! -d "$NVIM_CONFIG_DIR" ]]; then
  echo "ERROR: nvim config dir not found: $NVIM_CONFIG_DIR" >&2
  echo "Tip: set NVIM_CONFIG_DIR=/path/to/nvim" >&2
  exit 1
fi

echo "workspace: $WORKSPACE_DIR"
echo "nvim cfg:  $NVIM_CONFIG_DIR"
echo "wait:      ${MAX_WAIT}s"
echo "log:       $LOG_FILE"

mkdir -p "$(dirname "$LOG_FILE")"
: >"$LOG_FILE"

{
  echo "=== $(date) ==="
  echo "PWD=$(pwd)"
  echo "devcontainer version:"
  devcontainer --version || true
  echo
} >>"$LOG_FILE" 2>&1

echo "=== check running (exec true) ==="
if devcontainer exec --workspace-folder "$WORKSPACE_DIR" bash -lc 'true' >/dev/null 2>&1; then
  echo "already running. (skip devcontainer up)"
  echo "=== ssh inject (call) ==="
  ./scripts/devcontainers/cli_ssh_inject.sh
  echo "=== devcontainer up: done ==="
  echo "Next: ssh devc-app"
  exit 0
fi

echo "=== devcontainer up (background) ==="
devcontainer up --workspace-folder "$WORKSPACE_DIR" \
  --skip-post-create \
  --default-user-env-probe none \
  --skip-non-blocking-commands \
  --additional-features '{
    "ghcr.io/devcontainers/features/sshd:1": {},
    "ghcr.io/duduribeiro/devcontainer-features/neovim:1": { "version": "stable" }
  }' \
  --mount "type=bind,source=${NVIM_CONFIG_DIR},target=/nvim-config/nvim" \
  >>"$LOG_FILE" 2>&1 &

UP_PID=$!

echo "=== wait ready (exec true) ==="
READY=0
for ((i = 1; i <= MAX_WAIT; i++)); do
  if ! kill -0 "$UP_PID" >/dev/null 2>&1; then
    echo "ERROR: devcontainer up exited before ready." >&2
    echo "---- log tail ----" >&2
    tail -n 200 "$LOG_FILE" >&2 || true
    exit 1
  fi

  if devcontainer exec --workspace-folder "$WORKSPACE_DIR" bash -lc 'true' >/dev/null 2>&1; then
    READY=1
    echo "ready."
    break
  fi

  if ((i % 10 == 0)); then
    echo "waiting... ${i}s"
  fi

  if ((i % 30 == 0)); then
    echo "---- log tail ----"
    tail -n 120 "$LOG_FILE" 2>/dev/null || true
    echo "------------------"
  fi

  sleep 1
done

if [[ "$READY" -ne 1 ]]; then
  echo "ERROR: container not ready (timeout: ${MAX_WAIT}s)" >&2
  echo "---- log tail ----" >&2
  tail -n 200 "$LOG_FILE" >&2 || true
  kill "$UP_PID" >/dev/null 2>&1 || true
  exit 1
fi

# ぶら下がり停止（コンテナは生きる）
kill "$UP_PID" >/dev/null 2>&1 || true
set +e
wait "$UP_PID" 2>/dev/null
set -e

echo "=== ssh inject (call) ==="
./scripts/devcontainers/cli_ssh_inject.sh

echo "=== devcontainer up: done ==="
echo "Next: ssh devc-app"
