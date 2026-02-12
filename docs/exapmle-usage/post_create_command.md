# post_create_command.sh 利用例

本ドキュメントでは、Dev Container の `postCreateCommand` を利用した  
初回セットアップ処理の実装例を説明します。

---

## 概要

`postCreateCommand` は、コンテナ作成後に一度だけ実行される処理です。

本テンプレートでは以下を目的としています：

- Backend / Frontend の初期セットアップ
- パッケージの自動インストール
- 冪等（idempotent）実行制御
- 実行ログの保存

---

## devcontainer.json 設定例

```json
{
  "postCreateCommand": "scripts/devcontainers/post_create_command.sh"
}
```

---

## post_create_command.sh 全体例

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND_ROOT="$REPO_ROOT/backend"
FRONTEND_ROOT="$REPO_ROOT/frontend"

export PATH="/usr/local/bin:$PATH"

: "${LOG_FILE:=/tmp/post_create_command.log}"
POSTCREATE_MARKER="/var/tmp/devcontainer-postcreate.done"

log() {
  echo "$@" | tee -a "$LOG_FILE"
}

run_shell() {
  local cmd="$1"
  log "+ $cmd"
  bash -lc "$cmd" 2>&1 | tee -a "$LOG_FILE"
}

log "=== postCreate: start ==="
log "log file: $LOG_FILE"

if [[ -f "$POSTCREATE_MARKER" ]]; then
  log "postCreate already executed. skip."
  exit 0
fi

mkdir -p "$(dirname "$POSTCREATE_MARKER")"

# Backend
if [[ -d "$BACKEND_ROOT" ]]; then
  cd "$BACKEND_ROOT"
  run_shell "uv init || true"

  if [[ -f "pyproject.toml" ]]; then
    run_shell "uv add --dev ruff pyright pytest"
    run_shell "uv add fastapi wireup"
    run_shell "uv sync"
  fi
fi

# Frontend
if [[ -d "$FRONTEND_ROOT" ]]; then
  cd "$FRONTEND_ROOT"
  run_shell "pnpm init || true"

  if [[ -f "package.json" ]]; then
    run_shell "pnpm add vite react react-router jotai tailwindcss"
    run_shell "pnpm add -D eslint prettier"
  fi
fi

touch "$POSTCREATE_MARKER"
log "postCreate marker created: $POSTCREATE_MARKER"
log "=== postCreate: done ==="
```

---

## 冪等性（Idempotency）

以下のマーカーファイルにより、複数回実行を防止しています：

```
/var/tmp/devcontainer-postcreate.done
```

これにより：

- `devcontainer rebuild`
- コンテナ再作成

時でも安全に運用可能です。

---

## ログ確認方法

```
cat /tmp/post_create_command.log
```

---

## カスタマイズ指針

このスクリプトは例です。実際のプロジェクトでは：

- DB migration 実行
- 初期 seed データ投入
- フロントエンド build
- monorepo bootstrap

などに置き換えてください。

---

## 推奨方針

postCreate は「環境初期化専用」に留めるのがベストです。

アプリのビルドや起動処理は docker-compose 側に責務を持たせると、
役割分離が明確になります。
