#!/usr/bin/env bash
set -euo pipefail

echo "=== devcontainer up: start ==="

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"

WORKSPACE_DIR="${WORKSPACE_DIR:-.}"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-$HOME/.config/nvim}"
MAX_WAIT="${MAX_WAIT:-400}"
LOG_FILE="${LOG_FILE:-/tmp/devcontainer-up.log}"

# ホスト側のGitConfig を利用可能とするための mount用（ホストの ~/.gitconfig をコンテナに注入）
HOST_GITCONFIG="${HOME}/.gitconfig"

UP_PID=""

cleanup() {
  if [ -n "${UP_PID}" ] && kill -0 "$UP_PID" 2>/dev/null; then
    echo "stopping devcontainer up (pid=$UP_PID)"
    kill "$UP_PID" 2>/dev/null || true
  fi
  rm -f "${ADDITIONAL_FEATURES_JSON:-}"
}

# スクリプト終了時・エラー時・Ctrl-C 時に必ず cleanup を呼ぶ
trap cleanup EXIT INT TERM

echo "REPO_ROOT: $REPO_ROOT"
echo "workspace: $WORKSPACE_DIR"
echo "nvim cfg:  $NVIM_CONFIG_DIR"
echo "wait:      ${MAX_WAIT}s"
echo "log:       $LOG_FILE"

mkdir -p "$(dirname "$LOG_FILE")"
: >"$LOG_FILE"

# JSON を安全に外部ファイル化して読み込み
ADDITIONAL_FEATURES_JSON=$(mktemp)
cat >"$ADDITIONAL_FEATURES_JSON" <<'EOF'
{
  "ghcr.io/devcontainers/features/sshd:1": {},
  "ghcr.io/stu-bell/devcontainer-features/neovim:0": {}
}
EOF

# ==================================================
# devcontainer comamnd ARGS | RUN_USER_COMMANDS_ARGS
# ==================================================
ARGS=(
  --workspace-folder "$WORKSPACE_DIR"
  --skip-post-create
  --additional-features "$(<"$ADDITIONAL_FEATURES_JSON")"
  --mount "type=bind,source=${NVIM_CONFIG_DIR},target=/nvim-config/nvim"
  --mount "type=bind,source=${HOST_GITCONFIG},target=/home/vscode/.gitconfig"
  --log-level trace
)

RUN_USER_COMMANDS_ARGS=(
  --workspace-folder "$WORKSPACE_DIR"
  --skip-post-attach
  --log-level trace
)

# devcontainer.json ファイルが見つからない場合 即終了
if [[ ! -f "./.devcontainer/devcontainer.json" ]]; then
  echo "ERROR: ./.devcontainer/devcontainer.json not found" >&2
  exit 1
fi

# neovim 設定ディレクトリが見つからなければ即終了
if [[ ! -d "$NVIM_CONFIG_DIR" ]]; then
  echo "ERROR: nvim config dir not found: $NVIM_CONFIG_DIR" >&2
  echo "Tip: set NVIM_CONFIG_DIR=/path/to/nvim" >&2
  exit 1
fi

# date | PWD | devcontainer version 表示
{
  echo "=== $(date) ==="
  echo "PWD=$(pwd)"
  echo "devcontainer version:"
  devcontainer --version || true
  echo
} >>"$LOG_FILE" 2>&1

# ====================
# devcontainer up 処理 (コンテナが既に up している場合)
# ====================
echo "=== check running (exec true) ==="
if devcontainer exec --workspace-folder "$WORKSPACE_DIR" -- echo ok >/dev/null 2>&1; then
  echo "already running. (skip devcontainer up)"

  # --- run devcontainer run-user-commands
  devcontainer run-user-commands "${RUN_USER_COMMANDS_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"

  echo "=== ssh inject (call) ==="
  ./scripts/devcontainers/clis/cli_ssh_inject.sh
  echo "=== devcontainer up: done ==="
  echo "Next: ssh devc-app"
  exit 0
fi

# ===============================================
# devcontainer up 処理 (コンテナ down 時のケース)
# ===============================================
echo "=== devcontainer up (background) ==="

# --- devcontainer up exec ---
devcontainer up "${ARGS[@]}" 2>&1 | tee -a "$LOG_FILE" &

UP_PID=$!

echo "devcontainer up pid=${UP_PID} (background)"
echo "log: $LOG_FILE"

# ==========================
# コンテナが起動するまで待機する処理 (後続コマンドを実行させるために定義)
# ==========================
echo "=== waiting container... ==="

START_TIME=$(date +%s)
until devcontainer exec --workspace-folder "$WORKSPACE_DIR" -- echo ok >/dev/null 2>&1; do
  sleep 1
  if (($(date +%s) - START_TIME > MAX_WAIT)); then
    echo "ERROR: container did not start within ${MAX_WAIT}s" >&2
    exit 1
  fi
done

# ===================================
# devcontainer run-user-commands 処理
# ===================================
echo "=== run devcontainer user commands (postCreate etc) ==="

# --- run devcontainer run-user-commands
devcontainer run-user-commands "${RUN_USER_COMMANDS_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"

# =================================
# neovim ssh 接続用の公開鍵注入処理
# =================================
echo "=== ssh inject (call) ==="
./scripts/devcontainers/clis/cli_ssh_inject.sh

# 一時ファイル削除
rm -f "$ADDITIONAL_FEATURES_JSON"

echo "=== devcontainer up: done ==="
echo "Next: ssh devc-app"
