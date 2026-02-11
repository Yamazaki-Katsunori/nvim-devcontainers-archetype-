# nvim-devcontainers-archetype

Neovim ユーザーと VS Code / Cursor / JetBrains 系ユーザーの **開発環境差異を最小化**することを目的にした、Dev Containers + Docker Compose ベースのテンプレートリポジトリです。

- **ランタイム / DB / ミドルウェア**はコンテナ側に寄せる（再現性・統一性）
- **Neovim は SSH 経由でコンテナに入り、ホストの nvim 設定を mount して利用**できる（編集体験の維持）
- VS Code など GUI エディタ利用者は通常どおり Dev Containers で開ける想定

---

## 1. 概要

このテンプレートは以下を提供します。  
※ compose 構成については、利用時に適宜変更してください。

### Docker Compose 構成（例）
- workspace（開発用）
- web（nginx）
- db（postgres）
- valkey（Redis互換 / in-memory）
- mailpit（mail）
- minio（S3互換オブジェクトストレージ）

### Neovim ユーザー向けスクリプト（`scripts/devcontainers/clis/`）
- `cli_up.sh`：通常起動（必要な mount / 付加 features / ssh鍵注入）
- `cli_rebuild.sh`：環境変更があった時の作り直し
- `cli_down.sh`：停止
- `cli_reset.sh`：完全初期化
- `cli_ssh_inject.sh`：公開鍵を `authorized_keys` に注入

---

## 2. 利用前の準備（ホスト側）

### 2.1 必須
- Docker Desktop（または Docker Engine + Compose）
- Node.js（devcontainer CLI を使う場合のみ）
- devcontainer CLI

実行例:
```
npm i -g @devcontainers/cli
```

### 2.2 SSH 鍵（Neovim ユーザー）
SSH 接続用の鍵がまだ無い場合は生成します。

実行例:
```
ssh-keygen -t ed25519 -C "devcontainer" -f ~/.ssh/id_ed25519
```

### 2.3 ssh-agent（任意：利便性UP）
毎回パスフレーズを打ちたくない場合（または鍵を明示的に読み込ませたい場合）:

実行例:
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

---

## 3. 利用手順

### 3.1 初回 or 環境変更があった場合（推奨）
Dockerfile / compose.yaml / devcontainer 設定を変更した後は `rebuild` を使います。

実行例:
```
./scripts/devcontainers/clis/cli_rebuild.sh
```

`NO_CACHE=1` を付けると no-cache rebuild します。

実行例:
```
NO_CACHE=1 ./scripts/devcontainers/clis/cli_rebuild.sh
```

### 3.2 通常起動
普段の起動は `up` を使います。

実行例:
```
./scripts/devcontainers/clis/cli_up.sh
```

### 3.3 SSH 接続（Neovim ユーザー）
`~/.ssh/config` に接続設定を入れておくと楽です（例）。

例:
```
Host devc-app
  HostName localhost
  Port 2222
  User vscode
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

接続:

実行例:
```
ssh devc-app
```

### 3.4 Neovim 起動（コンテナ内）
SSH で入った後、ラッパー（例：`nvim-devc`）で起動します。

実行例:
```
nvim-devc .
```

---

## 4. post_create_command.sh（テンプレ用）

### ポイント
- 実際の uv / pnpm インストールは行わない  
- ログ出力のみで処理が実行されたことを確認可能  
- 冪等性あり（再実行しても同じ処理は行われない）

実行例:
```
./scripts/devcontainers/post_create_command.sh
# => "postCreate command running..." がログに出力されます
```

### 必要に応じて
- 各自の環境に合わせてパッケージ追加や初期化コマンドを追記可能

---

## 5. git 操作

### 5.1 ホスト側 git
- `.devcontainer/compose.yaml` や `.env` などはホストリポジトリで管理
- `git add/commit/push` はホスト側で行う

例:
```
git status
git add .
git commit -m "Update devcontainer template"
git push
```

### 5.2 コンテナ内 git（workspace）
- ssh で workspace コンテナに入った上で作業可能

例:
```
ssh devc-app
cd /workspaces/app
git status
git add .
git commit -m "Test commit from container"
git push
```

### 5.3 Neovim 内 git操作（LazyVim 補助）
- `gitsigns.nvim` で diff / blame を確認  
- `vim-dadbod-completion` などで DB 関連補助  
- `:Gwrite`, `:Gcommit` など vim 内 git コマンドはプラグイン依存  
- 大規模変更や push はホストターミナル推奨

---

## 6. 補足事項

### Neovim 設定ファイルに関して
本テンプレートは **XDG Base Directory** に沿った Neovim 設定配置を前提にし、ホストの設定をコンテナへ mount して利用します。  
XDG 以外の配置で運用している場合は、mount 先や `nvim-devc`（ラッパー）の環境変数を調整してください。

`docker/services/workspace/Dockerfile` の例（抜粋）:
```
# -----------------------------------------------------------------------------
# 2) nvim wrapper to isolate XDG dirs in container
# -----------------------------------------------------------------------------
RUN cat > /usr/local/bin/nvim-devc <<'EOF' && chmod +x /usr/local/bin/nvim-devc
#!/usr/bin/env bash
set -euo pipefail
export XDG_CONFIG_HOME=/nvim-config
export XDG_DATA_HOME="${HOME}/.local/share-nvim-devc"
export XDG_STATE_HOME="${HOME}/.local/state-nvim-devc"
export XDG_CACHE_HOME="${HOME}/.cache-nvim-devc"
exec nvim "$@"
EOF
```

### devcontainer CLI スクリプトに関して
`cli_up.sh` および `cli_rebuild.sh` 内の `devcontainer up` オプションは、環境に合わせて適宜調整してください。

例（`cli_up.sh` 抜粋）:
```
ADDITIONAL_FEATURES_JSON=$(mktemp)
cat >"$ADDITIONAL_FEATURES_JSON" <<'EOF'
{
  "ghcr.io/devcontainers/features/sshd:1": {},
  "ghcr.io/stu-bell/devcontainer-features/neovim:0": {}
}
EOF

ARGS=(
  --workspace-folder "$WORKSPACE_DIR"
  --skip-post-create
  --additional-features "$(<"$ADDITIONAL_FEATURES_JSON")"
  --mount "type=bind,source=${NVIM_CONFIG_DIR},target=/nvim-config/nvim"
  --log-level trace
)
~~ 中略~~

# --- devcontainer up exec ---
devcontainer up "${ARGS[@]}" 2>&1 | tee -a "$LOG_FILE" &

```

---

## 7. 注意事項 / トレードオフ

### 7.1 セキュリティ（SSH 鍵 mount について）
本テンプレートは、Neovim ユーザーが SSH で入れる利便性を優先し、公開鍵注入を自動化しています。

- `cli_ssh_inject.sh` で **公開鍵**を `authorized_keys` に注入
- **秘密鍵をコンテナに mount しない**運用を推奨します


### 7.2 初回セットアップ時の Mason / Treesitter 競合
初回起動時に Mason / Treesitter のインストールが並列で走り、以下のようなメッセージが出ることがあります。

- `Package is already installing`

対処：
- 一度 `:qa` で終了 → 再起動で収束する場合が多い
- 必要なら Mason の tmp/state を削除してやり直す

### 7.3 “閉じた開発環境” と “編集体験” のバランス
- **統一性**：言語ランタイム・formatter・linter・test はコンテナに寄せやすい（再現性が高い）
- **編集体験**：Neovim をホストで使うため、SSH / mount / 権限などの摩擦が発生し得る
- 本テンプレートは「統一性を維持しつつ、Neovim の編集体験も残す」落とし所を狙っています

---

## 8. ディレクトリ構成（例）

例:
```
.
├── .devcontainer/
├── docker/
│   ├── compose.yaml
│   └── services/
        └── scripts
            └── devcontainers
                ├── clis
                │   ├── cli_down.sh
                │   ├── cli_rebuild.sh
                │   ├── cli_reset.sh
                │   ├── cli_ssh_inject.sh
                │   └── cli_up.sh
                └── post_create_command.sh
└── README.md
```

---

## License

License: Not specified yet (no license grant at this time).  
If you want to use this template in your project/company, please wait until a license is added or open an Issue.

